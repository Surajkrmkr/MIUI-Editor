import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../../domain/entities/deployment_config.dart';

class DeploymentService {
  Process? _process;

  /// Starts the Python script and returns a stream of output lines.
  /// stdout lines are emitted as-is; stderr lines are prefixed with [ERR].
  Stream<String> start(DeploymentConfig config) {
    final controller = StreamController<String>();

    Process.start(
      'python3',
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

      process.stdout
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen(controller.add, onDone: () {});

      process.stderr
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen(
            (line) => controller.add('[ERR] $line'),
            onDone: () {},
          );

      process.exitCode.then((code) {
        controller.add('--- Process exited with code $code ---');
        controller.close();
        _process = null;
      });
    }).catchError((Object e) {
      controller.add('[FATAL] Failed to start process: $e');
      controller.close();
    });

    return controller.stream;
  }

  void stop() {
    _process?.kill();
    _process = null;
  }
}
