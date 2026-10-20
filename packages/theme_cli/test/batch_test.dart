import 'dart:convert';
import 'dart:io';

import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:theme_cli/src/batch_runner.dart';
import 'package:theme_cli/theme_cli.dart';
import 'package:theme_core/theme_core.dart';

/// Builds jobs in order like the real render process, and can be told to die
/// on a theme (a number of times) or fail it.
class ScriptedSidecar implements Sidecar {
  ScriptedSidecar({
    this.dieOn = const {},
    this.failOn = const {},
    this.launchError,
  });

  /// Spec file name -> how many times the process dies on it before it works.
  final Map<String, int> dieOn;
  final Set<String> failOn;
  final String? launchError;
  final runs = <List<String>>[];
  final _died = <String, int>{};

  @override
  Future<SidecarOutcome> run(
    List<BuildJob> jobs, {
    void Function(BuildJobResult result)? onResult,
  }) async {
    runs.add([for (final j in jobs) p.basename(j.spec)]);
    if (launchError != null) return SidecarOutcome(launchError: launchError);
    final results = <BuildJobResult>[];
    for (final job in jobs) {
      final file = p.basename(job.spec);
      final name = p.basenameWithoutExtension(file);
      if ((_died[file] ?? 0) < (dieOn[file] ?? 0)) {
        _died[file] = (_died[file] ?? 0) + 1;
        return SidecarOutcome(
          results: results,
          exitCode: 1,
          logTail: 'engine died on $file',
        );
      }
      final r = failOn.contains(file)
          ? BuildJobResult(
              id: job.id,
              ok: false,
              errorCode: 'build.failed',
              message: 'nope',
            )
          : BuildJobResult(
              id: job.id,
              ok: true,
              mtz: p.join(job.outDir, '$name.mtz'),
              workspace: p.join(job.outDir, name),
              seconds: 1,
            );
      results.add(r);
      onResult?.call(r);
    }
    return SidecarOutcome(results: results);
  }
}

