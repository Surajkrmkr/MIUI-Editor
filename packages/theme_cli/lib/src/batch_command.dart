import 'dart:convert';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:path/path.dart' as p;
import 'package:theme_core/theme_core.dart' show IssueSeverity;

import 'batch_runner.dart';
import 'exit_codes.dart';
import 'fonts_dirs.dart';
import 'root_config.dart';
import 'root_option.dart';
import 'sidecar.dart';
import 'sidecar_options.dart';

/// `theme batch <spec or folder>... --out <dir>`: builds many themes, resuming
/// where an earlier run stopped.
class BatchCommand extends Command<int> {
  BatchCommand(this._out, this._err, this._cwd, this._sidecarOverride) {
    argParser
      ..addOption(
        'out',
        abbr: 'o',
        valueHelp: 'dir',
        help: 'Folder that receives <name>/ and <name>.mtz for every theme.',
      )
      ..addOption(
        'chunk',
        defaultsTo: '20',
        valueHelp: 'n',
        help: 'Themes per render process; a fresh process starts for each.',
      )
      ..addOption(
        'retries',
        defaultsTo: '1',
        valueHelp: 'n',
        help: 'Extra attempts for a theme that crashes the render process.',
      )
      ..addFlag(
        'force',
        negatable: false,
        help: 'Rebuild themes whose .mtz is already newer than the spec.',
      )
      ..addFlag(
        'preview',
        negatable: false,
        help: 'Also write <name>.preview.png and <name>.lockscreen.png.',
      )
      ..addFlag(
        'contrast',
        defaultsTo: true,
        help: 'Decode wallpapers to check text legibility while validating.',
      )
      ..addOption(
        'report',
        valueHelp: 'file',
        help:
            'Where to write the JSON report. Default: <out>/batch-report.json',
      )
      ..addFlag(
        'json',
        negatable: false,
        help: 'Print one JSON object per line as themes finish.',
      );
    argParser
      ..addOption(
        'week',
        valueHelp: 'n',
        help:
            'Build into <root>/THEMES/Week<n> (so --out can be left out) and '
            'set workspace.week in every spec.',
      )
      ..addOption(
        'folder',
        valueHelp: 'n',
        help:
            'Wallpaper folder <root>/Wall/<n>: set as workspace.folder, and '
            'wallpapers given by name are looked up there.',
      );
    addSidecarOptions(argParser);
    addFontsDirOption(argParser);
    addRootOption(argParser);
  }

  final StringSink _out, _err;
  final Directory _cwd;
  final Sidecar? _sidecarOverride;

  @override
  String get name => 'batch';

  @override
  String get description =>
      'Build many theme specs, skipping what is already built (needs Flutter).';

  @override
  String get invocation =>
      'theme batch <spec.json | folder>... --out <dir> [options]';

