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
    test('list the built-in sets of the user', () async {
      final r = await call('list_widget_styles', {
        'user': 'suraj',
      }, withRoot: false);
      final sets = body(r)['sets'] as List;
      expect(sets.map((s) => s['id']), contains('builtin-studio-suraj'));
      expect(sets.every((s) => s['builtin'] == true), isTrue);
      expect(sets.every((s) => s['user'] == 'suraj'), isTrue);
    });

    test('the built-in styles are shared out, none twice', () async {
      final ids = <String>[];
      for (final user in themeUsers) {
        final r = await call('list_widget_styles', {
          'user': user,
        }, withRoot: false);
        ids.addAll([
          for (final s in body(r)['sets'] as List)
            for (final st in s['styles'] as List) st['id'] as String,
        ]);
      }
      expect(ids.toSet(), hasLength(ids.length));
      final all = WidgetLibrary.builtin.styleSets.expand((s) => s.styles);
      expect(ids, hasLength(all.length));
    });

    test('a user without that kind of set gets none, not others\'', () async {
      final r = await call('list_widget_styles', {
        'user': 'suraj',
        'type': 'dragToUnlock',
      }, withRoot: false);
      expect(body(r)['sets'], isEmpty);
      expect(body(r)['note'], contains('another user'));
    });

    test('Suraj\'s old styles went to Rajat and Abhishek', () async {
      for (final user in ['rajat', 'abhishek']) {
        final r = await call('list_widget_styles', {
          'user': user,
        }, withRoot: false);
        expect(
          (body(r)['sets'] as List).every((s) => s['user'] == user),
          isTrue,
        );
      }
    });

    test('need to know the user', () async {
      final r = await call('list_widget_styles', {});
      expect(r['isError'], isTrue);
      expect(r['content'][0]['text'], contains('Ask the designer'));
      final bad = await call('list_widget_styles', {'user': 'nobody'});
      expect(bad['isError'], isTrue);
    });

    test('list_users names every user with their set count', () async {
      final r = await call('list_users', {}, withRoot: false);
      final users = body(r)['users'] as List;
      expect(users.map((u) => u['user']), themeUsers);
      final counts = {for (final u in users) u['user']: u['style_sets']};
      expect(counts['suraj'], 1);
      expect(counts['rajat'], greaterThan(0));
    });

    test('filter by element type', () async {
      final r = await call('list_widget_styles', {
        'user': 'suraj',
        'type': 'analogClock',
      });
      final styles = [
        for (final s in body(r)['sets'] as List) ...s['styles'] as List,
      ];
      expect(styles, isNotEmpty);
      expect(styles.every((s) => s['type'] == 'analogClock'), isTrue);
    });

    test('get_widget_style applies a style to an element', () async {
      final list = await call('list_widget_styles', {
        'user': 'suraj',
        'type': 'analogClock',
      });
      final id = (body(list)['sets'] as List)
          .expand((s) => s['styles'] as List)
          .first['id'];
      final r = await call('get_widget_style', {
        'id': id,
        'user': 'suraj',
        'element': jsonEncode({'type': 'analogClock', 'dx': 120}),
      });
      final element = body(r)['element'] as Map;
      expect(element['dx'], 120);
      expect(element['type'], 'analogClock');
    });

    test('a style for another element type is refused', () async {
      final list = await call('list_widget_styles', {
        'user': 'suraj',
        'type': 'analogClock',
      });
      final id = (body(list)['sets'] as List)
          .expand((s) => s['styles'] as List)
          .first['id'];
      final r = await call('get_widget_style', {
        'id': id,
        'user': 'suraj',
        'element': '{"type":"hourClock"}',
      });
      expect(r['isError'], isTrue);
    });

    test('an element that is not JSON is refused', () async {
      final r = await call('get_widget_style', {
        'id': 'x',
        'user': 'suraj',
        'element': '[',
      });
      expect(r['isError'], isTrue);
    });

    test('another user\'s style is refused, and so is no user', () async {
      final list = await call('list_widget_styles', {
        'user': 'rajat',
        'type': 'analogClock',
      }, withRoot: false);
      final id = (body(list)['sets'] as List)
          .expand((s) => s['styles'] as List)
          .first['id'];
      final other = await call('get_widget_style', {
        'id': id,
        'user': 'suraj',
      }, withRoot: false);
      expect(other['isError'], isTrue);
      expect(other['content'][0]['text'], contains('belongs to rajat'));
      final none = await call('get_widget_style', {'id': id}, withRoot: false);
      expect(none['isError'], isTrue);
      final own = await call('get_widget_style', {
        'id': id,
        'user': 'rajat',
      }, withRoot: false);
      expect(own.containsKey('isError'), isFalse);
    });

    group('clock sets', () {
      test('are listed and read for their user only', () async {
        final list = await call('list_clock_sets', {
          'user': 'suraj',
        }, withRoot: false);
        final sets = body(list)['clock_sets'] as List;
        expect(sets, hasLength(10));
        final id = sets.first['id'] as String;
        final got = await call('get_clock_set', {
          'id': id,
          'user': 'suraj',
        }, withRoot: false);
        expect(body(got)['elements'], isNotEmpty);
        expect(body(got)['fonts_needed'], isNotEmpty);
        final other = await call('get_clock_set', {
          'id': id,
          'user': 'rajat',
        }, withRoot: false);
        expect(other['isError'], isTrue);
        expect(other['content'][0]['text'], contains('belongs to suraj'));
      });

      test('all shared ones went to somebody else', () async {
        var total = 0;
        for (final user in themeUsers.where((u) => u != 'suraj')) {
          final list = await call('list_clock_sets', {
            'user': user,
          }, withRoot: false);
          total += (body(list)['clock_sets'] as List).length;
        }
        expect(total, 15);
      });

      test('need the user', () async {
        final r = await call('list_clock_sets', {}, withRoot: false);
        expect(r['isError'], isTrue);
      });
    });

    group('weather and battery sets', () {
      for (final kind in ['weather', 'battery']) {
        test('$kind sets are Suraj\'s alone', () async {
          final list = await call('list_${kind}_sets', {
            'user': 'suraj',
          }, withRoot: false);
          final sets = body(list)['${kind}_sets'] as List;
          expect(sets, hasLength(12));
          final id = sets.first['id'] as String;
          final got = await call('get_${kind}_set', {
            'id': id,
            'user': 'suraj',
          }, withRoot: false);
          expect(body(got)['elements'], isNotEmpty);
          final other = await call('get_${kind}_set', {
            'id': id,
            'user': 'rajat',
          }, withRoot: false);
          expect(other['isError'], isTrue);
          final empty = await call('list_${kind}_sets', {
            'user': 'rajat',
          }, withRoot: false);
          expect(body(empty)['${kind}_sets'], isEmpty);
        });
      }
    });

    group('validate_spec and the user\'s styles', () {
      Future<List<String>> codes(Map<String, Object?> spec) async {
        final r = await call('validate_spec', {
          'spec': jsonEncode(spec),
          'contrast': false,
        }, withRoot: false);
        return [for (final i in body(r)['issues'] as List) i['code'] as String];
      }

      Future<Map<String, Object?>> base(String user) async {
        final r = await call('get_base_spec', {
          'title': 'T',
          'user': user,
        }, withRoot: false);
        return Map<String, Object?>.from(body(r)['spec'] as Map);
      }

      test('a spec without a user is warned about', () async {
        final spec = await base('suraj');
        (spec['meta'] as Map).remove('profile');
        expect(await codes(spec), contains('meta.profile_missing'));
      });

      test('a style from another user is warned about', () async {
        final list = await call('list_widget_styles', {
          'user': 'rajat',
          'type': 'analogClock',
        }, withRoot: false);
        final id = (body(list)['sets'] as List)
            .expand((s) => s['styles'] as List)
            .first['id'];
        final styled = await call('get_widget_style', {
          'id': id,
          'user': 'rajat',
          'element': {'type': 'analogClock'},
        }, withRoot: false);
        final element = body(styled)['element'];
        final spec = await base('suraj');
        ((spec['lockscreen'] as Map)['elements'] as List).add(element);
        expect(await codes(spec), contains('style.other_user'));

        final mine = await base('rajat');
        ((mine['lockscreen'] as Map)['elements'] as List).add(element);
        final found = await codes(mine);
        expect(found, isNot(contains('style.other_user')));
        expect(found, isNot(contains('meta.profile_missing')));
      });
    });

    group('the designer\'s own sets in WidgetStyles/', () {
      void save(String name, Object? json) =>
          File(p.join(root.widgetStylesDir, name))
            ..createSync(recursive: true)
            ..writeAsStringSync(jsonEncode(json));

      test('are listed for their user only and can be applied', () async {
        save('mine.json', {
          'format': 'miui-editor.widget-style-set',
          'version': 1,
          'id': 'mine',
          'name': 'Mine',
          'user': 'suraj',
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
        save('theirs.json', {
          'format': 'miui-editor.widget-style-set',
          'version': 1,
          'id': 'theirs',
          'name': 'Theirs',
          'user': 'rajat',
          'styles': [
            {
              'id': 'theirs-1',
              'name': 'Red',
              'type': 'tapToUnlock',
              'appearance': {'color': '#FF0000'},
            },
          ],
        });
        save('broken.json', {'format': 'x'});
        final r = await call('list_widget_styles', {'user': 'Suraj'});
        final sets = body(r)['sets'] as List;
        final own = sets.where((s) => s['builtin'] == false).toList();
        expect(sets.map((s) => s['id']), contains('mine'));
        expect(sets.map((s) => s['id']), isNot(contains('theirs')));
        expect(sets.every((s) => s['user'] == 'suraj'), isTrue);
        final mine = own.single;
        expect(mine['builtin'], isFalse);
        expect(mine['user'], 'suraj');
        expect((mine['styles'] as List).map((s) => s['id']), ['mine-1']);
        expect(mine['left_out'], contains('1 styles'));
        expect(body(r)['unreadable'], [contains('broken.json')]);

        final got = await call('get_widget_style', {
          'id': 'mine-1',
          'user': 'suraj',
          'element': {'type': 'tapToUnlock'},
        });
        expect(body(got)['element']['color'], '#FFD700');

        final other = await call('get_widget_style', {
          'id': 'theirs-1',
          'user': 'suraj',
        });
        expect(other['isError'], isTrue);
        expect(other['content'][0]['text'], contains('belongs to rajat'));

        final users = body(await call('list_users', {}))['users'] as List;
        expect(users.firstWhere((u) => u['user'] == 'suraj')['style_sets'], 2);
      });

      test('a user without sets of the type gets none', () async {
        save('mine.json', {
          'format': 'miui-editor.widget-style-set',
          'version': 1,
          'id': 'mine',
          'name': 'Mine',
          'user': 'suraj',
          'styles': [
            {
              'id': 'mine-1',
              'name': 'Gold',
              'type': 'tapToUnlock',
              'appearance': {'color': '#FFD700'},
            },
          ],
        });
        final r = await call('list_widget_styles', {
          'user': 'suraj',
          'type': 'dragToUnlock',
        });
        expect(body(r)['sets'], isEmpty);
        expect(body(r)['note'], contains('dragToUnlock'));
      });

      test('a set nobody has claimed is not offered to a user', () async {
        save('old.json', {
          'format': 'miui-editor.widget-style-set',
          'version': 1,
          'id': 'old',
          'name': 'Old',
          'styles': [
            {
              'id': 'old-1',
              'name': 'Plain',
              'type': 'tapToUnlock',
              'appearance': {'color': '#FFFFFF'},
            },
          ],
        });
        final r = await call('list_widget_styles', {'user': 'suraj'});
        expect(
          (body(r)['sets'] as List).map((s) => s['id']),
          isNot(contains('old')),
        );
      });

      test('are only read when a root is set', () async {
        save('mine.json', {'format': 'miui-editor.widget-style-set'});
        final r = await call('list_widget_styles', {
          'user': 'suraj',
        }, withRoot: false);
        expect(body(r).containsKey('unreadable'), isFalse);
      });
    });
  });
}
