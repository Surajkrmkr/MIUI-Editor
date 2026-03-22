import '../../core/errors/failures.dart';
import '../../domain/entities/element_widget.dart';
import '../../domain/repositories/preset_repository.dart';

class LoadPresetUseCase {
  const LoadPresetUseCase(this._repo);
  final PresetRepository _repo;

  Future<(List<LockElement>?, Failure?)> call(String jsonPath) =>
      _repo.load(jsonPath);
}
