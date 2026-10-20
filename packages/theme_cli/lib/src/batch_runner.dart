import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:theme_core/theme_core.dart';

import 'preview_command.dart';
import 'sidecar.dart';

enum BatchStatus {
  /// Built now.
  built,

  /// Already built and newer than its spec.
  skipped,

  /// The spec has errors; nothing was built.
  invalid,

  /// The file couldn't be read.
  unreadable,

  /// A valid spec that failed while building.
  failed,

  /// Valid, but the batch stopped before reaching it.
  notRun,
}

/// What happened to one spec.
class BatchEntry {
  BatchEntry(this.spec);

  final String spec;
  String? name;
  BatchStatus status = BatchStatus.notRun;
  List<SpecIssue> issues = const [];
  String? mtz, workspace, preview, lockscreenPreview;
  String? errorCode, message;

  /// A rewritten copy of the spec that the render process reads instead.
  String? preparedSpec;
  double seconds = 0;

  /// Times the render process died while building this theme.
  int crashes = 0;

  Map<String, Object?> toJson() => {
    'spec': spec,
    if (name != null) 'name': name,
    'status': status.name,
    if (mtz != null) 'mtz': mtz,
    if (workspace != null) 'workspace': workspace,
    if (preview != null) 'preview': preview,
    if (lockscreenPreview != null) 'lockscreenPreview': lockscreenPreview,
    if (issues.isNotEmpty) 'issues': [for (final i in issues) i.toJson()],
    if (errorCode != null) 'error': {'code': errorCode, 'message': message},
    if (seconds > 0) 'seconds': seconds,
    if (crashes > 0) 'crashes': crashes,
  };
}

class BatchOptions {
  const BatchOptions({
    required this.outDir,
    this.chunkSize = 20,
    this.retries = 1,
    this.force = false,
    this.preview = false,
    this.mode = BuildMode.build,
    this.contrast = true,
    this.checkDesign = false,
    this.similarDesigns = const [],
    this.fontsDirs = const [],
    this.assetsRoot,
    this.baseDir,
    this.prepare,
    this.presetsDir,
  });

  final String outDir;

  /// Themes per render process; a fresh process every chunk keeps a leak or a
  /// crash from taking the whole batch with it.
  final int chunkSize;

  /// Extra attempts for a theme that killed the render process.
  final int retries;

  /// Rebuild even when the `.mtz` is newer than its spec.
  final bool force;
  final bool preview;

  /// What to draw; the quick modes skip most of a build and the package.
  final BuildMode mode;
  final bool contrast;

  /// Also warn about bare lockscreens.
  final bool checkDesign;

  /// Earlier themes to compare designs with; used with [checkDesign].
  final List<NamedDesign> similarDesigns;
  final List<String> fontsDirs;
  final String? assetsRoot;

  /// Where relative paths in every spec resolve; defaults to each spec's own
  /// folder.
  final String? baseDir;

  /// Fills in what a decoded spec leaves out before it is validated and
  /// built, changing it in place; [baseDir] is where its relative paths
  /// resolve.
  final void Function(Map<String, dynamic> spec, String baseDir)? prepare;

  /// When set, each built theme's spec and preview pictures go to
  /// `<presetsDir>/<name>/` (`preset.json`, `preview.png` for the
  /// lockscreen, `home.png`) instead of the theme folder.
  final String? presetsDir;
}

class BatchReport {
  BatchReport(this.entries, {this.sidecarError, required this.seconds});

  final List<BatchEntry> entries;

  /// Set when the render process couldn't run; the batch stopped there.
  final String? sidecarError;
  final double seconds;

  int count(BatchStatus s) => entries.where((e) => e.status == s).length;

  Map<String, Object?> toJson() => {
    'ok':
        sidecarError == null &&
        entries.every(
          (e) =>
              e.status == BatchStatus.built || e.status == BatchStatus.skipped,
        ),
    if (sidecarError != null)
      'error': {'code': 'sidecar', 'message': sidecarError},
    'summary': {
      'total': entries.length,
      for (final s in BatchStatus.values) s.name: count(s),
      'seconds': seconds,
    },
    'results': [for (final e in entries) e.toJson()],
  };
}

