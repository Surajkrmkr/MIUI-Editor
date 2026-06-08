import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/credential_models.dart';
import '../../infrastructure/services/secure_storage_service.dart';
import '../../infrastructure/services/google_api_service.dart';

class CredentialsStateNotifier extends AsyncNotifier<CredentialStatus> {
  final _storage = SecureStorageService();
  final _googleAuth = GoogleApiService();

  @override
  FutureOr<CredentialStatus> build() async {
    final config = await _storage.getOAuthConfig();
    final credentials = await _storage.getCredentials();

    return CredentialStatus(
      isSignedIn: credentials != null,
      clientId: config['clientId'],
      clientSecret: config['clientSecret'],
      firebaseProjectId: config['projectId'],
    );
  }

  Future<void> saveConfig({
    required String clientId,
    required String clientSecret,
    required String projectId,
  }) async {
    await _storage.saveOAuthConfig(
      clientId: clientId,
      clientSecret: clientSecret,
      projectId: projectId,
    );
    ref.invalidateSelf();
  }

  Future<bool> signIn() async {
    final success = await _googleAuth.signIn([
      'https://www.googleapis.com/auth/firebase.messaging',
      'https://www.googleapis.com/auth/admob.report',
      'https://www.googleapis.com/auth/playdeveloperreporting',
    ]);
    if (success) ref.invalidateSelf();
    return success;
  }

  Future<void> clearAll() async {
    await _storage.deleteAll();
    ref.invalidateSelf();
  }
}

final credentialsStateProvider =
    AsyncNotifierProvider<CredentialsStateNotifier, CredentialStatus>(
  CredentialsStateNotifier.new,
);
