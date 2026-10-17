import 'dart:io';

import 'package:args/command_runner.dart';

import 'src/batch_command.dart';
import 'src/build_command.dart';
import 'src/exit_codes.dart';
import 'src/mcp_command.dart';
import 'src/preview_command.dart';
import 'src/schema_command.dart';
import 'src/sidecar.dart';
import 'src/validate_command.dart';

export 'src/exit_codes.dart';
export 'src/sidecar.dart'
    show Sidecar, SidecarOutcome, FlutterSidecar, findProject, sidecarEntry;

/// Runs the `theme` CLI and returns its exit code.
///
/// [out] and [err] default to stdout and stderr; [cwd] resolves relative
/// paths; [sidecar] replaces the Flutter render process and [input] stdin
/// for `theme mcp` (for tests).
Future<int> runCli(
  List<String> args, {
  StringSink? out,
  StringSink? err,
  Directory? cwd,
  Sidecar? sidecar,
  Stream<List<int>>? input,
}) async {
  final o = out ?? stdout;
  final e = err ?? stderr;
  final dir = cwd ?? Directory.current;
  final runner =
      CommandRunner<int>(
          'theme',
          'Validate, build and preview MIUI/HyperOS themes.',
        )
        ..addCommand(ValidateCommand(o, e, dir))
        ..addCommand(BatchCommand(o, e, dir, sidecar))
        ..addCommand(BuildCommand(o, e, dir, sidecar))
        ..addCommand(McpCommand(o, e, dir, sidecar, input ?? stdin))
        ..addCommand(PreviewCommand(o, e, dir))
        ..addCommand(SchemaCommand(o, e, dir));

  try {
    return await runner.run(args) ?? ExitCodes.ok;
  } on UsageException catch (ex) {
    e.writeln(ex);
    return ExitCodes.usage;
  }
}
