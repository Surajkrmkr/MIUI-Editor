import 'dart:convert';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:path/path.dart' as p;
import 'package:theme_core/theme_core.dart';

import 'exit_codes.dart';
import 'fonts_dirs.dart';
import 'preview_command.dart';
import 'sidecar.dart';
import 'sidecar_options.dart';

/// `theme build <spec>... --out <dir>`: validates each spec, then builds the
/// valid ones in a single Flutter render process.
class BuildCommand extends Command<int> {
  BuildCommand(this._out, this._err, this._cwd, this._sidecarOverride) {
    argParser
      ..addOption(
        'out',
        abbr: 'o',
        valueHelp: 'dir',
        help: 'Folder that receives <name>/ and <name>.mtz for every theme.',
      )
      ..addFlag(
        'json',
        negatable: false,
        help: 'Print one JSON document instead of text.',
      )
      ..addFlag(
        'contrast',
        defaultsTo: true,
        help: 'Decode wallpapers to check text legibility while validating.',
      )
      ..addFlag(
        'preview',
        negatable: false,
        help:
            'Also write <out>/<name>.preview.png (home screen) and '
            '<name>.lockscreen.png.',
      );
    addSidecarOptions(argParser);
    addFontsDirOption(argParser);
  }

  final StringSink _out, _err;
  final Directory _cwd;
  final Sidecar? _sidecarOverride;

  @override
  String get name => 'build';

  @override
  String get description =>
      'Validate theme specs and build their .mtz files (needs Flutter).';

  @override
  String get invocation => 'theme build <spec.json>... --out <dir> [options]';

  @override
  Future<int> run() async {
    final specs = argResults!.rest;
    if (specs.isEmpty) usageException('Give at least one spec file.');
    final outOption = argResults!['out'] as String?;
    if (outOption == null) usageException('Missing --out <dir>.');
    final json = argResults!['json'] as bool;
    final outDir = p.normalize(p.absolute(_cwd.path, outOption));

    final specPaths = [
      for (final s in specs) p.normalize(p.absolute(_cwd.path, s)),
    ];
    final project = projectDirOf(argResults!, _cwd, specPaths);
    final fontsDirs = fontsDirsOf(argResults!, _cwd);

    // ── Validate ───────────────────────────────────────────────────────────
    final entries = <_Entry>[];
    for (final path in specPaths) {
      final entry = _Entry(path);
      entries.add(entry);
      final String text;
      try {
        text = File(path).readAsStringSync();
      } on FileSystemException catch (e) {
        entry.readError =
            'Cannot read $path: ${e.osError?.message ?? e.message}';
        continue;
      }
      entry.report = const SpecValidator().validateText(
        text,
        ValidationOptions(
          baseDir: p.dirname(path),
          assetsRoot: project,
          checkContrast: argResults!['contrast'] as bool,
          fontsDirs: fontsDirs,
        ),
      );
    }

    // ── Build ──────────────────────────────────────────────────────────────
    final jobs = [
      for (final e in entries)
        if (e.valid)
          BuildJob(
            id: e.path,
            spec: e.path,
            outDir: outDir,
            preview: argResults!['preview'] as bool,
            fontsDirs: fontsDirs,
          ),
    ];
    String? sidecarError;
    if (jobs.isNotEmpty) {
      final sidecar =
          _sidecarOverride ?? flutterSidecarOf(argResults!, project, _err);
      if (sidecar == null) {
        sidecarError = noProjectMessage;
      } else {
        final outcome = await sidecar.run(jobs);
        sidecarError = outcome.launchError;
        final byId = {for (final r in outcome.results) r.id: r};
        for (final e in entries.where((e) => e.valid)) {
          e.result = byId[e.path];
        }
        if (sidecarError == null &&
            entries.any((e) => e.valid && e.result == null)) {
          sidecarError =
              'The render process exited with code ${outcome.exitCode} before '
              'finishing every theme.\n${outcome.logTail}';
        }
      }
    }

    if (argResults!['preview'] as bool) {
      for (final e in entries) {
        final r = e.result;
        final workspace = r?.workspace;
        if (r?.ok != true || workspace == null) continue;
        e.lockscreenPreview = r!.lockscreenPreview;
        if (r.errorCode == 'preview.failed') e.previewError = r.message;
        try {
          e.preview = writeHomePreview(workspace, outDir);
        } on AppException catch (ex) {
          e.previewError ??= ex.message;
        }
      }
    }

    final code = sidecarError != null
        ? ExitCodes.sidecar
        : entries.any((e) => e.readError != null)
        ? ExitCodes.io
        : entries.any((e) => e.report != null && !e.report!.ok)
        ? ExitCodes.invalid
        : entries.any(
            (e) =>
                e.previewError != null || (e.result != null && !e.result!.ok),
          )
        ? ExitCodes.buildFailed
        : ExitCodes.ok;

    if (json) {
      _out.writeln(
        const JsonEncoder.withIndent('  ').convert({
          'command': 'build',
          'ok': code == ExitCodes.ok,
          'out': outDir,
          if (sidecarError != null)
            'error': {'code': 'sidecar', 'message': sidecarError},
          'results': [for (final e in entries) e.toJson()],
        }),
      );
    } else {
      for (final e in entries) {
        _printEntry(e);
      }
      if (sidecarError != null) _err.writeln(sidecarError);
    }
    return code;
  }

