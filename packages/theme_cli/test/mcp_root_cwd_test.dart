import 'dart:convert';
import 'dart:io';

import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:theme_cli/theme_cli.dart';

import 'support/fake_renderer.dart';

void main() {
  late Directory tmp;
  setUp(() => tmp = Directory.systemTemp.createTempSync('mcp_root_cwd'));
  tearDown(() => tmp.deleteSync(recursive: true));

  test('with a root, a relative out_dir is built inside the root', () async {
    final root = Directory(p.join(tmp.path, 'root'))..createSync();
    final elsewhere = Directory(p.join(tmp.path, 'repo'))..createSync();
    final png = img.encodePng(img.Image(width: 20, height: 40));
    File(p.join(root.path, 'wall.png')).writeAsBytesSync(png);
    File(p.join(root.path, 'assets', 'bg.png'))
      ..createSync(recursive: true)
      ..writeAsBytesSync(png);
    final spec = {
      'specVersion': 1,
      'meta': {'title': 'T', 'designer': 'D', 'authorTag': 'S'},
      'wallpaper': {'home': 'wall.png'},
      'icons': {'pack': 'u1'},
      'lockscreen': {
        'assetsDir': 'assets',
        'elements': [
          {'type': 'swipeUpUnlock'},
        ],
      },
    };
    final renderer = FakeRenderer();
    final request = jsonEncode({
      'jsonrpc': '2.0',
      'id': 1,
      'method': 'tools/call',
      'params': {
        'name': 'build_theme',
        'arguments': {'spec': jsonEncode(spec), 'out_dir': 'mine'},
      },
    });

    await runCli(
      ['mcp', '--root', root.path],
      out: StringBuffer(),
      err: StringBuffer(),
      cwd: elsewhere,
      sidecar: renderer,
      input: Stream.value(utf8.encode('$request\n')),
    );

    expect(renderer.jobs.single.outDir, p.join(root.path, 'mine'));
  });
}
