import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../../../wall_rio/infrastructure/services/r2_storage_client.dart';
import '../services/buffy_catalog_publisher.dart';
import 'buffy_credentials_provider.dart';

class BuffyStorageSignInRequired implements Exception {
  @override
  String toString() =>
      'Add the Cloudflare R2 keys in Buffy Settings → Credentials.';
}

/// Talks to the R2 bucket with the S3 API keys saved in Buffy Settings.
final buffyCatalogPublisherProvider =
    FutureProvider<BuffyCatalogPublisher>((ref) async {
  final status = await ref.watch(buffyCredentialsProvider.future);
  if (!status.hasR2) throw BuffyStorageSignInRequired();

  final client = http.Client();
  ref.onDispose(client.close);
  return BuffyCatalogPublisher(
    R2StorageClient(
      client,
      accountId: status.r2['accountId']!,
      accessKeyId: status.r2['accessKeyId']!,
      secretAccessKey: status.r2['secretAccessKey']!,
      bucket: status.r2['bucket']!,
    ),
  );
});
