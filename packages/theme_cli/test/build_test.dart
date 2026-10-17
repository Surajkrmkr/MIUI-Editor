import 'dart:convert';
import 'dart:io';

import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:theme_cli/theme_cli.dart';
import 'package:theme_core/theme_core.dart';

class FakeSidecar implements Sidecar {
  FakeSidecar(this.respond);

  final SidecarOutcome Function(List<BuildJob> jobs) respond;
  List<BuildJob>? received;

  @override
  Future<SidecarOutcome> run(
    List<BuildJob> jobs, {
    void Function(BuildJobResult result)? onResult,
  }) async {
    received = jobs;
    final outcome = respond(jobs);
    outcome.results.forEach(onResult ?? (_) {});
    return outcome;
  }
}

SidecarOutcome Function(List<BuildJob>) buildsAll({double seconds = 1.5}) =>
    (jobs) => SidecarOutcome(
      results: [
        for (final j in jobs)
          BuildJobResult(
            id: j.id,
            ok: true,
            mtz: p.join(j.outDir, '${p.basenameWithoutExtension(j.spec)}.mtz'),
            workspace: p.join(j.outDir, p.basenameWithoutExtension(j.spec)),
            seconds: seconds,
          ),
      ],
    );

void main() {
  late Directory tmp;

  setUp(() => tmp = Directory.systemTemp.createTempSync('theme_build_test'));
  tearDown(() => tmp.deleteSync(recursive: true));

  void png(String rel, int level) {
    final image = img.Image(width: 40, height: 90)
      ..clear(img.ColorRgb8(level, level, level));
    File(p.join(tmp.path, rel))
      ..createSync(recursive: true)
      ..writeAsBytesSync(img.encodePng(image));
  }

  /// Writes a valid spec named [name].json and returns the file name.
  String writeSpec(
    String name, {
    int uiVersion = 17,
    List<Map<String, Object>> elements = const [
      {'type': 'swipeUpUnlock'},
    ],
  }) {
    png('wall.png', 30);
    png('assets/bg.png', 0);
    File(p.join(tmp.path, '$name.json')).writeAsStringSync(
      jsonEncode({
        'specVersion': 1,
        'meta': {
          'title': name,
          'designer': 'D',
          'authorTag': 'T',
          'uiVersion': uiVersion,
        },
        'wallpaper': {'home': 'wall.png'},
        'icons': {'pack': 'u1'},
        'lockscreen': {'assetsDir': 'assets', 'elements': elements},
      }),
    );
    return '$name.json';
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

  test('valid specs go to the sidecar as absolute jobs and exit 0', () async {
    final sidecar = FakeSidecar(buildsAll());
    final r = await run([
      'build',
      writeSpec('Neon'),
      writeSpec('Dusk'),
      '--out',
      'out',
    ], sidecar: sidecar);

    expect(r.code, ExitCodes.ok, reason: r.err);
    expect(sidecar.received!.map((j) => j.spec), [
      p.join(tmp.path, 'Neon.json'),
      p.join(tmp.path, 'Dusk.json'),
    ]);
    expect(
      sidecar.received!.every((j) => j.outDir == p.join(tmp.path, 'out')),
      isTrue,
    );
    expect(r.out, contains('Neon.json: built'));
    expect(r.out, contains('Dusk.json: built'));
  });

  test('invalid specs are reported and never sent to the sidecar', () async {
    final sidecar = FakeSidecar(buildsAll());
    final r = await run([
      'build',
      writeSpec('Good'),
      writeSpec('Bad', uiVersion: 15),
      '--out',
      'out',
    ], sidecar: sidecar);

    expect(r.code, ExitCodes.invalid);
    expect(sidecar.received!.map((j) => p.basename(j.spec)), ['Good.json']);
    expect(r.out, contains('Bad.json: error'));
    expect(r.out, contains('[meta.ui_version]'));
    expect(r.out, contains('Bad.json: invalid'));
    expect(r.out, contains('Good.json: built'));
  });

  test('nothing is launched when every spec is invalid', () async {
    final sidecar = FakeSidecar(buildsAll());
    final r = await run([
      'build',
      writeSpec('Bad', uiVersion: 15),
      '--out',
      'out',
    ], sidecar: sidecar);
    expect(r.code, ExitCodes.invalid);
    expect(sidecar.received, isNull);
  });

  test('a failed build exits 4 and keeps going for the rest', () async {
    final sidecar = FakeSidecar(
      (jobs) => SidecarOutcome(
        results: [
          BuildJobResult(
            id: jobs[0].id,
            ok: false,
            errorCode: 'build.failed',
            message: 'boom',
          ),
          BuildJobResult(id: jobs[1].id, ok: true, mtz: '/x/Dusk.mtz'),
        ],
      ),
    );
    final r = await run([
      'build',
      writeSpec('Neon'),
      writeSpec('Dusk'),
      '--out',
      'out',
      '--json',
    ], sidecar: sidecar);

    expect(r.code, ExitCodes.buildFailed);
    final doc = jsonDecode(r.out) as Map<String, dynamic>;
    expect(doc['ok'], isFalse);
    final results = doc['results'] as List;
    expect(results[0]['ok'], isFalse);
    expect(results[0]['error']['code'], 'build.failed');
    expect(results[0]['error']['message'], 'boom');
    expect(results[1]['ok'], isTrue);
    expect(results[1]['mtz'], '/x/Dusk.mtz');
  });

  test('--json lists every spec with its stage', () async {
    final sidecar = FakeSidecar(buildsAll());
    final r = await run([
      'build',
      writeSpec('Good'),
      writeSpec('Bad', uiVersion: 15),
      'missing.json',
      '--out',
      'out',
      '--json',
    ], sidecar: sidecar);

    final doc = jsonDecode(r.out) as Map<String, dynamic>;
    expect(doc['command'], 'build');
    final stages = {
      for (final e in doc['results'] as List)
        p.basename(e['spec'] as String): e['stage'],
    };
    expect(stages, {
      'Good.json': 'done',
      'Bad.json': 'validate',
      'missing.json': 'read',
    });
    expect(r.code, ExitCodes.io);
  });

  test('a crashed render process exits 5 with its log', () async {
    final sidecar = FakeSidecar(
      (_) =>
          const SidecarOutcome(exitCode: 1, logTail: 'Bad state: engine died'),
    );
    final r = await run([
      'build',
      writeSpec('Neon'),
      '--out',
      'out',
    ], sidecar: sidecar);
    expect(r.code, ExitCodes.sidecar);
    expect(r.err, contains('engine died'));
  });

  test('a render process that cannot start exits 5', () async {
    final sidecar = FakeSidecar(
      (_) => const SidecarOutcome(launchError: 'Cannot run "flutter"'),
    );
    final r = await run([
      'build',
      writeSpec('Neon'),
      '--out',
      'out',
    ], sidecar: sidecar);
    expect(r.code, ExitCodes.sidecar);
    expect(r.err, contains('Cannot run'));
  });

  test(
    'without a Flutter project the error says how to point at one',
    () async {
      final r = await run(['build', writeSpec('Neon'), '--out', 'out']);
      expect(r.code, ExitCodes.sidecar);
      expect(r.err, contains('--project'));
    },
  );

  group('fonts that the spec gives no path for', () {
    String specWithFont() => writeSpec(
      'Ground',
      elements: [
        {'type': 'swipeUpUnlock'},
        {'type': 'hourClock', 'font': 'Ground'},
      ],
    );

    Directory fontsDir() {
      final dir = Directory(p.join(tmp.path, 'fonts'))..createSync();
      File(p.join(dir.path, 'Ground.ttf')).writeAsBytesSync([0, 1, 0, 0, 9]);
      return dir;
    }

    test('are an error without --fonts-dir', () async {
      final sidecar = FakeSidecar(buildsAll());
      final r = await run([
        'build',
        specWithFont(),
        '--out',
        'out',
      ], sidecar: sidecar);
      expect(r.code, ExitCodes.invalid);
      expect(r.out, contains('font.file_missing'));
      expect(sidecar.received, isNull);
    });

    test(
      'are found in --fonts-dir and the folder goes to the sidecar',
      () async {
        final dir = fontsDir();
        final sidecar = FakeSidecar(buildsAll());
        final r = await run([
          'build',
          specWithFont(),
          '--out',
          'out',
          '--fonts-dir',
          'fonts',
        ], sidecar: sidecar);

        expect(r.code, ExitCodes.ok, reason: '${r.out}\n${r.err}');
        expect(sidecar.received!.single.fontsDirs, [dir.path]);
      },
    );

    test('validate accepts --fonts-dir too', () async {
      fontsDir();
      final spec = specWithFont();
      expect((await run(['validate', spec])).code, ExitCodes.invalid);
      expect(
        (await run(['validate', spec, '--fonts-dir', 'fonts'])).code,
        ExitCodes.ok,
      );
    });
  });

  test('usage mistakes exit 2', () async {
    expect((await run(['build', '--out', 'out'])).code, ExitCodes.usage);
    expect((await run(['build', writeSpec('Neon')])).code, ExitCodes.usage);
  });

  test('findProject walks up to the folder with the sidecar entry', () {
    final deep = Directory(p.join(tmp.path, 'a', 'b'))
      ..createSync(recursive: true);
    expect(findProject([deep.path]), isNull);
    File(p.join(tmp.path, sidecarEntry))
      ..createSync(recursive: true)
      ..writeAsStringSync('');
    expect(findProject([deep.path]), tmp.path);
  });

  test('BuildJob and BuildJobResult round-trip through JSON', () {
    const job = BuildJob(id: 'a', spec: '/s.json', outDir: '/o', preview: true);
    expect(
      BuildJob.decodeAll(BuildJob.encodeAll([job])).single.toJson(),
      job.toJson(),
    );

    const r = BuildJobResult(
      id: 'a',
      ok: false,
      lockscreenPreview: '/o/a.lockscreen.png',
      errorCode: 'x',
      message: 'm',
      seconds: 2,
    );
    final lines = '${jsonEncode(r.toJson())}\n{"torn": \n';
    expect(BuildJobResult.decodeLines(lines).single.toJson(), r.toJson());
  });

  // Runs the real Flutter render process, so it needs the SDK and takes a
  // while; skipped when Flutter isn't installed.
  test(
    'end to end: builds an .mtz with the real render process',
    () async {
      final project = findProject([Directory.current.path]);
      if (project == null) markTestSkipped('repo root not found');
      final spec = writeSpec(
        'E2E',
        elements: [
          {'type': 'swipeUpUnlock'},
          {'type': 'hourClock', 'color': '#FFFFFF'},
        ],
      );

      final r = await run([
        'build',
        spec,
        '--out',
        'out',
        '--project',
        project!,
        '--preview',
        '--json',
      ]);
      expect(r.code, ExitCodes.ok, reason: '${r.out}\n${r.err}');

      final doc = jsonDecode(r.out) as Map<String, dynamic>;
      final entry = doc['results'][0] as Map<String, dynamic>;
      final mtz = File(entry['mtz'] as String);
      expect(mtz.existsSync(), isTrue);
      expect(mtz.lengthSync(), greaterThan(100 * 1024));
      expect(
        Directory(
          p.join(tmp.path, 'out', 'E2E', 'lockscreen', 'advance'),
        ).existsSync(),
        isTrue,
      );

      final home = img.decodePng(
        File(entry['preview'] as String).readAsBytesSync(),
      )!;
      expect(home.width, 540);
      final lock = img.decodePng(
        File(entry['lockscreenPreview'] as String).readAsBytesSync(),
      )!;
      expect((lock.width, lock.height), (554, 1200));
      // The wallpaper is black and the clock is white.
      expect(lock.getPixel(5, 5).r, 0);
      expect(
        lock.data!.any((px) => px.r > 200),
        isTrue,
        reason: 'no clock pixels in the lockscreen preview',
      );
    },
    timeout: const Timeout(Duration(minutes: 10)),
    skip: Process.runSync('flutter', ['--version']).exitCode != 0
        ? 'flutter not installed'
        : null,
  );
}
