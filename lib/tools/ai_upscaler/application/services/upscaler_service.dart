import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;
import '../../domain/models/upscale_options.dart';

class UpscalerService {
  static String? _resolvedBinary;
  static String? _resolvedModels;

  static final List<String> _binaryCandidates = [
    p.join(Directory.current.path, 'bin', 'realesrgan-ncnn-vulkan.exe'),
    p.join(Directory.current.path, 'realesrgan-ncnn-vulkan.exe'),
    p.join(Directory.current.path, 'bin', 'upscayl-bin.exe'),
    p.join(Directory.current.path, 'upscayl-bin.exe'),
    p.join(Directory.current.path, 'bin', 'realesrgan-ncnn-vulkan'),
    p.join(Directory.current.path, 'realesrgan-ncnn-vulkan'),
    if (Platform.isWindows) ...[
       'C:\\Users\\Piyush KPV\\Downloads\\upscayl-main\\resources\\win\\bin\\upscayl-bin.exe',
       'C:\\Program Files\\Upscayl\\resources\\bin\\upscayl-bin.exe',
       p.join(Platform.environment['APPDATA'] ?? '', 'Upscayl', 'resources', 'bin', 'upscayl-bin.exe'),
       'C:\\Users\\Piyush KPV\\Downloads\\upscayl-main\\resources\\bin\\realesrgan-ncnn-vulkan.exe',
       'C:\\Program Files\\Upscayl\\resources\\bin\\realesrgan-ncnn-vulkan.exe',
       p.join(Platform.environment['APPDATA'] ?? '', 'Upscayl', 'resources', 'bin', 'realesrgan-ncnn-vulkan.exe'),
    ],
    if (Platform.isLinux) ...[
      '/usr/bin/realesrgan-ncnn-vulkan',
      '/usr/local/bin/realesrgan-ncnn-vulkan',
      '/usr/bin/upscayl-bin',
      p.join(Platform.environment['HOME'] ?? '', '.local', 'bin', 'realesrgan-ncnn-vulkan'),
      p.join(Platform.environment['HOME'] ?? '', '.local', 'bin', 'upscayl-bin'),
    ],
  ];

  static final List<String> _modelsCandidates = [
    p.join(Directory.current.path, 'models'),
    if (Platform.isWindows) ...[
      'C:\\Users\\Piyush KPV\\Downloads\\upscayl-main\\resources\\models',
      'C:\\Program Files\\Upscayl\\resources\\models',
      p.join(Platform.environment['APPDATA'] ?? '', 'Upscayl', 'resources', 'models'),
    ],
  ];

  static Future<bool> isBinaryInstalled({String? customPath, String? customModelsPath}) async {
    if (customPath != null && File(customPath).existsSync()) {
      if (await _verifyBinary(customPath)) {
        _resolvedBinary = customPath;
        return true;
      }
    }
    
    if (_resolvedBinary != null && File(_resolvedBinary!).existsSync()) return true;

    // Try to find models first if not found, to help binary discovery
    if (_resolvedModels == null) {
      getModelsPath(customPath: customModelsPath);
    }

    // Check candidates
    for (final path in _binaryCandidates) {
      if (File(path).existsSync()) {
        if (await _verifyBinary(path)) {
          _resolvedBinary = path;
          return true;
        }
      }
    }

    // Try to derive from models path if we have it
    final mPath = _resolvedModels;
    if (mPath != null) {
      final possibleNames = Platform.isWindows ? ['upscayl-bin.exe', 'realesrgan-ncnn-vulkan.exe'] : ['upscayl-bin', 'realesrgan-ncnn-vulkan'];
      for (final name in possibleNames) {
        final derivedBinary = p.join(p.dirname(mPath), 'bin', name);
        if (File(derivedBinary).existsSync() && await _verifyBinary(derivedBinary)) {
          _resolvedBinary = derivedBinary;
          return true;
        }
        final derivedBinary2 = p.join(p.dirname(mPath), name);
        if (File(derivedBinary2).existsSync() && await _verifyBinary(derivedBinary2)) {
          _resolvedBinary = derivedBinary2;
          return true;
        }
      }
    }

    // Try system path
    final systemCommands = Platform.isWindows ? ['upscayl-bin.exe', 'realesrgan-ncnn-vulkan.exe'] : ['upscayl-bin', 'realesrgan-ncnn-vulkan'];
    for (final cmd in systemCommands) {
      try {
        final r = await Process.run(cmd, ['-h']);
        if (r.exitCode == 0) {
          _resolvedBinary = cmd;
          return true;
        }
      } catch (_) {}
    }

    return false;
  }

