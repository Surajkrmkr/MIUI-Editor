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
import 'tags.dart';
import 'ui/terminal_ui.dart';
import 'ui/wizard.dart';

/// `theme batch <spec or folder>... --out <dir>`: builds many themes, resuming
/// where an earlier run stopped.
class BatchCommand extends Command<int> {
  BatchCommand(
    this._out,
    this._err,
    this._cwd,
    this._sidecarOverride,
    this._ui,
  ) {
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
      )
      ..addFlag(
        'tags',
        defaultsTo: true,
        help:
            'Write <out>/$tagsFolderName/<name>.txt with tags picked from each '
            'lockscreen.',
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
  final TerminalUi _ui;

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
    final json = args['json'] as bool;
    final root = rootOf(args, _cwd);
    var rest = args.rest;
    var week = args['week'] as String?;
    final folder = args['folder'] as String?;
    var outOption = args['out'] as String?;
    var force = args['force'] as bool;
    var preview = args['preview'] as bool;
    if (rest.isEmpty && !json && _ui.canPrompt) {
      rest = askSpecs(_ui, _cwd) ?? rest;
      if (rest.isNotEmpty && outOption == null && week == null) {
        if (root != null) {
          final w = _ui.prompt('Week number (empty to pick a folder)').trim();
          if (w.isNotEmpty) week = w;
        }
        if (week == null) outOption = _ui.prompt('Output folder').trim();
      }
      if (rest.isNotEmpty) {
        force = _ui.confirm(
          'Rebuild themes that are up to date?',
          defaultValue: false,
        );
        preview = _ui.confirm('Also write preview images?');
      }
    }
    if (rest.isEmpty) usageException('Give spec files or folders.');
    for (final (name, value) in [('--week', week), ('--folder', folder)]) {
      if (value != null && !isSafeSegment(value)) {
        usageException('$name must be letters, digits, _ or -.');
      }
    }
    if (outOption != null && outOption.isEmpty) outOption = null;
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
    final outDir = outOption != null
        ? p.normalize(p.absolute(_cwd.path, outOption))
        : root!.weekDir(week!);

    final specs = discoverSpecs(rest, _cwd);
    if (specs.isEmpty) usageException('No .json spec files found.');
    final project = projectDirOf(args, _cwd, specs);

    final runner = BatchRunner(
      _sidecarOverride ?? flutterSidecarOf(args, project, _err),
    );
    var done = 0;
    final bar = json ? _ui.bar() : _ui.bar(total: specs.length);
    if (!json) bar.start('validating specs');
    final BatchReport report;
    try {
      report = await runner.run(
        specs,
        BatchOptions(
          outDir: outDir,
          chunkSize: chunk,
          retries: retries,
          force: force,
          preview: preview,
          contrast: args['contrast'] as bool,
          fontsDirs: fontsDirsOf(args, _cwd),
          assetsRoot: project,
          prepare: specPreparer(root: root, week: week, folder: folder),
          presetsDir: root?.presetsDir,
          tagCatalog: args['tags'] as bool
              ? TagCatalog.ofProject(project)
              : null,
        ),
        onStart: (e) =>
            bar.update(current: 'building ${e.name ?? p.basename(e.spec)}'),
        onEntry: (e) {
          done++;
          if (json) {
            _out.writeln(jsonEncode({'event': 'entry', ...e.toJson()}));
          } else {
            for (final line in _entryLines(e, done, specs.length)) {
              bar.log(line);
            }
            bar.update(done: done);
          }
        },
      );
    } finally {
      bar.finish();
    }

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

  List<String> _entryLines(BatchEntry e, int done, int total) {
    final tag = _ui.dim('[$done/$total]');
    final label = e.name ?? p.basename(e.spec);
    switch (e.status) {
      case BatchStatus.built:
        return [
          '$tag ${_ui.ok('built')}   $label '
              '${_ui.dim('(${e.seconds.toStringAsFixed(1)}s)')}',
        ];
      case BatchStatus.skipped:
        return [
          '$tag ${_ui.warn('skipped')} $label ${_ui.dim('(up to date)')}',
        ];
      case BatchStatus.invalid:
        return [
          '$tag ${_ui.bad('invalid')} ${p.basename(e.spec)}',
          for (final i in e.issues.where(
            (i) => i.severity == IssueSeverity.error,
          ))
            '         ${i.path.isEmpty ? '/' : i.path}: ${i.message} '
                '${_ui.dim('[${i.code}]')}',
          if (e.errorCode != null)
            '         ${e.message} ${_ui.dim('[${e.errorCode}]')}',
        ];
      case BatchStatus.unreadable:
        return ['$tag ${_ui.bad('unreadable')} ${e.message}'];
      case BatchStatus.failed:
        return [
          '$tag ${_ui.bad('failed')}  $label ${_ui.dim('[${e.errorCode}]')} '
              '${(e.message ?? '').split('\n').first}',
        ];
      case BatchStatus.notRun:
        return const [];
    }
  }

  void _printSummary(BatchReport r, String? reportPath) {
    final parts = [
      for (final s in BatchStatus.values)
        if (r.count(s) > 0) '${r.count(s)} ${s.name}',
    ];
    final line =
        '${r.entries.length} specs: ${parts.isEmpty ? 'nothing to do' : parts.join(', ')} '
        '(${_duration(r.seconds)})';
    if (_ui.interactive) {
      final bad =
          r.sidecarError != null ||
          r.count(BatchStatus.invalid) +
                  r.count(BatchStatus.failed) +
                  r.count(BatchStatus.unreadable) >
              0;
      _out.writeln(
        _ui.box(bad ? 'Batch finished with problems' : 'Batch finished', [
          for (final s in BatchStatus.values)
            if (r.count(s) > 0)
              '${_statusPaint(s, s.name.padRight(10))}${r.count(s)}',
          if (r.entries.isEmpty || parts.isEmpty) 'nothing to do',
          _ui.dim('time      ${_duration(r.seconds)}'),
          if (reportPath != null) _ui.dim('report    $reportPath'),
        ]),
      );
    } else {
      _out.writeln(line);
    }
    if (r.sidecarError != null) _err.writeln(r.sidecarError);
    if (!_ui.interactive && reportPath != null) {
      _out.writeln('Report: $reportPath');
    }
  }

  String _statusPaint(BatchStatus s, String text) => switch (s) {
    BatchStatus.built => _ui.ok(text),
    BatchStatus.skipped => _ui.warn(text),
    _ => _ui.bad(text),
  };

  static String _duration(double seconds) {
    final s = seconds.round();
    if (s < 60) return '${s}s';
    return s < 3600
        ? '${s ~/ 60}m${s % 60}s'
        : '${s ~/ 3600}h${(s % 3600) ~/ 60}m';
  }
}
