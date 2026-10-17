import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:test/test.dart';
import 'package:theme_cli/src/mcp/mcp_server.dart';

Future<List<Map<String, dynamic>>> exchange(
  McpServer server,
  List<Object?> lines,
) async {
  final sent = <Map<String, dynamic>>[];
  await server.serve(
    Stream.fromIterable([
      for (final l in lines) l is String ? l : jsonEncode(l),
    ]),
    (m) => sent.add(jsonDecode(jsonEncode(m)) as Map<String, dynamic>),
  );
  return sent;
}

Map<String, Object?> request(
  int id,
  String method, [
  Map<String, Object?>? params,
]) => {
  'jsonrpc': '2.0',
  'id': id,
  'method': method,
  if (params != null) 'params': params,
};

void main() {
  late List<McpTool> tools;
  late McpServer server;

  setUp(() {
    tools = [
      McpTool(
        name: 'echo',
        description: 'Echoes text.',
        inputSchema: const {'type': 'object'},
        readOnly: true,
        handler: (args, progress) async => ToolResult('said ${args['text']}'),
      ),
      McpTool(
        name: 'picture',
        description: 'Returns an image.',
        inputSchema: const {'type': 'object'},
        handler: (args, progress) async => ToolResult(
          'here',
          images: [
            ToolImage(Uint8List.fromList([1, 2, 3])),
          ],
        ),
      ),
      McpTool(
        name: 'picky',
        description: 'Rejects its arguments.',
        inputSchema: const {'type': 'object'},
        handler: (args, progress) async =>
            throw const ToolException('text must be a string'),
      ),
      McpTool(
        name: 'boom',
        description: 'Crashes.',
        inputSchema: const {'type': 'object'},
        handler: (args, progress) async => throw StateError('kaput'),
      ),
      McpTool(
        name: 'steps',
        description: 'Reports progress.',
        inputSchema: const {'type': 'object'},
        handler: (args, progress) async {
          progress(1, 2, 'half');
          progress(2, 2, 'done');
          return const ToolResult('finished');
        },
      ),
    ];
    server = McpServer(
      name: 'test',
      version: '9',
      tools: tools,
      instructions: 'be nice',
    );
  });

  group('initialize', () {
    test(
      'answers with the client\'s protocol version when it is supported',
      () async {
        for (final v in supportedProtocolVersions) {
          final r = await exchange(server, [
            request(1, 'initialize', {'protocolVersion': v}),
          ]);
          expect(r.single['result']['protocolVersion'], v);
        }
      },
    );

    test('offers its newest version to an unknown client', () async {
      final r = await exchange(server, [
        request(1, 'initialize', {'protocolVersion': '1999-01-01'}),
      ]);
      expect(
        r.single['result']['protocolVersion'],
        supportedProtocolVersions.first,
      );
    });

    test('describes itself and its tools capability', () async {
      final r = (await exchange(server, [
        request(1, 'initialize', {}),
      ])).single['result'];
      expect(r['serverInfo'], {'name': 'test', 'version': '9'});
      expect(r['capabilities']['tools'], isNotNull);
      expect(r['instructions'], 'be nice');
    });

    test('the initialized notification gets no answer', () async {
      final r = await exchange(server, [
        {'jsonrpc': '2.0', 'method': 'notifications/initialized'},
      ]);
      expect(r, isEmpty);
    });
  });

  test('ping is answered with an empty result', () async {
    final r = await exchange(server, [request(7, 'ping')]);
    expect(r.single, {
      'jsonrpc': '2.0',
      'id': 7,
      'result': <String, dynamic>{},
    });
  });

  test(
    'tools/list names every tool with its schema and read-only hint',
    () async {
      final listed =
          (await exchange(server, [
                request(1, 'tools/list'),
              ])).single['result']['tools']
              as List;
      expect(listed.map((t) => t['name']), [
        'echo',
        'picture',
        'picky',
        'boom',
        'steps',
      ]);
      expect(listed.first['annotations'], {'readOnlyHint': true});
      expect(listed.first['inputSchema'], {'type': 'object'});
    },
  );

  group('tools/call', () {
    Future<Map<String, dynamic>> call(
      String name, [
      Object? arguments = const <String, Object?>{},
    ]) async => (await exchange(server, [
      request(1, 'tools/call', {'name': name, 'arguments': arguments}),
    ])).single;

    test('returns the tool\'s text', () async {
      final r = await call('echo', {'text': 'hi'});
      expect(r['result']['content'], [
        {'type': 'text', 'text': 'said hi'},
      ]);
      expect(r['result'].containsKey('isError'), isFalse);
    });

    test('images come back base64 encoded', () async {
      final content = (await call('picture'))['result']['content'] as List;
      expect(content[1], {
        'type': 'image',
        'data': base64Encode([1, 2, 3]),
        'mimeType': 'image/png',
      });
    });

    test('arguments may be left out', () async {
      final r = (await exchange(server, [
        request(1, 'tools/call', {'name': 'echo'}),
      ])).single;
      expect(r['result']['content'][0]['text'], 'said null');
    });

    test('bad arguments are a tool error the model can read', () async {
      final r = await call('picky');
      expect(r['result']['isError'], isTrue);
      expect(r['result']['content'][0]['text'], 'text must be a string');
      expect(r.containsKey('error'), isFalse);
    });

    test('a crashing tool is a tool error, not a protocol error', () async {
      final logged = <String>[];
      final s = McpServer(
        name: 't',
        version: '1',
        tools: tools,
        log: logged.add,
      );
      final r = (await exchange(s, [
        request(1, 'tools/call', {'name': 'boom'}),
      ])).single;
      expect(r['result']['isError'], isTrue);
      expect(r['result']['content'][0]['text'], contains('kaput'));
      expect(logged.single, contains('boom'));
    });

    test('an unknown tool is an invalid-params error', () async {
      final r = await call('nope');
      expect(r['error']['code'], -32602);
      expect(r['error']['message'], contains('nope'));
    });

    test('arguments that are not an object are rejected', () async {
      expect((await call('echo', 'text'))['error']['code'], -32602);
    });

    test(
      'progress goes out as notifications when the client asked for it',
      () async {
        final r = await exchange(server, [
          request(3, 'tools/call', {
            'name': 'steps',
            '_meta': {'progressToken': 'tok'},
          }),
        ]);
        expect(
          r.take(2).map((m) => m['method']),
          everyElement('notifications/progress'),
        );
        expect(r[0]['params'], {
          'progressToken': 'tok',
          'progress': 1,
          'total': 2,
          'message': 'half',
        });
        expect(r.last['id'], 3);
      },
    );

    test('no progress is sent without a token', () async {
      final r = await exchange(server, [
        request(3, 'tools/call', {'name': 'steps'}),
      ]);
      expect(r, hasLength(1));
    });
  });

  group('errors', () {
    test('an unknown method', () async {
      final r = await exchange(server, [request(4, 'resources/list')]);
      expect(r.single['error']['code'], -32601);
      expect(r.single['id'], 4);
    });

    test('text that is not JSON', () async {
      final r = await exchange(server, ['{oops']);
      expect(r.single['error']['code'], -32700);
      expect(r.single['id'], isNull);
    });

    test('JSON that is not a request', () async {
      final r = await exchange(server, [
        [1, 2],
        {'id': 1, 'method': 'ping'},
      ]);
      expect(r.map((m) => m['error']['code']), [-32600, -32600]);
    });

    test('blank lines are ignored and later lines still work', () async {
      final r = await exchange(server, [
        '',
        '  ',
        jsonEncode(request(1, 'ping')),
      ]);
      expect(r.single['id'], 1);
    });
  });

  test(
    'slow calls do not hold up later ones, and serve waits for them',
    () async {
      final gate = Completer<void>();
      final slow = McpServer(
        name: 't',
        version: '1',
        tools: [
          McpTool(
            name: 'slow',
            description: '',
            inputSchema: const {'type': 'object'},
            handler: (args, progress) async {
              await gate.future;
              return const ToolResult('late');
            },
          ),
        ],
      );
      final sent = <int>[];
      final done = slow.serve(
        Stream.fromIterable([
          jsonEncode(request(1, 'tools/call', {'name': 'slow'})),
          jsonEncode(request(2, 'ping')),
        ]),
        (m) {
          sent.add(m['id'] as int);
          if (m['id'] == 2) gate.complete();
        },
      );
      await done;
      expect(sent, [2, 1]);
    },
  );
}
