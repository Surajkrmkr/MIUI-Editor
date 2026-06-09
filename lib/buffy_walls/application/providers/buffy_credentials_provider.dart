import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/buffy_credential_models.dart';
import '../../infrastructure/services/buffy_secure_storage_service.dart';
import '../../../wall_rio/infrastructure/services/google_api_service.dart';

class BuffyCredentialsStateNotifier extends AsyncNotifier<BuffyCredentialStatus> {
  final _storage = BuffySecureStorageService();
  late final _googleAuth = GoogleApiService(_storage);

  @override
  FutureOr<BuffyCredentialStatus> build() async {
    debugPrint('[Buffy] BuffyCredentialsStateNotifier.build: loading…');
    final config = await _storage.getOAuthConfig();
    final credentials = await _storage.getCredentials();

    final status = BuffyCredentialStatus(
      isSignedIn: credentials != null,
      clientId: config['clientId'],
      clientSecret: config['clientSecret'],
      firebaseProjectId: config['projectId'],
    );
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
    debugPrint('[Buffy] BuffyCredentialsStateNotifier.signIn: starting…');
    final success = await _googleAuth.signIn([
      'https://www.googleapis.com/auth/firebase.messaging',
      'https://www.googleapis.com/auth/admob.report',
      'https://www.googleapis.com/auth/playdeveloperreporting',
    ]);
    if (success) {
      ref.invalidateSelf();
    }
    return success;
  }

  Future<void> clearAll() async {
    await _storage.deleteAll();
    ref.invalidateSelf();
  }
}

final buffyCredentialsProvider =
    AsyncNotifierProvider<BuffyCredentialsStateNotifier, BuffyCredentialStatus>(
  BuffyCredentialsStateNotifier.new,
);