  @override
  Future<int> run() async {
    final args = argResults!;
    if (args.rest.isEmpty) usageException('Give spec files or folders.');
    final root = rootOf(args, _cwd);
    final week = args['week'] as String?;
    final folder = args['folder'] as String?;
    for (final (name, value) in [('--week', week), ('--folder', folder)]) {
      if (value != null && !isSafeSegment(value)) {
        usageException('$name must be letters, digits, _ or -.');
      }
    }
    final outOption = args['out'] as String?;
    if (outOption == null && week == null) {
      usageException('Give --out <dir>, or --week (with --root).');
    }
    if (outOption == null && root == null) {
      usageException('--week needs --root (or \$THEME_ROOT) to find THEMES.');
    }
    final chunk = int.tryParse(args['chunk'] as String);
    final retries = int.tryParse(args['retries'] as String);
    if (chunk == null || chunk < 1) {
      usageException('--chunk must be 1 or more.');
    }
    if (retries == null || retries < 0) {
      usageException('--retries must be 0 or more.');
    }
    final json = args['json'] as bool;
    final outDir = outOption != null
        ? p.normalize(p.absolute(_cwd.path, outOption))
        : root!.weekDir(week!);

    final specs = discoverSpecs(args.rest, _cwd);
    if (specs.isEmpty) usageException('No .json spec files found.');
    final project = projectDirOf(args, _cwd, specs);

    final runner = BatchRunner(
      _sidecarOverride ?? flutterSidecarOf(args, project, _err),
    );
    var done = 0;
    final report = await runner.run(
      specs,
      BatchOptions(
        outDir: outDir,
        chunkSize: chunk,
        retries: retries,
        force: args['force'] as bool,
        preview: args['preview'] as bool,
        contrast: args['contrast'] as bool,
        fontsDirs: fontsDirsOf(args, _cwd),
        assetsRoot: project,
        prepare: specPreparer(root: root, week: week, folder: folder),
        presetsDir: root?.presetsDir,
      ),
      onEntry: (e) {
        done++;
        if (json) {
          _out.writeln(jsonEncode({'event': 'entry', ...e.toJson()}));
        } else {
          _printEntry(e, done, specs.length);
        }
      },
    );

    final reportPath = p.normalize(
      p.absolute(
        _cwd.path,
        args['report'] as String? ?? p.join(outDir, 'batch-report.json'),
      ),
    );
    var reportWritten = true;
    try {
      File(reportPath)
        ..parent.createSync(recursive: true)
        ..writeAsStringSync(
          '${const JsonEncoder.withIndent('  ').convert(report.toJson())}\n',
        );
    } on FileSystemException catch (e) {
      reportWritten = false;
      _err.writeln(
        'Cannot write the report ${e.path ?? reportPath}: '
        '${e.osError?.message ?? e.message}',
      );
    }

    final summary = report.toJson();
    if (json) {
      _out.writeln(
        jsonEncode({
          'event': 'done',
          'ok': summary['ok'],
          if (report.sidecarError != null) 'error': summary['error'],
          'summary': summary['summary'],
          if (reportWritten) 'report': reportPath,
        }),
      );
    } else {
      _printSummary(report, reportWritten ? reportPath : null);
    }

    if (report.sidecarError != null) return ExitCodes.sidecar;
    if (report.count(BatchStatus.unreadable) > 0) return ExitCodes.io;
    if (report.count(BatchStatus.invalid) > 0) return ExitCodes.invalid;
    if (report.count(BatchStatus.failed) > 0) return ExitCodes.buildFailed;
    return ExitCodes.ok;
  }

  void _printEntry(BatchEntry e, int done, int total) {
    final tag = '[$done/$total]';
    final label = e.name ?? p.basename(e.spec);
    switch (e.status) {
      case BatchStatus.built:
        _out.writeln('$tag built   $label (${e.seconds.toStringAsFixed(1)}s)');
      case BatchStatus.skipped:
        _out.writeln('$tag skipped $label (up to date)');
      case BatchStatus.invalid:
        _out.writeln('$tag invalid ${p.basename(e.spec)}');
        for (final i in e.issues.where(
          (i) => i.severity == IssueSeverity.error,
        )) {
          _out.writeln(
            '         ${i.path.isEmpty ? '/' : i.path}: ${i.message} [${i.code}]',
          );
        }
        if (e.errorCode != null) {
          _out.writeln('         ${e.message} [${e.errorCode}]');
        }
      case BatchStatus.unreadable:
        _out.writeln('$tag unreadable ${e.message}');
      case BatchStatus.failed:
        _out.writeln(
          '$tag failed  $label [${e.errorCode}] ${(e.message ?? '').split('\n').first}',
        );
      case BatchStatus.notRun:
        break;
    }
  }

  void _printSummary(BatchReport r, String? reportPath) {
    final parts = [
      for (final s in BatchStatus.values)
        if (r.count(s) > 0) '${r.count(s)} ${s.name}',
    ];
    _out.writeln(
      '${r.entries.length} specs: ${parts.isEmpty ? 'nothing to do' : parts.join(', ')} '
      '(${_duration(r.seconds)})',
    );
    if (r.sidecarError != null) _err.writeln(r.sidecarError);
    if (reportPath != null) _out.writeln('Report: $reportPath');
  }

  static String _duration(double seconds) {
    final s = seconds.round();
    if (s < 60) return '${s}s';
    return s < 3600
        ? '${s ~/ 60}m${s % 60}s'
        : '${s ~/ 3600}h${(s % 3600) ~/ 60}m';
  }
}
