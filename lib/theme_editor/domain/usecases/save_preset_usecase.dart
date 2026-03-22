import '../../core/errors/failures.dart';
import '../../domain/entities/element_widget.dart';
import '../../domain/repositories/preset_repository.dart';

class SavePresetUseCase {
  const SavePresetUseCase(this._repo);
  final PresetRepository _repo;

  Future<Failure?> call(String presetName, List<LockElement> elements) =>
      _repo.save(presetName, elements);
}
