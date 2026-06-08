import 'dart:io';
import 'package:path/path.dart' as p;

class FileScanner {
  static final _supportedExtensions = {'.jpg', '.jpeg', '.png'};

  /// Recursively scans a directory for supported image files
  static Future<List<File>> scanForImages(String directoryPath) async {
    final dir = Directory(directoryPath);
    if (!await dir.exists()) return [];

    final files = <File>[];
    
    // Use recursive list, but catch potential access denied errors
    await for (final entity in dir.list(recursive: true, followLinks: false).handleError((e) {
      // Ignore files/folders that cannot be accessed
    })) {
      if (entity is File) {
        final ext = p.extension(entity.path).toLowerCase();
        if (_supportedExtensions.contains(ext)) {
          files.add(entity);
        }
      }
    }

    return files;
  }

  /// Calculates the expected output path preserving sub-directory structure
  static String calculateOutputPath(String rootFolder, String currentFilePath) {
    // rootFolder: Wallpapers
    // currentFilePath: Wallpapers/Nature/a.jpg
    // relative: Nature/a.jpg
    final relativePath = p.relative(currentFilePath, from: rootFolder);
    
    // newDir: Wallpapers/svg/Nature
    final baseName = p.basenameWithoutExtension(currentFilePath);
    final relativeDir = p.dirname(relativePath);
    
    final outputDir = p.join(rootFolder, 'svg', relativeDir == '.' ? '' : relativeDir);
    return p.join(outputDir, '$baseName.svg');
  }
}