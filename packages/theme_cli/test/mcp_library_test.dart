import 'dart:convert';
import 'dart:io';

import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:theme_cli/src/mcp/mcp_server.dart';
import 'package:theme_cli/src/mcp/theme_tools.dart';
import 'package:theme_cli/src/root_config.dart';

import 'support/fake_renderer.dart';

void main() {
  late Directory tmp;
  late ThemeRoot root;
  late FakeRenderer renderer;
  late McpServer server;

  setUp(() {
    tmp = Directory.systemTemp.createTempSync('mcp_library_test');
    root = ThemeRoot(p.join(tmp.path, 'Xiaomi Contract'));
    renderer = FakeRenderer();
    server = themeMcpServer(
      ThemeToolContext(cwd: tmp, project: null, sidecar: renderer, root: root),
    );
  });
  tearDown(() => tmp.deleteSync(recursive: true));

  void png(String path, {int w = 40, int h = 80, img.Color? color}) =>
      File(path)
        ..createSync(recursive: true)
        ..writeAsBytesSync(
          img.encodePng(
            img.Image(width: w, height: h)
              ..clear(color ?? img.ColorRgb8(20, 20, 60)),
          ),
        );

  void jpg(String path, img.Color color) => File(path)
    ..createSync(recursive: true)
    ..writeAsBytesSync(
      img.encodeJpg(img.Image(width: 120, height: 240)..clear(color)),
    );

  var nextId = 0;
  Future<Map<String, dynamic>> call(
    String tool,
    Map<String, Object?> args, {
    McpServer? on,
  }) async {
    final sent = <Map<String, dynamic>>[];
    final id = ++nextId;
    await (on ?? server).serve(
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
  List images(Map<String, dynamic> r) =>
      (r['content'] as List).where((c) => c['type'] == 'image').toList();
  String text(Map<String, dynamic> r) => r['content'][0]['text'] as String;

  group('list_wallpapers', () {
    setUp(() {
      png(p.join(root.wallFolder('2'), 'Sunset.jpg'));
      png(p.join(root.wallFolder('2'), 'Blue Sky.png'));
      File(p.join(root.wallFolder('2'), 'notes.txt')).writeAsStringSync('x');
      png(p.join(root.wallFolder('10'), 'a.png'));
      Directory(root.wallFolder('1')).createSync(recursive: true);
    });

    test('lists the folders in natural order with their counts', () async {
      final r = body(await call('list_wallpapers', {}));
      expect(r['folders'], [
        {'folder': '1', 'wallpapers': 0},
        {'folder': '2', 'wallpapers': 2},
        {'folder': '10', 'wallpapers': 1},
      ]);
    });

    test(
      'lists a folder\'s images, which the editor names its themes after',
      () async {
        final r = body(await call('list_wallpapers', {'folder': 2}));
        final names = (r['wallpapers'] as List).map((w) => w['name']);
        expect(names, ['Blue Sky.png', 'Sunset.jpg']);
        final sunset = (r['wallpapers'] as List).firstWhere(
          (w) => w['name'] == 'Sunset.jpg',
        );
        expect(sunset['theme_name'], 'Sunset');
        expect(sunset['path'], p.join(root.wallFolder('2'), 'Sunset.jpg'));
      },
    );

    test(
      'a folder that does not exist, or could escape, is an error',
      () async {
        for (final folder in ['99', '../THEMES']) {
          final r = await call('list_wallpapers', {'folder': folder});
          expect(r['isError'], isTrue, reason: folder);
        }
      },
    );

    test('needs the root', () async {
      final bare = themeMcpServer(
        ThemeToolContext(cwd: tmp, project: null, sidecar: renderer),
      );
      final r = await call('list_wallpapers', {}, on: bare);
      expect(r['isError'], isTrue);
      expect(text(r), contains('--root'));
    });
  });

  group('view_wallpaper', () {
    test(
      'returns a scaled picture, its dominant colors and its tone',
      () async {
        jpg(
          p.join(root.wallFolder('2'), 'Night.jpg'),
          img.ColorRgb8(10, 20, 90),
        );
        final r = await call('view_wallpaper', {
          'folder': '2',
          'name': 'Night',
          'max_width': 64,
        });

        final b = body(r);
        expect(b['width'], 120);
        expect(b['height'], 240);
        expect(b['tone'], 'dark');
        final top = (b['palette'] as List).first['color'] as String;
        final rgb = [
          for (var i = 1; i < 7; i += 2)
            int.parse(top.substring(i, i + 2), radix: 16),
        ];
        expect(rgb[2], greaterThan(rgb[0]), reason: 'bluish: $top');

        expect(images(r), hasLength(1));
        expect(images(r).single['mimeType'], 'image/jpeg');
        final shown = img.decodeJpg(
          base64Decode(images(r).single['data'] as String),
        )!;
        expect(shown.width, 64);
      },
    );

    test('two flat halves give two colors', () async {
      final image = img.Image(width: 100, height: 100)
        ..clear(img.ColorRgb8(240, 20, 20));
      img.fillRect(
        image,
        x1: 0,
        y1: 50,
        x2: 99,
        y2: 99,
        color: img.ColorRgb8(20, 20, 240),
      );
      File(
        p.join(tmp.path, 'halves.png'),
      ).writeAsBytesSync(img.encodePng(image));

      final b = body(await call('view_wallpaper', {'path': 'halves.png'}));
      final palette = b['palette'] as List;
      expect(
        palette.map((c) => c['color']),
        containsAll(['#F01414', '#1414F0']),
      );
      expect(palette.first['share'], closeTo(.5, .05));
    });

    test('a light picture is called light', () async {
      png(p.join(tmp.path, 'bright.png'), color: img.ColorRgb8(250, 250, 240));
      expect(
        body(await call('view_wallpaper', {'path': 'bright.png'}))['tone'],
        'light',
      );
    });

    test('errors name the problem', () async {
      png(p.join(root.wallFolder('2'), 'a.png'));
      File(p.join(tmp.path, 'text.png')).writeAsStringSync('not an image');
      for (final (args, hint) in [
        ({'folder': '2', 'name': 'zzz'}, 'No wallpaper'),
        ({'folder': '2'}, 'folder and name'),
        ({'path': 'missing.png'}, 'No such file'),
        ({'path': 'text.png'}, 'not an image'),
        ({'path': 'text.png', 'max_width': 10}, 'max_width'),
      ]) {
        final r = await call('view_wallpaper', args);
        expect(r['isError'], isTrue, reason: '$args');
        expect(text(r), contains(hint), reason: '$args');
      }
    });
  });

  group('presets', () {
    void preset(
      String name,
      List<Map<String, Object?>> elements, {
      bool preview = true,
    }) {
      File(p.join(root.presetsDir, name, 'preset.json'))
        ..createSync(recursive: true)
        ..writeAsStringSync(jsonEncode(elements));
      if (preview) {
        png(p.join(root.presetsDir, name, 'preview.png'), w: 831, h: 1800);
      }
    }

    setUp(() {
      preset('Abstract Glow', [
        {'type': 'swipeUpUnlock'},
        {'type': 'hourClock', 'font': 'Ground', 'color': 4294967295},
        {'type': 'minClock', 'font': 'Roboto'},
        {
          'type': 'slideToUnlock',
          'unlockIconPath': 'assets/element_3_icon.png',
        },
      ]);
      preset('After Midnight', [
        {'type': 'analogClock'},
      ], preview: false);
      Directory(p.join(root.presetsDir, 'Empty')).createSync(recursive: true);
    });

    test('list_presets shows names with their element types', () async {
      final r = body(await call('list_presets', {}));
      expect(
        r['total'],
        2,
        reason: 'a folder without preset.json is not a preset',
      );
      expect(r['presets'], [
        {
          'name': 'Abstract Glow',
          'elements': [
            'swipeUpUnlock',
            'hourClock',
            'minClock',
            'slideToUnlock',
          ],
          'has_preview': true,
        },
        {
          'name': 'After Midnight',
          'elements': ['analogClock'],
          'has_preview': false,
        },
      ]);
    });

    test('list_presets filters by name and limits', () async {
      expect(
        (body(await call('list_presets', {'query': 'MIDNIGHT'}))['presets']
                as List)
            .single['name'],
        'After Midnight',
      );
      final limited = body(await call('list_presets', {'limit': 1}));
      expect(limited['total'], 2);
      expect(limited['presets'], hasLength(1));
      expect((await call('list_presets', {'limit': 0}))['isError'], isTrue);
    });

    test(
      'get_preset returns pasteable elements, the fonts they need and a small preview',
      () async {
        final r = await call('get_preset', {'name': 'Abstract Glow'});
        final b = body(r);
        final elements = b['elements'] as List;
        expect(elements.map((e) => e['type']), [
          'swipeUpUnlock',
          'hourClock',
          'minClock',
          'slideToUnlock',
        ]);
        expect(
          elements.last['unlockIconPath'],
          p.join(
            root.presetsDir,
            'Abstract Glow',
            'assets',
            'element_3_icon.png',
          ),
        );
        expect(b['fonts_needed'], ['Ground']);

        final shown = img.decodeJpg(
          base64Decode(images(r).single['data'] as String),
        )!;
        expect(shown.width, 360);
      },
    );

    test('the preview can be left out or be missing', () async {
      expect(
        images(
          await call('get_preset', {'name': 'Abstract Glow', 'image': false}),
        ),
        isEmpty,
      );
      final r = await call('get_preset', {'name': 'After Midnight'});
      expect(r.containsKey('isError'), isFalse);
      expect(images(r), isEmpty);
    });

    test('presets are valid spec elements', () async {
      final elements = body(
        await call('get_preset', {'name': 'Abstract Glow'}),
      )['elements'];
      final spec = {
        'specVersion': 1,
        'meta': {'title': 'X'},
        'wallpaper': {'home': 'w.png'},
        'icons': {'pack': 'u1'},
        'lockscreen': {'elements': elements},
      };
      final r = body(
        await call('validate_spec', {'spec': spec, 'contrast': false}),
      );
      expect(
        (r['issues'] as List).where(
          (i) => (i['path'] as String).startsWith('/lockscreen/elements'),
        ),
        isEmpty,
      );
    });

    test('unknown or unsafe names are errors', () async {
      for (final name in ['Nope', '../Preset', 'Empty', '']) {
        expect(
          (await call('get_preset', {'name': name}))['isError'],
          isTrue,
          reason: name,
        );
      }
    });
  });

  group('weeks and defaults', () {
    Map<String, Object?> wallSpec({
      Object? workspace,
      String home = 'Sunset.jpg',
    }) {
      png(p.join(root.wallFolder('2'), 'Sunset.jpg'));
      png(p.join(root.assetsDir, 'bg.png'));
      return {
        'specVersion': 1,
        'meta': {'title': 'Neon', 'designer': 'D', 'authorTag': 'T'},
        'wallpaper': {'home': home},
        'icons': {'pack': 'u1'},
        'lockscreen': {
          'elements': [
            {'type': 'swipeUpUnlock'},
            {'type': 'hourClock', 'color': '#FFFFFF'},
          ],
        },
        'workspace': ?workspace,
      };
    }

    test('week and folder build a bare spec into THEMES/Week<n>', () async {
      final r = await call('build_theme', {
        'spec': wallSpec(),
        'week': 3,
        'folder': 2,
      });

      expect(r.containsKey('isError'), isFalse, reason: text(r));
      expect(body(r)['mtz'], p.join(root.weekDir('3'), 'Neon.mtz'));
      final built = renderer.specs.single;
      expect(built['workspace'], {'week': '3', 'folder': '2'});
      expect(
        built['wallpaper']['home'],
        p.join(root.wallFolder('2'), 'Sunset.jpg'),
      );
      expect(built['lockscreen']['assetsDir'], root.assetsDir);
    });

    test(
      'the spec\'s own workspace.week picks the folder when none is given',
      () async {
        final r = await call('build_theme', {
          'spec': wallSpec(workspace: {'week': '7', 'folder': '2'}),
        });
        expect(body(r)['mtz'], p.join(root.weekDir('7'), 'Neon.mtz'));
      },
    );

    test('an explicit out_dir wins over the week', () async {
      final out = p.join(tmp.path, 'elsewhere');
      final r = await call('build_theme', {
        'spec': wallSpec(),
        'week': 3,
        'folder': 2,
        'out_dir': out,
      });
      expect(body(r)['mtz'], p.join(out, 'Neon.mtz'));
    });

    test('without a week or out_dir it says what to give', () async {
      final r = await call('build_theme', {
        'spec': wallSpec(workspace: {'folder': '2'}),
      });
      expect(r['isError'], isTrue);
      expect(text(r), contains('week'));
    });

    test('a week that could escape THEMES is refused', () async {
      for (final args in [
        {'week': '../x'},
        {'week': 'a/b'},
      ]) {
        final r = await call('build_theme', {
          'spec': wallSpec(),
          'folder': 2,
          ...args,
        });
        expect(r['isError'], isTrue, reason: '$args');
        expect(renderer.jobs, isEmpty);
      }
      final r = await call('build_theme', {
        'spec': wallSpec(workspace: {'week': '../x', 'folder': '2'}),
      });
      expect(r['isError'], isTrue);
      expect(renderer.jobs, isEmpty);
    });

    test('validate_spec sees the same defaults as the build', () async {
      final r = body(
        await call('validate_spec', {
          'spec': wallSpec(),
          'folder': 2,
          'contrast': false,
        }),
      );
      expect(r['ok'], isTrue, reason: '${r['issues']}');
      final without = body(
        await call('validate_spec', {'spec': wallSpec(), 'contrast': false}),
      );
      expect(
        without['ok'],
        isFalse,
        reason: 'no folder, so Sunset.jpg is not found',
      );
    });

    test('build_batch takes a week too', () async {
      final path = File(p.join(tmp.path, 'specs', 'neon.json'))
        ..createSync(recursive: true);
      path.writeAsStringSync(jsonEncode(wallSpec()));
      final r = await call('build_batch', {
        'paths': ['specs'],
        'week': 4,
        'folder': 2,
      });
      expect(r.containsKey('isError'), isFalse, reason: text(r));
      expect(File(p.join(root.weekDir('4'), 'Neon.mtz')).existsSync(), isTrue);
    });

    test('preview_theme finds a theme by week and name', () async {
      await call('build_theme', {
        'spec': wallSpec(),
        'week': 3,
        'folder': 2,
        'preview': false,
      });
      final r = await call('preview_theme', {
        'week': 3,
        'name': 'Neon',
        'width': 270,
      });
      expect(images(r), hasLength(1));
      expect(
        (await call('preview_theme', {
          'week': 3,
          'name': '../Neon',
        }))['isError'],
        isTrue,
      );
      expect((await call('preview_theme', {'week': 3}))['isError'], isTrue);
    });
  });

  group('get_rules', () {
    void rules(String text) => File(root.rulesFile)
      ..createSync(recursive: true)
      ..writeAsStringSync(text);

    test('returns the rules file', () async {
      rules('# Rules\n- one unlock\n');
      expect(text(await call('get_rules', {})), contains('one unlock'));
    });

    test('returns one section up to the next heading of its level', () async {
      rules(
        '# Icons\n- match wallpaper\n## Shape\n- round\n# Lock\n- unlock\n',
      );
      final icons = text(await call('get_rules', {'section': 'icons'}));
      expect(icons, contains('match wallpaper'));
      expect(icons, contains('round'));
      expect(icons, isNot(contains('unlock')));
      final shape = text(await call('get_rules', {'section': 'Shape'}));
      expect(shape, isNot(contains('match wallpaper')));
    });

    test('an unknown section is an error', () async {
      rules('# Icons\n- x\n');
      final r = await call('get_rules', {'section': 'nope'});
      expect(r['isError'], isTrue);
    });

    test('no file says so', () async {
      expect(text(await call('get_rules', {})), contains('no rules'));
    });
  });
}
