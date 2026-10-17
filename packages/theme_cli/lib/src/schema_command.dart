import 'dart:convert';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:path/path.dart' as p;
import 'package:theme_core/theme_core.dart';

import 'exit_codes.dart';

/// `theme schema`: prints the JSON Schema of the theme spec.
class SchemaCommand extends Command<int> {
  SchemaCommand(this._out, this._err, this._cwd) {
    argParser.addOption(
      'out',
      abbr: 'o',
      valueHelp: 'file',
      help: 'Write the schema to this file instead of printing it.',
    );
  }

  final StringSink _out, _err;
  final Directory _cwd;

  @override
  String get name => 'schema';

  @override
  String get description =>
      'Print the JSON Schema of the theme spec, for editors and AI tools.';

  @override
  Future<int> run() async {
    final text =
        '${const JsonEncoder.withIndent('  ').convert(themeSpecSchema())}\n';
    final out = argResults!['out'] as String?;
    if (out == null) {
      _out.write(text);
      return ExitCodes.ok;
    }
    final file = File(p.normalize(p.absolute(_cwd.path, out)));
    try {
      file.parent.createSync(recursive: true);
      file.writeAsStringSync(text);
    } on FileSystemException catch (e) {
      _err.writeln(
        'Cannot write ${file.path}: ${e.osError?.message ?? e.message}',
      );
      return ExitCodes.io;
    }
    _out.writeln(file.path);
    return ExitCodes.ok;
  }
}
