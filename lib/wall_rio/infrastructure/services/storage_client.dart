import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

/// Thrown when an upload's generation precondition fails (HTTP 412): the
/// object was created or changed since it was read.
class StoragePreconditionFailed implements Exception {
  StoragePreconditionFailed(this.path);
  final String path;
  @override
  String toString() => 'StoragePreconditionFailed: $path changed or already exists';
}

class StorageException implements Exception {
  StorageException(this.message, [this.statusCode]);
  final String message;
  final int? statusCode;
  @override
  String toString() => 'StorageException(${statusCode ?? '-'}): $message';
}

class StorageObject {
  const StorageObject({
    required this.path,
    required this.generation,
    required this.size,
    this.updated,
  });

  final String path;
  final String generation;
  final int size;
  final DateTime? updated;

  factory StorageObject.fromJson(Map<String, dynamic> json) => StorageObject(
        path: json['name'] as String,
        generation: '${json['generation']}',
        size: int.tryParse('${json['size']}') ?? 0,
        updated: DateTime.tryParse('${json['updated']}'),
      );
}

/// Minimal Google Cloud Storage JSON API client.
///
/// [client] must add OAuth credentials with the `devstorage.read_write` scope
/// (the CMS uses the signed-in Google account, which bypasses Firebase rules).
class StorageClient {
  StorageClient(this._client, this.bucket);

  final http.Client _client;
  final String bucket;

  static const _api = 'https://storage.googleapis.com/storage/v1';
  static const _upload = 'https://storage.googleapis.com/upload/storage/v1';

  String _objectUrl(String path) =>
      '$_api/b/$bucket/o/${Uri.encodeComponent(path)}';

  /// Metadata for [path], or null if it does not exist.
  Future<StorageObject?> stat(String path) async {
    final res = await _client.get(Uri.parse(_objectUrl(path)));
    if (res.statusCode == 404) return null;
    _check(res, 'stat $path');
    return StorageObject.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  /// Downloads [path]; gzip-encoded objects arrive decompressed.
  Future<({Uint8List bytes, String generation})> download(String path) async {
    final res = await _client.get(Uri.parse('${_objectUrl(path)}?alt=media'));
    _check(res, 'download $path');
    final generation = res.headers['x-goog-generation'];
    if (generation == null) {
      throw StorageException('No generation header for $path');
    }
    return (bytes: res.bodyBytes, generation: generation);
  }

  /// Uploads [bytes] to [path].
  ///
  /// [ifGenerationMatch] `'0'` means "only if it doesn't exist yet"; any other
  /// value means "only if it is still at that generation". Throws
  /// [StoragePreconditionFailed] otherwise.
  Future<StorageObject> upload(
    String path,
    List<int> bytes, {
    required String contentType,
    String? cacheControl,
    String? contentEncoding,
    String? ifGenerationMatch,
  }) async {
    final query = {
      'uploadType': 'multipart',
      if (ifGenerationMatch != null) 'ifGenerationMatch': ifGenerationMatch,
    };
    final uri = Uri.parse('$_upload/b/$bucket/o').replace(queryParameters: query);
    final metadata = jsonEncode({
      'name': path,
      'contentType': contentType,
      if (cacheControl != null) 'cacheControl': cacheControl,
      if (contentEncoding != null) 'contentEncoding': contentEncoding,
    });

    const boundary = 'wallrio_cms_boundary';
    final body = BytesBuilder(copy: false)
      ..add(utf8.encode('--$boundary\r\n'
          'Content-Type: application/json; charset=UTF-8\r\n\r\n'
          '$metadata\r\n'
          '--$boundary\r\n'
          'Content-Type: $contentType\r\n\r\n'))
      ..add(bytes)
      ..add(utf8.encode('\r\n--$boundary--'));

    final res = await _client.post(
      uri,
      headers: {'Content-Type': 'multipart/related; boundary=$boundary'},
      body: body.takeBytes(),
    );
    if (res.statusCode == 412) throw StoragePreconditionFailed(path);
    _check(res, 'upload $path');
    return StorageObject.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  /// Server-side copy of [source] to [dest]. With [ifSourceGenerationMatch],
  /// throws [StoragePreconditionFailed] if [source] has changed since then.
  Future<void> copy(String source, String dest, {String? ifSourceGenerationMatch}) async {
    final uri = Uri.parse(
      '${_objectUrl(source)}/copyTo/b/$bucket/o/${Uri.encodeComponent(dest)}',
    ).replace(queryParameters: {
      if (ifSourceGenerationMatch != null)
        'ifSourceGenerationMatch': ifSourceGenerationMatch,
    });
    final res = await _client.post(uri);
    if (res.statusCode == 412) throw StoragePreconditionFailed(source);
    _check(res, 'copy $source → $dest');
  }

  Future<void> delete(String path) async {
    final res = await _client.delete(Uri.parse(_objectUrl(path)));
    if (res.statusCode == 404) return;
    _check(res, 'delete $path');
  }

  /// All objects under [prefix].
  Future<List<StorageObject>> list(String prefix) async {
    final objects = <StorageObject>[];
    String? pageToken;
    do {
      final uri = Uri.parse('$_api/b/$bucket/o').replace(queryParameters: {
        'prefix': prefix,
        'fields': 'items(name,generation,size,updated),nextPageToken',
        if (pageToken != null) 'pageToken': pageToken,
      });
      final res = await _client.get(uri);
      _check(res, 'list $prefix');
      final json = jsonDecode(res.body) as Map<String, dynamic>;
      for (final item in (json['items'] as List? ?? const [])) {
        objects.add(StorageObject.fromJson(item as Map<String, dynamic>));
      }
      pageToken = json['nextPageToken'] as String?;
    } while (pageToken != null);
    return objects;
  }

  void _check(http.Response res, String action) {
    if (res.statusCode >= 200 && res.statusCode < 300) return;
    final detail = res.body.length > 300 ? res.body.substring(0, 300) : res.body;
    throw StorageException('$action failed: $detail', res.statusCode);
  }
}
