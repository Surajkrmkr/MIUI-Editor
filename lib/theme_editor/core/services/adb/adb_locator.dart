import 'dart:async';
import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'adb_models.dart';
import 'adb_process.dart';

/// Resolves a working adb binary on macOS and Windows.
class AdbLocator {
  static const _macZipUrl =
      'https://dl.google.com/android/repository/platform-tools-latest-darwin.zip';
  static const _winZipUrl =
      'https://dl.google.com/android/repository/platform-tools-latest-windows.zip';

  String? _cached;

  String? get cachedPath => _cached;

  static String get exeName => Platform.isWindows ? 'adb.exe' : 'adb';

  /// `<app support>/platform-tools`, where downloaded adb lives.
  Future<String> managedDir() async =>
      p.join((await getApplicationSupportDirectory()).path, 'platform-tools');

  void clearCache() => _cached = null;

  /// Resolves adb in order: user path, downloaded, PATH, common SDK locations.
  Future<AdbResult<String>> locate({
    String? userPath,
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh && _cached != null) {
      return AdbResult.success(AdbStep.locate, _cached!);
    }

    final tried = <String>[];
    final user = userPath?.trim() ?? '';
    if (user.isNotEmpty) {
      final candidate = _normalizeUserPath(user);
      final r = await verify(candidate);
      if (r.ok) return _cache(candidate);
      tried.add('$candidate (configured path: ${r.message})');
    }

    final candidates = <String>[
      p.join(await managedDir(), exeName),
      ...await _fromPath(),
      ..._commonLocations(),
    ];
    for (final c in candidates) {
      if (tried.any((t) => t.startsWith(c))) continue;
      if (!File(c).existsSync()) continue;
      final r = await verify(c);
      if (r.ok) return _cache(c);
      tried.add('$c (${r.message})');
    }

    return AdbResult.failure(
      AdbStep.locate,
      'ADB not found. Set its path in ADB settings or click "Download ADB".',
      stderr: tried.isEmpty ? '' : 'Rejected:\n${tried.join('\n')}',
    );
  }

  /// Runs `adb version` against [adbPath].
  Future<AdbResult<String>> verify(String adbPath) async {
    if (!File(adbPath).existsSync()) {
      return AdbResult.failure(AdbStep.locate, 'File does not exist');
    }
    final out = await runProcess(adbPath, const ['version']);
    if (out.ok && out.stdout.contains('Android Debug Bridge')) {
      return AdbResult.success(
        AdbStep.locate,
        out.stdout.trim(),
        stdout: out.stdout,
      );
    }
    return AdbResult.failure(
      AdbStep.locate,
      'Not a working adb binary',
      stdout: out.stdout,
      stderr: out.stderr,
    );
  }

  /// Downloads Google's platform-tools into the app support directory.
  ///
  /// [onProgress] receives 0..1, or null when the size is unknown.
  Future<AdbResult<String>> download({
    void Function(double? progress)? onProgress,
  }) async {
    if (!Platform.isMacOS && !Platform.isWindows) {
      return AdbResult.failure(
        AdbStep.download,
        'Automatic download supports macOS and Windows only',
      );
    }
    final supportDir = (await getApplicationSupportDirectory()).path;
    final zipPath = p.join(supportDir, 'platform-tools-download.zip');
    final targetDir = await managedDir();
    final client = http.Client();

    try {
      await Directory(supportDir).create(recursive: true);
      final url = Platform.isMacOS ? _macZipUrl : _winZipUrl;
      final response = await client
          .send(http.Request('GET', Uri.parse(url)))
          .timeout(const Duration(seconds: 30));
      if (response.statusCode != 200) {
        return AdbResult.failure(
          AdbStep.download,
          'Download failed (HTTP ${response.statusCode})',
        );
      }

      final total = response.contentLength;
      var received = 0;
      final sink = File(zipPath).openWrite();
      try {
        await for (final chunk in response.stream.timeout(
          const Duration(seconds: 60),
        )) {
          sink.add(chunk);
          received += chunk.length;
          onProgress?.call(
            total == null || total == 0 ? null : received / total,
          );
        }
      } finally {
        await sink.close();
      }

      final existing = Directory(targetDir);
      if (existing.existsSync()) {
        try {
          await existing.delete(recursive: true);
        } on FileSystemException catch (e) {
          return AdbResult.failure(
            AdbStep.download,
            'Could not replace the existing platform-tools folder. '
            'Stop the running adb server (Restart ADB server) and try again.',
            stderr: e.toString(),
          );
        }
      }

      // The zip contains a top-level "platform-tools/" folder; keep it intact
      // so adb.exe stays next to AdbWinApi.dll / AdbWinUsbApi.dll.
      await extractFileToDisk(zipPath, supportDir);

      final adbPath = p.join(targetDir, exeName);
      if (!File(adbPath).existsSync()) {
        return AdbResult.failure(
          AdbStep.download,
          'adb was not found in the downloaded archive',
        );
      }
      if (Platform.isMacOS) {
        final chmod = await runProcess('/bin/chmod', ['+x', adbPath]);
        if (!chmod.ok) {
          return AdbResult.failure(
            AdbStep.download,
            'chmod +x failed',
            stdout: chmod.stdout,
            stderr: chmod.stderr,
          );
        }
      }

      final v = await verify(adbPath);
      if (!v.ok) {
        return AdbResult.failure(
          AdbStep.download,
          'Downloaded adb did not run: ${v.message}',
          stdout: v.stdout,
          stderr: v.stderr,
        );
      }
      _cached = adbPath;
      return AdbResult.success(AdbStep.download, adbPath, stdout: v.stdout);
    } on Object catch (e) {
      return AdbResult.failure(
        AdbStep.download,
        'Download failed',
        stderr: e.toString(),
      );
    } finally {
      client.close();
      final zip = File(zipPath);
      if (zip.existsSync()) {
        try {
          await zip.delete();
        } on FileSystemException {
          // Leftover temp zip is harmless.
        }
      }
    }
  }

  AdbResult<String> _cache(String path) {
    _cached = path;
    return AdbResult.success(AdbStep.locate, path);
  }

  /// Accepts either the binary itself or the folder that contains it.
  String _normalizeUserPath(String input) {
    final path = p.normalize(input);
    if (Directory(path).existsSync()) return p.join(path, exeName);
    return path;
  }

  Future<List<String>> _fromPath() async {
    final out = Platform.isWindows
        ? await runProcess('where.exe', const ['adb'])
        : await runProcess('/usr/bin/which', const ['adb']);
    if (!out.ok) return const [];
    return out.stdout
        .split(RegExp(r'\r?\n'))
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();
  }

  List<String> _commonLocations() {
    final env = Platform.environment;
    final result = <String>[];
    for (final key in const ['ANDROID_HOME', 'ANDROID_SDK_ROOT']) {
      final sdk = env[key];
      if (sdk != null && sdk.isNotEmpty) {
        result.add(p.join(sdk, 'platform-tools', exeName));
      }
    }
    if (Platform.isMacOS) {
      final home = env['HOME'];
      if (home != null) {
        result.add(
          p.join(home, 'Library', 'Android', 'sdk', 'platform-tools', exeName),
        );
      }
      // GUI apps don't inherit the shell PATH, so check Homebrew directly.
      result.addAll(const ['/opt/homebrew/bin/adb', '/usr/local/bin/adb']);
    } else if (Platform.isWindows) {
      final local = env['LOCALAPPDATA'];
      if (local != null) {
        result.add(p.join(local, 'Android', 'Sdk', 'platform-tools', exeName));
      }
    }
    return result;
  }
}
