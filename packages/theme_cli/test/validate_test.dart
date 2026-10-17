import 'dart:convert';
import 'dart:io';

import 'package:image/image.dart' as img;
import 'package:test/test.dart';
import 'package:theme_cli/theme_cli.dart';

void main() {
  late Directory tmp;

  setUp(() => tmp = Directory.systemTemp.createTempSync('theme_cli_test'));
  tearDown(() => tmp.deleteSync(recursive: true));

  void png(String rel, int level) {
    final image = img.Image(width: 60, height: 130)
      ..clear(img.ColorRgb8(level, level, level));
    File('${tmp.path}/$rel')
      ..createSync(recursive: true)
      ..writeAsBytesSync(img.encodePng(image));
  }

  Map<String, dynamic> spec({int wallpaperLevel = 30, int uiVersion = 17}) {
    png('wall.png', wallpaperLevel);
    png('ls/bg.png', 0);
    return {
      'specVersion': 1,
      'meta': {
        'title': 'Neon',
        'designer': 'Suraj',
        'authorTag': 'Sj',
        'uiVersion': uiVersion,
      },
      'wallpaper': {'home': 'wall.png'},
      'icons': {
        'pack': 'u7',
        'background': {
          'colors': ['#2575FC'],
        },
      },
      'lockscreen': {
        'assetsDir': 'ls',
        'elements': [
          {'type': 'swipeUpUnlock'},
          {'type': 'hourClock', 'color': '#FFFFFF'},
        ],
      },
    };
  }

  String write(Map<String, dynamic> s, [String name = 'theme.json']) {
    File('${tmp.path}/$name').writeAsStringSync(jsonEncode(s));
    return name;
  }

  Future<({int code, String out, String err})> run(List<String> args) async {
    final out = StringBuffer(), err = StringBuffer();
    final code = await runCli(args, out: out, err: err, cwd: tmp);
    return (code: code, out: out.toString(), err: err.toString());
  }

  test('a valid spec exits 0', () async {
    final r = await run(['validate', write(spec())]);
    expect(r.code, ExitCodes.ok);
    expect(r.out, contains('valid (0 error(s), 0 warning(s))'));
    expect(r.err, isEmpty);
  });

  test('an invalid spec exits 1 and lists the problems', () async {
    final r = await run(['validate', write(spec(uiVersion: 15))]);
    expect(r.code, ExitCodes.invalid);
    expect(r.out, contains('/meta/uiVersion'));
    expect(r.out, contains('[meta.ui_version]'));
    expect(r.out, contains('Only HyperOS 3'));
    expect(r.out, contains('invalid (1 error(s)'));
  });

  test('--json prints one machine-readable document', () async {
    final r = await run(['validate', write(spec(uiVersion: 15)), '--json']);
    expect(r.code, ExitCodes.invalid);
    final doc = jsonDecode(r.out) as Map<String, dynamic>;
    expect(doc['command'], 'validate');
    expect(doc['ok'], isFalse);
    expect(doc['errors'], 1);
    expect(doc['spec'], endsWith('theme.json'));
    final issue = (doc['issues'] as List).single as Map<String, dynamic>;
    expect(issue['code'], 'meta.ui_version');
    expect(issue['path'], '/meta/uiVersion');
    expect(issue['severity'], 'error');
  });

  test('warnings exit 0 unless --strict', () async {
    final name = write(spec(wallpaperLevel: 240));
    var r = await run(['validate', name, '--json']);
    expect(r.code, ExitCodes.ok);
    expect(jsonDecode(r.out)['warnings'], 1);

    r = await run(['validate', name, '--strict']);
    expect(r.code, ExitCodes.invalid);
    expect(r.out, contains('contrast.text'));
  });

  test('--no-contrast skips the wallpaper check', () async {
    final name = write(spec(wallpaperLevel: 240));
    final r = await run(['validate', name, '--no-contrast', '--strict']);
    expect(r.code, ExitCodes.ok);
  });

  test('broken JSON is a spec error, not a crash', () async {
    File('${tmp.path}/bad.json').writeAsStringSync('{"specVersion": ');
    final r = await run(['validate', 'bad.json', '--json']);
    expect(r.code, ExitCodes.invalid);
    expect(jsonDecode(r.out)['issues'][0]['code'], 'spec.json');
  });

  test('an unreadable file exits 3, with JSON on stdout when asked', () async {
    var r = await run(['validate', 'missing.json']);
    expect(r.code, ExitCodes.io);
    expect(r.err, contains('Cannot read'));
    expect(r.out, isEmpty);

    r = await run(['validate', 'missing.json', '--json']);
    expect(r.code, ExitCodes.io);
    final doc = jsonDecode(r.out) as Map<String, dynamic>;
    expect(doc['ok'], isFalse);
    expect(doc['error']['code'], 'io.read');
  });

  test('usage mistakes exit 2', () async {
    for (final args in [
      <String>[],
      ['validate'],
      ['validate', 'a.json', 'b.json'],
      ['nope'],
      ['validate', '--bogus', 'a.json'],
    ]) {
      final r = await run(args);
      // `theme` with no arguments prints help, which is not an error.
      expect(
        r.code,
        args.isEmpty ? ExitCodes.ok : ExitCodes.usage,
        reason: args.join(' '),
      );
    }
  });

  test('--assets-root enables icon pack checks', () async {
    final name = write(spec());
    Directory('${tmp.path}/repo/assets/icons/u7').createSync(recursive: true);
    final r = await run(['validate', name, '--assets-root', 'repo', '--json']);
    expect(r.code, ExitCodes.invalid);
    expect(jsonDecode(r.out)['issues'][0]['code'], 'icons.pack_incomplete');
  });

  test('the real executable reports exit codes to the shell', () async {
    final name = write(spec(uiVersion: 15));
    final result = await Process.run(Platform.resolvedExecutable, [
      'run',
      'bin/theme.dart',
      'validate',
      '${tmp.path}/$name',
      '--json',
    ], workingDirectory: Directory.current.path);
    expect(result.exitCode, ExitCodes.invalid, reason: '${result.stderr}');
    expect(jsonDecode(result.stdout as String)['ok'], isFalse);
  });
}
