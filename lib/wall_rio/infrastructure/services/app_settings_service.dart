import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/models/catalog.dart';

class AppSettingsService {
  static const String _admobPublisherIdKey = 'admob_publisher_id';
  static const String _playPackageNameKey = 'play_package_name';
  static const String _bucketKey = 'wallrio_storage_bucket';
  static const String _jsonFolderKey = 'wallrio_storage_json_folder';
  static const String _imagesRootKey = 'wallrio_storage_images_root';
  static const String _liveRootKey = 'wallrio_storage_live_root';

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

  Future<StorageSettings> getStorageSettings() async {
    final prefs = await SharedPreferences.getInstance();
    const defaults = StorageSettings();
    return StorageSettings(
      bucket: prefs.getString(_bucketKey) ?? defaults.bucket,
      jsonFolder: prefs.getString(_jsonFolderKey) ?? defaults.jsonFolder,
      imagesRoot: prefs.getString(_imagesRootKey) ?? defaults.imagesRoot,
      liveRoot: prefs.getString(_liveRootKey) ?? defaults.liveRoot,
    );
  }

  Future<void> setStorageSettings(StorageSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_bucketKey, settings.bucket);
    await prefs.setString(_jsonFolderKey, settings.jsonFolder);
    await prefs.setString(_imagesRootKey, settings.imagesRoot);
    await prefs.setString(_liveRootKey, settings.liveRoot);
  }
}
