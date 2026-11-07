import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../../../wall_rio/infrastructure/services/storage_client.dart';
import '../../domain/buffy_storage_layout.dart';

class BuffyFileExistsException implements Exception {
  BuffyFileExistsException(this.path);
  final String path;
  @override
  String toString() =>
      '$path already exists with different contents. Use a new name: '
      'apps cache images forever, so a replaced file would never show up.';
}

class BuffyCatalogChangedException implements Exception {
  @override
  String toString() =>
      'The live catalog changed since it was loaded. Nothing was published. '
      'Reload it and re-apply your changes.';
}

/// What publishing would do. Publish is refused while [problems] isn't empty.
class BuffyPublishPreview {
  const BuffyPublishPreview({
    required this.localCount,
    required this.liveCount,
    required this.liveGeneration,
    required this.problems,
  });

  final int localCount;
  final int liveCount;
  final String liveGeneration;
  final List<String> problems;
}

class BuffyCatalogPublisher {
  BuffyCatalogPublisher(this._storage);

  final StorageClient _storage;

  /// Uploads a new media file. An identical file already there counts as done,
  /// so a failed batch can be retried; different contents are refused.
  Future<void> uploadNewMedia(String path, List<int> bytes) async {
    try {
      await _storage.upload(
        path,
        bytes,
        contentType: buffyContentType(path),
        cacheControl: kBuffyMediaCacheControl,
        ifGenerationMatch: '0',
      );
    } on StoragePreconditionFailed {
      final existing = await _storage.download(path);
      if (!listEquals<int>(existing.bytes, bytes)) {
        throw BuffyFileExistsException(path);
      }
    }
  }

  Future<({String json, String generation})> load() async {
    final live = await _storage.download(kBuffyCatalogObject);
    return (json: utf8.decode(live.bytes), generation: live.generation);
  }

  /// Uploads an image to a new object in [folder]; returns its download URL.
  Future<String> uploadImage(
    String folder,
    String fileName,
    List<int> bytes,
  ) async {
    final object = buffyUploadObject(folder, fileName, DateTime.now());
    await uploadNewMedia(object, bytes);
    return buffyDownloadUrl(object);
  }

  /// The objects in [folder], newest first.
  Future<List<StorageObject>> listFolder(String folder) async {
    final objects = await _storage.list('$kBuffyMediaRoot/$folder/');
    final epoch = DateTime.fromMillisecondsSinceEpoch(0);
    return objects
      ..sort((a, b) => (b.updated ?? epoch).compareTo(a.updated ?? epoch));
  }

  /// Checks [localJson], which was edited from the catalog at [generation].
  Future<BuffyPublishPreview> preview(
    String localJson, {
    required String generation,
  }) async {
    final objects = {
      ...(await _storage.list('$kBuffyMediaRoot/')).map((o) => o.path),
      ...(await _storage.list('$kBuffyExternalRoot/')).map((o) => o.path),
    };
    final live = await load();
    if (live.generation != generation) throw BuffyCatalogChangedException();
    return BuffyPublishPreview(
      localCount: _wallpaperCount(localJson),
      liveCount: _wallpaperCount(live.json),
      liveGeneration: generation,
      problems: checkCatalog(localJson, objects),
    );
  }

  /// Backs up the live catalog and replaces it, unless it changed since it was
  /// loaded. Returns the new generation.
  Future<String> publish(String localJson, BuffyPublishPreview preview) async {
    if (preview.problems.isNotEmpty) {
      throw StateError('Catalog has ${preview.problems.length} problems');
    }
    final stamp = DateTime.now().toUtc().toIso8601String().replaceAll(':', '-');
    try {
      await _storage.copy(
        kBuffyCatalogObject,
        '$kBuffyCatalogHistoryPrefix$stamp.json',
        ifSourceGenerationMatch: preview.liveGeneration,
      );
      final uploaded = await _storage.upload(
        kBuffyCatalogObject,
        gzip.encode(utf8.encode(localJson)),
        contentType: 'application/json',
        contentEncoding: 'gzip',
        cacheControl: kBuffyCatalogCacheControl,
        ifGenerationMatch: preview.liveGeneration,
      );
      return uploaded.generation;
    } on StoragePreconditionFailed {
      throw BuffyCatalogChangedException();
    }
  }

  static int _wallpaperCount(String json) {
    final decoded = jsonDecode(json);
    if (decoded is! Map<String, dynamic>) return 0;
    final popular = decoded['popular'];
    return popular is List ? popular.length : 0;
  }

  /// Everything that would break the app if [json] went live.
  static List<String> checkCatalog(String json, Set<String> objects) {
    final Object? decoded;
    try {
      decoded = jsonDecode(json);
    } on FormatException catch (e) {
      return ['Not valid JSON: ${e.message}'];
    }
    if (_wallpaperCount(json) == 0) {
      return ['The catalog has no wallpapers.'];
    }

    final problems = <String>{};
    void visit(Object? node) {
      if (node is Map) {
        node.values.forEach(visit);
      } else if (node is List) {
        node.forEach(visit);
      } else if (node is String && node.startsWith('http')) {
        final host = Uri.tryParse(node)?.host;
        if (kBuffyRetiredMediaHosts.contains(host)) {
          problems.add('Still on $host: $node');
          return;
        }
        if (host != 'firebasestorage.googleapis.com') return;
        final object = buffyObjectFromUrl(node);
        if (object == null) {
          problems.add('Points at another bucket: $node');
        } else if (object != kBuffyCatalogObject && !objects.contains(object)) {
          problems.add('Missing from the bucket: $object');
        }
      }
    }

    visit(decoded);
    return problems.toList();
  }
}
