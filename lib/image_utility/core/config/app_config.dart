import 'package:shared_preferences/shared_preferences.dart';

/// Manages app configuration and API keys
class AppConfig {
  static const String _pexelsKeyPref = 'pexels_api_key';
  static const String _unsplashKeyPref = 'unsplash_api_key';
  static const String _pixabayKeyPref = 'pixabay_api_key';
  static const String _fireflyKeyPref = 'firefly_api_key';
  static const String _geminiKeyPref = 'gemini_api_key';
  static const String _upscaylKeyPref = 'upscayl_api_key';
  static const String _downloadPathPref = 'download_path';
  static const String _tagsPathPref = 'tags_path';  // Changed from tagsJsonPath
  static const String _copyrightPathPref = 'copyright_path';

  final SharedPreferences _prefs;

  AppConfig(this._prefs);

  static Future<AppConfig> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    return AppConfig(prefs);
  }

  // Pexels API Key
  String? get pexelsApiKey => _prefs.getString(_pexelsKeyPref);
  Future<void> setPexelsApiKey(String key) async {
    await _prefs.setString(_pexelsKeyPref, key);
  }

  // Unsplash API Key
  String? get unsplashApiKey => _prefs.getString(_unsplashKeyPref);
  Future<void> setUnsplashApiKey(String key) async {
    await _prefs.setString(_unsplashKeyPref, key);
  }

  // Pixabay API Key
  String? get pixabayApiKey => _prefs.getString(_pixabayKeyPref);
  Future<void> setPixabayApiKey(String key) async {
    await _prefs.setString(_pixabayKeyPref, key);
  }

  // Adobe Firefly API Key
  String? get fireflyApiKey => _prefs.getString(_fireflyKeyPref);
  Future<void> setFireflyApiKey(String key) async {
    await _prefs.setString(_fireflyKeyPref, key);
  }

  // Gemini API Key
  String? get geminiApiKey => _prefs.getString(_geminiKeyPref);
  Future<void> setGeminiApiKey(String key) async {
    await _prefs.setString(_geminiKeyPref, key);
  }

  // Upscayl API Key
  String? get upscaylApiKey => _prefs.getString(_upscaylKeyPref);
  Future<void> setUpscaylApiKey(String key) async {
    await _prefs.setString(_upscaylKeyPref, key);
  }

  // Download Path
  String? get downloadPath => _prefs.getString(_downloadPathPref);
  Future<void> setDownloadPath(String path) async {
    await _prefs.setString(_downloadPathPref, path);
  }

  // Tags Directory Path (changed from tagsJsonPath)
  String? get tagsPath => _prefs.getString(_tagsPathPref);
  Future<void> setTagsPath(String path) async {
    await _prefs.setString(_tagsPathPref, path);
  }

  // Copyright Path
  String? get copyrightPath => _prefs.getString(_copyrightPathPref);
  Future<void> setCopyrightPath(String path) async {
    await _prefs.setString(_copyrightPathPref, path);
  }

  // Clear all API keys
  Future<void> clearAllKeys() async {
    await _prefs.remove(_pexelsKeyPref);
    await _prefs.remove(_unsplashKeyPref);
    await _prefs.remove(_pixabayKeyPref);
    await _prefs.remove(_fireflyKeyPref);
    await _prefs.remove(_geminiKeyPref);
    await _prefs.remove(_upscaylKeyPref);
  }

  // Check if any provider is configured
  bool hasAnyProvider() {
    return (pexelsApiKey?.isNotEmpty ?? false) ||
           (unsplashApiKey?.isNotEmpty ?? false) ||
           (pixabayApiKey?.isNotEmpty ?? false) ||
           (fireflyApiKey?.isNotEmpty ?? false);
  }
}
