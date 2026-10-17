import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:theme_cli/src/mcp/theme_tools.dart';
import 'package:theme_cli/src/root_config.dart';
import 'package:theme_core/theme_core.dart';

import 'support/fake_renderer.dart';

void main() {
  late Directory tmp;
  late ThemeRoot root;

  setUp(() {
    tmp = Directory.systemTemp.createTempSync('mcp_widgets_test');
    root = ThemeRoot(p.join(tmp.path, 'Xiaomi Contract'));
  });
  tearDown(() => tmp.deleteSync(recursive: true));

  var nextId = 0;
  Future<Map<String, dynamic>> call(
    String tool,
    Map<String, Object?> args, {
    bool withRoot = true,
  }) async {
    final server = themeMcpServer(
      ThemeToolContext(
        cwd: tmp,
        project: null,
        sidecar: FakeRenderer(),
        root: withRoot ? root : null,
      ),
    );
    final sent = <Map<String, dynamic>>[];
    final id = ++nextId;
    await server.serve(
      Stream.value(
        jsonEncode({
          'jsonrpc': '2.0',
          'id': id,
          'method': 'tools/call',
          'params': {'name': tool, 'arguments': args},
        }),
      ),
      (m) => sent.add(jsonDecode(jsonEncode(m)) as Map<String, dynamic>),
    );
    return sent.firstWhere((m) => m['id'] == id)['result']
        as Map<String, dynamic>;
  }

  Map<String, dynamic> body(Map<String, dynamic> r) =>
      jsonDecode(r['content'][0]['text'] as String) as Map<String, dynamic>;

  group('list_widgets / get_widget', () {
    test('list the widgets by category, no root needed', () async {
      final r = await call('list_widgets', {}, withRoot: false);
      final cats = body(r)['categories'] as List;
      expect(cats.map((c) => c['category']), contains('Battery'));
      final battery = cats.firstWhere((c) => c['category'] == 'Battery');
      expect(battery['widgets'][0]['name'], 'Battery Ring');
      expect(battery['widgets'][0]['types'], contains('arcShape'));
    });

    test('filter by category, ignoring case', () async {
      final r = await call('list_widgets', {'category': 'music'});
      expect((body(r)['categories'] as List).single['category'], 'Music');
    });

    test('get_widget returns elements that parse as a spec', () async {
      final r = await call('get_widget', {'name': 'bento desert'});
      final elements = body(r)['elements'] as List;
      expect(elements.length, greaterThan(10));
      final parsed = ThemeSpec.parse({
        'specVersion': 1,
        'meta': {'title': 'T', 'designer': 'D', 'authorTag': 'Sj'},
        'wallpaper': {'home': 'w.jpg'},
        'icons': {'pack': 'u7'},
        'lockscreen': {'elements': elements},
      });
      expect(parsed.spec, isNotNull);
    });

    test('an unknown widget says what exists', () async {
      final r = await call('get_widget', {'name': 'nope'});
      expect(r['isError'], isTrue);
      expect(r['content'][0]['text'], contains('Battery Ring'));
    });
  });

  group('list_widget_styles / get_widget_style', () {
    test('list the built-in sets', () async {
      final r = await call('list_widget_styles', {}, withRoot: false);
      final sets = body(r)['sets'] as List;
      expect(sets.map((s) => s['id']), contains('builtin-analog'));
      expect(sets.every((s) => s['builtin'] == true), isTrue);
    });

    test('filter by element type', () async {
      final r = await call('list_widget_styles', {'type': 'analogClock'});
      final styles = [
        for (final s in body(r)['sets'] as List) ...s['styles'] as List,
      ];
      expect(styles, isNotEmpty);
      expect(styles.every((s) => s['type'] == 'analogClock'), isTrue);
    });

    test('get_widget_style applies a style to an element', () async {
      final list = await call('list_widget_styles', {'type': 'analogClock'});
      final id = (body(list)['sets'] as List)
          .expand((s) => s['styles'] as List)
          .first['id'];
      final r = await call('get_widget_style', {
        'id': id,
        'element': jsonEncode({'type': 'analogClock', 'dx': 120}),
      });
      final element = body(r)['element'] as Map;
      expect(element['dx'], 120);
      expect(element['type'], 'analogClock');
    });

    test('a style for another element type is refused', () async {
      final list = await call('list_widget_styles', {'type': 'analogClock'});
      final id = (body(list)['sets'] as List)
          .expand((s) => s['styles'] as List)
          .first['id'];
      final r = await call('get_widget_style', {
        'id': id,
        'element': '{"type":"hourClock"}',
      });
      expect(r['isError'], isTrue);
    });

    test('an element that is not JSON is refused', () async {
      final r = await call('get_widget_style', {'id': 'x', 'element': '['});
      expect(r['isError'], isTrue);
    });

    group('the designer\'s own sets in WidgetStyles/', () {
      void save(String name, Object? json) =>
          File(p.join(root.widgetStylesDir, name))
            ..createSync(recursive: true)
            ..writeAsStringSync(jsonEncode(json));

      test('are listed after the built-in ones and can be applied', () async {
        save('mine.json', {
          'format': 'miui-editor.widget-style-set',
          'version': 1,
          'id': 'mine',
          'name': 'Mine',
          'styles': [
            {
              'id': 'mine-1',
              'name': 'Gold',
              'type': 'tapToUnlock',
              'appearance': {'color': '#FFD700'},
            },
            {
              'id': 'mine-2',
              'name': 'Photo',
              'type': 'tapToUnlock',
              'appearance': {'unlockIcon': 'customPng'},
              'iconPng': 'AAAA',
            },
          ],
        });
        save('broken.json', {'format': 'x'});
        final r = await call('list_widget_styles', {});
        final sets = body(r)['sets'] as List;
        final mine = sets.firstWhere((s) => s['id'] == 'mine');
        expect(mine['builtin'], isFalse);
        expect((mine['styles'] as List).map((s) => s['id']), ['mine-1']);
        expect(mine['left_out'], contains('1 styles'));
        expect(body(r)['unreadable'], [contains('broken.json')]);

        final got = await call('get_widget_style', {
          'id': 'mine-1',
          'element': {'type': 'tapToUnlock'},
        });
        expect(body(got)['element']['color'], '#FFD700');
      });

      test('are only read when a root is set', () async {
        save('mine.json', {'format': 'miui-editor.widget-style-set'});
        final r = await call('list_widget_styles', {}, withRoot: false);
        expect(body(r).containsKey('unreadable'), isFalse);
      });
    });
  });
}
