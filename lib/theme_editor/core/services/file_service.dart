import 'dart:io';
import 'package:path_provider/path_provider.dart';

class FileService {
  Future<String> get tempDirPath async => (await getTemporaryDirectory()).path;

  Future<String> get docDirPath async =>
      (await getApplicationDocumentsDirectory()).path;

  Future<File> writeBytes(String path, List<int> bytes) async {
    final f = File(path);
    await f.parent.create(recursive: true);
    return f.writeAsBytes(bytes);
  }

  Future<File> writeString(String path, String content) async {
    final f = File(path);
    await f.parent.create(recursive: true);
    return f.writeAsString(content);
  }

  Future<List<int>> readBytes(String path) => File(path).readAsBytes();
  Future<String> readString(String path) => File(path).readAsString();
  Future<bool> exists(String path) => File(path).exists();
  Future<bool> dirExists(String path) => Directory(path).exists();

  Future<Directory> createDir(String path) =>
      Directory(path).create(recursive: true);

  Future<void> copyFile(String src, String dest) async {
    await File(dest).parent.create(recursive: true);
    await File(src).copy(dest);
  }

  Future<void> deleteFile(String path) async {
    final f = File(path);
    if (await f.exists()) await f.delete();
  }

  Future<List<FileSystemEntity>> listDir(String path) async {
    final dir = Directory(path);
    if (!await dir.exists()) return [];
    return dir.list().toList();
  }
}
