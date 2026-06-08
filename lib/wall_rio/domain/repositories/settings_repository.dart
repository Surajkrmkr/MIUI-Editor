import '../../domain/models/cms_models.dart';

abstract class SettingsRepository {
  Future<List<SavedFilePath>> getSavedPaths();
  Future<void> savePath(SavedFilePath path);
  Future<void> removePath(String path);
  Future<void> updateLastOpened(String path);
}
