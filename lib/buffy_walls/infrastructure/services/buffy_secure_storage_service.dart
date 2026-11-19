import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BuffySecureStorageService {
  static const _clientIdKey     = 'buffy_oauth_client_id';
  static const _clientSecretKey = 'buffy_oauth_client_secret';
  static const _projectIdKey    = 'buffy_fcm_project_id';
  static const _credentialsKey  = 'buffy_oauth_credentials';
  static const _r2Keys = {
    'accountId': 'buffy_r2_account_id',
    'accessKeyId': 'buffy_r2_access_key_id',
    'secretAccessKey': 'buffy_r2_secret_access_key',
    'bucket': 'buffy_r2_bucket',
  };

  /// Cloudflare R2 S3 API keys: accountId, accessKeyId, secretAccessKey,
  /// bucket. Values are never logged.
  Future<void> saveR2Config(Map<String, String> config) async {
    final prefs = await SharedPreferences.getInstance();
    for (final e in _r2Keys.entries) {
      await prefs.setString(e.value, config[e.key] ?? '');
    }
    debugPrint('[Buffy] saveR2Config: saved ✓');
  }

  Future<Map<String, String>> getR2Config() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      for (final e in _r2Keys.entries) e.key: prefs.getString(e.value) ?? '',
    };
  }

  Future<void> saveOAuthConfig({
    required String clientId,
    required String clientSecret,
    required String projectId,
  }) async {
    debugPrint('[Buffy] saveOAuthConfig: clientId=${clientId.isEmpty ? "<empty>" : "${clientId.substring(0, clientId.length.clamp(0, 12))}…"}');
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_clientIdKey, clientId);
    await prefs.setString(_clientSecretKey, clientSecret);
    await prefs.setString(_projectIdKey, projectId);
    debugPrint('[Buffy] saveOAuthConfig: written to SharedPreferences ✓');
  }

  Future<Map<String, String?>> getOAuthConfig() async {
    final prefs = await SharedPreferences.getInstance();
    final result = {
      'clientId':     prefs.getString(_clientIdKey),
      'clientSecret': prefs.getString(_clientSecretKey),
      'projectId':    prefs.getString(_projectIdKey),
    };
    debugPrint('[Buffy] getOAuthConfig: clientId=${result['clientId'] == null ? "null" : "present"}, projectId=${result['projectId'] ?? "null"}');
    return result;
  }

  Future<void> saveCredentials(Map<String, dynamic> json) async {
    debugPrint('[Buffy] saveCredentials: saving ${json.keys.toList()}');
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_credentialsKey, jsonEncode(json));
    debugPrint('[Buffy] saveCredentials: saved ✓');
  }

  Future<Map<String, dynamic>?> getCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_credentialsKey);
    if (data == null) return null;
    return jsonDecode(data) as Map<String, dynamic>;
  }

  Future<void> deleteAll() async {
    debugPrint('[Buffy] deleteAll: clearing all credentials');
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_clientIdKey);
    await prefs.remove(_clientSecretKey);
    await prefs.remove(_projectIdKey);
    await prefs.remove(_credentialsKey);
    for (final key in _r2Keys.values) {
      await prefs.remove(key);
    }
    debugPrint('[Buffy] deleteAll: done ✓');
  }
}
