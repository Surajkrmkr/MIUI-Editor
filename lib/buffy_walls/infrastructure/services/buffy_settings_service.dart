import 'package:shared_preferences/shared_preferences.dart';

class BuffySettingsService {
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
}
