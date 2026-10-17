import 'dart:convert';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:path/path.dart' as p;
import 'package:theme_core/theme_core.dart';

import 'exit_codes.dart';

/// Writes `<outDir>/<workspace name>.preview.png` and returns its path.
String writeHomePreview(String workspace, String outDir, {int width = 540}) {
  final bytes = HomePreview.compose(workspace, width: width);
  final path = p.join(outDir, '${p.basename(workspace)}.preview.png');
  File(path)
    ..createSync(recursive: true)
    ..writeAsBytesSync(bytes);
  return path;
}

/// `theme preview <workspace>...`: draws a home-screen image from theme
/// folders that `theme build` already produced. Needs no Flutter.
class PreviewCommand extends Command<int> {
  PreviewCommand(this._out, this._err, this._cwd) {
    argParser
      ..addOption(
        'out',
        abbr: 'o',
        valueHelp: 'dir',
        help: 'Where to write the images. Defaults to next to each workspace.',
      )
      ..addOption(
        'width',
        defaultsTo: '540',
        valueHelp: 'px',
        help: 'Image width; the height follows a 1080x2340 screen.',
      )
      ..addFlag('json', negatable: false, help: 'Print JSON instead of text.');
  }

  final StringSink _out, _err;
  final Directory _cwd;

  @override
  String get name => 'preview';

  @override
  String get description =>
      'Draw a home-screen preview PNG from built theme folders.';

  @override
  String get invocation => 'theme preview <workspace-dir>... [options]';

  @override
  Future<int> run() async {
    final dirs = argResults!.rest;
    if (dirs.isEmpty) usageException('Give at least one built theme folder.');
    final width = int.tryParse(argResults!['width'] as String);
    if (width == null || width < 64 || width > 2160) {
      usageException('--width must be a number from 64 to 2160.');
    }
    final outOption = argResults!['out'] as String?;

    final results = <Map<String, Object?>>[];
    var code = ExitCodes.ok;
    for (final d in dirs) {
      final workspace = p.normalize(p.absolute(_cwd.path, d));
      final outDir = outOption == null
          ? p.dirname(workspace)
          : p.normalize(p.absolute(_cwd.path, outOption));
      try {
        final path = writeHomePreview(workspace, outDir, width: width);
        results.add({'workspace': workspace, 'ok': true, 'preview': path});
      } on AppException catch (e) {
        code = ExitCodes.io;
        results.add({
          'workspace': workspace,
          'ok': false,
          'error': {'code': 'preview.failed', 'message': e.message},
        });
      }
    }

    if (argResults!['json'] as bool) {
      _out.writeln(
        const JsonEncoder.withIndent('  ').convert({
          'command': 'preview',
          'ok': code == ExitCodes.ok,
          'results': results,
        }),
      );
    } else {
      for (final r in results) {
        if (r['ok'] == true) {
          _out.writeln(r['preview']);
        } else {
          _err.writeln((r['error'] as Map)['message']);
        }
      }
    }
    return code;
  }
}
