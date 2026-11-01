import 'package:flutter_test/flutter_test.dart';
import 'package:miui_icon_generator/wall_rio/domain/catalog_rules.dart';
import 'package:miui_icon_generator/wall_rio/domain/models/catalog.dart';

void main() {
  const bucket = 'wallrio-e551b.firebasestorage.app';
  const settings = StorageSettings();

  group('storage URLs', () {
    test('match the format the app already loads', () {
      expect(
        CatalogRules.storageUrl(
          bucket,
          'wallrio_wall_data/Nature/Golden Fields.jpg',
        ),
        'https://firebasestorage.googleapis.com/v0/b/$bucket/o/'
        'wallrio_wall_data%2FNature%2FGolden%20Fields.jpg?alt=media',
      );
    });

    test('round-trip back to the object path', () {
      const path = 'wallrio_wall_data/Desktop/Thumbnail/GTA-small.jpg';
      final url = CatalogRules.storageUrl(bucket, path);
      expect(CatalogRules.objectPathFromUrl(bucket, url), path);
      expect(
        CatalogRules.objectPathFromUrl(bucket, 'https://gitlab.com/x.png'),
        isNull,
      );
    });
  });

  test('nextId uses max + 1 even with duplicates and string ids', () {
    expect(
      CatalogRules.nextId([
        {'id': 3},
        {'id': '7'},
        {'id': 7},
        {'id': 'x'},
      ]),
      8,
    );
    expect(CatalogRules.nextId([]), 1);
  });

  test('defaultAuthor takes the newest entry with an author', () {
    expect(
      CatalogRules.defaultAuthor([
        {'author': ' '},
        {'author': 'Team Shadow'},
      ]),
      'Team Shadow',
    );
    expect(CatalogRules.defaultAuthor([]), 'WallRio');
  });

  test('nameFromFilename title-cases and drops the extension', () {
    expect(
      CatalogRules.nameFromFilename('golden_fields-2.jpeg'),
      'Golden Fields 2',
    );
    expect(CatalogRules.nameFromFilename('Abyss Dragon.png'), 'Abyss Dragon');
  });

  group('upload formats', () {
    test('image catalogs accept JPG, JPEG and PNG regardless of case', () {
      for (final kind in [
        CatalogKind.mobile,
        CatalogKind.desktop,
        CatalogKind.collections,
      ]) {
        for (final extension in ['jpg', 'jpeg', 'png', 'JPG', 'JPEG', 'PNG']) {
          expect(
            CatalogRules.acceptsUpload(kind, '/uploads/wallpaper.$extension'),
            isTrue,
          );
        }
        for (final filename in [
          'wallpaper.webp',
          'wallpaper.mp4',
          'wallpaper',
        ]) {
          expect(
            CatalogRules.acceptsUpload(kind, '/uploads/$filename'),
            isFalse,
          );
        }
      }
    });

    test('live catalog accepts only MP4 regardless of case', () {
      for (final extension in ['mp4', 'MP4']) {
        expect(
          CatalogRules.acceptsUpload(
            CatalogKind.live,
            '/uploads/video.$extension',
          ),
          isTrue,
        );
      }
      for (final filename in ['video.mov', 'wallpaper.png', 'video']) {
        expect(
          CatalogRules.acceptsUpload(CatalogKind.live, '/uploads/$filename'),
          isFalse,
        );
      }
    });
  });

  group('resolution', () {
    test('mobile needs at least 1720 × 3728', () {
      expect(
        CatalogRules.resolutionError(CatalogKind.mobile, 1720, 3728),
        isNull,
      );
      expect(
        CatalogRules.resolutionError(CatalogKind.mobile, 1440, 3200),
        contains('1720 × 3728'),
      );
      expect(
        CatalogRules.resolutionError(CatalogKind.mobile, 3728, 1720),
        isNotNull,
      );
    });

    test('desktop needs at least 3840 × 2160', () {
      expect(
        CatalogRules.resolutionError(CatalogKind.desktop, 3840, 2160),
        isNull,
      );
      expect(
        CatalogRules.resolutionError(CatalogKind.desktop, 2560, 1440),
        contains('3840 × 2160'),
      );
    });
  });

  test('objectPaths follow the existing layout', () {
    final mobile = CatalogRules.objectPaths(
      settings: settings,
      kind: CatalogKind.mobile,
      folder: 'Nature',
      name: 'Golden Fields',
      extension: 'jpg',
    );
    expect(mobile, {
      'url': 'wallrio_wall_data/Nature/Golden Fields.jpg',
      'thumbnail':
          'wallrio_wall_data/Nature/Thumbnails/Golden Fields-small.jpg',
    });

    final desktop = CatalogRules.objectPaths(
      settings: settings,
      kind: CatalogKind.desktop,
      folder: 'Gaming',
      name: 'GTA/VI',
      extension: 'png',
    );
    expect(desktop['url'], 'wallrio_wall_data/Desktop/GTAVI.png');
    expect(
      desktop['thumbnail'],
      'wallrio_wall_data/Desktop/Thumbnail/GTAVI-small.jpg',
    );

    final live = CatalogRules.objectPaths(
      settings: settings,
      kind: CatalogKind.live,
      folder: 'Cartoon',
      name: 'Dudu TinCan',
      extension: 'mp4',
    );
    expect(live, {
      'videoUrl': 'wallrio_live/livewalls/Dudu TinCan.mp4',
      'previewVideo': 'wallrio_live/previews/Dudu TinCan_preview.mp4',
      'thumbnail': 'wallrio_live/thumbnails/Dudu TinCan.jpg',
    });

    final collection = CatalogRules.objectPaths(
      settings: settings,
      kind: CatalogKind.collections,
      folder: 'Bubu Dudu',
      name: 'Bubu 41',
      extension: 'png',
    );
    expect(collection['url'], 'wallrio_wall_data/Bubu Dudu/Bubu 41.png');
    expect(
      collection['thumbnail'],
      'wallrio_wall_data/Bubu Dudu/Thumbnails/Bubu 41-small.jpg',
    );
  });

  test('live and collection kinds', () {
    expect(CatalogRules.resolutionError(CatalogKind.live, 1080, 1920), isNull);
    expect(
      CatalogRules.resolutionError(CatalogKind.live, 720, 1280),
      contains('1080 × 1920'),
    );
    expect(CatalogKind.live.identityField, 'videoUrl');
    expect(CatalogKind.collections.stringIds, isTrue);
  });

  test('newestFirst follows the list order, defaulting to newest first', () {
    expect(
      CatalogRules.newestFirst([
        {'id': '40'},
        {'id': '1'},
      ]),
      isTrue,
    );
    expect(
      CatalogRules.newestFirst([
        {'id': '1'},
        {'id': '52'},
      ]),
      isFalse,
    );
    expect(
      CatalogRules.newestFirst([
        {'id': 3},
      ]),
      isTrue,
    );
  });

  test('collection product ids and checks', () {
    expect(
      CatalogRules.defaultProductId('Bubu Dudu!'),
      'com.wallrio.collection.bubududu',
    );
    final existing = [
      {
        'id': '1',
        'name': 'Christmas',
        'productId': 'com.wallrio.collection.christmas',
      },
    ];
    expect(
      CatalogRules.validateCollection(
        collections: existing,
        name: 'Neon',
        productId: 'com.wallrio.collection.neon',
      ),
      isEmpty,
    );
    final problems = CatalogRules.validateCollection(
      collections: existing,
      name: 'christmas',
      productId: 'com.wallrio.collection.christmas',
    );
    expect(problems, hasLength(2));
    expect(
      CatalogRules.validateCollection(
        collections: existing,
        name: 'Christmas',
        productId: 'com.wallrio.collection.christmas',
        editingId: '1',
      ),
      isEmpty,
    );
    expect(
      CatalogRules.validateCollection(
        collections: existing,
        name: 'X',
        productId: 'Bad Id',
      ),
      contains(contains('Product id')),
    );
  });

  test('buildEntry adds type only for desktop', () {
    final draft = WallpaperDraft(
      localPath: '/x.jpg',
      width: 1,
      height: 1,
      name: ' GTA ',
      author: 'WallRio',
      category: 'Gaming',
      tags: ['Neon'],
    );
    final entry = CatalogRules.buildEntry(
      kind: CatalogKind.desktop,
      id: 100,
      draft: draft,
      media: {'url': 'u', 'thumbnail': 't'},
      subjectId: 's',
    );
    expect(entry.keys.take(3), ['id', 'type', 'name']);
    expect(entry['type'], 'desktop');
    expect(entry['name'], 'GTA');
    final mobile = CatalogRules.buildEntry(
      kind: CatalogKind.mobile,
      id: 1,
      draft: draft,
      media: {'url': 'u', 'thumbnail': 't'},
    );
    expect(mobile.containsKey('type'), isFalse);
    expect(mobile['subjectId'], isNotEmpty);

    final live = CatalogRules.buildEntry(
      kind: CatalogKind.live,
      id: 79,
      draft: draft,
      media: {'videoUrl': 'v', 'previewVideo': 'p', 'thumbnail': 't'},
    );
    expect(live.keys.toList(), [
      'id',
      'type',
      'name',
      'author',
      'videoUrl',
      'thumbnail',
      'previewVideo',
      'tags',
      'category',
      'color',
      'isPremium',
      'subjectId',
    ]);
    expect(live['type'], 'live');

    final inCollection = CatalogRules.buildEntry(
      kind: CatalogKind.collections,
      id: 41,
      draft: draft,
      media: {'url': 'u', 'thumbnail': 't'},
    );
    expect(inCollection['id'], '41');
    expect(inCollection.keys.take(2), ['id', 'subjectId']);
  });

  group('validate', () {
    final good = {
      'id': 5,
      'name': 'A',
      'author': 'WallRio',
      'category': 'Nature',
      'url': CatalogRules.storageUrl(bucket, 'p/a.jpg'),
      'thumbnail': CatalogRules.storageUrl(bucket, 'p/a-small.jpg'),
    };

    test('passes a complete entry whose files exist', () {
      expect(
        CatalogRules.validate(
          bucket: bucket,
          kind: CatalogKind.mobile,
          walls: [good],
          changed: [good],
          existingObjects: {'p/a.jpg', 'p/a-small.jpg'},
        ),
        isEmpty,
      );
    });

    test('flags missing fields, missing files and duplicate new ids', () {
      final bad = {...good, 'author': ''};
      final problems = CatalogRules.validate(
        bucket: bucket,
        kind: CatalogKind.mobile,
        walls: [
          bad,
          {'id': 5},
        ],
        changed: [bad],
        existingObjects: {'p/a.jpg'},
      );
      expect(problems, contains('"A" is missing author'));
      expect(
        problems.any((p) => p.contains('missing file: p/a-small.jpg')),
        isTrue,
      );
      expect(problems, contains('Duplicate id 5'));
    });

    test('ignores old duplicate ids the edit did not touch', () {
      expect(
        CatalogRules.validate(
          bucket: bucket,
          kind: CatalogKind.mobile,
          walls: [
            {'id': 1},
            {'id': 1},
          ],
          changed: [],
        ),
        isEmpty,
      );
    });
  });

  group('CatalogDocument', () {
    test(
      'desktop walls live in the first inner list and are written back there',
      () {
        final doc = CatalogDocument(
          kind: CatalogKind.desktop,
          root: {
            'walls': [
              [
                {'id': 1},
              ],
            ],
          },
          generation: '1',
        );
        expect(doc.wallsOf(), [
          {'id': 1},
        ]);
        final next = doc.copyWithWalls([
          {'id': 2},
          {'id': 1},
        ]);
        expect(next.root['walls'], [
          [
            {'id': 2},
            {'id': 1},
          ],
        ]);
      },
    );

    test('collections edit one collection and keep the others', () {
      final doc = CatalogDocument(
        kind: CatalogKind.collections,
        root: {
          'collections': [
            {
              'id': '2',
              'name': 'B',
              'walls': [
                {'id': '1'},
              ],
            },
            {'id': '1', 'name': 'A', 'walls': []},
          ],
        },
        generation: '1',
      );
      expect(doc.wallsOf('2'), [
        {'id': '1'},
      ]);
      expect(doc.allWalls, hasLength(1));
      final next = doc.copyWithWalls([
        {'id': '9'},
      ], '1');
      expect(next.wallsOf('1'), [
        {'id': '9'},
      ]);
      expect(next.wallsOf('2'), [
        {'id': '1'},
      ]);
      expect(next.collection('1')!['name'], 'A');
    });

    test('mobile keeps the other root fields', () {
      final doc = CatalogDocument(
        kind: CatalogKind.mobile,
        root: {
          'banners': [1],
          'walls': [
            {'id': 1},
          ],
        },
        generation: '1',
      );
      final next = doc.copyWithWalls([]);
      expect(next.root['banners'], [1]);
      expect(next.root['walls'], isEmpty);
    });
  });
}
