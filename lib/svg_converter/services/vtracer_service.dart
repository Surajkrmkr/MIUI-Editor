import 'dart:io';

class VTracerService {
  // The python3 executable that has the vtracer module — resolved once.
  static String? _python;

  /// Find a python3 interpreter that can `import vtracer`.
  /// Tries bare `python3` first (works when the app is launched from a
  /// terminal with the right PATH), then falls back to common macOS locations.
  static Future<String?> _resolvePython() async {
    if (_python != null) return _python;

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
      await _resolvePython() != null;

  static Future<void> convert({
    required String input,
    required String output,
    required String mode,
    required int colorPrecision,
    required int filterSpeckle,
  }) async {
    final py = await _resolvePython();
    if (py == null) throw Exception('vtracer Python module not found');

    // Call the Python binding directly — no CLI binary needed.
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
      throw Exception('vtracer error: ${result.stderr}');
    }
  }
}
