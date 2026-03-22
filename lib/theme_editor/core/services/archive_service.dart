import 'dart:io';
import 'package:archive/archive_io.dart';

class ArchiveService {
  Future<void> compressDir(String sourceDir, String destPath,
      {bool includeDirName = false}) async {
    final enc = ZipFileEncoder()..create(destPath);
    await enc.addDirectory(Directory(sourceDir),
        includeDirName: includeDirName);
    enc.close();
  }

  ZipFileEncoder createEncoder(String destPath) =>
      ZipFileEncoder()..create(destPath);
}
