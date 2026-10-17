import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:path/path.dart' as p;
import 'package:theme_core/theme_core.dart';

import 'adapters.dart';
import 'icons/icon_renderer.dart';
import 'lockscreen/lock_element_spec_bridge.dart';
import 'lockscreen/lockscreen_frame_renderer.dart';
import 'system/system_modules_renderer.dart';

/// [ThemeRenderer] backed by `dart:ui`; the images come out the same whether
/// it runs inside the app or headless under the Flutter test runner.
///
/// Icons, templates and weather art are read from the asset bundle, so the
/// host project must declare the repo's `assets/` folders.
class FlutterThemeRenderer implements ThemeRenderer {
  /// [context] gives the lockscreen frame capture a theme and text direction.
  FlutterThemeRenderer({required this.context, AssetBundle? bundle})
    : _bundle = bundle ?? rootBundle;

  final BuildContext context;
  final AssetBundle _bundle;

  @override
  Future<void> loadFonts(List<FontFile> fonts) async {
    final byFamily = <String, FontLoader>{};
    for (final f in fonts) {
      final bytes = await File(f.path).readAsBytes();
      (byFamily[f.family] ??= FontLoader(
        f.family,
      )).addFont(Future.value(ByteData.sublistView(Uint8List.fromList(bytes))));
    }
    for (final loader in byFamily.values) {
      await loader.load();
    }
  }

  @override
  Future<List<String>> iconNames(String pack) async {
    final manifest = await AssetManifest.loadFromAssetBundle(_bundle);
    final prefix = 'assets/icons/$pack/';
    return [
      for (final key in manifest.listAssets())
        if (key.startsWith(prefix) && key.endsWith('.svg'))
          p.basenameWithoutExtension(key),
    ]..sort();
  }

  @override
  Future<Failure?> renderIcons({
    required ThemeLayout layout,
    required IconStyle style,
    required String pack,
    required List<String> iconNames,
    ProgressCallback? onProgress,
  }) => const IconRenderer().render(
    style: style,
    pack: pack,
    layout: layout,
    iconNames: iconNames,
    onProgress: onProgress,
  );

  @override
  Future<Failure?> renderSystemModules({
    required ThemeLayout layout,
    required IconStyle style,
    required String iconPack,
    required String wallpaperPath,
  }) => const SystemModulesRenderer().render(
    accent: style.accent.toColor(),
    layout: layout,
    wallpaperSourcePath: wallpaperPath,
    style: style,
    iconFolder: iconPack,
  );

  @override
  Future<Failure?> renderLockscreenFrames({
    required ThemeLayout layout,
    required List<LockElementSpec> elements,
    ProgressCallback? onProgress,
  }) => const LockscreenFrameRenderer().render(
    context: context,
    elements: [for (final e in elements) e.toLockElement()],
    layout: layout,
    onProgress: onProgress ?? (_, __) {},
  );
}
