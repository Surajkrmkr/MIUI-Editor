import '../models/cms_models.dart';

abstract class VersionRepository {
  Future<List<LocalVersion>> getVersions(String filePath);
  Future<void> saveVersion(LocalVersion version);
  Future<void> deleteVersion(String id);
}
