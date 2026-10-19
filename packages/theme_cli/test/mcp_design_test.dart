import 'dart:convert';
import 'dart:io';

import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:theme_cli/src/mcp/theme_tools.dart';
import 'package:theme_cli/src/root_config.dart';

import 'support/fake_renderer.dart';

void main() {
  late Directory tmp;
  late ThemeRoot root;

  setUp(() {
    tmp = Directory.systemTemp.createTempSync('mcp_design_test');
    root = ThemeRoot(p.join(tmp.path, 'Xiaomi Contract'));
  });
  tearDown(() => tmp.deleteSync(recursive: true));

  var nextId = 0;
  Future<Map<String, dynamic>> call(
    String tool,
    Map<String, Object?> args,
  ) async {
    final server = themeMcpServer(
      ThemeToolContext(
        cwd: tmp,
        project: null,
        sidecar: FakeRenderer(),
        root: root,
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

  void picture(String path) => File(path)
    ..createSync(recursive: true)
    ..writeAsBytesSync(img.encodePng(img.Image(width: 400, height: 800)));

  group('references', () {
    test(
      'an empty or missing folder tells the agent to ask, not to use Preset',
      () async {
        final r = body(await call('list_references', {}));
        expect(r['total'], 0);
        expect(r['note'], contains('do not use the Preset folder'));
      },
    );

    test(
      'pictures, picture + json pairs and preset folders are listed',
      () async {
        final dir = root.referencesDir;
        picture(p.join(dir, 'Plain.png'));
        picture(p.join(dir, 'Rich.png'));
        File(p.join(dir, 'Rich.json')).writeAsStringSync(
          jsonEncode([
            {'type': 'hourClock'},
            {'type': 'slideToUnlock', 'unlockIconPath': 'x.png'},
          ]),
        );
        picture(p.join(dir, 'Folder', 'preview.png'));
        File(p.join(dir, 'Folder', 'preset.json')).writeAsStringSync(
          jsonEncode([
            {'type': 'minClock'},
          ]),
        );
        File(p.join(dir, 'notes.txt')).writeAsStringSync('x');

        final r = body(await call('list_references', {}));
        expect(r['references'], [
          {'name': 'Folder', 'has_elements': true},
          {'name': 'Plain', 'has_elements': false},
          {'name': 'Rich', 'has_elements': true},
        ]);
        expect(
          (body(await call('list_references', {'query': 'ric'}))['references']
                  as List)
              .single['name'],
          'Rich',
        );
      },
    );

    test('get_reference returns the picture and any elements', () async {
      final dir = root.referencesDir;
      picture(p.join(dir, 'Plain.png'));
      picture(p.join(dir, 'Rich.png'));
      File(p.join(dir, 'Rich.json')).writeAsStringSync(
        jsonEncode({
          'lockscreen': {
            'elements': [
              {'type': 'hourClock'},
            ],
          },
        }),
      );

      final plain = await call('get_reference', {'name': 'Plain'});
      expect(
        (plain['content'] as List).any((c) => c['type'] == 'image'),
        isTrue,
      );
      expect(body(plain)['note'], contains('Only the picture'));
      expect(body(plain).containsKey('elements'), isFalse);

      final rich = await call('get_reference', {'name': 'Rich'});
      expect(body(rich)['elements'], [
        {'type': 'hourClock'},
      ]);
    });

    test('unknown or unsafe names are errors', () async {
      picture(p.join(root.referencesDir, 'A.png'));
      for (final name in ['Nope', '../A', '']) {
        expect(
          (await call('get_reference', {'name': name}))['isError'],
          isTrue,
          reason: name,
        );
      }
    });
  });

  group('check_uniqueness', () {
    Map<String, Object?> spec(
      String title,
      List<Map<String, Object?>> elements,
    ) => {
      'specVersion': 1,
      'meta': {'title': title, 'designer': 'D', 'authorTag': 'S'},
      'wallpaper': {'home': 'w.png'},
      'icons': {'pack': 'u1'},
      'lockscreen': {'elements': elements},
    };

    final design = [
      {'type': 'hourClock', 'dy': -100},
      {'type': 'minClock', 'dy': -100},
      {'type': 'slideToUnlock'},
      {'type': 'weatherTemp'},
    ];

    void save(String name, Map<String, Object?> s) =>
        File(p.join(root.specsDir, '$name.json'))
          ..createSync(recursive: true)
          ..writeAsStringSync(jsonEncode(s));

    test('nothing to compare with is distinct', () async {
      final r = body(
        await call('check_uniqueness', {'spec': jsonEncode(spec('A', design))}),
      );
      expect(r['verdict'], 'distinct');
      expect(r['design']['unlock'], 'slideToUnlock/classic');
    });

    test('the same design again is too similar and says why', () async {
      save('Old', spec('Old', design));
      final r = body(
        await call('check_uniqueness', {
          'spec': jsonEncode(spec('New', design)),
        }),
      );
      expect(r['verdict'], 'too_similar');
      final closest = (r['closest'] as List).single as Map;
      expect(closest['name'], 'Old');
      expect(closest['similarity'], 1.0);
      expect(closest['shares'], contains('unlock slideToUnlock/classic'));
    });

    test('a different design is distinct', () async {
      save('Old', spec('Old', design));
      final other = [
        {'type': 'analogClock', 'dx': 90, 'dy': 150, 'color': '#FF2200'},
        {'type': 'tapToUnlock'},
        {'type': 'calendarGrid'},
        {'type': 'rectangleShape'},
      ];
      final r = body(
        await call('check_uniqueness', {
          'spec': jsonEncode(spec('New', other)),
        }),
      );
      expect(r['verdict'], 'distinct');
    });

    test('a spec is not compared with itself', () async {
      save('Same', spec('Same', design));
      final r = body(
        await call('check_uniqueness', {
          'path': p.join(root.specsDir, 'Same.json'),
        }),
      );
      expect(r['compared_with'], 0);
      final again = body(
        await call('check_uniqueness', {
          'spec': jsonEncode(spec('Same', design)),
        }),
      );
      expect(again['compared_with'], 0);
    });

    test('earlier specs in week folders are compared too', () async {
      File(p.join(root.specsDir, 'Week32', 'Old.json'))
        ..createSync(recursive: true)
        ..writeAsStringSync(jsonEncode(spec('Old', design)));
      final r = body(
        await call('check_uniqueness', {
          'spec': jsonEncode(spec('New', design)),
        }),
      );
      expect(r['compared_with'], 1);
      expect(r['verdict'], 'too_similar');
    });

    test(
      'validate_spec names a close earlier theme without being asked',
      () async {
        File(p.join(root.specsDir, 'Week32', 'Old.json'))
          ..createSync(recursive: true)
          ..writeAsStringSync(jsonEncode(spec('Old', design)));
        final r = body(
          await call('validate_spec', {
            'spec': jsonEncode(spec('New', design)),
            'contrast': false,
          }),
        );
        final warning = (r['issues'] as List).firstWhere(
          (i) => i['code'] == 'lockscreen.too_similar',
        );
        expect(warning['message'], contains('"Old"'));
      },
    );

    test('the starter layout is flagged by validate_spec', () async {
      final base = body(await call('get_base_spec', {'title': 'S'}))['spec'];
      final r = body(
        await call('validate_spec', {
          'spec': jsonEncode(base),
          'contrast': false,
        }),
      );
      expect([
        for (final i in r['issues'] as List) i['code'],
      ], contains('lockscreen.base_layout'));
    });

    test('a spec with errors is refused', () async {
      final r = await call('check_uniqueness', {'spec': '{"specVersion":1}'});
      expect(r['isError'], isTrue);
    });

    test('needs exactly one of spec and path', () async {
      expect((await call('check_uniqueness', {}))['isError'], isTrue);
    });
  });

  group('get_base_spec', () {
    test('returns a spec with the title, wallpaper and workspace', () async {
      final r = body(
        await call('get_base_spec', {
          'title': 'Neon',
          'wallpaper': 'Neon.jpg',
          'week': '4',
          'folder': '2',
        }),
      );
      final spec = r['spec'] as Map;
      expect(spec['meta']['title'], 'Neon');
      expect(spec['wallpaper']['home'], 'Neon.jpg');
      expect(spec['workspace'], {'week': '4', 'folder': '2'});
      expect((spec['lockscreen']['elements'] as List), isNotEmpty);
      expect(r['layout_guide'], contains('3.9'));
    });

    test('works without a wallpaper, week or folder', () async {
      final r = body(await call('get_base_spec', {'title': 'X'}));
      expect((r['spec'] as Map).containsKey('workspace'), isFalse);
      expect(r['spec']['wallpaper']['home'], isNotEmpty);
    });

    test('needs a title and a safe week', () async {
      expect((await call('get_base_spec', {}))['isError'], isTrue);
      expect(
        (await call('get_base_spec', {
          'title': 'X',
          'week': '../x',
        }))['isError'],
        isTrue,
      );
    });
  });

  test('get_widget warns about positions off the screen', () async {
    final bento = body(await call('get_widget', {'name': 'Bento Desert'}));
    expect(bento['warning'], contains('outside the screen'));
    final ring = body(await call('get_widget', {'name': 'Battery Ring'}));
    expect(ring.containsKey('warning'), isFalse);
  });

  test('validate_spec warns about a bare lockscreen', () async {
    final r = body(
      await call('validate_spec', {
        'spec': jsonEncode({
          'specVersion': 1,
          'meta': {'title': 'X', 'designer': 'D', 'authorTag': 'S'},
          'wallpaper': {'home': 'w.png'},
          'icons': {'pack': 'u1'},
          'lockscreen': {
            'elements': [
              {'type': 'swipeUpUnlock'},
              {'type': 'hourClock'},
            ],
          },
        }),
        'contrast': false,
      }),
    );
    final codes = [for (final i in r['issues'] as List) i['code']];
    expect(codes, contains('lockscreen.sparse'));
  });
}
