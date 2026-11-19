import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:miui_icon_generator/buffy_walls/application/services/buffy_catalog_publisher.dart';
import 'package:miui_icon_generator/buffy_walls/domain/buffy_storage_layout.dart';
import 'package:miui_icon_generator/wall_rio/infrastructure/services/r2_storage_client.dart';
import 'package:miui_icon_generator/wall_rio/infrastructure/services/storage_client.dart';

// Example keys from the AWS Signature V4 documentation.
const _key = 'AKIAIOSFODNN7EXAMPLE';
const _secret = 'wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY';
final _awsDate = DateTime.utc(2013, 5, 24);

String _signature(Map<String, String> headers) =>
    RegExp(r'Signature=(\w+)').firstMatch(headers['authorization']!)![1]!;

void main() {
  group('signS3Request matches the AWS documentation examples', () {
    Map<String, String> sign(
      String method,
      String path, {
      Map<String, String> query = const {},
      Map<String, String> headers = const {},
      String body = '',
    }) => signS3Request(
      method: method,
      host: 'examplebucket.s3.amazonaws.com',
      path: path,
      query: query,
      headers: headers,
      payload: utf8.encode(body),
      accessKeyId: _key,
      secretAccessKey: _secret,
      region: 'us-east-1',
      now: _awsDate,
    );

    test('GET object', () {
      final h = sign('GET', '/test.txt', headers: {'Range': 'bytes=0-9'});
      expect(
        h['authorization'],
        contains('SignedHeaders=host;range;x-amz-content-sha256;x-amz-date'),
      );
      expect(
        _signature(h),
        'f0e8bdb87c964420e857bd35b5d6ed310bd44f0170aba48dd91039c6036bdb41',
      );
    });

    test(r'PUT object with a $ in the key', () {
      final h = sign(
        'PUT',
        r'/test$file.text',
        headers: {
          'Date': 'Fri, 24 May 2013 00:00:00 GMT',
          'x-amz-storage-class': 'REDUCED_REDUNDANCY',
        },
        body: 'Welcome to Amazon S3.',
      );
      expect(
        _signature(h),
        '98ad721746da40c64f1a55b78f14c238d841ea1380cd77a1b5971af0ece108bd',
      );
    });

    test('GET bucket with a query', () {
      final h = sign('GET', '/', query: {'max-keys': '2', 'prefix': 'J'});
      expect(
        _signature(h),
        '34b48302e7b5fa45bde8084f4b7868a86f0a534bc59db6670ed5711ef69dc6f7',
      );
    });
  });

  group('R2StorageClient', () {
    late List<http.Request> sent;

    R2StorageClient client(http.Response Function(http.Request) reply) {
      sent = [];
      return R2StorageClient(
        MockClient((r) async {
          sent.add(r);
          return reply(r);
        }),
        accountId: 'acct',
        accessKeyId: _key,
        secretAccessKey: _secret,
        bucket: 'buffy',
      );
    }

    test('encodes the key in the URL exactly as signed', () async {
      final r2 = client((_) => http.Response('', 200, headers: {'etag': '"e1"'}));
      await r2.download('buffy_wall_data/Games/Halloween (7).png');
      expect(
        sent.single.url.toString(),
        'https://acct.r2.cloudflarestorage.com/buffy/buffy_wall_data/Games/Halloween%20%287%29.png',
      );
      expect(sent.single.headers['authorization'], startsWith('AWS4-HMAC-SHA256'));
      expect(sent.single.headers['authorization'], contains('/auto/s3/aws4_request'));
    });

    test('create-only upload sends If-None-Match and maps 412', () async {
      final r2 = client((_) => http.Response('', 412));
      await expectLater(
        r2.upload('a/b.png', [1], contentType: 'image/png', ifGenerationMatch: '0'),
        throwsA(isA<StoragePreconditionFailed>()),
      );
      expect(sent.single.method, 'PUT');
      expect(sent.single.headers['if-none-match'], '*');
      expect(sent.single.headers.containsKey('if-match'), isFalse);
    });

    test('upload at a generation sends If-Match and returns the new ETag', () async {
      final r2 = client((_) => http.Response('', 200, headers: {'etag': '"new"'}));
      final object = await r2.upload(
        'buffyjson/buffy.json',
        utf8.encode('{}'),
        contentType: 'application/json',
        cacheControl: 'public, max-age=300',
        ifGenerationMatch: 'old',
      );
      expect(sent.single.headers['if-match'], '"old"');
      expect(sent.single.headers['cache-control'], 'public, max-age=300');
      expect(sent.single.headers['content-type'], startsWith('application/json'));
      expect(sent.single.body, '{}');
      expect(object.generation, 'new');
    });

    test('copy names the encoded source and its ETag', () async {
      final r2 = client((_) => http.Response('<CopyObjectResult/>', 200));
      await r2.copy('buffyjson/buffy.json', 'buffyjson/history/x.json',
          ifSourceGenerationMatch: 'e1');
      expect(sent.single.url.path, '/buffy/buffyjson/history/x.json');
      expect(sent.single.headers['x-amz-copy-source'], '/buffy/buffyjson/buffy.json');
      expect(sent.single.headers['x-amz-copy-source-if-match'], '"e1"');
    });

    test('copy maps 412 and errors inside a 200', () async {
      await expectLater(
        client((_) => http.Response('', 412)).copy('a', 'b', ifSourceGenerationMatch: 'x'),
        throwsA(isA<StoragePreconditionFailed>()),
      );
      await expectLater(
        client((_) => http.Response('<Error><Code>InternalError</Code></Error>', 200))
            .copy('a', 'b'),
        throwsA(isA<StorageException>()),
      );
    });

    test('stat returns null for a missing object', () async {
      final r2 = client((_) => http.Response('', 404));
      expect(await r2.stat('nope.png'), isNull);
      expect(sent.single.method, 'HEAD');
    });

    test('list follows continuation tokens and parses objects', () async {
      final r2 = client((r) {
        final token = r.url.queryParameters['continuation-token'];
        return http.Response(
          token == null
              ? '<ListBucketResult><IsTruncated>true</IsTruncated>'
                    '<NextContinuationToken>t/2</NextContinuationToken>'
                    '<Contents><Key>p/a &amp; b.png</Key><ETag>"e1"</ETag>'
                    '<Size>10</Size><LastModified>2026-11-15T10:21:30.000Z</LastModified></Contents>'
                    '</ListBucketResult>'
              : '<ListBucketResult><IsTruncated>false</IsTruncated>'
                    '<Contents><Key>p/c.png</Key><ETag>"e2"</ETag><Size>5</Size></Contents>'
                    '</ListBucketResult>',
          200,
        );
      });
      final objects = await r2.list('p/');
      expect(objects.map((o) => o.path), ['p/a & b.png', 'p/c.png']);
      expect(objects.first.generation, 'e1');
      expect(objects.first.size, 10);
      expect(objects.first.updated, DateTime.utc(2026, 11, 15, 10, 21, 30));
      expect(sent.first.url.query, 'list-type=2&prefix=p%2F');
      expect(sent.last.url.queryParameters['continuation-token'], 't/2');
    });

    test('list reads UTF-8 names even without a charset', () async {
      final r2 = client(
        (_) => http.Response.bytes(
          utf8.encode(
            '<ListBucketResult><IsTruncated>false</IsTruncated>'
            '<Contents><Key>buffy_wall_data/Sports/Barça Spirit 🍓.jpg</Key>'
            '<ETag>"e"</ETag><Size>1</Size></Contents></ListBucketResult>',
          ),
          200,
          headers: {'content-type': 'application/xml'},
        ),
      );
      expect((await r2.list('buffy_wall_data/')).single.path,
          'buffy_wall_data/Sports/Barça Spirit 🍓.jpg');
    });

    test('errors carry the status code', () async {
      await expectLater(
        client((_) => http.Response('<Error>AccessDenied</Error>', 403)).download('x'),
        throwsA(isA<StorageException>().having((e) => e.statusCode, 'status', 403)),
      );
    });
  });

  group('Buffy Cloudflare URLs', () {
    test('match the links already in the catalog and round-trip', () {
      const cases = {
        'buffy_wall_data/Gradient/Thumbnails/Sunset Flow 🌅-small.jpg':
            'https://buffywalls.teamshadow.tech/buffy_wall_data/Gradient/Thumbnails/Sunset%20Flow%20%F0%9F%8C%85-small.jpg',
        'buffy_external/github/piyushkpv/new/new (8).jpg':
            'https://buffywalls.teamshadow.tech/buffy_external/github/piyushkpv/new/new%20%288%29.jpg',
      };
      cases.forEach((object, url) {
        expect(buffyDownloadUrl(object), url);
        expect(buffyObjectFromUrl(url), object);
      });
      expect(buffyObjectFromUrl('https://example.com/a.png'), isNull);
    });

    test('catalog check wants Cloudflare links to existing objects', () {
      String catalog(List<String> urls) => jsonEncode({
        'popular': [
          for (final u in urls) {'id': 1, 'imageUrl': u},
        ],
      });
      const ok = 'buffy_wall_data/A/x.jpg';
      expect(
        BuffyCatalogPublisher.checkCatalog(catalog([buffyDownloadUrl(ok)]), {ok}),
        isEmpty,
      );
      expect(
        BuffyCatalogPublisher.checkCatalog(
          catalog([buffyDownloadUrl('buffy_wall_data/A/missing.jpg')]),
          {ok},
        ),
        ['Missing from the bucket: buffy_wall_data/A/missing.jpg'],
      );
      const firebase =
          'https://firebasestorage.googleapis.com/v0/b/buffywalls.appspot.com/o/x?alt=media';
      expect(
        BuffyCatalogPublisher.checkCatalog(catalog([firebase]), {ok}).single,
        startsWith('Still on firebasestorage.googleapis.com'),
      );
    });
  });
}