/// Builds many specs: validates them all first, skips what is already built,
/// then renders the rest in chunks, retrying a theme that crashes the render
/// process.
///
/// Chunks run one after another: two `flutter test` runs in one project
/// collide in its build folder.
class BatchRunner {
  BatchRunner(this.sidecar);

  /// Null when no Flutter project was found; only matters if something needs
  /// building.
  final Sidecar? sidecar;

  /// Process crashes in a row without a single result before giving up.
  static const _maxEmptyRuns = 3;

  Future<BatchReport> run(
    List<String> specPaths,
    BatchOptions options, {
    void Function(BatchEntry entry)? onEntry,
  }) async {
    final clock = Stopwatch()..start();
    Directory? scratchDir;
    Directory scratch() =>
        scratchDir ??= Directory.systemTemp.createTempSync('theme_batch');
    final entries = <BatchEntry>[
      for (final path in specPaths.toSet()) BatchEntry(path),
    ];
    final pending = <BatchEntry>[];
    final owners = <String, BatchEntry>{};

    for (final e in entries) {
      _check(e, options, owners, scratch);
      if (e.status == BatchStatus.notRun) pending.add(e);
      if (e.status != BatchStatus.notRun) onEntry?.call(e);
    }

    String? sidecarError;
    if (pending.isNotEmpty) {
      final s = sidecar;
      if (s == null) {
        sidecarError =
            'No Flutter project found. Run from the repo, or pass --project '
            '<dir> (a folder containing $sidecarEntry).';
      } else {
        sidecarError = await _build(s, pending, options, onEntry);
      }
    }
    final leftovers = scratchDir;
    if (leftovers != null && leftovers.existsSync()) {
      leftovers.deleteSync(recursive: true);
    }
    return BatchReport(
      entries,
      sidecarError: sidecarError,
      seconds: clock.elapsedMilliseconds / 1000,
    );
  }

  /// Reads and validates one spec, and decides whether it needs building.
  void _check(
    BatchEntry e,
    BatchOptions options,
    Map<String, BatchEntry> owners,
    Directory Function() scratch,
  ) {
    final String text;
    try {
      text = File(e.spec).readAsStringSync();
    } on FileSystemException catch (ex) {
      e
        ..status = BatchStatus.unreadable
        ..errorCode = 'io.read'
        ..message =
            'Cannot read ${e.spec}: ${ex.osError?.message ?? ex.message}';
      return;
    }
    final baseDir = options.baseDir ?? p.dirname(e.spec);
    final validation = ValidationOptions(
      baseDir: baseDir,
      assetsRoot: options.assetsRoot,
      checkContrast: options.contrast,
      checkDesign: options.checkDesign,
      similarDesigns: options.similarDesigns,
      fontsDirs: options.fontsDirs,
    );
    Object? decoded;
    try {
      decoded = jsonDecode(text);
    } on FormatException {
      decoded = null;
    }
    final prepare = options.prepare;
    String? prepared;
    final ValidationReport report;
    if (prepare != null && decoded is Map<String, dynamic>) {
      final before = jsonEncode(decoded);
      prepare(decoded, baseDir);
      final after = jsonEncode(decoded);
      report = const SpecValidator().validate(decoded, validation);
      if (after != before) prepared = after;
    } else {
      report = const SpecValidator().validateText(text, validation);
    }
    e.issues = report.issues;
    final spec = report.spec;
    e.name = spec?.outputName;
    if (!report.ok || spec == null) {
      e.status = BatchStatus.invalid;
      return;
    }

    final first = owners[spec.outputName];
    if (first != null) {
      e
        ..status = BatchStatus.invalid
        ..errorCode = 'batch.duplicate_name'
        ..message =
            '"${spec.outputName}" is already built from ${first.spec}; '
            'one of the two needs another title or output.name.';
      return;
    }
    owners[spec.outputName] = e;
    if (prepared != null) {
      e.preparedSpec = p.join(
        scratch().path,
        '${owners.length}-${p.basename(e.spec)}',
      );
      File(e.preparedSpec!).writeAsStringSync(prepared);
    }

    final out = p.join(p.absolute(options.outDir), p.basename(spec.outputName));
    if (!options.force && _upToDate(e.spec, out, spec, options)) {
      e
        ..status = BatchStatus.skipped
        ..mtz = '$out.mtz'
        ..workspace = out;
      if (options.preview) {
        final shots = _previewFiles(out, spec, options);
        e.preview = shots.home;
        if (spec.lockscreen.elements.isNotEmpty) {
          e.lockscreenPreview = shots.lock;
        }
      }
    }
  }

