import 'dart:typed_data';
import '../../core/errors/failures.dart';
import '../../domain/entities/element_widget.dart';

abstract interface class PresetRepository {
  Future<Failure?> save(String presetName, List<LockElement> elements, {Uint8List? previewBytes});
  Future<(List<LockElement>?, Failure?)> load(String jsonPath);
  Future<(List<String>, Failure?)> listPaths();
}
