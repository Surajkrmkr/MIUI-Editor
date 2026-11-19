import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/models/catalog.dart';

class AppSettingsService {
  static const String _admobPublisherIdKey = 'admob_publisher_id';
  static const String _playPackageNameKey = 'play_package_name';
  static const String _bucketKey = 'wallrio_storage_bucket';
  static const String _publicBaseUrlKey = 'wallrio_storage_public_base_url';
  static const _r2Keys = {
    'accountId': 'wallrio_r2_account_id',
    'accessKeyId': 'wallrio_r2_access_key_id',
    'secretAccessKey': 'wallrio_r2_secret_access_key',
  };
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
    final bucket = prefs.getString(_bucketKey);
    // A bucket saved while the data was on Firebase isn't an R2 bucket name.
    final isFirebaseBucket = bucket != null &&
        (bucket.endsWith('.firebasestorage.app') ||
            bucket.endsWith('.appspot.com'));
    final base = prefs.getString(_publicBaseUrlKey) ?? defaults.publicBaseUrl;
    return StorageSettings(
      bucket: bucket == null || isFirebaseBucket ? defaults.bucket : bucket,
      publicBaseUrl: base.endsWith('/') ? base : '$base/',
      jsonFolder: prefs.getString(_jsonFolderKey) ?? defaults.jsonFolder,
      imagesRoot: prefs.getString(_imagesRootKey) ?? defaults.imagesRoot,
      liveRoot: prefs.getString(_liveRootKey) ?? defaults.liveRoot,
    );
  }

  Future<void> setStorageSettings(StorageSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_bucketKey, settings.bucket);
    await prefs.setString(_publicBaseUrlKey, settings.publicBaseUrl);
    await prefs.setString(_jsonFolderKey, settings.jsonFolder);
    await prefs.setString(_imagesRootKey, settings.imagesRoot);
    await prefs.setString(_liveRootKey, settings.liveRoot);
  }

  /// Cloudflare R2 S3 API keys: accountId, accessKeyId, secretAccessKey.
  /// Empty strings when not set.
  Future<Map<String, String>> getR2Keys() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      for (final e in _r2Keys.entries) e.key: prefs.getString(e.value) ?? '',
    };
  }

  Future<void> setR2Keys(Map<String, String> keys) async {
    final prefs = await SharedPreferences.getInstance();
    for (final e in _r2Keys.entries) {
      await prefs.setString(e.value, keys[e.key] ?? '');
    }
  }
}