  /// Where the home-screen and lockscreen pictures of a built theme end up.
  static ({String home, String lock}) _previewFiles(
    String out,
    ThemeSpec spec,
    BatchOptions options,
  ) {
    final presets = options.presetsDir;
    if (presets == null) {
      return (home: '$out.preview.png', lock: '$out.lockscreen.png');
    }
    final dir = p.join(presets, p.basename(spec.outputName));
    return (
      home: p.join(
        dir,
        spec.lockscreen.elements.isEmpty ? 'preview.png' : 'home.png',
      ),
      lock: p.join(dir, 'preview.png'),
    );
  }

  static bool _upToDate(
    String specPath,
    String out,
    ThemeSpec spec,
    BatchOptions options,
  ) {
    final mtz = File('$out.mtz');
    if (!mtz.existsSync()) return false;
    if (mtz.lastModifiedSync().isBefore(File(specPath).lastModifiedSync())) {
      return false;
    }
    if (!options.preview) return true;
    final shots = _previewFiles(out, spec, options);
    return File(shots.home).existsSync() &&
        (spec.lockscreen.elements.isEmpty || File(shots.lock).existsSync());
  }

  /// Moves the spec the build left in the theme folder, and the preview
  /// pictures, into the theme's preset folder.
  static void _saveAsPreset(BatchEntry e, BatchOptions options) {
    final dir = Directory(p.join(options.presetsDir!, p.basename(e.name!)))
      ..createSync(recursive: true);
    final built = File(p.join(e.workspace!, 'theme.spec.json'));
    if (built.existsSync()) {
      final json = jsonDecode(built.readAsStringSync()) as Map<String, dynamic>;
      _absolutePaths(json, options.baseDir ?? p.dirname(e.spec));
      File(p.join(dir.path, 'preset.json')).writeAsStringSync(
        '${const JsonEncoder.withIndent('  ').convert(json)}\n',
      );
      built.deleteSync();
    }
    String? move(String? from, String name) {
      if (from == null || !File(from).existsSync()) return from;
      final to = p.join(dir.path, name);
      File(from).copySync(to);
      File(from).deleteSync();
      return to;
    }

    e.lockscreenPreview = move(e.lockscreenPreview, 'preview.png');
    e.preview = move(
      e.preview,
      e.lockscreenPreview == null ? 'preview.png' : 'home.png',
    );
  }

  /// Makes the file paths of a spec absolute, so it still works away from
  /// [baseDir].
  static void _absolutePaths(Map<String, dynamic> spec, String baseDir) {
    void fix(Object? map, String key) {
      if (map is! Map) return;
      final v = map[key];
      if (v is String && v.isNotEmpty && !p.isAbsolute(v)) {
        map[key] = p.normalize(p.join(baseDir, v));
      }
    }

    fix(spec['wallpaper'], 'home');
    fix(spec['wallpaper'], 'lock');
    fix(spec['lockscreen'], 'assetsDir');
    final fonts = spec['fonts'];
    if (fonts is List) {
      for (final f in fonts) {
        fix(f, 'path');
      }
    }
  }

