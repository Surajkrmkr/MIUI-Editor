import 'dart:convert';
import 'dart:io';

import 'package:args/command_runner.dart';

import 'exit_codes.dart';
import 'fonts_dirs.dart';
import 'mcp/theme_tools.dart';
import 'root_option.dart';
import 'sidecar.dart';
import 'sidecar_options.dart';

/// `theme mcp`: a Model Context Protocol server on stdin/stdout, so an AI
/// agent can validate, build and preview themes by itself.
class McpCommand extends Command<int> {
  McpCommand(this._out, this._err, this._cwd, this._sidecarOverride, this._in) {
    addSidecarOptions(argParser);
    addFontsDirOption(argParser);
    addRootOption(argParser);
  }

  final StringSink _out, _err;
  final Directory _cwd;
  final Sidecar? _sidecarOverride;
  final Stream<List<int>> _in;

  @override
  String get name => 'mcp';

  @override
  String get description =>
      'Serve validate/build/preview tools to an AI agent over MCP (stdio).';

  @override
  Future<int> run() async {
    final args = argResults!;
    final project = projectDirOf(args, _cwd, const []);
    final root = rootOf(args, _cwd);
    final context = ThemeToolContext(
      // With a root, relative paths from the agent land there, not where the
      // client happened to start the server.
      cwd: root == null ? _cwd : Directory(root.path),
      project: project,
      sidecar: _sidecarOverride ?? flutterSidecarOf(args, project, _err),
      fontsDirs: fontsDirsOf(args, _cwd),
      root: root,
    );
    if (project == null) {
      _err.writeln(
        'theme mcp: $noProjectMessage Building will fail until then.',
      );
    }

    final server = themeMcpServer(context, log: _err.writeln);
    await server.serve(
      _in.transform(utf8.decoder).transform(const LineSplitter()),
      (message) => _out.writeln(jsonEncode(message)),
    );
    final out = _out;
    if (out is IOSink) await out.flush();
    return ExitCodes.ok;
  }
}
