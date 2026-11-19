import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/catalog.dart';
import 'package:http/http.dart' as http;

import '../../infrastructure/services/app_settings_service.dart';
import '../../infrastructure/services/r2_storage_client.dart';
import '../../infrastructure/services/storage_client.dart';
import '../services/catalog_service.dart';

/// Thrown when the Cloudflare R2 keys haven't been entered yet.
class NotSignedInException implements Exception {
  @override
  String toString() =>
      'Add the Cloudflare R2 keys in Settings → Storage to load the catalogs.';
}

/// Cloudflare R2 S3 API keys: accountId, accessKeyId, secretAccessKey.
class R2KeysNotifier extends AsyncNotifier<Map<String, String>> {
  final _service = AppSettingsService();

  @override
  FutureOr<Map<String, String>> build() => _service.getR2Keys();

  Future<void> save(Map<String, String> keys) async {
    await _service.setR2Keys(keys);
    state = AsyncValue.data(Map.of(keys));
  }
}

final r2KeysProvider =
    AsyncNotifierProvider<R2KeysNotifier, Map<String, String>>(
      R2KeysNotifier.new,
    );

class StorageSettingsNotifier extends AsyncNotifier<StorageSettings> {
  final _service = AppSettingsService();

  @override
  FutureOr<StorageSettings> build() => _service.getStorageSettings();

  Future<void> save(StorageSettings settings) async {
    await _service.setStorageSettings(settings);
    state = AsyncValue.data(settings);
  }
}

final storageSettingsProvider =
    AsyncNotifierProvider<StorageSettingsNotifier, StorageSettings>(
      StorageSettingsNotifier.new,
    );

/// R2 client for the saved keys; rebuilt when the keys or bucket change.
final storageClientProvider = FutureProvider<StorageClient>((ref) async {
  final keys = await ref.watch(r2KeysProvider.future);
  final settings = await ref.watch(storageSettingsProvider.future);
  if (keys.values.any((v) => v.isEmpty) || keys.length < 3) {
    throw NotSignedInException();
  }
  final client = http.Client();
  ref.onDispose(client.close);
  return R2StorageClient(
    client,
    accountId: keys['accountId']!,
    accessKeyId: keys['accessKeyId']!,
    secretAccessKey: keys['secretAccessKey']!,
    bucket: settings.bucket,
  );
});

final catalogServiceProvider = FutureProvider<CatalogService>((ref) async {
  final storage = await ref.watch(storageClientProvider.future);
  final settings = await ref.watch(storageSettingsProvider.future);
  return CatalogService(storage, settings);
});

class SelectedKindNotifier extends Notifier<CatalogKind> {
  @override
  CatalogKind build() => CatalogKind.mobile;

  void select(CatalogKind kind) => state = kind;
}

final selectedKindProvider =
    NotifierProvider<SelectedKindNotifier, CatalogKind>(
      SelectedKindNotifier.new,
    );

/// The collection shown in the Collections tab; null means "the first one".
class SelectedCollectionNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void select(String? id) => state = id;
}

final selectedCollectionProvider =
    NotifierProvider<SelectedCollectionNotifier, String?>(
      SelectedCollectionNotifier.new,
    );

/// The live catalog for one kind, plus the actions that change it. Each action
/// saves to Storage and then replaces the state with what was saved.
class CatalogNotifier
    extends FamilyAsyncNotifier<CatalogDocument, CatalogKind> {
  @override
  FutureOr<CatalogDocument> build(CatalogKind kind) async {
    final service = await ref.watch(catalogServiceProvider.future);
    return service.load(kind);
  }

  Future<CatalogService> get _service =>
      ref.read(catalogServiceProvider.future);

  Future<void> reload() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async => (await _service).load(arg));
  }

  Future<void> publish(
    List<WallpaperDraft> drafts, {
    String? collectionId,
    void Function(String status)? onProgress,
  }) async {
    final doc = await future;
    final saved = await (await _service).publish(
      doc,
      drafts,
      collectionId: collectionId,
      onProgress: onProgress,
    );
    state = AsyncValue.data(saved);
  }

  Future<void> updateEntry(
    Map<String, dynamic> entry, {
    String? collectionId,
  }) async {
    final saved = await (await _service).updateEntry(
      await future,
      entry,
      collectionId: collectionId,
    );
    state = AsyncValue.data(saved);
  }

  Future<void> deleteEntry(
    Map<String, dynamic> entry, {
    String? collectionId,
    bool deleteFiles = false,
  }) async {
    final saved = await (await _service).deleteEntry(
      await future,
      entry,
      collectionId: collectionId,
      deleteFiles: deleteFiles,
    );
    state = AsyncValue.data(saved);
  }

  /// Creates a collection and returns its id.
  Future<String> createCollection({
    required String name,
    required String productId,
    bool hideForIOS = false,
  }) async {
    final saved = await (await _service).createCollection(
      await future,
      name: name,
      productId: productId,
      hideForIOS: hideForIOS,
    );
    state = AsyncValue.data(saved);
    return '${saved.collections.first['id']}';
  }

  Future<void> updateCollection(
    String id, {
    required String name,
    required String productId,
    required bool hideForIOS,
  }) async {
    final saved = await (await _service).updateCollection(
      await future,
      id,
      name: name,
      productId: productId,
      hideForIOS: hideForIOS,
    );
    state = AsyncValue.data(saved);
  }

  Future<void> restore(StorageObject backup) async {
    final saved = await (await _service).restore(arg, backup);
    state = AsyncValue.data(saved);
  }

  Future<void> updateFields(
    Map<String, dynamic> fields, {
    Set<String> removed = const {},
  }) async {
    final saved = await (await _service).updateFields(
      await future,
      fields,
      removed: removed,
    );
    state = AsyncValue.data(saved);
  }
}

final catalogProvider =
    AsyncNotifierProvider.family<CatalogNotifier, CatalogDocument, CatalogKind>(
      CatalogNotifier.new,
    );

final catalogHistoryProvider =
    FutureProvider.family<List<StorageObject>, CatalogKind>((ref, kind) async {
      ref.watch(catalogProvider(kind)); // refresh after every save
      final service = await ref.watch(catalogServiceProvider.future);
      return service.history(kind);
    });

/// Images uploaded for push notifications.
final pushImagesProvider =
    FutureProvider.autoDispose<List<({StorageObject object, String url})>>((
      ref,
    ) async {
      final service = await ref.watch(catalogServiceProvider.future);
      return service.listImages(CatalogService.pushFolder);
    });