void main() {
  late Directory tmp;
  late String out;

  setUp(() {
    tmp = Directory.systemTemp.createTempSync('batch_test');
    out = p.join(tmp.path, 'out');
  });
  tearDown(() => tmp.deleteSync(recursive: true));

  String png(String rel) {
    final f = File(p.join(tmp.path, rel));
    if (!f.existsSync()) {
      f
        ..createSync(recursive: true)
        ..writeAsBytesSync(
          img.encodePng(
            img.Image(width: 30, height: 60)..clear(img.ColorRgb8(20, 20, 60)),
          ),
        );
    }
    return f.path;
  }

  /// Writes specs/<name>.json and returns its path.
  String spec(String name, {String? title, bool valid = true}) {
    png('wall.png');
    png('assets/bg.png');
    final f = File(p.join(tmp.path, 'specs', '$name.json'))
      ..createSync(recursive: true);
    f.writeAsStringSync(
      jsonEncode({
        'specVersion': 1,
        'meta': {
          'title': title ?? name,
          'designer': 'D',
          'authorTag': 'T',
          'uiVersion': valid ? 17 : 15,
        },
        'wallpaper': {'home': p.join(tmp.path, 'wall.png')},
        'icons': {'pack': 'u1'},
        'lockscreen': {
          'assetsDir': p.join(tmp.path, 'assets'),
          'elements': [
            {'type': 'swipeUpUnlock'},
          ],
        },
      }),
    );
    return f.path;
  }

  /// Marks [name] as already built, [ahead] seconds after its spec.
  void built(
    String name,
    String specPath, {
    int ahead = 10,
    bool previews = false,
  }) {
    final mtz = File(p.join(out, '$name.mtz'))..createSync(recursive: true);
    mtz.setLastModifiedSync(
      File(specPath).lastModifiedSync().add(Duration(seconds: ahead)),
    );
    if (previews) {
      File(p.join(out, '$name.preview.png')).writeAsBytesSync([0]);
      File(p.join(out, '$name.lockscreen.png')).writeAsBytesSync([0]);
    }
  }

  BatchOptions opts({
    int chunk = 20,
    int retries = 1,
    bool force = false,
    bool preview = false,
  }) => BatchOptions(
    outDir: out,
    chunkSize: chunk,
    retries: retries,
    force: force,
    preview: preview,
    contrast: false,
  );

  Map<String, BatchStatus> statuses(BatchReport r) => {
    for (final e in r.entries) p.basenameWithoutExtension(e.spec): e.status,
  };

  group('BatchRunner', () {
    test('builds the valid specs and reports every other kind', () async {
      final good = spec('good');
      final bad = spec('bad', valid: false);
      final twin = spec('twin', title: 'good');
      final missing = p.join(tmp.path, 'specs', 'missing.json');
      final sidecar = ScriptedSidecar();

      final r = await BatchRunner(
        sidecar,
      ).run([good, bad, twin, missing], opts());

      expect(statuses(r), {
        'good': BatchStatus.built,
        'bad': BatchStatus.invalid,
        'twin': BatchStatus.invalid,
        'missing': BatchStatus.unreadable,
      });
      expect(sidecar.runs, [
        ['good.json'],
      ]);
      final dup = r.entries.firstWhere((e) => e.spec == twin);
      expect(dup.errorCode, 'batch.duplicate_name');
      expect(dup.message, contains(good));
    });

    test('saves the built spec to the preset and theme folders', () async {
      final s = spec('kept');
      final built = File(p.join(out, 'kept', 'theme.spec.json'))
        ..createSync(recursive: true)
        ..writeAsStringSync(
          jsonEncode({
            'meta': {'title': 'kept'},
            'wallpaper': {'home': 'wall.png'},
          }),
        );
      final presets = p.join(tmp.path, 'Preset');
      final r = await BatchRunner(ScriptedSidecar()).run([
        s,
      ], BatchOptions(outDir: out, contrast: false, presetsDir: presets));
      expect(r.entries.single.status, BatchStatus.built);
      final saved = jsonDecode(
        File(p.join(presets, 'kept', 'preset.json')).readAsStringSync(),
      );
      expect(saved['wallpaper']['home'], p.join(p.dirname(s), 'wall.png'));
      expect(jsonDecode(built.readAsStringSync()), saved);
    });

    test('a spec given twice is built once', () async {
      final s = spec('once');
      final sidecar = ScriptedSidecar();
      final r = await BatchRunner(sidecar).run([s, s], opts());
      expect(r.entries, hasLength(1));
      expect(sidecar.runs.single, ['once.json']);
    });

    test('splits the work into chunks, one render process each', () async {
      final specs = [for (var i = 0; i < 5; i++) spec('t$i')];
      final sidecar = ScriptedSidecar();
      final r = await BatchRunner(sidecar).run(specs, opts(chunk: 2));
      expect(sidecar.runs.map((c) => c.length), [2, 2, 1]);
      expect(r.count(BatchStatus.built), 5);
    });

    test('reports each theme as soon as it finishes, in order', () async {
      final specs = [for (var i = 0; i < 3; i++) spec('t$i')];
      final heard = <String>[];
      await BatchRunner(
        ScriptedSidecar(),
      ).run(specs, opts(), onEntry: (e) => heard.add(e.name!));
      expect(heard, ['t0', 't1', 't2']);
    });

    group('resuming', () {
      test('skips a theme whose .mtz is newer than its spec', () async {
        final s = spec('done');
        built('done', s);
        final sidecar = ScriptedSidecar();

        final r = await BatchRunner(sidecar).run([s], opts());

        expect(r.entries.single.status, BatchStatus.skipped);
        expect(r.entries.single.mtz, p.join(out, 'done.mtz'));
        expect(sidecar.runs, isEmpty);
      });

      test('rebuilds when the spec changed after the build', () async {
        final s = spec('edited');
        built('edited', s, ahead: -10);
        final r = await BatchRunner(ScriptedSidecar()).run([s], opts());
        expect(r.entries.single.status, BatchStatus.built);
      });

      test('--force rebuilds anyway', () async {
        final s = spec('forced');
        built('forced', s);
        final r = await BatchRunner(
          ScriptedSidecar(),
        ).run([s], opts(force: true));
        expect(r.entries.single.status, BatchStatus.built);
      });

      test('needs the preview images too when asked for them', () async {
        final s = spec('shots');
        built('shots', s);
        final missing = ScriptedSidecar();
        await BatchRunner(missing).run([s], opts(preview: true));
        expect(missing.runs, hasLength(1));

        built('shots', s, previews: true);
        final present = ScriptedSidecar();
        final r = await BatchRunner(present).run([s], opts(preview: true));
        expect(r.entries.single.status, BatchStatus.skipped);
        expect(
          r.entries.single.lockscreenPreview,
          p.join(out, 'shots.lockscreen.png'),
        );
        expect(present.runs, isEmpty);
      });

      test('needs no render process when everything is up to date', () async {
        final s = spec('only');
        built('only', s);
        final r = await BatchRunner(null).run([s], opts());
        expect(r.sidecarError, isNull);
        expect(r.count(BatchStatus.skipped), 1);
      });
    });

    group('crashes', () {
      test(
        'a theme that kills the process once is retried and built',
        () async {
          final specs = [spec('a'), spec('b'), spec('c')];
          final sidecar = ScriptedSidecar(dieOn: {'b.json': 1});

          final r = await BatchRunner(sidecar).run(specs, opts());

          expect(statuses(r).values, everyElement(BatchStatus.built));
          expect(r.entries[1].crashes, 1);
          expect(sidecar.runs, [
            ['a.json', 'b.json', 'c.json'],
            ['b.json', 'c.json'],
          ]);
        },
      );

      test(
        'one that always kills it is failed; the rest still build',
        () async {
          final specs = [spec('a'), spec('b'), spec('c')];
          final sidecar = ScriptedSidecar(dieOn: {'b.json': 99});

          final r = await BatchRunner(sidecar).run(specs, opts(retries: 1));

          expect(statuses(r), {
            'a': BatchStatus.built,
            'b': BatchStatus.failed,
            'c': BatchStatus.built,
          });
          final b = r.entries[1];
          expect(b.errorCode, 'build.crash');
          expect(b.crashes, 2);
          expect(b.message, contains('engine died on b.json'));
        },
      );

      test('--retries 0 gives up on the first crash', () async {
        final sidecar = ScriptedSidecar(dieOn: {'a.json': 99});
        final r = await BatchRunner(sidecar).run([spec('a')], opts(retries: 0));
        expect(r.entries.single.crashes, 1);
        expect(r.entries.single.status, BatchStatus.failed);
        expect(sidecar.runs, hasLength(1));
      });

      test('a process that dies before any theme stops the batch', () async {
        final specs = [for (var i = 0; i < 6; i++) spec('t$i')];
        final sidecar = ScriptedSidecar(
          dieOn: {for (final s in specs) p.basename(s): 99},
        );

        final r = await BatchRunner(sidecar).run(specs, opts(retries: 5));

        expect(r.sidecarError, contains('died 3 times'));
        expect(sidecar.runs, hasLength(3));
        expect(r.count(BatchStatus.built), 0);
        expect(r.count(BatchStatus.notRun), greaterThan(0));
      });
    });

    test('a failed build does not stop the others', () async {
      final specs = [spec('a'), spec('b')];
      final r = await BatchRunner(
        ScriptedSidecar(failOn: {'a.json'}),
      ).run(specs, opts());
      expect(statuses(r), {'a': BatchStatus.failed, 'b': BatchStatus.built});
      expect(r.entries[0].message, 'nope');
    });

    test('a process that cannot start stops the batch', () async {
      final r = await BatchRunner(
        ScriptedSidecar(launchError: 'no flutter'),
      ).run([spec('a')], opts());
      expect(r.sidecarError, 'no flutter');
      expect(r.entries.single.status, BatchStatus.notRun);
    });

    test('without a project there is nothing to build with', () async {
      final r = await BatchRunner(null).run([spec('a')], opts());
      expect(r.sidecarError, contains('--project'));
    });
  });

  group('theme batch', () {
    Future<({int code, String out, String err})> cli(
      List<String> args,
      Sidecar sidecar,
    ) async {
      final o = StringBuffer(), e = StringBuffer();
      final code = await runCli(
        args,
        out: o,
        err: e,
        cwd: tmp,
        sidecar: sidecar,
      );
      return (code: code, out: o.toString(), err: e.toString());
    }

    test('takes a folder, prints progress and writes the report', () async {
      spec('a');
      spec('b');
      spec('bad', valid: false);
      final r = await cli([
        'batch',
        'specs',
        '--out',
        'out',
        '--no-contrast',
      ], ScriptedSidecar());

      expect(r.code, ExitCodes.invalid);
      expect(r.out, contains('built   a'));
      expect(r.out, contains('built   b'));
      expect(r.out, contains('invalid bad.json'));
      expect(r.out, contains('[meta.ui_version]'));
      expect(r.out, contains('3 specs: 2 built, 1 invalid'));

      final report =
          jsonDecode(File(p.join(out, 'batch-report.json')).readAsStringSync())
              as Map;
      expect(report['ok'], isFalse);
      expect((report['summary'] as Map)['built'], 2);
      expect((report['summary'] as Map)['invalid'], 1);
      expect((report['results'] as List), hasLength(3));
    });

    test('--json prints one object per line and a closing summary', () async {
      spec('a');
      final r = await cli([
        'batch',
        'specs',
        '--out',
        'out',
        '--json',
        '--no-contrast',
        '--report',
        'r.json',
      ], ScriptedSidecar());

      final lines = [
        for (final l in const LineSplitter().convert(r.out))
          jsonDecode(l) as Map,
      ];
      expect(lines.map((l) => l['event']), ['entry', 'done']);
      expect(lines.first['status'], 'built');
      expect(lines.last['ok'], isTrue);
      expect(lines.last['report'], p.join(tmp.path, 'r.json'));
      expect(File(p.join(tmp.path, 'r.json')).existsSync(), isTrue);
      expect(r.code, ExitCodes.ok);
    });

    test('exit codes: failed build 4, no render process 5', () async {
      spec('a');
      expect(
        (await cli([
          'batch',
          'specs',
          '--out',
          'out',
          '--no-contrast',
        ], ScriptedSidecar(failOn: {'a.json'}))).code,
        ExitCodes.buildFailed,
      );
      expect(
        (await cli([
          'batch',
          'specs',
          '--out',
          'out',
          '--no-contrast',
          '--force',
        ], ScriptedSidecar(launchError: 'x'))).code,
        ExitCodes.sidecar,
      );
    });

    test('a second run builds nothing', () async {
      spec('a');
      final first = ScriptedSidecar();
      await cli(['batch', 'specs', '--out', 'out', '--no-contrast'], first);
      // The fake writes no files, so stand in for the first run's output.
      built('a', p.join(tmp.path, 'specs', 'a.json'));

      final second = ScriptedSidecar();
      final r = await cli([
        'batch',
        'specs',
        '--out',
        'out',
        '--no-contrast',
      ], second);
      expect(r.out, contains('skipped a'));
      expect(second.runs, isEmpty);
      expect(r.code, ExitCodes.ok);
    });

    test('usage mistakes exit 2', () async {
      spec('a');
      final s = ScriptedSidecar();
      expect((await cli(['batch', '--out', 'out'], s)).code, ExitCodes.usage);
      expect((await cli(['batch', 'specs'], s)).code, ExitCodes.usage);
      expect(
        (await cli(['batch', 'specs', '--out', 'out', '--chunk', '0'], s)).code,
        ExitCodes.usage,
      );
      Directory(p.join(tmp.path, 'empty')).createSync();
      expect(
        (await cli(['batch', 'empty', '--out', 'out'], s)).code,
        ExitCodes.usage,
      );
    });
  });
}
