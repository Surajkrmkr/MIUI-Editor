import 'dart:io';
import 'package:archive/archive.dart';
import 'package:path/path.dart' as path;

/// Service to generate copyright zip files
class CopyrightService {
  /// Generate a zip file containing copyright information
  /// The zip contains a txt file with the original image URL
  Future<File> generateCopyrightZip({
    required String name,
    required String imageUrl,
    required String outputPath,
  }) async {
    // Create txt file content
    final txtContent = imageUrl;

    // Create archive
    final archive = Archive();

    // Add txt file to archive
    final txtFile = ArchiveFile(
      '$name.txt',
      txtContent.length,
      txtContent.codeUnits,
    );
    archive.addFile(txtFile);

    // Encode archive to zip
    final zipEncoder = ZipEncoder();
    final zipData = zipEncoder.encode(archive);

    // Write zip file
    final zipPath = path.join(outputPath, '$name.zip');
    final zipFile = File(zipPath);
    await zipFile.writeAsBytes(zipData);

    return zipFile;
  }

  /// Generate copyright zip from multiple URLs (batch operation)
  Future<File> generateBatchCopyrightZip({
    required Map<String, String> nameToUrlMap,
    required String outputPath,
    String? zipName,
  }) async {
    final archive = Archive();

    // Add each URL as a txt file
    for (final entry in nameToUrlMap.entries) {
      final txtContent = entry.value;
      final txtFile = ArchiveFile(
        '${entry.key}.txt',
        txtContent.length,
        txtContent.codeUnits,
      );
      archive.addFile(txtFile);
    }

    // Encode archive
    final zipEncoder = ZipEncoder();
    final zipData = zipEncoder.encode(archive);

    // Write zip file
    final fileName = zipName ?? 'copyright_batch_${DateTime.now().millisecondsSinceEpoch}';
    final zipPath = path.join(outputPath, '$fileName.zip');
    final zipFile = File(zipPath);
    await zipFile.writeAsBytes(zipData);

    return zipFile;
  }

  /// Extract copyright information from a zip file
  Future<Map<String, String>> extractCopyrightZip(File zipFile) async {
    final bytes = await zipFile.readAsBytes();
    final archive = ZipDecoder().decodeBytes(bytes);

    final Map<String, String> nameToUrlMap = {};

    for (final file in archive) {
      if (file.isFile && file.name.endsWith('.txt')) {
        final content = String.fromCharCodes(file.content as List<int>);
        final name = path.basenameWithoutExtension(file.name);
        nameToUrlMap[name] = content;
      }
    }

    return nameToUrlMap;
  }
}
