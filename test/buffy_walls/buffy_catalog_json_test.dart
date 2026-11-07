import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:miui_icon_generator/buffy_walls/domain/buffy_catalog_json.dart';
import 'package:miui_icon_generator/buffy_walls/domain/buffy_storage_layout.dart';

Map<String, dynamic> _wall(int id, {String name = 'A'}) => {
  'id': id,
  'name': name,
  'designer': 'Buffy',
  'category': 'Nature',
  'imageUrl': 'https://x/$id.jpg',
  'compressUrl': 'https://x/$id-small.jpg',
  'isHot': false,
  'isPremium': false,
  'colors': <String>[],
  'tags': <String>[],
};

void main() {
  final catalog = jsonEncode({
    'titles': ['BuffyWalls'],
    'banners': {'free': 'https://a/free.png'},
    'popular': [_wall(1), _wall(2)],
    'adBanners': [
      {'id': 1, 'url': 'https://a/b.png', 'category': '', 'link': ''},
    ],
  });

  test('fields exclude the wallpaper list and keep order', () {
    expect(parseBuffyCatalogFields(catalog).keys, [
      'titles',
      'banners',
      'adBanners',
    ]);
  });

  test('encode applies edited, removed and new fields in place', () {
    final fields = parseBuffyCatalogFields(catalog)
      ..remove('titles')
      ..['banners'] = {'free': 'https://a/new.png'}
      ..['hotColors'] = ['Black'];
    final out =
        jsonDecode(
              encodeBuffyCatalog((
                catalog: catalog,
                fields: fields,
                wallpapers: [_wall(1)],
              )),
            )
            as Map<String, dynamic>;

    expect(out.keys, ['banners', 'popular', 'adBanners', 'hotColors']);
    expect(out['banners'], {'free': 'https://a/new.png'});
    expect((out['popular'] as List).length, 1);
  });

  test('diff reports added, removed, edited wallpapers and changed fields', () {
    final after = encodeBuffyCatalog((
      catalog: catalog,
      fields: {
        ...parseBuffyCatalogFields(catalog),
        'titles': ['New'],
      },
      wallpapers: [
        _wall(1, name: 'B'),
        _wall(3),
      ],
    ));
    final diff = diffBuffyCatalog((before: catalog, after: after));

    expect(diff.added.map((w) => w.id), [3]);
    expect(diff.removed.map((w) => w.id), [2]);
    expect(diff.edited.map((w) => w.id), [1]);
    expect(diff.fieldsChanged, ['titles']);
    expect(diffBuffyCatalog((before: catalog, after: catalog)).isEmpty, isTrue);
  });

  test('upload objects get a safe, unique name', () {
    expect(
      buffyUploadObject(
        'PushBanners',
        'Diwali Sale!.PNG',
        DateTime.utc(2026, 11, 7, 8, 9, 10),
      ),
      'buffy_wall_data/PushBanners/Diwali_Sale_-20261107080910.png',
    );
  });
}
