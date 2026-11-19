import 'dart:convert';
import 'dart:io' show HttpDate;
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';

import 'storage_client.dart';

/// Cloudflare R2 through its S3-compatible API, signed with AWS Signature V4.
///
/// Offers the same calls as [StorageClient], so the Wall Rio and Buffy CMS code
/// works with either. An object's "generation" is its ETag: uploads and copies made with
/// one only succeed while the object is unchanged.
class R2StorageClient implements StorageClient {
  R2StorageClient(
    this._client, {
    required this.accountId,
    required this.accessKeyId,
    required this.secretAccessKey,
    required this.bucket,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  final http.Client _client;
  final String accountId;
  final String accessKeyId;
  final String secretAccessKey;
  @override
  final String bucket;
  final DateTime Function() _clock;

  String get _host => '$accountId.r2.cloudflarestorage.com';

  Future<http.Response> _send(
    String method,
    String key, {
    Map<String, String>? query,
    Map<String, String> headers = const {},
    List<int> body = const [],
  }) async {
    final path = '/$bucket${key.isEmpty ? '' : '/$key'}';
    final queryString = canonicalS3Query(query ?? const {});
    // Built by hand so the URL is encoded exactly as it was signed.
    final uri = Uri.parse(
      'https://$_host${encodeS3Path(path)}'
      '${queryString.isEmpty ? '' : '?$queryString'}',
    );
    final signed = signS3Request(
      method: method,
      host: _host,
      path: path,
      query: query ?? const {},
      headers: headers,
      payload: body,
      accessKeyId: accessKeyId,
      secretAccessKey: secretAccessKey,
      region: 'auto',
      now: _clock(),
    );
    final request = http.Request(method, uri)
      ..headers.addAll(signed)
      ..bodyBytes = body;
    return http.Response.fromStream(await _client.send(request));
  }

  @override
  Future<StorageObject?> stat(String path) async {
    final res = await _send('HEAD', path);
    if (res.statusCode == 404) return null;
    _check(res, 'stat $path');
    return StorageObject(
      path: path,
      generation: _etag(res.headers, path),
      size: int.tryParse(res.headers['content-length'] ?? '') ?? 0,
      updated: _httpDate(res.headers['last-modified']),
    );
  }

  @override
  Future<({Uint8List bytes, String generation})> download(String path) async {
    final res = await _send('GET', path);
    _check(res, 'download $path');
    return (bytes: res.bodyBytes, generation: _etag(res.headers, path));
  }

  /// [ifGenerationMatch] `'0'` means "only if it doesn't exist yet"; any other
  /// value is an ETag the object must still have. [metadata] is ignored.
  @override
  Future<StorageObject> upload(
    String path,
    List<int> bytes, {
    required String contentType,
    String? cacheControl,
    String? contentEncoding,
    String? ifGenerationMatch,
    Map<String, String>? metadata,
  }) async {
    final res = await _send(
      'PUT',
      path,
      body: bytes,
      headers: {
        'content-type': contentType,
        if (cacheControl != null) 'cache-control': cacheControl,
        if (contentEncoding != null) 'content-encoding': contentEncoding,
        if (ifGenerationMatch == '0') 'if-none-match': '*',
        if (ifGenerationMatch != null && ifGenerationMatch != '0')
          'if-match': '"$ifGenerationMatch"',
      },
    );
    if (res.statusCode == 412) throw StoragePreconditionFailed(path);
    _check(res, 'upload $path');
    return StorageObject(
      path: path,
      generation: _etag(res.headers, path),
      size: bytes.length,
      updated: _clock().toUtc(),
    );
  }

  @override
  Future<void> copy(
    String source,
    String dest, {
    String? ifSourceGenerationMatch,
  }) async {
    final res = await _send(
      'PUT',
      dest,
      headers: {
        'x-amz-copy-source': '/$bucket/${encodeS3Path(source)}',
        if (ifSourceGenerationMatch != null)
          'x-amz-copy-source-if-match': '"$ifSourceGenerationMatch"',
      },
    );
    if (res.statusCode == 412) throw StoragePreconditionFailed(source);
    _check(res, 'copy $source → $dest');
    // S3 can report a failed copy inside a 200 response.
    if (_text(res).contains('<Error>')) {
      throw StorageException('copy $source → $dest failed: ${_short(_text(res))}');
    }
  }

  @override
  Future<void> delete(String path) async {
    final res = await _send('DELETE', path);
    if (res.statusCode == 404) return;
    _check(res, 'delete $path');
  }

  @override
  Future<List<StorageObject>> list(String prefix) async {
    final objects = <StorageObject>[];
    String? token;
    do {
      final res = await _send(
        'GET',
        '',
        query: {
          'list-type': '2',
          'prefix': prefix,
          'continuation-token': ?token,
        },
      );
      _check(res, 'list $prefix');
      final doc = XmlDocument.parse(_text(res));
      String? text(XmlElement e, String name) =>
          e.getElement(name)?.innerText;
      for (final item in doc.findAllElements('Contents')) {
        objects.add(
          StorageObject(
            path: text(item, 'Key') ?? '',
            generation: _unquote(text(item, 'ETag') ?? ''),
            size: int.tryParse(text(item, 'Size') ?? '') ?? 0,
            updated: DateTime.tryParse(text(item, 'LastModified') ?? ''),
          ),
        );
      }
      final truncated =
          doc.findAllElements('IsTruncated').firstOrNull?.innerText == 'true';
      token = truncated
          ? doc.findAllElements('NextContinuationToken').firstOrNull?.innerText
          : null;
    } while (token != null);
    return objects;
  }

  String _etag(Map<String, String> headers, String path) {
    final etag = headers['etag'];
    if (etag == null) throw StorageException('No ETag for $path');
    return _unquote(etag);
  }

  static String _unquote(String etag) =>
      etag.replaceFirst(RegExp(r'^W/'), '').replaceAll('"', '');

  static DateTime? _httpDate(String? value) {
    if (value == null) return null;
    try {
      return HttpDate.parse(value);
    } catch (_) {
      return null;
    }
  }

  /// R2 sends XML without a charset, which `http` would read as Latin-1 and
  /// garble every non-ASCII key; S3 responses are always UTF-8.
  static String _text(http.Response res) =>
      utf8.decode(res.bodyBytes, allowMalformed: true);

  static String _short(String body) =>
      body.length > 300 ? body.substring(0, 300) : body;

  void _check(http.Response res, String action) {
    if (res.statusCode >= 200 && res.statusCode < 300) return;
    throw StorageException('$action failed: ${_short(_text(res))}', res.statusCode);
  }
}

/// Encodes an object key for a URL path: every byte except unreserved
/// characters and `/` is percent-encoded, as S3 signing requires.
String encodeS3Path(String key) => key.split('/').map(_encodeS3).join('/');

String _encodeS3(String value) {
  final out = StringBuffer();
  for (final byte in utf8.encode(value)) {
    final c = String.fromCharCode(byte);
    if (RegExp(r'[A-Za-z0-9\-_.~]').hasMatch(c)) {
      out.write(c);
    } else {
      out.write('%${byte.toRadixString(16).toUpperCase().padLeft(2, '0')}');
    }
  }
  return out.toString();
}

/// [query] encoded and sorted as S3 signing requires.
String canonicalS3Query(Map<String, String> query) =>
    (query.entries
            .map((e) => '${_encodeS3(e.key)}=${_encodeS3(e.value)}')
            .toList()
          ..sort())
        .join('&');

/// Headers for an AWS Signature V4 signed S3 request, including
/// `authorization`. [path] is the unencoded path starting with `/`.
Map<String, String> signS3Request({
  required String method,
  required String host,
  required String path,
  required Map<String, String> query,
  required Map<String, String> headers,
  required List<int> payload,
  required String accessKeyId,
  required String secretAccessKey,
  required String region,
  required DateTime now,
  String service = 's3',
}) {
  final utc = now.toUtc();
  String two(int n) => n.toString().padLeft(2, '0');
  final date = '${utc.year}${two(utc.month)}${two(utc.day)}';
  final amzDate = '${date}T${two(utc.hour)}${two(utc.minute)}${two(utc.second)}Z';
  final payloadHash = sha256.convert(payload).toString();

  final all = <String, String>{
    for (final e in headers.entries) e.key.toLowerCase(): e.value.trim(),
    'host': host,
    'x-amz-content-sha256': payloadHash,
    'x-amz-date': amzDate,
  };
  final names = all.keys.toList()..sort();
  final signedHeaders = names.join(';');
  final canonicalHeaders = names.map((n) => '$n:${all[n]}\n').join();
  final canonicalQuery = canonicalS3Query(query);

  final canonicalRequest = [
    method,
    encodeS3Path(path),
    canonicalQuery,
    canonicalHeaders,
    signedHeaders,
    payloadHash,
  ].join('\n');

  final scope = '$date/$region/$service/aws4_request';
  final stringToSign = [
    'AWS4-HMAC-SHA256',
    amzDate,
    scope,
    sha256.convert(utf8.encode(canonicalRequest)).toString(),
  ].join('\n');

  List<int> hmac(List<int> key, String data) =>
      Hmac(sha256, key).convert(utf8.encode(data)).bytes;
  var key = hmac(utf8.encode('AWS4$secretAccessKey'), date);
  key = hmac(key, region);
  key = hmac(key, service);
  key = hmac(key, 'aws4_request');
  final signature = Hmac(sha256, key).convert(utf8.encode(stringToSign));

  return {
    ...{for (final n in names) if (n != 'host') n: all[n]!},
    'authorization':
        'AWS4-HMAC-SHA256 Credential=$accessKeyId/$scope, '
        'SignedHeaders=$signedHeaders, Signature=$signature',
  };
}
