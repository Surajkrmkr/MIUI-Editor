import 'dart:io';
import '../../core/constants/path_constants.dart';
import '../../core/errors/failures.dart';
import '../../domain/repositories/tag_repository.dart';

class TagRepositoryImpl implements TagRepository {
  @override
  Future<Failure?> save(
      String weekNum, String themeName, List<String> tags) async {
    try {
      final tagDir = PathConstants.tagDirectory(weekNum);
      await Directory(tagDir).create(recursive: true);
      await File(PathConstants.p('$tagDir$themeName.txt'))
          .writeAsString(tags.join(','));
      return null;
    } catch (e) {
      return FileFailure(e.toString());
    }
  }

  @override
  Future<(List<String>?, Failure?)> load(
      String weekNum, String themeName) async {
    try {
      final path =
          PathConstants.p('${PathConstants.tagDirectory(weekNum)}$themeName.txt');
      final file = File(path);
      if (!await file.exists()) return (null, null); // no file yet — not an error
      final content = await file.readAsString();
      return (content.split(',').where((t) => t.isNotEmpty).toList(), null);
    } catch (e) {
      return (null, FileFailure(e.toString()));
    }
  }
}
