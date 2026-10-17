import 'dart:convert';
import 'dart:io';

import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:theme_cli/src/mcp/theme_tools.dart';

import 'support/fake_renderer.dart';

/// Gemini's function calling takes a small part of JSON Schema, and hosts
/// built on it (Antigravity, Gemini CLI, Gemini Code Assist) pass tool
/// schemas on as they are, so a tool outside that part fails to load.
const _allowed = {
  'type',
  'description',
  'enum',
  'properties',
  'required',
  'items',
  'minimum',
  'maximum',
  'minItems',
  'maxItems',
};

void main() {
  late Directory tmp;
  late FakeRenderer renderer;

  setUp(() {
    tmp = Directory.systemTemp.createTempSync('mcp_schema_test');
    renderer = FakeRenderer();
  });
  tearDown(() => tmp.deleteSync(recursive: true));

  Future<Map<String, dynamic>> request(
    String method, [
    Map<String, Object?>? params,
  ]) async {
    final sent = <Map<String, dynamic>>[];
    final server = themeMcpServer(
      ThemeToolContext(cwd: tmp, project: null, sidecar: renderer),
    );
    await server.serve(
      Stream.value(
        jsonEncode({
          'jsonrpc': '2.0',
          'id': 1,
          'method': method,
          if (params != null) 'params': params,
        }),
      ),
      (m) => sent.add(jsonDecode(jsonEncode(m)) as Map<String, dynamic>),
    );
    return sent.single['result'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> call(String tool, Map<String, Object?> args) =>
      request('tools/call', {'name': tool, 'arguments': args});

  Iterable<String> problems(String where, Object? node) sync* {
    if (node is! Map) {
      yield '$where: not an object';
      return;
    }
    for (final key in node.keys) {
      if (!_allowed.contains(key)) {
        yield '$where: "$key" is outside the Gemini subset';
      }
    }
    final type = node['type'];
    if (type is! String) {
      yield '$where: type must be one plain string, got $type';
    }
    if (type == 'object') {
      final props = node['properties'];
      if (props is! Map || props.isEmpty) {
        yield '$where: an object needs properties';
      }
      if (props is Map) {
        for (final e in props.entries) {
          yield* problems('$where.${e.key}', e.value);
        }
        final required = node['required'];
        if (required is List) {
          for (final r in required) {
            if (!props.containsKey(r)) {
              yield '$where: required "$r" is not a property';
            }
          }
        }
      }
    }
    if (type == 'array') yield* problems('$where[]', node['items']);
    if (node['enum'] is List &&
        (node['enum'] as List).any((v) => v is! String)) {
      yield '$where: enum values must be strings';
    }
  }

  test('every tool schema stays within what Gemini accepts', () async {
    final tools = (await request('tools/list'))['tools'] as List;
    expect(tools, isNotEmpty);
    final found = [
      for (final t in tools) ...problems(t['name'] as String, t['inputSchema']),
    ];
    expect(found, isEmpty);
  });

  test('tool names are plain identifiers', () async {
    final tools = (await request('tools/list'))['tools'] as List;
    for (final t in tools) {
      expect(t['name'], matches(RegExp(r'^[A-Za-z_][A-Za-z0-9_]{0,62}$')));
      expect(t['description'], isNotEmpty);
    }
  });

  group('get_spec_schema', () {
    test('returns all of it without a section', () async {
      final r =
          jsonDecode(
                (await call('get_spec_schema', {}))['content'][0]['text']
                    as String,
              )
              as Map;
      expect(
        (r['properties'] as Map).keys,
        containsAll(['meta', 'icons', 'lockscreen']),
      );
    });

    test('returns one section with the definitions it uses', () async {
      final r =
          jsonDecode(
                (await call('get_spec_schema', {
                      'section': 'icons',
                    }))['content'][0]['text']
                    as String,
              )
              as Map;
      expect(r['section'], 'icons');
      expect((r['schema'] as Map)['properties'], contains('shape'));
      expect((r[r'$defs'] as Map).keys, containsAll(['color', 'alignment']));
      expect((r[r'$defs'] as Map).containsKey('element'), isFalse);
    });

    test(
      'the lockscreen and element sections carry the element definition',
      () async {
        for (final section in ['lockscreen', 'element']) {
          final r =
              jsonDecode(
                    (await call('get_spec_schema', {
                          'section': section,
                        }))['content'][0]['text']
                        as String,
                  )
                  as Map;
          expect((r[r'$defs'] as Map)['element'], isNotNull, reason: section);
        }
        final element =
            jsonDecode(
                  (await call('get_spec_schema', {
                        'section': 'element',
                      }))['content'][0]['text']
                      as String,
                )
                as Map;
        expect(
          ((element['schema'] as Map)['properties'] as Map).keys,
          contains('unlockSkin'),
        );
      },
    );

    test('an unknown section lists the valid ones', () async {
      final r = await call('get_spec_schema', {'section': 'nope'});
      expect(r['isError'], isTrue);
      expect(r['content'][0]['text'], contains('lockscreen'));
    });
  });

  group('spec as text', () {
    Map<String, Object?> spec() {
      File(p.join(tmp.path, 'wall.png')).writeAsBytesSync(
        img.encodePng(
          img.Image(width: 30, height: 60)..clear(img.ColorRgb8(20, 20, 60)),
        ),
      );
      File(p.join(tmp.path, 'assets', 'bg.png'))
        ..createSync(recursive: true)
        ..writeAsBytesSync(img.encodePng(img.Image(width: 10, height: 10)));
      return {
        'specVersion': 1,
        'meta': {'title': 'Neon'},
        'wallpaper': {'home': p.join(tmp.path, 'wall.png')},
        'icons': {'pack': 'u1'},
        'lockscreen': {
          'assetsDir': p.join(tmp.path, 'assets'),
          'elements': [
            {'type': 'swipeUpUnlock'},
          ],
        },
      };
    }

    test('validate_spec and build_theme take JSON text', () async {
      final text = jsonEncode(spec());
      final v =
          jsonDecode(
                (await call('validate_spec', {
                      'spec': text,
                      'contrast': false,
                    }))['content'][0]['text']
                    as String,
              )
              as Map;
      expect(v['ok'], isTrue, reason: '${v['issues']}');

      final b = await call('build_theme', {
        'spec': text,
        'out_dir': p.join(tmp.path, 'out'),
        'preview': false,
      });
      expect(b.containsKey('isError'), isFalse, reason: '${b['content']}');
      expect(renderer.jobs, hasLength(1));
    });

    test('an object still works for hosts that pass decoded JSON', () async {
      final v =
          jsonDecode(
                (await call('validate_spec', {
                      'spec': spec(),
                      'contrast': false,
                    }))['content'][0]['text']
                    as String,
              )
              as Map;
      expect(v['ok'], isTrue);
    });

    test(
      'text that is not JSON, or not an object, is an error the model can read',
      () async {
        for (final (text, hint) in [
          ('{oops', 'not valid JSON'),
          ('[1, 2]', 'JSON object'),
          ('"x"', 'JSON object'),
        ]) {
          final r = await call('validate_spec', {'spec': text});
          expect(r['isError'], isTrue, reason: text);
          expect(r['content'][0]['text'], contains(hint), reason: text);
        }
      },
    );
  });
}
