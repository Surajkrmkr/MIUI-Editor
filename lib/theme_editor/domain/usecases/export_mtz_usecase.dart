import 'dart:io';
import 'package:archive/archive_io.dart';
import '../../core/constants/path_constants.dart';
import '../../core/errors/failures.dart';

/// Packs the theme folder into a .mtz (zip) file.
///
/// Structure inside the .mtz:
///   description.xml
///   plugin_config.xml
///   wallpaper/          (directory)
///   icons               (zipped sub-module)
///   clock_2x4           (zipped sub-module)
///   lockscreen          (zipped sub-module)
///
/// Each module sub-directory is zipped separately (without its folder name
/// at the root of the zip) to match the MIUI theme engine expectation.
///
/// When [dualVersion] is true, two MTZ files are produced:
///   - themeName_HyperOS1.mtz  → description.xml with uiVersion=15
///   - themeName_HyperOS3.mtz  → description.xml with uiVersion=17
class ExportMtzUseCase {
  const ExportMtzUseCase();

  static const List<String> _modules = ['icons', 'clock_2x4', 'lockscreen'];

  Future<(String?, Failure?)> call({
    required String themePath,
    required String themeName,
    bool dualVersion = false,
  }) async {
    if (dualVersion) {
      return _exportDual(themePath, themeName);
    }
    return _exportSingle(themePath, themeName, null);
  }

  // ── Dual version export ────────────────────────────────────────────────────

  Future<(String?, Failure?)> _exportDual(
      String themePath, String themeName) async {
    final (_, f1) =
        await _exportSingle(themePath, '${themeName}_V1', '15');
    if (f1 != null) return (null, f1);

    final (path2, f2) =
        await _exportSingle(themePath, '${themeName}_V3', '17');
    if (f2 != null) return (null, f2);

    final parentDir = Directory(themePath).parent.path;
    return (parentDir, null);
  }

  // ── Single version export ──────────────────────────────────────────────────

  Future<(String?, Failure?)> _exportSingle(
    String themePath,
    String themeName,
    String? overrideUiVersion,
  ) async {
    final parentDir = Directory(themePath).parent.path;
    final mtzPath =
        PathConstants.p('$parentDir${PathConstants.sep}$themeName.mtz');
    final tempDir = PathConstants.p('${themePath}temp${PathConstants.sep}');

    ZipFileEncoder? encoder;
    try {
      await Directory(tempDir).create(recursive: true);
      encoder = ZipFileEncoder()..create(mtzPath);

      // description.xml — optionally with overridden uiVersion
      final descFile = File(PathConstants.p('${themePath}description.xml'));
      if (descFile.existsSync()) {
        if (overrideUiVersion != null) {
          final original = await descFile.readAsString();
          final modified = original.replaceFirst(
            RegExp(r'<uiVersion>[^<]*</uiVersion>'),
            '<uiVersion>$overrideUiVersion</uiVersion>',
          );
          final tempDescPath =
              PathConstants.p('${tempDir}description.xml');
          await File(tempDescPath).writeAsString(modified);
          encoder.addFile(File(tempDescPath));
        } else {
          encoder.addFile(descFile);
        }
      }

      // plugin_config.xml
      final pluginFile =
          File(PathConstants.p('${themePath}plugin_config.xml'));
      if (pluginFile.existsSync()) encoder.addFile(pluginFile);

      // Wallpaper directory (flat — no sub-zip)
      final wallDir = Directory(PathConstants.wallpaperDir(themePath));
      if (wallDir.existsSync()) encoder.addDirectory(wallDir);

      // Each module → zipped into temp/ then added to main zip
      for (final mod in _modules) {
        final modDir = Directory(PathConstants.p('$themePath$mod'));
        if (!modDir.existsSync()) continue;

        final subZipPath = PathConstants.p('$tempDir$mod');
        final subEnc = ZipFileEncoder()..create(subZipPath);
        await subEnc.addDirectory(modDir, includeDirName: false);
        subEnc.close();
        await encoder.addFile(File(subZipPath));
      }

      await encoder.close();
      encoder = null;

      // Clean up temp
      await Directory(tempDir).delete(recursive: true);

      return (mtzPath, null);
    } catch (e) {
      encoder?.close();
      return (null, ExportFailure(e.toString()));
    }
  }
}
