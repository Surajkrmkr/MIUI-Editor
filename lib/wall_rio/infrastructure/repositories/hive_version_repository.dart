import 'package:hive_flutter/hive_flutter.dart';
import '../../domain/models/cms_models.dart';
import '../../domain/repositories/version_repository.dart';

class HiveVersionRepository implements VersionRepository {
  static const String _boxName = 'versions';

  Future<Box<LocalVersion>> _getBox() async {
    return await Hive.openBox<LocalVersion>(_boxName);
  }

  @override
  Future<List<LocalVersion>> getVersions(String filePath) async {
    final box = await _getBox();
    return box.values
        .where((v) => v.filePath == filePath)
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  @override
  Future<void> saveVersion(LocalVersion version) async {
    final box = await _getBox();
    await box.put(version.id, version);
  }

  @override
  Future<void> deleteVersion(String id) async {
    final box = await _getBox();
    await box.delete(id);
  }
}
