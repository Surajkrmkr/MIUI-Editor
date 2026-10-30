import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:theme_cli/src/mcp/mcp_server.dart';
import 'package:theme_cli/src/mcp/theme_tools.dart';
import 'package:theme_core/theme_core.dart' show BuildMode;

import 'support/fake_renderer.dart';

void main() {
  late Directory tmp;
  late FakeRenderer renderer;
  late McpServer server;
  late String out;

  setUp(() {
    tmp = Directory.systemTemp.createTempSync('mcp_tools_test');
    out = p.join(tmp.path, 'out');
    renderer = FakeRenderer();
    server = themeMcpServer(
      ThemeToolContext(cwd: tmp, project: null, sidecar: renderer),
    );
  });
  tearDown(() => tmp.deleteSync(recursive: true));

  String wallpaper() {
    final f = File(p.join(tmp.path, 'wall.png'));
    if (!f.existsSync()) {
      f.writeAsBytesSync(
        img.encodePng(
          img.Image(width: 30, height: 60)..clear(img.ColorRgb8(20, 20, 60)),
        ),
      );
    }
    return f.path;
  }

  File assetsBg() => File(p.join(tmp.path, 'assets', 'bg.png'))
    ..createSync(recursive: true)
    ..writeAsBytesSync(img.encodePng(img.Image(width: 10, height: 10)));

  Map<String, Object?> specJson(
    String title, {
    int uiVersion = 17,
    String wall = 'wall.png',
  }) {
    wallpaper();
    assetsBg();
    return {
      'specVersion': 1,
      'meta': {
        'title': title,
        'designer': 'D',
        'authorTag': 'T',
        'uiVersion': uiVersion,
      },
      'wallpaper': {'home': wall},
      'icons': {'pack': 'u1'},
      'lockscreen': {
        'assetsDir': 'assets',
        'elements': [
          {'type': 'swipeUpUnlock'},
          {'type': 'hourClock', 'color': '#FFFFFF'},
        ],
      },
    };
  }

  /// A spec file in specs/ whose paths are relative to tmp, or absolute.
  String specFile(String title, {int uiVersion = 17, bool absolute = false}) {
    final f = File(p.join(tmp.path, 'specs', '$title.json'))
      ..createSync(recursive: true);
    final spec = specJson(title, uiVersion: uiVersion);
    if (absolute) {
      (spec['wallpaper'] as Map)['home'] = p.join(tmp.path, 'wall.png');
      (spec['lockscreen'] as Map)['assetsDir'] = p.join(tmp.path, 'assets');
    }
    f.writeAsStringSync(jsonEncode(spec));
    return f.path;
  }

  var nextId = 0;
  Future<(Map<String, dynamic>, List<Map<String, dynamic>>)> call(
    String tool,
    Map<String, Object?> args, {
    McpServer? on,
    bool progress = false,
  }) async {
    final sent = <Map<String, dynamic>>[];
    final id = ++nextId;
    await (on ?? server).serve(
      Stream.value(
        jsonEncode({
          'jsonrpc': '2.0',
          'id': id,
          'method': 'tools/call',
          'params': {
            'name': tool,
            'arguments': args,
            if (progress) '_meta': {'progressToken': 'p'},
          },
        }),
      ),
      (m) => sent.add(jsonDecode(jsonEncode(m)) as Map<String, dynamic>),
    );
    final reply = sent.firstWhere((m) => m['id'] == id);
    return (reply['result'] as Map<String, dynamic>, sent);
  }

  Map<String, dynamic> body(Map<String, dynamic> result) =>
      jsonDecode((result['content'] as List).first['text'] as String)
          as Map<String, dynamic>;
  List images(Map<String, dynamic> result) =>
      (result['content'] as List).where((c) => c['type'] == 'image').toList();

  test('offers the tools', () async {
    final sent = <Map<String, dynamic>>[];
    await server.serve(
      Stream.value(
        jsonEncode({'jsonrpc': '2.0', 'id': 1, 'method': 'tools/list'}),
      ),
      (m) => sent.add(jsonDecode(jsonEncode(m)) as Map<String, dynamic>),
    );
    final names = (sent.single['result']['tools'] as List).map(
      (t) => t['name'],
    );
    expect(names, [
      'get_spec_schema',
      'validate_spec',
      'build_theme',
      'preview_lockscreen',
      'preview_icons',
      'build_batch',
      'preview_theme',
      'list_fonts',
      'list_wallpapers',
      'view_wallpaper',
      'list_presets',
      'get_preset',
      'get_rules',
      'list_users',
      'list_widgets',
      'get_widget',
      'list_widget_styles',
      'get_widget_style',
      'get_base_spec',
      'list_references',
      'get_reference',
      'check_uniqueness',
    ]);
  });

  test('get_spec_schema returns the JSON Schema', () async {
    final (r, _) = await call('get_spec_schema', {});
    expect(body(r)[r'$schema'], contains('json-schema.org'));
    expect((body(r)['properties'] as Map).keys, contains('lockscreen'));
  });

  group('validate_spec', () {
    test('accepts a good inline spec', () async {
      final (r, _) = await call('validate_spec', {
        'spec': specJson('Neon'),
        'base_dir': tmp.path,
        'contrast': false,
      });
      expect(r.containsKey('isError'), isFalse, reason: '$r');
      expect(body(r)['ok'], isTrue);
    });

    test('reports errors with their JSON path, as a tool error', () async {
      final spec = specJson('Neon', uiVersion: 15);
      (spec['lockscreen'] as Map)['elements'] = [
        {'type': 'hourClok'},
      ];
      final (r, _) = await call('validate_spec', {
        'spec': spec,
        'base_dir': tmp.path,
      });
      expect(r['isError'], isTrue);
      final issues = body(r)['issues'] as List;
      expect(
        issues.map((i) => i['path']),
        contains('/lockscreen/elements/0/type'),
      );
      expect(issues.first['hint'] ?? issues.last['hint'], isNotNull);
    });

    test('reads a spec file and resolves paths next to it', () async {
      final (r, _) = await call('validate_spec', {
        'path': specFile('Neon'),
        'contrast': false,
      });
      // The wallpaper sits in tmp, not in specs/, so the relative path misses.
      expect(body(r)['ok'], isFalse);
      final (r2, _) = await call('validate_spec', {
        'path': specFile('Neon'),
        'base_dir': tmp.path,
        'contrast': false,
      });
      expect(body(r2)['ok'], isTrue, reason: '${body(r2)}');
    });

    test('wants exactly one of spec and path', () async {
      for (final args in [
        <String, Object?>{},
        {'spec': specJson('A'), 'path': 'x.json'},
      ]) {
        final (r, _) = await call('validate_spec', args);
        expect(r['isError'], isTrue);
        expect(r['content'][0]['text'], contains('exactly one'));
      }
    });

    test('says when the file is missing', () async {
      final (r, _) = await call('validate_spec', {'path': 'nope.json'});
      expect(r['isError'], isTrue);
      expect(r['content'][0]['text'], contains('Cannot read'));
    });

    test('fonts_dirs supply font files', () async {
      final spec = specJson('Neon');
      ((spec['lockscreen'] as Map)['elements'] as List)[1]['font'] = 'Ground';
      final missing = body(
        (await call('validate_spec', {
          'spec': spec,
          'base_dir': tmp.path,
          'contrast': false,
        })).$1,
      );
      expect(
        (missing['issues'] as List).map((i) => i['code']),
        contains('font.file_missing'),
      );

      final dir = Directory(p.join(tmp.path, 'fonts'))..createSync();
      File(p.join(dir.path, 'Ground.ttf')).writeAsBytesSync([0, 1, 0, 0, 9]);
      final found = body(
        (await call('validate_spec', {
          'spec': spec,
          'base_dir': tmp.path,
          'contrast': false,
          'fonts_dirs': ['fonts'],
        })).$1,
      );
      expect(found['ok'], isTrue, reason: '$found');
    });
  });

  group('build_theme', () {
    test('builds an inline spec and returns both preview images', () async {
      final (r, _) = await call('build_theme', {
        'spec': specJson('Neon'),
        'out_dir': out,
        'base_dir': tmp.path,
      });
      expect(r.containsKey('isError'), isFalse, reason: '${r['content'][0]}');
      final b = body(r);
      expect(b['ok'], isTrue);
      expect(b['status'], 'built');
      expect(File(b['mtz'] as String).existsSync(), isTrue);
      expect(images(r), hasLength(2));
      expect(
        base64Decode(images(r).first['data'] as String).sublist(1, 4),
        'PNG'.codeUnits,
      );
    });

    test(
      'the inline spec is rendered relative to base_dir and cleaned up',
      () async {
        await call('build_theme', {
          'spec': specJson('Neon'),
          'out_dir': out,
          'base_dir': tmp.path,
        });
        final job = renderer.jobs.single;
        expect(job.baseDir, tmp.path);
        expect(File(job.spec).existsSync(), isFalse);
        expect(job.preview, isTrue);
      },
    );

    test('preview can be turned off', () async {
      final (r, _) = await call('build_theme', {
        'spec': specJson('Neon'),
        'out_dir': out,
        'base_dir': tmp.path,
        'preview': false,
      });
      expect(images(r), isEmpty);
      expect(renderer.jobs.single.preview, isFalse);
    });

    test('builds a spec file in place', () async {
      final path = specFile('Dusk');
      final (r, _) = await call('build_theme', {
        'path': path,
        'out_dir': out,
        'base_dir': tmp.path,
      });
      expect(body(r)['ok'], isTrue);
      expect(renderer.jobs.single.spec, path);
    });

    test(
      'an invalid spec is reported with its issues and never rendered',
      () async {
        final (r, _) = await call('build_theme', {
          'spec': specJson('Neon', uiVersion: 15),
          'out_dir': out,
          'base_dir': tmp.path,
        });
        expect(r['isError'], isTrue);
        expect(body(r)['status'], 'invalid');
        expect(
          (body(r)['issues'] as List).map((i) => i['code']),
          contains('meta.ui_version'),
        );
        expect(images(r), isEmpty);
        expect(renderer.jobs, isEmpty);
      },
    );

    test('a render process that cannot start is an error', () async {
      renderer.launchError = 'no flutter';
      final (r, _) = await call('build_theme', {
        'spec': specJson('Neon'),
        'out_dir': out,
        'base_dir': tmp.path,
      });
      expect(r['isError'], isTrue);
      expect(body(r)['error']['message'], 'no flutter');
    });

    test('needs a folder to build into', () async {
      final (r, _) = await call('build_theme', {'spec': specJson('Neon')});
      expect(r['isError'], isTrue);
      expect(r['content'][0]['text'], contains('out_dir'));
    });

    test('two calls at once render one after the other', () async {
      renderer.delay = const Duration(milliseconds: 80);
      await Future.wait([
        call('build_theme', {
          'spec': specJson('One'),
          'out_dir': out,
          'base_dir': tmp.path,
        }),
        call('build_theme', {
          'spec': specJson('Two'),
          'out_dir': out,
          'base_dir': tmp.path,
        }),
      ]);
      expect(renderer.jobs, hasLength(2));
      expect(renderer.mostAtOnce, 1);
    });
  });

  group('quick previews', () {
    test('preview_lockscreen returns the lockscreen picture only', () async {
      final (r, _) = await call('preview_lockscreen', {
        'spec': jsonEncode(specJson('Quick')),
      });
      expect(r['isError'], isNot(true));
      final content = r['content'] as List;
      expect(content.where((c) => c['type'] == 'image'), hasLength(1));
      final info = body(r);
      expect(info['ok'], isTrue);
      expect(info['mode'], 'lockscreen');
      expect(info.containsKey('mtz'), isFalse);
      expect(info.containsKey('lockscreenPreview'), isFalse);
      expect(renderer.jobs.single.mode, BuildMode.lockscreen);
    });

    test('preview_icons returns the home screen picture only', () async {
      final (r, _) = await call('preview_icons', {
        'spec': jsonEncode(specJson('Quick')),
      });
      expect(
        (r['content'] as List).where((c) => c['type'] == 'image'),
        hasLength(1),
      );
      expect(body(r)['mode'], 'icons');
      expect(renderer.jobs.single.mode, BuildMode.icons);
    });

    test('they leave nothing behind and need no week or folder', () async {
      final before = Directory.systemTemp
          .listSync()
          .where((e) => e.path.contains('theme_quick'))
          .length;
      await call('preview_lockscreen', {'spec': jsonEncode(specJson('Q'))});
      await call('preview_icons', {'spec': jsonEncode(specJson('Q'))});
      expect(
        Directory.systemTemp
            .listSync()
            .where((e) => e.path.contains('theme_quick'))
            .length,
        before,
      );
    });

    test('an invalid spec is reported and never rendered', () async {
      final spec = specJson('Bad', uiVersion: 15);
      final (r, _) = await call('preview_lockscreen', {
        'spec': jsonEncode(spec),
      });
      expect(r['isError'], isTrue);
      expect(renderer.jobs, isEmpty);
    });
  });

  group('build_batch', () {
    test(
      'builds a folder, reports progress and keeps the answer short',
      () async {
        specFile('a', absolute: true);
        specFile('b', absolute: true);
        specFile('bad', uiVersion: 15, absolute: true);
        final (r, sent) = await call('build_batch', {
          'paths': ['specs'],
          'out_dir': out,
        }, progress: true);

        final b = body(r);
        expect(r['isError'], isTrue);
        expect(b['ok'], isFalse);
        expect(b['summary']['built'], 2);
        expect(b['summary']['invalid'], 1);
        final results = b['results'] as List;
        expect(
          results
              .where((e) => e['status'] == 'built')
              .every(
                (e) =>
                    e.keys.toSet().containsAll(['name', 'mtz']) &&
                    e['issues'] == null,
              ),
          isTrue,
        );
        expect(
          results.firstWhere((e) => e['status'] == 'invalid')['issues'],
          isNotEmpty,
        );

        final progress = sent
            .where((m) => m['method'] == 'notifications/progress')
            .toList();
        expect(progress.map((m) => m['params']['progress']), [1, 2, 3]);
        expect(progress.every((m) => m['params']['total'] == 3), isTrue);
      },
    );

    test('a second call skips what is built', () async {
      specFile('a', absolute: true);
      await call('build_batch', {
        'paths': ['specs'],
        'out_dir': out,
      });
      final before = renderer.jobs.length;
      final (r, _) = await call('build_batch', {
        'paths': ['specs'],
        'out_dir': out,
      });
      expect(body(r)['summary']['skipped'], 1);
      expect(body(r)['ok'], isTrue);
      expect(renderer.jobs.length, before);
    });

    test('rejects empty or bad arguments', () async {
      for (final args in <Map<String, Object?>>[
        {'paths': [], 'out_dir': out},
        {'paths': 'specs', 'out_dir': out},
        {
          'paths': ['specs'],
          'out_dir': out,
          'chunk': 0,
        },
        {
          'paths': ['empty'],
          'out_dir': out,
        },
      ]) {
        Directory(p.join(tmp.path, 'empty')).createSync();
        final (r, _) = await call('build_batch', args);
        expect(r['isError'], isTrue, reason: '$args');
      }
    });
  });

  group('preview_theme', () {
    test('draws the home screen of a built theme', () async {
      await call('build_theme', {
        'spec': specJson('Neon'),
        'out_dir': out,
        'base_dir': tmp.path,
        'preview': false,
      });
      final (r, _) = await call('preview_theme', {
        'workspace': p.join(out, 'Neon'),
        'width': 270,
      });
      expect(images(r), hasLength(1));
      final png = img.decodePng(
        base64Decode(images(r).single['data'] as String),
      )!;
      expect(png.width, 270);
    });

    test('a folder that was not built is an error', () async {
      final (r, _) = await call('preview_theme', {
        'workspace': p.join(tmp.path, 'nowhere'),
      });
      expect(r['isError'], isTrue);
      expect(r['content'][0]['text'], contains('build the theme first'));
    });

    test('width is checked', () async {
      final (r, _) = await call('preview_theme', {
        'workspace': tmp.path,
        'width': 5,
      });
      expect(r['isError'], isTrue);
    });
  });
}
