import 'package:shared_preferences/shared_preferences.dart';

class BuffySettingsService {
  static const String _jsonPathKey = 'buffy_json_file_path';
  static const String _localRepoPathKey = 'buffy_local_repo_path';
  static const String _admobPublisherIdKey = 'buffy_admob_publisher_id';
  static const String _playPackageNameKey = 'buffy_play_package_name';

  Future<String?> getAdMobPublisherId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_admobPublisherIdKey);
  }

  Future<void> setAdMobPublisherId(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_admobPublisherIdKey, id);
  }

  Future<String?> getPlayPackageName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_playPackageNameKey);
  }

  Future<void> setPlayPackageName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_playPackageNameKey, name);
  }

  Future<String?> getJsonPath() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_jsonPathKey);
  }

  Future<void> setJsonPath(String path) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_jsonPathKey, path);
  }

  Future<String?> getLocalRepoPath() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_localRepoPathKey);
  }

  Future<void> setLocalRepoPath(String path) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_localRepoPathKey, path);
  }
}
