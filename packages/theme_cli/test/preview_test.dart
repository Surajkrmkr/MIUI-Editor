import 'dart:convert';
import 'dart:io';

import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:theme_cli/theme_cli.dart';
import 'package:theme_core/theme_core.dart';

class _Sidecar implements Sidecar {
  _Sidecar(this.workspace, {this.lockscreenPreview, this.previewError});

  final String workspace;
  final String? lockscreenPreview, previewError;
  List<BuildJob> received = [];

  @override
  Future<SidecarOutcome> run(
    List<BuildJob> jobs, {
    void Function(BuildJobResult result)? onResult,
  }) async {
    received = jobs;
    return SidecarOutcome(
      results: [
        for (final j in jobs)
          BuildJobResult(
            id: j.id,
            ok: true,
            mtz: '/x.mtz',
            workspace: workspace,
            lockscreenPreview: lockscreenPreview,
            errorCode: previewError == null ? null : 'preview.failed',
            message: previewError,
          ),
      ],
    );
  }
}

void main() {
  late Directory tmp;

  setUp(() => tmp = Directory.systemTemp.createTempSync('theme_preview_test'));
  tearDown(() => tmp.deleteSync(recursive: true));

  void png(String rel, int w, int h, int level) {
    File(p.join(tmp.path, rel))
      ..createSync(recursive: true)
      ..writeAsBytesSync(
        img.encodePng(
          img.Image(width: w, height: h)
            ..clear(img.ColorRgb8(level, level, level)),
        ),
      );
  }

  /// A folder shaped like `theme build` output.
  String builtWorkspace(String name) {
    png('built/$name/wallpaper/default_wallpaper.jpg', 40, 90, 30);
    png(
      'built/$name/icons/res/drawable-xxhdpi/com.android.settings.png',
      180,
      180,
      200,
    );
    return p.join(tmp.path, 'built', name);
  }

  Future<({int code, String out, String err})> run(
    List<String> args, {
    Sidecar? sidecar,
  }) async {
    final out = StringBuffer(), err = StringBuffer();
    final code = await runCli(
      args,
      out: out,
      err: err,
      cwd: tmp,
      sidecar: sidecar,
    );
    return (code: code, out: out.toString(), err: err.toString());
  }

  test('writes <name>.preview.png next to the workspace by default', () async {
    final ws = builtWorkspace('Neon');
    final r = await run(['preview', ws]);

    final file = File(p.join(tmp.path, 'built', 'Neon.preview.png'));
    expect(r.code, ExitCodes.ok, reason: r.err);
    expect(file.existsSync(), isTrue);
    expect(img.decodePng(file.readAsBytesSync())!.width, 540);
    expect(r.out.trim(), file.path);
  });

  test('--out and --width are honoured and --json lists the files', () async {
    final r = await run([
      'preview',
      builtWorkspace('Neon'),
      builtWorkspace('Dusk'),
      '--out',
      'shots',
      '--width',
      '270',
      '--json',
    ]);

    expect(r.code, ExitCodes.ok, reason: r.err);
    final doc = jsonDecode(r.out) as Map<String, dynamic>;
    final files = [
      for (final e in doc['results'] as List) e['preview'] as String,
    ];
    expect(files.map(p.basename), ['Neon.preview.png', 'Dusk.preview.png']);
    for (final f in files) {
      expect(p.dirname(f), p.join(tmp.path, 'shots'));
      expect(img.decodePng(File(f).readAsBytesSync())!.width, 270);
    }
  });

  test(
    'a folder that was not built exits 3 and the others still render',
    () async {
      final r = await run([
        'preview',
        'nowhere',
        builtWorkspace('Neon'),
        '--json',
      ]);
      expect(r.code, ExitCodes.io);
      final results = (jsonDecode(r.out) as Map)['results'] as List;
      expect(results[0]['ok'], isFalse);
      expect(results[0]['error']['code'], 'preview.failed');
      expect(results[1]['ok'], isTrue);
    },
  );

  test('usage mistakes exit 2', () async {
    expect((await run(['preview'])).code, ExitCodes.usage);
    expect(
      (await run(['preview', 'x', '--width', 'wide'])).code,
      ExitCodes.usage,
    );
  });

  /// Writes a valid spec and returns its file name.
  String writeSpec() {
    png('wall.png', 40, 90, 30);
    png('assets/bg.png', 10, 10, 0);
    File(p.join(tmp.path, 'Neon.json')).writeAsStringSync(
      jsonEncode({
        'specVersion': 1,
        'meta': {
          'title': 'Neon',
          'designer': 'D',
          'authorTag': 'T',
          'uiVersion': 17,
        },
        'wallpaper': {'home': 'wall.png'},
        'icons': {'pack': 'u1'},
        'lockscreen': {
          'assetsDir': 'assets',
          'elements': [
            {'type': 'swipeUpUnlock'},
          ],
        },
      }),
    );
    return 'Neon.json';
  }

  test(
    'build --preview draws the home image and reports the lockscreen one',
    () async {
      final sidecar = _Sidecar(
        builtWorkspace('Neon'),
        lockscreenPreview: '/out/Neon.lockscreen.png',
      );
      final r = await run([
        'build',
        writeSpec(),
        '--out',
        'out',
        '--preview',
        '--json',
      ], sidecar: sidecar);

      expect(r.code, ExitCodes.ok, reason: '${r.out}\n${r.err}');
      expect(sidecar.received.single.preview, isTrue);
      final entry = ((jsonDecode(r.out) as Map)['results'] as List).single;
      expect(entry['preview'], p.join(tmp.path, 'out', 'Neon.preview.png'));
      expect(File(entry['preview'] as String).existsSync(), isTrue);
      expect(entry['lockscreenPreview'], '/out/Neon.lockscreen.png');
    },
  );

  test('without --preview the sidecar is not asked to draw', () async {
    final sidecar = _Sidecar(builtWorkspace('Neon'));
    final r = await run([
      'build',
      writeSpec(),
      '--out',
      'out',
    ], sidecar: sidecar);

    expect(r.code, ExitCodes.ok, reason: r.err);
    expect(sidecar.received.single.preview, isFalse);
    expect(r.out, isNot(contains('preview')));
  });

  test('a failed lockscreen preview exits 4 but still lists the mtz', () async {
    final sidecar = _Sidecar(
      builtWorkspace('Neon'),
      previewError: 'engine said no',
    );
    final r = await run([
      'build',
      writeSpec(),
      '--out',
      'out',
      '--preview',
      '--json',
    ], sidecar: sidecar);

    expect(r.code, ExitCodes.buildFailed);
    final entry = ((jsonDecode(r.out) as Map)['results'] as List).single;
    expect(entry['ok'], isFalse);
    expect(entry['mtz'], '/x.mtz');
    expect(entry['error'], {
      'code': 'preview.failed',
      'message': 'engine said no',
    });
  });
}
