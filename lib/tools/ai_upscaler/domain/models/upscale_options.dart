import 'package:flutter/material.dart';

enum UpscalePreset {
  standard(
    'Upscayl Standard',
    'Great for most images, balance of speed and quality',
    Icons.auto_awesome_rounded,
    'upscayl-standard-4x',
  ),
  lite(
    'Upscayl Lite',
    'Faster processing for simpler images',
    Icons.bolt_rounded,
    'upscayl-lite-4x',
  ),
  highFidelity(
    'High Fidelity',
    'Best for photos with realistic details',
    Icons.camera_rounded,
  'high-fidelity-4x',
  ),
  remacri(
    'Remacri (Non-Commercial)',
    'Excellent for digital art and paintings',
    Icons.brush_rounded,
    'remacri-4x',
  ),
  ultramix(
    'Ultramix (Non-Commercial)',
    'Enhanced textures for complex scenes',
    Icons.texture_rounded,
    'ultramix-balanced-4x',
  ),
  ultrasharp(
    'Ultrasharp (Non-Commercial)',
    'Perfect for UI, text, and sharp graphics',
    Icons.web_rounded,
    'ultrasharp-4x',
  ),
  digitalArt(
    'Digital Art',
    'Optimized for illustrations and icons',
    Icons.palette_rounded,
    'digital-art-4x',
  );

  final String label;
  final String description;
  final IconData icon;
  final String modelName;

  const UpscalePreset(this.label, this.description, this.icon, this.modelName);
}

enum UpscaleScale {
  x2('2x', 2),
  x4('4x', 4),
  x8('8x', 8);

  final String label;
  final int value;
  const UpscaleScale(this.label, this.value);
}

enum OutputFormat {
  png('PNG'),
  jpg('JPG'),
  webp('WebP');

  final String label;
  const OutputFormat(this.label);
}

enum UpscaleTaskStatus { pending, processing, success, failed }

class UpscaleTask {
  final String id;
  final String inputPath;
  final String outputPath;
  final UpscaleTaskStatus status;
  final double progress;
  final String? errorMessage;
  final List<String> logs;

  UpscaleTask({
    required this.id,
    required this.inputPath,
    required this.outputPath,
    this.status = UpscaleTaskStatus.pending,
    this.progress = 0.0,
    this.errorMessage,
    this.logs = const [],
  });

  UpscaleTask copyWith({
    UpscaleTaskStatus? status,
    double? progress,
    String? errorMessage,
    List<String>? logs,
  }) {
    return UpscaleTask(
      id: id,
      inputPath: inputPath,
      outputPath: outputPath,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      errorMessage: errorMessage ?? this.errorMessage,
      logs: logs ?? this.logs,
    );
  }
}
