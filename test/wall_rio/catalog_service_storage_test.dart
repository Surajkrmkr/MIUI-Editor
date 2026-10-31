// Runs CatalogService against the real bucket, inside a throwaway folder.
// Skipped unless WALLRIO_TEST_TOKEN is set:
//
//   WALLRIO_TEST_TOKEN=$(gcloud auth print-access-token) \
//     flutter test test/wall_rio/catalog_service_storage_test.dart
//
// Each test seeds a catalog under a unique prefix, exercises the service and
// removes the prefix afterwards. The live test needs ffmpeg.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import 'package:miui_icon_generator/wall_rio/application/services/catalog_service.dart';
import 'package:miui_icon_generator/wall_rio/domain/models/catalog.dart';
import 'package:miui_icon_generator/wall_rio/infrastructure/services/storage_client.dart';
import 'package:miui_icon_generator/wall_rio/infrastructure/services/video_engine.dart';

class _BearerClient extends http.BaseClient {
  _BearerClient(this._token);
  final String _token;
  final _inner = http.Client();
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers['Authorization'] = 'Bearer $_token';
    return _inner.send(request);
  }
}

void main() {
  final token = Platform.environment['WALLRIO_TEST_TOKEN'];
  final prefix = 'cms_test_${DateTime.now().millisecondsSinceEpoch}';
  final settings = StorageSettings(
    jsonFolder: '$prefix/wallriojson',
    imagesRoot: '$prefix/wallrio_wall_data',
  );

  test('publish → edit → conflict → delete → restore', () async {
    final storage = StorageClient(_BearerClient(token!), settings.bucket);
    final service = CatalogService(storage, settings);
    final tmp = await Directory.systemTemp.createTemp('wallrio_cms_test');

    try {
      // Seed a small desktop catalog in the nested walls: [[...]] shape.
      final seed = {'walls': [[{'id': 7, 'name': 'Old', 'author': 'Team Shadow', 'url': 'x', 'thumbnail': 'y', 'category': 'Gaming'}]]};
      await storage.upload(settings.jsonPath(CatalogKind.desktop),
          gzip.encode(utf8.encode(jsonEncode(seed))),
          contentType: 'application/json', contentEncoding: 'gzip');

      final image = File('${tmp.path}/neon_city.png')
        ..writeAsBytesSync(img.encodePng(img.Image(width: 3840, height: 2160)));
      var doc = await service.load(CatalogKind.desktop);
      expect(doc.wallsOf().single['name'], 'Old');

      doc = await service.publish(doc, [
        WallpaperDraft(localPath: image.path, width: 3840, height: 2160,
            name: 'Neon City', author: 'Team Shadow', category: 'Gaming', tags: ['Neon']),
      ]);
      final added = doc.wallsOf().first;
      expect(added['id'], 8);
      expect(added['type'], 'desktop');
      expect(doc.wallsOf().length, 2);

      // Files exist, thumbnail is 640×360 JPEG, JSON is stored gzipped.
      final thumbPath = '${settings.imagesRoot}/Desktop/Thumbnail/Neon City-small.jpg';
      final thumb = img.decodeJpg((await storage.download(thumbPath)).bytes)!;
      expect([thumb.width, thumb.height], [640, 360]);
      expect(await storage.stat('${settings.imagesRoot}/Desktop/Neon City.png'), isNotNull);
      final reread = await service.load(CatalogKind.desktop);
      expect(reread.root['walls'], isA<List>().having((w) => w.first, 'inner', isA<List>()));
      expect(reread.wallsOf().first['name'], 'Neon City');

      // Same name again is refused before anything uploads.
      await expectLater(service.publish(reread, [
        WallpaperDraft(localPath: image.path, width: 3840, height: 2160,
            name: 'Neon City', author: 'x', category: 'Gaming'),
      ]), throwsA(isA<NameTakenException>()));

      // Saving from a stale copy re-applies the edit to the latest version.
      final stale = doc;
      doc = await service.updateEntry(doc, {...added, 'author': 'Suraj'});
      final merged = await service.updateEntry(stale, {...added, 'tags': ['Neon', 'City']});
      expect(merged.wallsOf().first['tags'], ['Neon', 'City']);
      expect(merged.wallsOf().length, 2);

      // Delete removes the entry and, when unreferenced, its files.
      doc = await service.deleteEntry(merged, merged.wallsOf().first, deleteFiles: true);
      expect(doc.wallsOf().single['name'], 'Old');
      expect(await storage.stat(thumbPath), isNull);

      // Every save left a backup; restoring the newest brings back its contents.
      final backups = await service.history(CatalogKind.desktop);
      expect(backups.length, greaterThanOrEqualTo(4));
      final restored = await service.restore(CatalogKind.desktop, backups.first);
      expect(restored.wallsOf().first['name'], 'Neon City');
    } finally {
      for (final object in await storage.list('$prefix/')) {
        await storage.delete(object.path);
      }
      await tmp.delete(recursive: true);
    }
  }, skip: token == null ? 'Set WALLRIO_TEST_TOKEN to run against the bucket' : false,
     timeout: const Timeout(Duration(minutes: 3)));

  Future<void> seed(StorageClient storage, CatalogKind kind, Object json) => storage.upload(
        settings.jsonPath(kind),
        gzip.encode(utf8.encode(jsonEncode(json))),
        contentType: 'application/json',
        contentEncoding: 'gzip',
      );

  Future<void> cleanUp(StorageClient storage) async {
    for (final object in await storage.list('$prefix/')) {
      await storage.delete(object.path);
    }
  }

  test('live: MP4 → preview clip + thumbnail + live_wall.json entry', () async {
    final storage = StorageClient(_BearerClient(token!), settings.bucket);
    final service = CatalogService(storage, settings);
    final tmp = await Directory.systemTemp.createTemp('wallrio_cms_live');
    try {
      await seed(storage, CatalogKind.live, {'walls': [{'id': 78, 'type': 'live', 'name': 'Old', 'author': 'WallRio'}]});
      final video = '${tmp.path}/neon_rain.mp4';
      final made = await Process.run(VideoEngine.ffmpeg, [
        '-f', 'lavfi', '-i', 'testsrc=size=1080x1920:rate=30:duration=2',
        '-pix_fmt', 'yuv420p', '-y', video,
      ]);
      expect(made.exitCode, 0, reason: '${made.stderr}');
      final size = await VideoEngine.probe(video);
      expect([size!.width, size.height], [1080, 1920]);

      var doc = await service.load(CatalogKind.live);
      doc = await service.publish(doc, [
        WallpaperDraft(localPath: video, width: 1080, height: 1920,
            name: 'Neon Rain', author: 'WallRio', category: 'Abstract', isPremium: true),
      ]);
      final entry = doc.wallsOf().first;
      expect(entry['id'], 79);
      expect(entry['type'], 'live');
      expect('${entry['previewVideo']}', contains('previews%2FNeon%20Rain_preview.mp4'));

      final preview = await storage.stat('${settings.liveRoot}/previews/Neon Rain_preview.mp4');
      final thumb = img.decodeJpg((await storage.download('${settings.liveRoot}/thumbnails/Neon Rain.jpg')).bytes)!;
      expect(preview, isNotNull);
      expect([thumb.width, thumb.height], [304, 540]); // fits 960×540 like process_videos.py

      // Editing a live entry matches it by videoUrl.
      doc = await service.updateEntry(doc, {...entry, 'name': 'Neon Rain 2'});
      expect(doc.wallsOf().first['name'], 'Neon Rain 2');
    } finally {
      await cleanUp(storage);
      await tmp.delete(recursive: true);
    }
  }, skip: token == null ? 'Set WALLRIO_TEST_TOKEN to run against the bucket' : false,
     timeout: const Timeout(Duration(minutes: 3)));

  test('collections: create, upload into one, keep its order', () async {
    final storage = StorageClient(_BearerClient(token!), settings.bucket);
    final service = CatalogService(storage, settings);
    final tmp = await Directory.systemTemp.createTemp('wallrio_cms_coll');
    try {
      // "Formscape" lists oldest first, like some real collections.
      await seed(storage, CatalogKind.collections, {
        'collections': [
          {'id': '10', 'productId': 'com.wallrio.collection.formscape', 'name': 'Formscape',
           'walls': [{'id': '1', 'name': 'F1'}, {'id': '2', 'name': 'F2'}]},
        ],
      });
      var doc = await service.load(CatalogKind.collections);
      doc = await service.createCollection(doc, name: 'Neon Nights',
          productId: 'com.wallrio.collection.neonnights', hideForIOS: true);
      final created = doc.collections.first;
      expect(created['id'], '11');
      expect(created['hideForIOS'], isTrue);
      expect(created['walls'], isEmpty);

      await expectLater(
        service.createCollection(doc, name: 'neon nights', productId: 'com.wallrio.collection.other'),
        throwsA(isA<CatalogValidationException>()),
      );

      final image = File('${tmp.path}/f3.png')
        ..writeAsBytesSync(img.encodePng(img.Image(width: 1720, height: 3728)));
      doc = await service.publish(doc, collectionId: '10', [
        WallpaperDraft(localPath: image.path, width: 1720, height: 3728,
            name: 'F3', author: 'Team Shadow', category: 'Formscape', isPremium: true),
      ]);
      final walls = doc.wallsOf('10');
      expect(walls.map((w) => w['id']), ['1', '2', '3']); // appended: oldest-first list
      expect(walls.last['url'], contains('Formscape%2FF3.png'));
      expect(await storage.stat('${settings.imagesRoot}/Formscape/Thumbnails/F3-small.jpg'), isNotNull);
      expect(doc.wallsOf('11'), isEmpty);

      doc = await service.updateCollection(doc, '11',
          name: 'Neon Nights', productId: 'com.wallrio.collection.neonnights', hideForIOS: false);
      expect(doc.collection('11')!.containsKey('hideForIOS'), isFalse);
    } finally {
      await cleanUp(storage);
      await tmp.delete(recursive: true);
    }
  }, skip: token == null ? 'Set WALLRIO_TEST_TOKEN to run against the bucket' : false,
     timeout: const Timeout(Duration(minutes: 3)));
}
