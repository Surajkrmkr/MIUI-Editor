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

    final args = mode == DeploymentMode.upload
        ? [
            '${config.scriptsDir}/script_main.py',
            '--base-path', config.basePath,
            '--max-tab', config.maxTab.toString(),
            '--email', config.email,
            '--password', config.password,
            '--description', config.description,
          ]
        : [
            '${config.scriptsDir}/script_update.py',
            '--v2-path', config.v2Path,
            '--max-tab', config.maxTab.toString(),
            '--email', config.email,
            '--password', config.password,
            '--description', config.description,
          ];

    final pythonPath = _resolvePythonPath();

    Process.start(
      pythonPath,
      args,
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

  static String _resolvePythonPath() {
    if (Platform.isMacOS) {
      final candidates = [
        '/Library/Frameworks/Python.framework/Versions/3.14/bin/python3',
        '/Library/Frameworks/Python.framework/Versions/3.13/bin/python3',
        '/Library/Frameworks/Python.framework/Versions/3.12/bin/python3',
        '/opt/homebrew/bin/python3',
        '/usr/local/bin/python3',
        '/usr/bin/python3',
      ];
      for (final candidate in candidates) {
        if (File(candidate).existsSync()) {
          return candidate;
        }
      }
    } else if (Platform.isWindows) {
      final localAppData = Platform.environment['LOCALAPPDATA'];
      final candidates = [
        if (localAppData != null) ...[
          '$localAppData\\Programs\\Python\\Python314\\python.exe',
          '$localAppData\\Programs\\Python\\Python313\\python.exe',
          '$localAppData\\Programs\\Python\\Python312\\python.exe',
        ],
        r'C:\Program Files\Python314\python.exe',
        r'C:\Program Files\Python313\python.exe',
        r'C:\Program Files\Python312\python.exe',
      ];
      for (final candidate in candidates) {
        if (File(candidate).existsSync()) {
          return candidate;
        }
      }
      return 'python';
    }
    return 'python3';
  }
}
