import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

import '../errors/failures.dart';

/// Replaces the running app with a downloaded release, then relaunches it.
class UpdateInstallerService {
  const UpdateInstallerService();

  static const _windowsExe = 'miui_icon_generator.exe';

  static const _macScript = r'''#!/bin/sh
pid="$1"; src="$2"; dst="$3"
while kill -0 "$pid" 2>/dev/null; do sleep 1; done
rm -rf "$dst.new" "$dst.old"
if ditto "$src" "$dst.new" && mv "$dst" "$dst.old" && mv "$dst.new" "$dst"; then
  rm -rf "$dst.old"
else
  [ -e "$dst" ] || mv "$dst.old" "$dst"
  rm -rf "$dst.new"
fi
xattr -dr com.apple.quarantine "$dst" 2>/dev/null
open "$dst"
''';

  static const _windowsScript =
      r'''param([int]$ProcessId, [string]$Source, [string]$Target, [string]$Exe)
Wait-Process -Id $ProcessId -Timeout 60 -ErrorAction SilentlyContinue
Copy-Item -Path (Join-Path $Source '*') -Destination $Target -Recurse -Force -ErrorAction SilentlyContinue
Start-Process -FilePath (Join-Path $Target $Exe)
''';

  /// Returns a failure when the update cannot be applied; exits the app on success.
  Future<Failure?> install(String zipPath) async {
    if (!kReleaseMode) {
      return const FileFailure(
        'Updates can only be installed in release builds',
      );
    }
    try {
      if (Platform.isMacOS) return await _installMac(zipPath);
      if (Platform.isWindows) return await _installWindows(zipPath);
      return const FileFailure('Updates are not supported on this platform');
    } catch (e) {
      return FileFailure('Update failed: $e');
    }
  }

  Future<Failure?> _installMac(String zipPath) async {
    final bundle = _macBundle();
    if (bundle == null) {
      return const FileFailure('Could not locate the app bundle');
    }
    if (!_isWritable(p.dirname(bundle))) {
      return FileFailure('No permission to modify ${p.dirname(bundle)}');
    }
    final staging = Directory(p.join(p.dirname(zipPath), 'extracted'));
    await staging.create(recursive: true);
    final extract = await Process.run('ditto', [
      '-x',
      '-k',
      zipPath,
      staging.path,
    ]);
    if (extract.exitCode != 0) {
      return FileFailure('Extraction failed: ${extract.stderr}');
    }

    final source = staging
        .listSync()
        .whereType<Directory>()
        .where((d) => d.path.endsWith('.app'))
        .firstOrNull;
    if (source == null) {
      return const FileFailure('Update package has no app bundle');
    }

    final script = File(p.join(p.dirname(zipPath), 'apply_update.sh'));
    await script.writeAsString(_macScript);
    await Process.start('/bin/sh', [
      script.path,
      '$pid',
      source.path,
      bundle,
    ], mode: ProcessStartMode.detached);
    exit(0);
  }

  Future<Failure?> _installWindows(String zipPath) async {
    final target = p.dirname(Platform.resolvedExecutable);
    if (!_isWritable(target)) {
      return FileFailure('No permission to modify $target');
    }
    final staging = Directory(p.join(p.dirname(zipPath), 'extracted'));
    await staging.create(recursive: true);
    final extract = await Process.run('tar', [
      '-xf',
      zipPath,
      '-C',
      staging.path,
    ]);
    if (extract.exitCode != 0) {
      return FileFailure('Extraction failed: ${extract.stderr}');
    }
    if (!File(p.join(staging.path, _windowsExe)).existsSync()) {
      return const FileFailure('Update package is missing the application');
    }

    final script = File(p.join(p.dirname(zipPath), 'apply_update.ps1'));
    await script.writeAsString(_windowsScript);
    await Process.start('powershell', [
      '-NoProfile',
      '-ExecutionPolicy',
      'Bypass',
      '-WindowStyle',
      'Hidden',
      '-File',
      script.path,
      '-ProcessId',
      '$pid',
      '-Source',
      staging.path,
      '-Target',
      target,
      '-Exe',
      _windowsExe,
    ], mode: ProcessStartMode.detached);
    exit(0);
  }

  String? _macBundle() {
    var dir = Platform.resolvedExecutable;
    while (dir != p.dirname(dir)) {
      if (dir.endsWith('.app')) return dir;
      dir = p.dirname(dir);
    }
    return null;
  }

  bool _isWritable(String dir) {
    try {
      final probe = File(p.join(dir, '.miui_update_probe'));
      probe.writeAsStringSync('');
      probe.deleteSync();
      return true;
    } on FileSystemException {
      return false;
    }
  }
}
