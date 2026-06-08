import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

// All persistent data uses SharedPreferences — flutter_secure_storage Keychain
// writes fail silently on macOS dev builds without a signed keychain-access-groups
// entitlement, making sign-in state appear lost after every restart.
// For a desktop app the SharedPreferences pref file is already on-device only.
class SecureStorageService {
  // Kept only to delete legacy Keychain entries during clearAll.
  static const _legacyStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static const _clientIdKey     = 'wallrio_oauth_client_id';
  static const _clientSecretKey = 'wallrio_oauth_client_secret';
  static const _projectIdKey    = 'wallrio_fcm_project_id';
  static const _credentialsKey  = 'wallrio_oauth_credentials';

  // ── OAuth config ───────────────────────────────────────────────────────────

  Future<void> saveOAuthConfig({
    required String clientId,
    required String clientSecret,
    required String projectId,
  }) async {
    debugPrint('[WallRio] saveOAuthConfig: clientId=${clientId.isEmpty ? "<empty>" : "${clientId.substring(0, clientId.length.clamp(0, 12))}…"}');
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_clientIdKey, clientId);
    await prefs.setString(_clientSecretKey, clientSecret);
    await prefs.setString(_projectIdKey, projectId);
    debugPrint('[WallRio] saveOAuthConfig: written to SharedPreferences ✓');
  }

  Future<Map<String, String?>> getOAuthConfig() async {
    final prefs = await SharedPreferences.getInstance();
    final result = {
      'clientId':     prefs.getString(_clientIdKey),
      'clientSecret': prefs.getString(_clientSecretKey),
      'projectId':    prefs.getString(_projectIdKey),
    };
    debugPrint('[WallRio] getOAuthConfig: clientId=${result['clientId'] == null ? "null" : "present"}, projectId=${result['projectId'] ?? "null"}');
    return result;
  }

  // ── OAuth credentials (access + refresh tokens) ────────────────────────────

  Future<void> saveCredentials(Map<String, dynamic> json) async {
    debugPrint('[WallRio] saveCredentials: saving ${json.keys.toList()}');
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_credentialsKey, jsonEncode(json));
    // Verify write succeeded
    final verify = prefs.getString(_credentialsKey);
    debugPrint('[WallRio] saveCredentials: verified=${verify != null} ✓');
  }

  Future<Map<String, dynamic>?> getCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_credentialsKey);
    debugPrint('[WallRio] getCredentials: stored=${data != null ? "yes (${data.length} chars)" : "null"}');
    if (data == null) return null;
    return jsonDecode(data) as Map<String, dynamic>;
  }

  Future<void> deleteAll() async {
    debugPrint('[WallRio] deleteAll: clearing all credentials');
    // Clear SharedPreferences keys
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_clientIdKey);
    await prefs.remove(_clientSecretKey);
    await prefs.remove(_projectIdKey);
    await prefs.remove(_credentialsKey);
    // Also attempt to clear any legacy Keychain entries
    try {
      await _legacyStorage.deleteAll();
    } catch (e) {
      debugPrint('[WallRio] deleteAll: legacy Keychain clear skipped: $e');
    }
    debugPrint('[WallRio] deleteAll: done ✓');
  }
}
