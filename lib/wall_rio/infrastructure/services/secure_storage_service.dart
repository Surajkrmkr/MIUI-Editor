import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static const _clientIdKey = 'oauth_client_id';
  static const _clientSecretKey = 'oauth_client_secret';
  static const _projectIdKey = 'fcm_project_id';
  static const _credentialsKey = 'oauth_credentials';

  Future<void> saveOAuthConfig({
    required String clientId,
    required String clientSecret,
    required String projectId,
  }) async {
    await _storage.write(key: _clientIdKey, value: clientId);
    await _storage.write(key: _clientSecretKey, value: clientSecret);
    await _storage.write(key: _projectIdKey, value: projectId);
  }

  Future<Map<String, String?>> getOAuthConfig() async {
    return {
      'clientId': await _storage.read(key: _clientIdKey),
      'clientSecret': await _storage.read(key: _clientSecretKey),
      'projectId': await _storage.read(key: _projectIdKey),
    };
  }

  Future<void> saveCredentials(Map<String, dynamic> json) async {
    await _storage.write(key: _credentialsKey, value: jsonEncode(json));
  }

  Future<Map<String, dynamic>?> getCredentials() async {
    final data = await _storage.read(key: _credentialsKey);
    if (data == null) return null;
    return jsonDecode(data) as Map<String, dynamic>;
  }

  Future<void> deleteAll() async {
    await _storage.deleteAll();
  }
}
