import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:googleapis_auth/auth_io.dart';

import '../../../wall_rio/application/providers/credentials_provider.dart';
import '../../../wall_rio/infrastructure/services/google_api_service.dart';
import '../../../wall_rio/infrastructure/services/storage_client.dart';
import '../../domain/buffy_storage_layout.dart';
import '../../infrastructure/services/buffy_secure_storage_service.dart';
import '../services/buffy_catalog_publisher.dart';
import 'buffy_credentials_provider.dart';

class BuffyStorageSignInRequired implements Exception {
  @override
  String toString() =>
      'Sign in with Google in Buffy Settings to allow Firebase Storage access.';
}

/// Uses the signed-in Google account, which bypasses the bucket's client rules.
final buffyCatalogPublisherProvider =
    FutureProvider<BuffyCatalogPublisher>((ref) async {
  await ref.watch(buffyCredentialsProvider.future);
  final secureStorage = BuffySecureStorageService();

  final saved = await secureStorage.getCredentials();
  if (saved == null ||
      !AccessCredentials.fromJson(saved).scopes.contains(storageScope)) {
    throw BuffyStorageSignInRequired();
  }

  final client = await GoogleApiService(secureStorage)
      .getAuthenticatedClient([storageScope]);
  if (client == null) throw BuffyStorageSignInRequired();
  ref.onDispose(client.close);
  return BuffyCatalogPublisher(StorageClient(client, kBuffyBucket));
});
