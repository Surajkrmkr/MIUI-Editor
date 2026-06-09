import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

class VTracerService {
  // The python3 executable that has the vtracer module — resolved once.
  static String? _python;
  static String? _resolvedBinary;

  /// Find a standalone vtracer binary in the tool's bin directory.
  static Future<String?> _resolveBinary() async {
    if (_resolvedBinary != null) return _resolvedBinary;

    final candidates = [
      p.join(Directory.current.path, 'lib', 'tools', 'svg_converter', 'bin', 'vtracer.exe'),
      'vtracer.exe',
      'vtracer',
    ];

    for (final path in candidates) {
      try {
        final r = await Process.run(path, ['--version']);
        if (r.exitCode == 0 || r.stdout.toString().contains('vtracer')) {
          return _resolvedBinary = path;
        }
      } catch (_) {}
    }
    return null;
  }

  /// Find a python3 interpreter that can `import vtracer`.
  static Future<String?> _resolvePython() async {
    if (_python != null) return _python;
    
    // Check if we have the binary first, as it's preferred by the user
    if (await _resolveBinary() != null) return null;

    final candidates = [
      'python3',
      '/Library/Frameworks/Python.framework/Versions/3.12/bin/python3',
      '/Library/Frameworks/Python.framework/Versions/3.11/bin/python3',
      '/opt/homebrew/bin/python3',
      '/usr/local/bin/python3',
      '/usr/bin/python3',
    ];

    for (final py in candidates) {
      try {
        final r = await Process.run(py, ['-c', 'import vtracer']);
        if (r.exitCode == 0) return _python = py;
      } catch (_) {}
    }
    return null;
  }

  static Future<bool> isVTracerInstalled() async =>
      await _resolveBinary() != null || await _resolvePython() != null;

  static Future<void> convert({
    required String input,
    required String output,
    required String mode,
    required int colorPrecision,
    required int filterSpeckle,
  }) async {
    final binary = await _resolveBinary();
    if (binary != null) {
      final result = await Process.run(binary, [
        '--input', input,
        '--output', output,
        '--mode', mode,
        '--color_precision', colorPrecision.toString(),
        '--filter_speckle', filterSpeckle.toString(),
      ]);
      if (result.exitCode != 0) {
        throw Exception('vtracer binary error: ${result.stderr}');
      }
      return;
    }

    final py = await _resolvePython();
    if (py == null) throw Exception('vtracer not found (neither binary nor python module)');

    // Call the Python binding directly
    const script =
        'import vtracer, sys; '
        'vtracer.convert_image_to_svg_py('
        'sys.argv[1], sys.argv[2], '
        'mode=sys.argv[3], '
        'color_precision=int(sys.argv[4]), '
        'filter_speckle=int(sys.argv[5]))';

    final result = await Process.run(py, [
      '-c', script,
      input,
      output,
      mode,
      colorPrecision.toString(),
      filterSpeckle.toString(),
    ]);

    if (result.exitCode != 0) {
      throw Exception('vtracer python error: ${result.stderr}');
    }
  }
}
