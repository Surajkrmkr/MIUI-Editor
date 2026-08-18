import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:path/path.dart' as p;

class VTracerOptions {
  final String mode; // pixel, polygon, spline
  final String colorMode; // color, bw
  final int colorPrecision;
  final int filterSpeckle;
  final int segmentLength;
  final int cornerThreshold;

  VTracerOptions({
    this.mode = 'spline',
    this.colorMode = 'color',
    this.colorPrecision = 6,
    this.filterSpeckle = 4,
    this.segmentLength = 4,
    this.cornerThreshold = 60,
  });
}

class VTracerService {
  Future<String?> traceImage(String inputPath, String outputPath, [VTracerOptions? options]) async {
    final opts = options ?? VTracerOptions();
    
    final args = [
      '--input', inputPath,
      '--output', outputPath,
      '--mode', opts.mode,
      '--colormode', opts.colorMode,
      '--color_precision', opts.colorPrecision.toString(),
      '--filter_speckle', opts.filterSpeckle.toString(),
      '--segment_length', opts.segmentLength.toString(),
      '--corner_threshold', opts.cornerThreshold.toString(),
    ];

    try {
      final vtracerPath = p.join(Directory.current.path, 'bin', 'vtracer.exe');
      final result = await Process.run(vtracerPath, args);
      if (result.exitCode == 0) {
        return outputPath;
      } else {
        // Try fallback to PATH
        final resultFallback = await Process.run('vtracer.exe', args);
        if (resultFallback.exitCode == 0) return outputPath;
        
        debugPrint('VTracer failed: ${result.stderr}');
        return null;
      }
    } catch (e) {
      debugPrint('VTracer error: $e');
      return null;
    }
  }
}

final vtracerServiceProvider = Provider((ref) => VTracerService());
