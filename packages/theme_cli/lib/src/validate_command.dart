import 'dart:convert';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:path/path.dart' as p;
import 'package:theme_core/theme_core.dart';

import 'exit_codes.dart';
import 'fonts_dirs.dart';
import 'root_config.dart';
import 'root_option.dart';

/// `theme validate <spec>`: checks a theme spec without building anything.
class ValidateCommand extends Command<int> {
  ValidateCommand(this._out, this._err, this._cwd) {
    argParser
      ..addFlag(
        'json',
        negatable: false,
        help: 'Print one JSON document instead of text.',
      )
      ..addFlag(
        'strict',
        negatable: false,
        help: 'Exit with 1 on warnings too.',
      )
      ..addFlag(
        'contrast',
        defaultsTo: true,
        help: 'Decode the wallpaper to check text legibility.',
      )
      ..addFlag(
        'design',
        negatable: false,
        help:
            'Also warn about a bare lockscreen: few elements, no clock, '
            'no live information, no decoration, one font size.',
      )
      ..addOption(
        'assets-root',
        valueHelp: 'dir',
        help:
            'Repo root holding assets/icons. Defaults to \$THEME_ASSETS_ROOT, '
            'then the nearest parent of the spec or cwd that has assets/icons.',
      );
    addFontsDirOption(argParser);
    addRootOption(argParser);
  }

  final StringSink _out, _err;
  final Directory _cwd;

  @override
  String get name => 'validate';

  @override
  String get description => 'Check a theme spec and report every problem.';

  @override
  String get invocation => 'theme validate <spec.json> [options]';

  @override
  Future<int> run() async {
    final rest = argResults!.rest;
    if (rest.length != 1) {
      usageException('Expected exactly one spec file, got ${rest.length}.');
    }
    final json = argResults!['json'] as bool;
    final specPath = p.normalize(p.absolute(_cwd.path, rest.single));
    final file = File(specPath);

    final String text;
    try {
      text = await file.readAsString();
    } on FileSystemException catch (e) {
      final message = e.osError?.message ?? e.message;
      if (json) {
        _out.writeln(
          const JsonEncoder.withIndent('  ').convert({
            'command': 'validate',
            'spec': specPath,
            'ok': false,
            'error': {
              'code': 'io.read',
              'message': 'Cannot read $specPath: $message',
            },
          }),
        );
      } else {
        _err.writeln('Cannot read $specPath: $message');
      }
      return ExitCodes.io;
    }

    final options = ValidationOptions(
      baseDir: p.dirname(specPath),
      assetsRoot: _assetsRoot(specPath),
      checkContrast: argResults!['contrast'] as bool,
      checkDesign: argResults!['design'] as bool,
      fontsDirs: fontsDirsOf(argResults!, _cwd),
    );
    final prepare = specPreparer(root: rootOf(argResults!, _cwd));
    Object? decoded;
    try {
      decoded = jsonDecode(text);
    } on FormatException {
      decoded = null;
    }
    final ValidationReport report;
    if (prepare != null && decoded is Map<String, dynamic>) {
      prepare(decoded, options.baseDir);
      report = const SpecValidator().validate(decoded, options);
    } else {
      report = const SpecValidator().validateText(text, options);
    }

    if (json) {
      _out.writeln(
        const JsonEncoder.withIndent('  ').convert({
          'command': 'validate',
          'spec': specPath,
          ...report.toJson(),
        }),
      );
    } else {
      _printText(report, specPath);
    }

    final strict = argResults!['strict'] as bool;
    final failed = !report.ok || (strict && report.warningCount > 0);
    return failed ? ExitCodes.invalid : ExitCodes.ok;
  }

  String? _assetsRoot(String specPath) {
    final explicit =
        argResults!['assets-root'] as String? ??
        Platform.environment['THEME_ASSETS_ROOT'];
    if (explicit != null && explicit.isNotEmpty) {
      return p.normalize(p.absolute(_cwd.path, explicit));
    }
    for (final start in [p.dirname(specPath), _cwd.path]) {
      var dir = start;
      while (true) {
        if (Directory(p.join(dir, 'assets', 'icons', 'u1')).existsSync()) {
          return dir;
        }
        final parent = p.dirname(dir);
        if (parent == dir) break;
        dir = parent;
      }
    }
    return null;
  }

  void _printText(ValidationReport report, String specPath) {
    for (final i in report.issues) {
      final sev = i.severity == IssueSeverity.error ? 'error  ' : 'warning';
      _out.writeln(
        '$sev ${i.path.isEmpty ? '/' : i.path}: ${i.message} [${i.code}]',
      );
      if (i.hint != null) _out.writeln('        ${i.hint}');
    }
    final summary =
        '${report.errorCount} error(s), ${report.warningCount} warning(s)';
    _out.writeln(
      report.ok
          ? '${p.basename(specPath)}: valid ($summary)'
          : '${p.basename(specPath)}: invalid ($summary)',
    );
  }
}
