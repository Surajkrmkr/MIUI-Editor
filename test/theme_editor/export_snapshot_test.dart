import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show FontLoader;
import 'package:flutter_test/flutter_test.dart';
import 'package:theme_core/theme_core.dart';

import 'fixtures/mtz_snapshot.dart';
import 'package:miui_icon_generator/theme_editor/domain/entities/user_profile.dart';
import 'package:miui_icon_generator/theme_editor/domain/usecases/export_combined_usecase.dart';
import 'package:miui_icon_generator/theme_editor/domain/usecases/export_icons_usecase.dart';
import 'package:miui_icon_generator/theme_editor/domain/usecases/export_module_usecase.dart';
import 'package:miui_icon_generator/theme_editor/domain/usecases/export_mtz_usecase.dart';

/// Characterization test for the export pipeline (icons, module, system
/// modules, .mtz). Regenerate the golden with `UPDATE_GOLDENS=1 flutter test`.
const _goldenPath = 'test/theme_editor/goldens/export_snapshot.json';
const _themeName = 'GoldenTheme';

Future<void> _loadMaterialIcons() async {
  // flutter_tester lives at <root>/bin/cache/artifacts/engine/<platform>/.
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

Future<String> _wallpaper(String dir) async {
  final rec = ui.PictureRecorder();
  const r = Rect.fromLTWH(0, 0, 1200, 2600);
  Canvas(rec).drawRect(
    r,
    Paint()
      ..shader = ui.Gradient.linear(r.topLeft, r.bottomRight, const [
        Color(0xff0b1026),
        Color(0xff2a1b4d),
      ]),
  );
  final image = await rec.endRecording().toImage(1200, 2600);
  final png = await image.toByteData(format: ui.ImageByteFormat.png);
  final f = File('$dir/wall.png')..writeAsBytesSync(png!.buffer.asUint8List());
  return f.path;
}

void main() {
  testWidgets('full export produces the expected .mtz contents', (
    tester,
  ) async {
    await tester.runAsync(() async {
      await _loadMaterialIcons();

      final root = Directory('build/export_snapshot');
      if (root.existsSync()) root.deleteSync(recursive: true);
      root.createSync(recursive: true);
      final themePath = '${root.path}/$_themeName/';
      Directory(themePath).createSync(recursive: true);
      final wall = await _wallpaper(root.path);

      final failure =
          await const ExportCombinedUseCase(
            exportIcons: ExportIconsUseCase(),
            exportModule: ExportModuleUseCase(),
          ).call(
            style: const IconStyle(
              shape: IconShape.cookie7,
              effect: IconEffect.liquidGlass,
              texture: IconTexture.grain,
              bgColor: Rgba(0xff3d7bff),
              bgColor2: Rgba(0xff8a5cff),
              accent: Rgba(0xff3d7bff),
            ),
            profile: kUserProfiles[UserProfileType.suraj]!,
            layout: ThemeLayout(themePath),
            themeName: _themeName,
            wallpaperSourcePath: wall,
            iconNames: const [
              'com.android.mms',
              'com.android.settings',
              'com.android.contacts',
            ],
            onProgress: (_, __) {},
            designerName: 'Golden Designer',
            authorTag: 'GD',
            uiVersion: '17',
          );
      expect(failure, isNull, reason: failure?.toString());

      final (mtzPath, mtzFailure) = await const ExportMtzUseCase().call(
        layout: ThemeLayout(themePath),
        themeName: _themeName,
      );
      expect(mtzFailure, isNull, reason: mtzFailure?.toString());
      expect(mtzPath, isNotNull);

      final actual = snapshotMtz(mtzPath!);

      final description = actual['description.xml'];
      expect(
        description,
        isNotNull,
        reason: 'description.xml missing from .mtz',
      );
      final descriptionXml = File(
        '${themePath}description.xml',
      ).readAsStringSync();
      expect(descriptionXml, contains('<uiVersion>17</uiVersion>'));
      expect(descriptionXml, contains('Golden Designer'));

      final golden = File(_goldenPath);
      if (Platform.environment['UPDATE_GOLDENS'] == '1' ||
          !golden.existsSync()) {
        golden.parent.createSync(recursive: true);
        golden.writeAsStringSync(
          '${const JsonEncoder.withIndent('  ').convert(actual)}\n',
        );
        // ignore: avoid_print
        print('Wrote golden: $_goldenPath (${actual.length} entries)');
        return;
      }

      final expected = Map<String, Object>.from(
        jsonDecode(golden.readAsStringSync()) as Map,
      );
      expect(diffSnapshots(expected, actual), isEmpty);
    });
  });
}
