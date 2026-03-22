import '../../core/errors/failures.dart';
import '../../domain/repositories/tag_repository.dart';

class SaveTagFileUseCase {
  const SaveTagFileUseCase(this._repo);
  final TagRepository _repo;

  Future<Failure?> call(
          String weekNum, String themeName, List<String> tags) =>
      _repo.save(weekNum, themeName, tags);
}
