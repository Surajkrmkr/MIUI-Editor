import '../../core/errors/failures.dart';
import '../../domain/entities/element_widget.dart';

abstract interface class PresetRepository {
  Future<Failure?> save(String presetName, List<LockElement> elements);
  Future<(List<LockElement>?, Failure?)> load(String jsonPath);
  Future<(List<String>, Failure?)> listPaths();
}