  void _printEntry(_Entry e) {
    final name = p.basename(e.path);
    if (e.readError != null) {
      _err.writeln(e.readError);
      return;
    }
    final report = e.report!;
    for (final i in report.issues) {
      final sev = i.severity == IssueSeverity.error ? 'error  ' : 'warning';
      _out.writeln(
        '$name: $sev ${i.path.isEmpty ? '/' : i.path}: ${i.message} [${i.code}]',
      );
      if (i.hint != null) _out.writeln('        ${i.hint}');
    }
    if (!report.ok) {
      _out.writeln('$name: invalid (${report.errorCount} error(s))');
    } else if (e.result == null) {
      _out.writeln('$name: not built');
    } else if (e.result!.ok) {
      _out.writeln(
        '$name: built ${e.result!.mtz} (${e.result!.seconds.toStringAsFixed(1)}s)',
      );
      if (e.preview != null) _out.writeln('$name: preview ${e.preview}');
      if (e.lockscreenPreview != null) {
        _out.writeln('$name: preview ${e.lockscreenPreview}');
      }
      if (e.previewError != null) {
        _out.writeln('$name: preview failed: ${e.previewError}');
      }
    } else {
      _out.writeln(
        '$name: build failed [${e.result!.errorCode}] ${e.result!.message}',
      );
    }
  }
}

class _Entry {
  _Entry(this.path);

  final String path;
  String? readError;
  ValidationReport? report;
  BuildJobResult? result;
  String? preview, lockscreenPreview, previewError;

  bool get valid => readError == null && report != null && report!.ok;

  Map<String, Object?> toJson() => {
    'spec': path,
    'ok': (result?.ok ?? false) && previewError == null,
    'stage': readError != null
        ? 'read'
        : !valid
        ? 'validate'
        : result == null
        ? 'build'
        : 'done',
    if (readError != null) 'error': {'code': 'io.read', 'message': readError},
    if (report != null) 'issues': [for (final i in report!.issues) i.toJson()],
    if (result?.mtz != null) 'mtz': result!.mtz,
    if (result?.workspace != null) 'workspace': result!.workspace,
    if (preview != null) 'preview': preview,
    if (lockscreenPreview != null) 'lockscreenPreview': lockscreenPreview,
    if (result != null && !result!.ok)
      'error': {'code': result!.errorCode, 'message': result!.message}
    else if (previewError != null)
      'error': {'code': 'preview.failed', 'message': previewError},
    if (result != null) 'seconds': result!.seconds,
  };
}
