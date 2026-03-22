import 'dart:io';
import 'package:flutter/material.dart';
import 'package:xml/xml.dart';
import '../../core/constants/path_constants.dart';
import '../../core/errors/failures.dart';
import '../../domain/entities/user_profile.dart';
import '../../resources/color_values.dart';
import '../../resources/description.dart';

/// Copies module XMLs + PNGs, writes description.xml, plugin_config.xml,
/// clock manifest, and wallpaper files.
///
/// Mirrors the original ModuleProvider.copyModule() but:
///  - no BuildContext dependency for data operations
///  - accent color injected as a value (not pulled from a Provider inside)
///  - all paths go through PathConstants.p()
class ExportModuleUseCase {
  const ExportModuleUseCase();

  Future<Failure?> call({
    required Color accentColor,
    required UserProfile profile,
    required String themePath,
    required String themeName,
    required String wallpaperSourcePath,
  }) async {
    try {
      // ── 1. Copy module XML files + theme_values.xml ───────────────────────
      for (final module in _modules) {
        for (final subDir in PathConstants.subDirs) {
          final srcDir = PathConstants.p(
              '${PathConstants.sample2Path}$module${PathConstants.sep}$subDir');
          final dstDir =
              PathConstants.p('$themePath$module${PathConstants.sep}$subDir');

          await Directory(dstDir).create(recursive: true);

          final src = Directory(srcDir);
          if (!await src.exists()) continue;

          await for (final entity in src.list()) {
            if (entity is File) {
              final fileName =
                  entity.path.split(Platform.isWindows ? r'\' : '/').last;
              await entity.copy(PathConstants.p('$dstDir$fileName'));
            }
          }
        }

        // Copy theme_fallback.xml
        final fallbackSrc = PathConstants.p(
            '${PathConstants.sample2Path}$module${PathConstants.sep}theme_fallback.xml');
        final fallbackDst = PathConstants.p(
            '$themePath$module${PathConstants.sep}theme_fallback.xml');
        if (await File(fallbackSrc).exists()) {
          await File(fallbackSrc).copy(fallbackDst);
        }

        // Write accent-substituted theme_values.xml
        final xmlTemplate = ColorValues.getXmlString[module];
        if (xmlTemplate != null) {
          final accentHex =
              '#ff${accentColor.toARGB32().toRadixString(16).substring(2, 8)}';
          final substituted = xmlTemplate.replaceAll('#ffff8cee', accentHex);
          final doc = XmlDocument.parse(substituted);
          await File(PathConstants.p(
                  '$themePath$module${PathConstants.sep}theme_values.xml'))
              .writeAsString(doc.toXmlString(pretty: true, indent: '\t'));
        }
      }

      // ── 2. Wallpaper ──────────────────────────────────────────────────────
      final wallDir = PathConstants.wallpaperDir(themePath);
      await Directory(wallDir).create(recursive: true);
      await File(wallpaperSourcePath)
          .copy(PathConstants.p('${wallDir}default_lock_wallpaper.jpg'));
      await File(wallpaperSourcePath)
          .copy(PathConstants.p('${wallDir}default_wallpaper.jpg'));

      // ── 3. clock_2x4/manifest.xml ─────────────────────────────────────────
      final clockDir =
          PathConstants.p('${themePath}clock_2x4${PathConstants.sep}');
      await Directory(clockDir).create(recursive: true);
      await File(PathConstants.p('${clockDir}manifest.xml')).writeAsString(
        XmlDocument.parse(ThemeDescription.clockManifest)
            .toXmlString(pretty: true, indent: '\t'),
      );

      // ── 4. description.xml ────────────────────────────────────────────────
      final rawDesc = ThemeDescription.buildDescription(
        themeName: themeName,
        designerName: profile.displayName,
        authorTag: profile.authorTag,
      );
      await File(PathConstants.p('${themePath}description.xml')).writeAsString(
        XmlDocument.parse(rawDesc).toXmlString(pretty: true, indent: '\t'),
      );

      // ── 5. plugin_config.xml ──────────────────────────────────────────────
      await File(PathConstants.p('${themePath}plugin_config.xml'))
          .writeAsString(
        XmlDocument.parse(ThemeDescription.pluginConfig)
            .toXmlString(pretty: true, indent: '\t'),
      );

      return null;
    } catch (e) {
      return ExportFailure(e.toString());
    }
  }

  // Modules that get XML color files copied (extend this list freely)
  static const List<String> _modules = [
    'com.android.contacts',
    'com.android.mms',
    'com.android.systemui',
    'com.android.settings',
  ];
}
