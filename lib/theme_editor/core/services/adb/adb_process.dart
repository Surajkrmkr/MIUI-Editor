import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import 'adb_models.dart';

/// Runs an executable with an argument list (no shell) and a hard timeout.
///
/// The process is killed when [timeout] elapses. Never throws.
Future<ProcessOutput> runProcess(
  String executable,
  List<String> args, {
  Duration timeout = const Duration(seconds: 15),
}) async {
  debugPrint('[adb] \$ $executable ${args.join(' ')}');
  final Process process;
  try {
    process = await Process.start(executable, args);
  } on ProcessException catch (e) {
    debugPrint('[adb] failed to start: ${e.message}');
    return ProcessOutput(exitCode: -1, stdout: '', stderr: e.message);
  }

  const decoder = Utf8Decoder(allowMalformed: true);
  final stdoutF = process.stdout.transform(decoder).join();
  final stderrF = process.stderr.transform(decoder).join();

  var timedOut = false;
  final exitCode = await process.exitCode.timeout(
    timeout,
    onTimeout: () {
      timedOut = true;
      process.kill();
      return -1;
    },
  );

  // A forked adb server can keep the pipes open, so don't wait forever.
  const drain = Duration(seconds: 2);
  final out = await stdoutF.timeout(drain, onTimeout: () => '');
  final err = await stderrF.timeout(drain, onTimeout: () => '');

  final result = ProcessOutput(
    exitCode: exitCode,
    stdout: out,
    stderr: timedOut
        ? '${err.isEmpty ? '' : '$err\n'}Timed out after ${timeout.inSeconds}s'
        : err,
    timedOut: timedOut,
  );
  debugPrint(
    '[adb] exit=$exitCode timedOut=$timedOut\n'
    '[adb] stdout: ${out.trim()}\n[adb] stderr: ${result.stderr.trim()}',
  );
  return result;
}
