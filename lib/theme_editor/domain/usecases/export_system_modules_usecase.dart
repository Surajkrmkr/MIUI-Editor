import 'package:flutter/material.dart';
import 'package:theme_core/theme_core.dart';
import 'package:theme_raster_flutter/theme_raster_flutter.dart';

/// Generates the HyperOS 3 system app modules; the drawing lives in
/// theme_raster_flutter's [SystemModulesRenderer].
class ExportSystemModulesUseCase {
  const ExportSystemModulesUseCase();

  static const List<String> modules = SystemModulesRenderer.modules;

  static List<String> missingOutputs(ThemeLayout layout) =>
      SystemModulesRenderer.missingOutputs(layout);

  static String withColors(String xml, Map<String, Color> colors) =>
      SystemModulesRenderer.withColors(xml, colors);

  static Future<WallpaperPalette> wallpaperPalette(String path) =>
      SystemModulesRenderer.wallpaperPalette(path);

  Future<Failure?> call({
    required Color accent,
    required ThemeLayout layout,
    required String wallpaperSourcePath,
    IconStyle style = const IconStyle(),
    String iconFolder = 'u1',
  }) => const SystemModulesRenderer().render(
    accent: accent,
    layout: layout,
    wallpaperSourcePath: wallpaperSourcePath,
    style: style,
    iconFolder: iconFolder,
  );
}
