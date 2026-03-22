import '../../core/errors/failures.dart';

abstract interface class TagRepository {
  Future<Failure?> save(String weekNum, String themeName, List<String> tags);
  Future<(List<String>?, Failure?)> load(String weekNum, String themeName);
}
