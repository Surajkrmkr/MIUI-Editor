import '../../core/errors/failures.dart';
import '../../domain/repositories/tag_repository.dart';

class LoadTagFileUseCase {
  const LoadTagFileUseCase(this._repo);
  final TagRepository _repo;

  Future<(List<String>?, Failure?)> call(
          String weekNum, String themeName) =>
      _repo.load(weekNum, themeName);
}