  /// Renders [pending] chunk by chunk; returns why it stopped early, if it did.
  Future<String?> _build(
    Sidecar sidecar,
    List<BatchEntry> pending,
    BatchOptions options,
    void Function(BatchEntry)? onEntry,
  ) async {
    final byId = {for (final e in pending) e.spec: e};
    final size = options.chunkSize < 1 ? 1 : options.chunkSize;
    var emptyRuns = 0;

    void finish(BuildJobResult r) {
      final e = byId[r.id];
      if (e == null || e.status != BatchStatus.notRun) return;
      e.seconds = r.seconds;
      if (!r.ok) {
        e
          ..status = BatchStatus.failed
          ..errorCode = r.errorCode
          ..message = r.message;
      } else {
        e
          ..status = BatchStatus.built
          ..mtz = r.mtz
          ..workspace = r.workspace
          ..lockscreenPreview = r.lockscreenPreview;
        var previewError = r.errorCode == 'preview.failed' ? r.message : null;
        if (options.preview && r.workspace != null) {
          try {
            e.preview = writeHomePreview(r.workspace!, options.outDir);
          } on AppException catch (ex) {
            previewError ??= ex.message;
          }
        }
        if (previewError != null) {
          e
            ..status = BatchStatus.failed
            ..errorCode = 'preview.failed'
            ..message = previewError;
        }
        if (options.presetsDir != null &&
            options.mode == BuildMode.build &&
            e.workspace != null) {
          try {
            _saveAsPreset(e, options);
          } on FileSystemException catch (ex) {
            e
              ..status = BatchStatus.failed
              ..errorCode = 'preset.write'
              ..message = 'Cannot save to the preset folder: ${ex.message}';
          }
        }
      }
      onEntry?.call(e);
    }

    for (var start = 0; start < pending.length; start += size) {
      var todo = pending.sublist(
        start,
        (start + size).clamp(0, pending.length),
      );
      while (todo.isNotEmpty) {
        final outcome = await sidecar.run([
          for (final e in todo)
            BuildJob(
              id: e.spec,
              spec: e.preparedSpec ?? e.spec,
              outDir: p.absolute(options.outDir),
              preview: options.preview,
              mode: options.mode,
              fontsDirs: options.fontsDirs,
              baseDir:
                  options.baseDir ??
                  (e.preparedSpec == null ? null : p.dirname(e.spec)),
            ),
        ], onResult: finish);
        if (outcome.launchError != null) return outcome.launchError;
        for (final r in outcome.results) {
          finish(r);
        }

        todo = [
          for (final e in todo)
            if (e.status == BatchStatus.notRun) e,
        ];
        if (todo.isEmpty) break;

        // Results arrive in job order, so the first unfinished theme is the
        // one the process died on.
        final crashed = todo.first;
        final progressed = outcome.results.isNotEmpty;
        emptyRuns = progressed ? 0 : emptyRuns + 1;
        if (emptyRuns >= _maxEmptyRuns) {
          return 'The render process died $_maxEmptyRuns times without '
              'finishing a theme (exit code ${outcome.exitCode}).\n'
              '${outcome.logTail}';
        }
        crashed.crashes++;
        if (crashed.crashes > options.retries) {
          crashed
            ..status = BatchStatus.failed
            ..errorCode = 'build.crash'
            ..message =
                'The render process died ${crashed.crashes} times on this '
                'theme (exit code ${outcome.exitCode}).\n${outcome.logTail}';
          onEntry?.call(crashed);
          todo = todo.sublist(1);
        }
      }
    }
    return null;
  }
}

/// Spec files as given; a folder contributes its `.json` files, sorted.
List<String> discoverSpecs(List<String> args, Directory cwd) {
  final found = <String>[];
  for (final a in args) {
    final path = p.normalize(p.absolute(cwd.path, a));
    if (Directory(path).existsSync()) {
      found.addAll(
        Directory(path)
            .listSync()
            .whereType<File>()
            .map((f) => f.path)
            .where((f) => f.toLowerCase().endsWith('.json'))
            .toList()
          ..sort(),
      );
    } else {
      found.add(path);
    }
  }
  return found.toSet().toList();
}
