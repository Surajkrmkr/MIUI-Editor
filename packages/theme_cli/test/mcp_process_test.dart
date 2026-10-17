import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

/// Talks to `theme mcp` the way an agent's host does: JSON lines over stdio.
class McpClient {
  McpClient._(this._process) {
    _lines = _process.stdout
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .map((l) => jsonDecode(l) as Map<String, dynamic>)
        .asBroadcastStream();
  }

  final Process _process;
  late final Stream<Map<String, dynamic>> _lines;
  var _id = 0;
  final stderrText = StringBuffer();

  static Future<McpClient> start(
    List<String> extra, {
    Map<String, String>? env,
  }) async {
    final process = await Process.start(
      Platform.resolvedExecutable,
      ['bin/theme.dart', 'mcp', ...extra],
      workingDirectory: Directory.current.path,
      environment: env,
    );
    final client = McpClient._(process);
    process.stderr.transform(utf8.decoder).listen(client.stderrText.write);
    return client;
  }

  Future<Map<String, dynamic>> request(
    String method, [
    Map<String, Object?>? params,
  ]) {
    final id = ++_id;
    final reply = _lines.firstWhere((m) => m['id'] == id);
    _process.stdin.writeln(
      jsonEncode({
        'jsonrpc': '2.0',
        'id': id,
        'method': method,
        if (params != null) 'params': params,
      }),
    );
    return reply.timeout(const Duration(minutes: 3));
  }

  void notify(String method) =>
      _process.stdin.writeln(jsonEncode({'jsonrpc': '2.0', 'method': method}));

  Future<Map<String, dynamic>> callTool(
    String name,
    Map<String, Object?> args,
  ) async =>
      (await request('tools/call', {'name': name, 'arguments': args}))['result']
          as Map<String, dynamic>;

  Future<int> close() async {
    await _process.stdin.close();
    return _process.exitCode.timeout(const Duration(seconds: 20));
  }
}

void main() {
  late Directory tmp;

  setUp(() => tmp = Directory.systemTemp.createTempSync('mcp_process_test'));
  tearDown(() => tmp.deleteSync(recursive: true));

  Map<String, Object?> spec(String title) {
    for (final rel in ['wall.png', 'assets/bg.png']) {
      File(p.join(tmp.path, rel))
        ..createSync(recursive: true)
        ..writeAsBytesSync(
          img.encodePng(
            img.Image(width: 30, height: 60)..clear(img.ColorRgb8(20, 20, 60)),
          ),
        );
    }
    return {
      'specVersion': 1,
      'meta': {'title': title, 'designer': 'D', 'authorTag': 'T'},
      'wallpaper': {'home': p.join(tmp.path, 'wall.png')},
      'icons': {'pack': 'u1'},
      'lockscreen': {
        'assetsDir': p.join(tmp.path, 'assets'),
        'elements': [
          {'type': 'swipeUpUnlock'},
          {'type': 'hourClock', 'color': '#FFFFFF'},
        ],
      },
    };
  }

  test('speaks the protocol over stdio and exits when stdin closes', () async {
    final client = await McpClient.start([]);
    final init = await client.request('initialize', {
      'protocolVersion': '2025-06-18',
      'capabilities': <String, Object?>{},
      'clientInfo': {'name': 'test', 'version': '0'},
    });
    expect(init['result']['serverInfo']['name'], 'theme-cli');
    client.notify('notifications/initialized');

    final tools =
        (await client.request('tools/list'))['result']['tools'] as List;
    expect(
      tools.map((t) => t['name']),
      containsAll(['validate_spec', 'build_theme', 'build_batch']),
    );

    final r = await client.callTool('validate_spec', {
      'spec': spec('Neon'),
      'contrast': false,
    });
    final report = jsonDecode(r['content'][0]['text'] as String) as Map;
    expect(report['ok'], isTrue, reason: '${report['issues']}');

    expect(await client.close(), 0, reason: client.stderrText.toString());
  });

  test('stdout carries nothing but protocol messages', () async {
    final client = await McpClient.start([]);
    await client.request('ping');
    // A stray print would make McpClient's jsonDecode throw on the stream.
    await client.callTool('get_spec_schema', {});
    expect(await client.close(), 0);
  });

  // Runs the real Flutter render process; skipped when Flutter isn't there.
  test(
    'an agent can build a theme and get the images back',
    () async {
      final client = await McpClient.start([
        '--project',
        Directory.current.parent.parent.path,
      ]);
      await client.request('initialize', {'protocolVersion': '2025-06-18'});

      final r = await client.callTool('build_theme', {
        'spec': spec('Agent'),
        'out_dir': p.join(tmp.path, 'out'),
      });
      final built = jsonDecode(r['content'][0]['text'] as String) as Map;
      expect(
        built['ok'],
        isTrue,
        reason: '${built['error']} ${client.stderrText}',
      );
      expect(
        File(built['mtz'] as String).lengthSync(),
        greaterThan(100 * 1024),
      );

      final shots = (r['content'] as List)
          .where((c) => c['type'] == 'image')
          .toList();
      expect(shots, hasLength(2));
      final lock = img.decodePng(base64Decode(shots.first['data'] as String))!;
      expect((lock.width, lock.height), (554, 1200));

      expect(await client.close(), 0);
    },
    timeout: const Timeout(Duration(minutes: 10)),
    skip: Process.runSync('flutter', ['--version']).exitCode != 0
        ? 'flutter not installed'
        : null,
  );
}
