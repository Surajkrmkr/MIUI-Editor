import 'dart:convert';
import 'dart:io';
import '../../core/constants/path_constants.dart';
import '../../core/errors/failures.dart';
import '../../domain/entities/element_widget.dart';
import '../../domain/repositories/preset_repository.dart';

class PresetRepositoryImpl implements PresetRepository {
  @override
  Future<Failure?> save(String presetName, List<LockElement> elements) async {
    try {
      final path = PathConstants.p(
          '${PathConstants.presetPath}$presetName${PathConstants.sep}preset.json');
      final dir = File(path).parent;
      await dir.create(recursive: true);
      await File(path).writeAsString(
        jsonEncode(elements.map((e) => e.toJson()).toList()),
      );
      return null;
    } catch (e) {
      return FileFailure(e.toString());
    }
  }

  @override
  Future<(List<LockElement>?, Failure?)> load(String jsonPath) async {
    try {
      final raw = await File(jsonPath).readAsString();
      final list = (jsonDecode(raw) as List<dynamic>)
          .map((e) => LockElement.fromJson(e as Map<String, dynamic>))
          .toList();
      return (list, null);
    } catch (e) {
      return (null, FileFailure(e.toString()));
    }
  }

  @override
  Future<(List<String>, Failure?)> listPaths() async {
    try {
      final dir = Directory(PathConstants.presetPath);
      if (!await dir.exists()) return (const <String>[], null);
      final paths = (await dir.list().toList())
          .whereType<Directory>()
          .map((d) => d.path)
          .toList();
      paths.sort();
      return (paths, null);
    } catch (e) {
      return (const <String>[], FileFailure(e.toString()));
    }
  }
}
