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
class ExportMtzUseCase {
  const ExportMtzUseCase();

  static const List<String> _modules = ['icons', 'clock_2x4', 'lockscreen'];

  Future<(String?, Failure?)> call({
    required String themePath,
    required String themeName,
  }) async {
    // Output path: parent of theme folder / themeName.mtz
    final parentDir = Directory(themePath).parent.path;
    final mtzPath =
        PathConstants.p('$parentDir${PathConstants.sep}$themeName.mtz');
    final tempDir = PathConstants.p('${themePath}temp${PathConstants.sep}');

    ZipFileEncoder? encoder;
    try {
      await Directory(tempDir).create(recursive: true);
      encoder = ZipFileEncoder()..create(mtzPath);

      // Root XML files
      final descFile = File(PathConstants.p('${themePath}description.xml'));
      final pluginFile = File(PathConstants.p('${themePath}plugin_config.xml'));
      if (descFile.existsSync()) encoder.addFile(descFile);
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
