import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/credential_models.dart';
import '../../infrastructure/services/secure_storage_service.dart';
import '../../infrastructure/services/google_api_service.dart';

class CredentialsStateNotifier extends AsyncNotifier<CredentialStatus> {
  final _storage = SecureStorageService();
  final _googleAuth = GoogleApiService();

  @override
  FutureOr<CredentialStatus> build() async {
    debugPrint('[WallRio] CredentialsStateNotifier.build: loading…');
    final config = await _storage.getOAuthConfig();
    final credentials = await _storage.getCredentials();

    final status = CredentialStatus(
      isSignedIn: credentials != null,
      clientId: config['clientId'],
      clientSecret: config['clientSecret'],
      firebaseProjectId: config['projectId'],
    );
    debugPrint('[WallRio] CredentialsStateNotifier.build: isSignedIn=${status.isSignedIn}, clientId=${status.clientId == null ? "null" : "present"}');
    return status;
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
    // Update state in-place — avoids loading flash that breaks the form UI
    final current = state.value;
    if (current != null) {
      state = AsyncValue.data(current.copyWith(
        clientId: clientId,
        clientSecret: clientSecret,
        firebaseProjectId: projectId,
      ));
    }
  }

  Future<bool> signIn() async {
    debugPrint('[WallRio] CredentialsStateNotifier.signIn: starting…');
    final success = await _googleAuth.signIn([
      'https://www.googleapis.com/auth/firebase.messaging',
      'https://www.googleapis.com/auth/admob.report',
      'https://www.googleapis.com/auth/playdeveloperreporting',
    ]);
    debugPrint('[WallRio] CredentialsStateNotifier.signIn: result=$success');
    if (success) {
      debugPrint('[WallRio] CredentialsStateNotifier.signIn: invalidating provider…');
      ref.invalidateSelf();
    }
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
