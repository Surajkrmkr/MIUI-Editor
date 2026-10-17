import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:path/path.dart' as path;

import '../errors/failures.dart';
import '../layout/theme_layout.dart';
import 'theme_modules.dart';

/// Packs a theme workspace into a `.mtz` (zip).
///
/// Layout inside the archive:
///   description.xml, plugin_config.xml, wallpaper/  (flat)
///   one nested zip per module directory, named after the module and without
///   its folder name at the zip root, as the MIUI theme engine expects.
class MtzPackager {
  const MtzPackager();

  /// Writes `<parent>/<name>.mtz` and returns its path, or the failure.
  ///
  /// [descriptionXml] replaces the workspace's `description.xml` inside the
  /// archive when given.
  Future<(String?, Failure?)> pack({
    required ThemeLayout layout,
    required String name,
    String? descriptionXml,
  }) async {
    final hasSystemModules = ThemeModules.system.any(
      (m) => Directory(layout.module(m)).existsSync(),
    );
    if (hasSystemModules) {
      final missing = ThemeModules.missingOutputs(layout);
      if (missing.isNotEmpty) {
        return (
          null,
          ExportFailure(
            'Theme export is incomplete (missing ${missing.first}). '
            'Run Export again and fix its error before building the MTZ.',
          ),
        );
      }
    }

    final mtzPath = layout.mtzFile(name);
    final tempDir = layout.tempDir;
    ZipFileEncoder? encoder;
    try {
      await Directory(tempDir).create(recursive: true);
      encoder = ZipFileEncoder()..create(mtzPath);

      final descFile = File(layout.descriptionXml);
      if (descriptionXml != null) {
        final tempDesc = File(path.join(tempDir, 'description.xml'));
        await tempDesc.writeAsString(descriptionXml);
        encoder.addFile(tempDesc);
      } else if (descFile.existsSync()) {
        encoder.addFile(descFile);
      }

      final pluginFile = File(layout.pluginConfigXml);
      if (pluginFile.existsSync()) encoder.addFile(pluginFile);

      final wallDir = Directory(layout.wallpaperDir);
      if (wallDir.existsSync()) encoder.addDirectory(wallDir);

      for (final mod in ThemeModules.packed) {
        final modDir = Directory(layout.module(mod));
        if (!modDir.existsSync()) continue;

        final subZipPath = path.join(tempDir, mod);
        final subEnc = ZipFileEncoder()..create(subZipPath);
        await subEnc.addDirectory(modDir, includeDirName: false);
        subEnc.close();
        await encoder.addFile(File(subZipPath));
      }

      await encoder.close();
      encoder = null;
      return (mtzPath, null);
    } catch (e) {
      encoder?.close();
      return (null, ExportFailure(e.toString()));
    } finally {
      final temp = Directory(tempDir);
      if (temp.existsSync()) temp.deleteSync(recursive: true);
    }
  }
}
