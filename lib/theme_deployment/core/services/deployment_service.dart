import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../../domain/entities/deployment_config.dart';

class DeploymentService {
  Process? _process;

  /// Starts the Python script and returns a stream of output lines.
  /// stdout lines are emitted as-is; stderr lines are prefixed with [ERR].
  Stream<String> start(DeploymentConfig config, DeploymentMode mode) {
    final controller = StreamController<String>();

    Process.start(
      '/Library/Frameworks/Python.framework/Versions/3.14/bin/python3',
      [
        '${config.scriptsDir}/script_main.py',
        '--base-path', config.basePath,
        '--max-tab', config.maxTab.toString(),
        '--email', config.email,
        '--password', config.password,
        '--description', config.description,
      ],
      runInShell: true,
    ).then((process) {
      _process = process;

      // Safely forward stdout/stderr lines to the controller. Use wrappers
      // that check `controller.isClosed` before adding to avoid the
      // "Cannot add event after closing" error in race conditions where
      // the process exits and the controller is closed while streams still
      // emit data.
      process.stdout
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen((line) {
        if (!controller.isClosed) controller.add(line);
      }, onDone: () {});

      process.stderr
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen((line) {
        if (!controller.isClosed) controller.add('[ERR] $line');
      }, onDone: () {});

      process.exitCode.then((code) {
        if (!controller.isClosed) {
          controller.add('--- Process exited with code $code ---');
          controller.close();
        }
        _process = null;
      });
    }).catchError((Object e) {
      if (!controller.isClosed) {
        controller.add('[FATAL] Failed to start process: $e');
        controller.close();
      }
    });

    return controller.stream;
  }

  void stop() {
    _process?.kill();
    _process = null;
  }
}
