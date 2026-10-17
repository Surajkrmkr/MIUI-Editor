import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:theme_core/theme_core.dart';

/// Marker file of a project that can run the render process.
const sidecarEntry = 'tool/theme_sidecar_test.dart';

/// Nearest directory at or above any of [starts] that holds [sidecarEntry].
String? findProject(Iterable<String> starts) {
  for (final start in starts) {
    var dir = p.absolute(start);
    while (true) {
      if (File(p.join(dir, sidecarEntry)).existsSync()) return dir;
      final parent = p.dirname(dir);
      if (parent == dir) break;
      dir = parent;
    }
  }
  return null;
}

class SidecarOutcome {
  const SidecarOutcome({
    this.results = const [],
    this.launchError,
    this.exitCode = 0,
    this.logTail = '',
  });

  /// Results the process reported, in the order it finished them.
  final List<BuildJobResult> results;

  /// Set when the process couldn't start at all.
  final String? launchError;
  final int exitCode;

  /// Last lines of the process's output, for diagnosing a crash.
  final String logTail;
}

/// Runs build jobs in a process that has Flutter's rendering engine.
abstract interface class Sidecar {
  /// Builds [jobs] in order. [onResult] hears each result while the process
  /// is still working on the rest.
  Future<SidecarOutcome> run(
    List<BuildJob> jobs, {
    void Function(BuildJobResult result)? onResult,
  });
}

/// Runs the jobs with `flutter test`, which provides `dart:ui` headlessly and
/// the project's asset bundle. All jobs share one process, because starting
/// Flutter costs several seconds.
class FlutterSidecar implements Sidecar {
  FlutterSidecar({
    required this.projectDir,
    this.flutter = 'flutter',
    this.onOutput,
  });

  final String projectDir;
  final String flutter;

  /// Receives every output line when set (for `--verbose`).
  final void Function(String line)? onOutput;

  @override
  Future<SidecarOutcome> run(
    List<BuildJob> jobs, {
    void Function(BuildJobResult result)? onResult,
  }) async {
    final tmp = Directory.systemTemp.createTempSync('theme_sidecar');
    final jobsFile = File(p.join(tmp.path, 'jobs.json'))
      ..writeAsStringSync(BuildJob.encodeAll(jobs));
    final resultsFile = File(p.join(tmp.path, 'results.jsonl'));
    try {
      final Process process;
      try {
        process = await Process.start(
          flutter,
          [
            'test',
            sidecarEntry,
            '--no-pub',
            '--reporter',
            'failures-only',
            '--dart-define=THEME_JOBS=${jobsFile.path}',
            '--dart-define=THEME_RESULTS=${resultsFile.path}',
          ],
          workingDirectory: projectDir,
          runInShell: Platform.isWindows,
        );
      } on ProcessException catch (e) {
        return SidecarOutcome(
          launchError:
              'Cannot run "$flutter": ${e.message}. '
              'Install Flutter or pass --flutter <path>.',
        );
      }

      final tail = <String>[];
      void collect(Stream<List<int>> s) => s
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen((line) {
            tail.add(line);
            if (tail.length > 60) tail.removeAt(0);
            onOutput?.call(line);
          });
      collect(process.stdout);
      collect(process.stderr);

      var heard = 0;
      void drain() {
        if (onResult == null || !resultsFile.existsSync()) return;
        final all = BuildJobResult.decodeLines(resultsFile.readAsStringSync());
        for (; heard < all.length; heard++) {
          onResult(all[heard]);
        }
      }

      final poll = Timer.periodic(
        const Duration(milliseconds: 400),
        (_) => drain(),
      );
      final code = await process.exitCode;
      poll.cancel();
      // Let the stream listeners drain what the process wrote last.
      await Future<void>.delayed(const Duration(milliseconds: 50));
      drain();
      return SidecarOutcome(
        results: resultsFile.existsSync()
            ? BuildJobResult.decodeLines(resultsFile.readAsStringSync())
            : const [],
        exitCode: code,
        logTail: tail.join('\n'),
      );
    } finally {
      tmp.deleteSync(recursive: true);
    }
  }
}
