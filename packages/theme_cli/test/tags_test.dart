import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:theme_cli/src/tags.dart';
import 'package:theme_cli/theme_cli.dart';

void main() {
  final catalog = TagCatalog({
    'Features': ['Analog clock', 'Slide', 'Widget', 'Dynamic lock screen'],
    'Content style': ['Simple', 'Cool', 'Dark', 'Dream'],
    'Design genre': ['Abstract', 'Regular'],
    'Color': ['Orange', 'Blue', 'Gold'],
    'Nature': ['Moon', 'Night'],
    'Objects': ['Clock', 'Door'],
    'Seasons': ['Autumn'],
  });

  test('picks name, clock, unlock and fill tags, at most six', () {
    final tags = suggestTags(
      TagInput(
        title: 'Autumn Doorway',
        elementTypes: ['hourClock', 'minClock', 'swipeUpUnlock'],
      ),
      catalog,
    );
    expect(tags, ['Autumn', 'Door', 'Clock', 'Slide', 'Simple', 'Regular']);
  });

  test('analog clocks and widgets', () {
    final tags = suggestTags(
      TagInput(
        title: 'Moonlit',
        elementTypes: ['analogClock', 'musicBg', 'tapToUnlock'],
      ),
      catalog,
    );
    expect(tags.take(4), ['Moon', 'Night', 'Analog clock', 'Widget']);
    expect(tags.length, lessThanOrEqualTo(maxTags));
  });

  test('normalizeTags fixes case and rejects unknown or too many', () {
    expect(normalizeTags(['cool', 'SLIDE', 'cool'], catalog), [
      'Cool',
      'Slide',
    ]);
    expect(() => normalizeTags(['Nope'], catalog), throwsFormatException);
    expect(
      () => normalizeTags([
        'Cool',
        'Slide',
        'Dark',
        'Moon',
        'Door',
        'Clock',
        'Gold',
      ], catalog),
      throwsFormatException,
    );
  });

  test('theme tags writes 1tags/<name>.txt next to the themes', () async {
    final tmp = Directory.systemTemp.createTempSync('tags_cmd');
    addTearDown(() => tmp.deleteSync(recursive: true));
    final catalogFile = File(p.join(tmp.path, 'tags.json'))
      ..writeAsStringSync(
        '{"data":[{"name":"Objects","subTags":["Clock","Door"]},'
        '{"name":"Features","subTags":["Slide"]},'
        '{"name":"Content style","subTags":["Simple","Cool"]},'
        '{"name":"Design genre","subTags":["Regular","Abstract"]}]}',
      );
    final ws = Directory(p.join(tmp.path, 'Week1', 'Red Door'))
      ..createSync(recursive: true);
    File(p.join(ws.path, 'theme.spec.json')).writeAsStringSync(
      '{"meta":{"title":"Red Door"},"lockscreen":{"elements":['
      '{"type":"hourClock"},{"type":"swipeUpUnlock"}]}}',
    );
    final out = StringBuffer(), err = StringBuffer();
    final code = await runCli(
      ['tags', '--catalog', catalogFile.path, p.join(tmp.path, 'Week1')],
      out: out,
      err: err,
      cwd: tmp,
    );
    expect(code, 0, reason: '$err');
    final file = File(p.join(tmp.path, 'Week1', '1tags', 'Red Door.txt'));
    expect(file.readAsStringSync(), 'Door,Clock,Slide,Simple,Regular,Abstract');
  });
}