  static Future<bool> _verifyBinary(String path) async {
    try {
      final r = await Process.run(path, ['-h']);
      // Some versions return 1 for -h, but as long as it executes and shows help it's fine
      // We check if it produced some output or at least didn't throw a ProcessException
      return r.stderr.toString().contains('Usage') || r.stdout.toString().contains('Usage');
    } catch (_) {
      return false;
    }
  }

  static String get binaryPath => _resolvedBinary ?? (Platform.isWindows ? 'realesrgan-ncnn-vulkan.exe' : 'realesrgan-ncnn-vulkan');

  static String getModelsPath({String? customPath}) {
    if (customPath != null && Directory(customPath).existsSync()) {
      return _resolvedModels = p.absolute(customPath);
    }
    if (_resolvedModels != null && Directory(_resolvedModels!).existsSync()) {
      return _resolvedModels!;
    }
    for (final path in _modelsCandidates) {
      if (Directory(path).existsSync()) {
        return _resolvedModels = p.absolute(path);
      }
    }
    
    // Try to derive from binary path
    if (_resolvedBinary != null && !['realesrgan-ncnn-vulkan', 'realesrgan-ncnn-vulkan.exe', 'upscayl-bin', 'upscayl-bin.exe'].contains(_resolvedBinary!)) {
      final binaryDir = p.dirname(_resolvedBinary!);
      final derivedModels = p.join(p.dirname(binaryDir), 'models');
      if (Directory(derivedModels).existsSync()) {
        return _resolvedModels = p.absolute(derivedModels);
      }
      final derivedModels2 = p.join(binaryDir, 'models');
      if (Directory(derivedModels2).existsSync()) {
        return _resolvedModels = p.absolute(derivedModels2);
      }
    }
    
    return p.absolute('models');
  }

  /// Runs the upscaler for a single file.
  static Stream<double> upscale({
    required String input,
    required String output,
    required UpscalePreset preset,
    required UpscaleScale scale,
    required OutputFormat format,
    String? modelsDir,
    void Function(String log)? onLog,
  }) async* {
    final mPathFull = modelsDir ?? getModelsPath();
    final isAbsoluteBinary = File(binaryPath).isAbsolute;
    final binaryDir = isAbsoluteBinary ? p.dirname(binaryPath) : null;
    
    String mPath = mPathFull;
    if (isAbsoluteBinary && Directory(mPath).isAbsolute) {
      try {
        // Many ncnn binaries have a bug where they prepend their own path to absolute paths
        // Converting to a relative path from the binary's location avoids this.
        mPath = p.relative(mPath, from: binaryDir);
      } catch (_) {}
    }

    // Pass model name directly from preset
    String modelName = preset.modelName;

    final args = [
      '-i', input,
      '-o', output,
      '-n', modelName,
      '-s', scale.value.toString(),
      '-m', mPath,
      '-f', format.label.toLowerCase(),
      '-v',
    ];

    onLog?.call('Launching: $binaryPath ${args.join(' ')}');
    if (binaryDir != null) {
      onLog?.call('Working Directory: $binaryDir');
    }

    final process = await Process.start(
      binaryPath, 
      args, 
      workingDirectory: binaryDir,
    );

    final stderrQueue = process.stderr
        .transform(utf8.decoder)
        .transform(const LineSplitter());

    final stdoutQueue = process.stdout
        .transform(utf8.decoder)
        .transform(const LineSplitter());

    stdoutQueue.listen((line) => onLog?.call(line));

    double lastProgress = 0;

    await for (final line in stderrQueue) {
      onLog?.call(line);
      if (line.contains('%')) {
        final match = RegExp(r'(\d+\.\d+)%').firstMatch(line);
        if (match != null) {
          final progress = double.tryParse(match.group(1)!) ?? 0;
          if (progress > lastProgress) {
            lastProgress = progress;
            yield progress / 100.0;
          }
        }
      }
    }

    final exitCode = await process.exitCode;
    if (exitCode != 0) {
      throw Exception('Upscaler failed with exit code $exitCode');
    }
    
    yield 1.0;
  }
}
