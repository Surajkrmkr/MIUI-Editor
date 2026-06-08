import 'package:hive_flutter/hive_flutter.dart';
import '../../domain/models/cms_models.dart';
import '../../domain/repositories/settings_repository.dart';

class HiveSettingsRepository implements SettingsRepository {
  static const String _boxName = 'settings';
  static const String _pathsKey = 'saved_paths';

  Future<Box> _getBox() async {
    return await Hive.openBox(_boxName);
  }

  @override
  Future<List<SavedFilePath>> getSavedPaths() async {
    final box = await _getBox();
    final List? data = box.get(_pathsKey);
    List<SavedFilePath> paths = data == null ? [] : data.cast<SavedFilePath>().toList();
    
    // Add default live wall path if not present
    const liveWallPath = r'D:\Team Shadow\wallriojson\live_wall.json';
    if (!paths.any((p) => p.path == liveWallPath)) {
      paths.add(SavedFilePath(
        path: liveWallPath,
        label: 'Live Wallpapers',
        lastOpened: DateTime.fromMillisecondsSinceEpoch(0),
      ));
    }

    return paths..sort((a, b) => b.lastOpened.compareTo(a.lastOpened));
  }

  @override
  Future<void> savePath(SavedFilePath path) async {
    final box = await _getBox();
    final paths = await getSavedPaths();
    final index = paths.indexWhere((p) => p.path == path.path);
    
    if (index != -1) {
      paths[index] = path;
    } else {
      paths.add(path);
    }
    
    await box.put(_pathsKey, paths);
  }

  @override
  Future<void> removePath(String path) async {
    final box = await _getBox();
    final paths = await getSavedPaths();
    paths.removeWhere((p) => p.path == path);
    await box.put(_pathsKey, paths);
  }

  @override
  Future<void> updateLastOpened(String path) async {
    final paths = await getSavedPaths();
    final index = paths.indexWhere((p) => p.path == path);
    if (index != -1) {
      final updated = paths[index].copyWith(lastOpened: DateTime.now());
      await savePath(updated);
    }
  }
}
