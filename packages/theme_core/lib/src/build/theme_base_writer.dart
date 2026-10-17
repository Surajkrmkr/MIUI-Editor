import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:xml/xml.dart';

import '../layout/theme_layout.dart';
import 'description.dart';

/// Writes the files every theme needs regardless of style: wallpapers, clock
/// widget manifest, `description.xml` and `plugin_config.xml`.
class ThemeBaseWriter {
  const ThemeBaseWriter();

  /// Throws on I/O or malformed template errors.
  ///
  /// [uiVersion] is the target OS build; HyperOS 3 is `17`.
  Future<void> write({
    required ThemeLayout layout,
    required String title,
    required String designer,
    required String authorTag,
    required String wallpaperSourcePath,
    String? lockWallpaperSourcePath,
    String uiVersion = '17',
  }) async {
    await Directory(layout.wallpaperDir).create(recursive: true);
    await File(
      lockWallpaperSourcePath ?? wallpaperSourcePath,
    ).copy(layout.defaultLockWallpaper);
    await File(wallpaperSourcePath).copy(layout.defaultWallpaper);

    await Directory(layout.clockDir).create(recursive: true);
    await File(
      layout.clockManifest,
    ).writeAsString(_pretty(ThemeDescription.clockManifest));

    await Directory(
      path.dirname(layout.descriptionXml),
    ).create(recursive: true);
    await File(layout.descriptionXml).writeAsString(
      _pretty(
        ThemeDescription.buildDescription(
          themeName: title,
          designerName: designer,
          authorTag: authorTag,
          uiVersion: uiVersion,
        ),
      ),
    );
    await File(
      layout.pluginConfigXml,
    ).writeAsString(_pretty(ThemeDescription.pluginConfig));
  }

  static String _pretty(String xml) =>
      XmlDocument.parse(xml).toXmlString(pretty: true, indent: '\t');
}
