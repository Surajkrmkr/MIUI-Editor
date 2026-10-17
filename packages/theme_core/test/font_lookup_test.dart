import 'dart:io';

import 'package:test/test.dart';
import 'package:theme_core/theme_core.dart';

void main() {
  late Directory a, b;

  setUp(() {
    final tmp = Directory.systemTemp.createTempSync('font_lookup_test');
    a = Directory('${tmp.path}/a')..createSync();
    b = Directory('${tmp.path}/b')..createSync();
  });
  tearDown(() => a.parent.deleteSync(recursive: true));

  File touch(Directory d, String name) =>
      File('${d.path}/$name')..writeAsBytesSync([0, 1, 0, 0]);

  test('matches the family by file name, ignoring case and punctuation', () {
    final f = touch(a, 'Ground.ttf');
    expect(findFontFile('Ground', [a.path]), f.path);
    expect(findFontFile('ground', [a.path]), f.path);
  });

  test('"Fira Sans" finds FiraSans-Regular.otf', () {
    final f = touch(a, 'FiraSans-Regular.otf');
    expect(findFontFile('Fira Sans', [a.path]), f.path);
  });

  test('other weights and families do not match', () {
    touch(a, 'FiraSans-Bold.ttf');
    touch(a, 'Fira.ttf');
    touch(a, 'Ground.woff');
    expect(findFontFile('Fira Sans', [a.path]), isNull);
    expect(findFontFile('Ground', [a.path]), isNull);
  });

  test('folders are searched in order and missing ones are skipped', () {
    touch(a, 'Ground.ttf');
    final second = touch(b, 'Ground.ttf');
    expect(
      findFontFile('Ground', ['${a.parent.path}/none', b.path, a.path]),
      second.path,
    );
    expect(findFontFile('', [a.path]), isNull);
  });
}
