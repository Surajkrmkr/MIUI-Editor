import 'package:shared_preferences/shared_preferences.dart';

class AppSettingsService {
  static const String _jsonPathKey = 'wallrio_json_path';
  static const String _wallpaperRepoPathKey = 'wallrio_wallpaper_repo_path';
  static const String _admobPublisherIdKey = 'admob_publisher_id';
  static const String _playPackageNameKey = 'play_package_name';

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

  Future<String?> getWallpaperRepoPath() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_wallpaperRepoPathKey);
  }

  Future<void> setWallpaperRepoPath(String path) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_wallpaperRepoPathKey, path);
  }
}
