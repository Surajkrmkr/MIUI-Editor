import 'dart:typed_data';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show FontLoader;
import 'package:flutter_test/flutter_test.dart';
import 'package:miui_icon_generator/theme_editor/domain/entities/user_profile.dart';
import 'package:miui_icon_generator/theme_editor/domain/usecases/export_combined_usecase.dart';
import 'package:miui_icon_generator/theme_editor/domain/usecases/export_icons_usecase.dart';
import 'package:miui_icon_generator/theme_editor/domain/usecases/export_lockscreen_pngs_usecase.dart';
import 'package:miui_icon_generator/theme_editor/domain/usecases/export_module_usecase.dart';
import 'package:miui_icon_generator/theme_editor/domain/usecases/export_mtz_usecase.dart';
import 'package:miui_icon_generator/theme_editor/presentation/providers/element_provider.dart';
import 'package:path/path.dart' as p;
import 'package:theme_core/theme_core.dart';
import 'package:theme_raster_flutter/theme_raster_flutter.dart';

import 'fixtures/mtz_snapshot.dart';

/// ThemeBuilder + FlutterThemeRenderer must produce the same .mtz as the
/// editor's own export steps run by hand for the same inputs.
const _style = IconStyle(
  shape: IconShape.cookie7,
  effect: IconEffect.liquidGlass,
  texture: IconTexture.grain,
  bgColor: Rgba(0xff3d7bff),
  bgColor2: Rgba(0xff8a5cff),
  accent: Rgba(0xff3d7bff),
);

Future<void> _loadMaterialIcons() async {
  final flutterRoot =
      Platform.environment['FLUTTER_ROOT'] ??
      File(
        Platform.resolvedExecutable,
      ).parent.parent.parent.parent.parent.parent.path;
  final font = File(
    '$flutterRoot/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
  );
  if (!font.existsSync()) return;
  final loader = FontLoader('MaterialIcons')
    ..addFont(Future.value(ByteData.sublistView(font.readAsBytesSync())));
  await loader.load();
}

Future<void> _png(String path, Color a, Color b, int w, int h) async {
  final rec = ui.PictureRecorder();
  final r = Rect.fromLTWH(0, 0, w.toDouble(), h.toDouble());
  Canvas(rec).drawRect(
    r,
    Paint()..shader = ui.Gradient.linear(r.topLeft, r.bottomRight, [a, b]),
  );
  final image = await rec.endRecording().toImage(w, h);
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  File(path)
    ..createSync(recursive: true)
    ..writeAsBytesSync(data!.buffer.asUint8List());
}

void main() {
  testWidgets('spec build equals the editor export', (tester) async {
    await tester.pumpWidget(const SizedBox());
    final context = tester.element(find.byType(SizedBox));

    await tester.runAsync(() async {
      await _loadMaterialIcons();

      final root = Directory('build/theme_builder_test');
      if (root.existsSync()) root.deleteSync(recursive: true);
      root.createSync(recursive: true);
      final base = p.absolute(root.path);
      await _png(
        '$base/wall.png',
        const Color(0xff0b1026),
        const Color(0xff2a1b4d),
        1200,
        2600,
      );
      await _png('$base/assets/bg.png', Colors.black, Colors.black, 270, 585);

      final spec = ThemeSpec.fromJson({
        'specVersion': 1,
        'meta': {'title': 'Neon', 'designer': 'Designer', 'authorTag': 'Tag'},
        'wallpaper': {'home': 'wall.png'},
        'icons': IconsSpec.fromStyle(_style, pack: 'u1').toJson(),
        'systemUi': SystemUiSpec(
          accent: _style.accent,
          controlCenterTemplate: _style.ccTemplate,
        ).toJson(),
        'lockscreen': {
          'assetsDir': 'assets',
          'bgAlpha': 0.2,
          'elements': [
            {'type': 'swipeUpUnlock'},
            {'type': 'hourClock', 'color': 0xFFEEDD99},
            {
              'type': 'analogClock',
              'analogStyle': 'minimal',
              'width': 300,
              'height': 300,
            },
            {'type': 'shortcutSet', 'shortcutStyle': 'glossDock', 'width': 260},
          ],
        },
      });

      // ── New path ─────────────────────────────────────────────────────────
      final (built, failure) = await ThemeBuilder(
        FlutterThemeRenderer(context: context),
      ).build(spec, BuildOptions(baseDir: base, outDir: '$base/new'));
      expect(failure, isNull, reason: failure?.message);

      // ── Old path: the editor's own steps ────────────────────────────────
      final layout = ThemeLayout('$base/old/Neon');
      Directory(layout.root).createSync(recursive: true);
      final names = await FlutterThemeRenderer(
        context: context,
      ).iconNames('u1');
      final combined =
          await const ExportCombinedUseCase(
            exportIcons: ExportIconsUseCase(),
            exportModule: ExportModuleUseCase(),
          ).call(
            style: spec.iconStyle,
            profile: kUserProfiles[UserProfileType.suraj]!,
            layout: layout,
            themeName: 'Neon',
            wallpaperSourcePath: '$base/wall.png',
            iconNames: names,
            onProgress: (_, __) {},
            designerName: 'Designer',
            authorTag: 'Tag',
            uiVersion: '17',
          );
      expect(combined, isNull, reason: combined?.message);

      Directory(layout.lockscreenAdvance).createSync(recursive: true);
      File(
        '$base/assets/bg.png',
      ).copySync('${layout.lockscreenAdvance}/bg.png');
      File('${layout.lockscreenAdvance}/manifest.xml').writeAsStringSync(
        const ManifestBuilder()
            .build(spec.lockscreen.elements, bgAlpha: 0.2)
            .toXmlString(),
      );
      final frames = await const ExportLockscreenPngsUseCase().call(
        context: context,
        elementState: ElementState(
          elements: [
            for (final e in spec.lockscreen.elements) e.toLockElement(),
          ],
        ),
        layout: layout,
        onProgress: (_, __) {},
      );
      expect(frames, isNull, reason: frames?.message);

      final (oldMtz, packFailure) = await const ExportMtzUseCase().call(
        layout: layout,
        themeName: 'Neon',
      );
      expect(packFailure, isNull, reason: packFailure?.message);

      // ── Compare ──────────────────────────────────────────────────────────
      // The builder copies the theme's home icons into the lockscreen's icon
      // folder; the editor does that in a separate step this test skips.
      Map<String, Object> snap(String mtz) =>
          Map.of(snapshotMtz(mtz))
            ..removeWhere((k, _) => k.startsWith('lockscreen!/advance/icon/'));

      final expected = snap(oldMtz!);
      final actual = snap(built!.mtzPath);
      expect(expected.keys.where((k) => k.startsWith('icons!/')), isNotEmpty);
      expect(
        expected.keys.where((k) => k.startsWith('lockscreen!/')),
        isNotEmpty,
      );
      expect(diffSnapshots(expected, actual), isEmpty);
    });
  });
}
