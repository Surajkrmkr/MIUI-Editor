import 'dart:io';
import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_onnxruntime/flutter_onnxruntime.dart';
import 'package:image/image.dart' as img;

/// Input size and normalisation of the salient-object ONNX models rembg
/// publishes; picked from the model's file name.
enum SegmentationModel {
  isnet(1024, [.5, .5, .5], [1, 1, 1]),
  u2net(320, [.485, .456, .406], [.229, .224, .225]),
  birefnet(1024, [.485, .456, .406], [.229, .224, .225], logits: true);

  const SegmentationModel(
    this.size,
    this.mean,
    this.std, {
    this.logits = false,
  });

  final int size;
  final List<double> mean, std;

  /// The output is raw logits and needs a sigmoid.
  final bool logits;

  static SegmentationModel forFile(String path) {
    final name = path.split(Platform.pathSeparator).last.toLowerCase();
    if (name.contains('u2net')) return u2net;
    if (name.contains('birefnet')) return birefnet;
    return isnet;
  }
}

/// The wallpaper with everything but its main subject made transparent, the
/// same pixel size as the source.
class SubjectCutout {
  const SubjectCutout(this.png, this.width, this.height);
  final Uint8List png;
  final int width, height;
}

class SubjectSegmentationService {
  final _ort = OnnxRuntime();
  OrtSession? _session;
  String? _sessionPath;

  Future<SubjectCutout> cutout({
    required String imagePath,
    required String modelPath,
  }) async {
    final model = SegmentationModel.forFile(modelPath);
    final bytes = await File(imagePath).readAsBytes();
    final input = await Isolate.run(() => _toTensor(bytes, model));
    final session = await _open(modelPath);
    final tensor = await OrtValue.fromList(input, [
      1,
      3,
      model.size,
      model.size,
    ]);
    Map<String, OrtValue>? outputs;
    try {
      outputs = await session.run({session.inputNames.first: tensor});
      final raw = await outputs[session.outputNames.first]!.asFlattenedList();
      final mask = Float32List.fromList([
        for (final v in raw) (v as num).toDouble(),
      ]);
      return await Isolate.run(() => _compose(bytes, mask, model));
    } finally {
      await tensor.dispose();
      for (final value in outputs?.values ?? const <OrtValue>[]) {
        await value.dispose();
      }
    }
  }

  Future<OrtSession> _open(String modelPath) async {
    if (_session != null && _sessionPath == modelPath) return _session!;
    await _session?.close();
    _session = await _ort.createSession(modelPath);
    _sessionPath = modelPath;
    return _session!;
  }

  Future<void> dispose() async {
    await _session?.close();
    _session = null;
  }
}

img.Image _decode(Uint8List bytes) {
  final decoded = img.decodeImage(bytes);
  if (decoded == null) throw const FormatException('Unsupported image');
  return img.bakeOrientation(decoded);
}

/// NCHW float input for [model].
Float32List _toTensor(Uint8List bytes, SegmentationModel model) {
  final size = model.size;
  final resized = img.copyResize(
    _decode(bytes),
    width: size,
    height: size,
    interpolation: img.Interpolation.linear,
  );
  final plane = size * size;
  final out = Float32List(3 * plane);
  for (final p in resized) {
    final i = p.y * size + p.x;
    out[i] = (p.r / 255 - model.mean[0]) / model.std[0];
    out[plane + i] = (p.g / 255 - model.mean[1]) / model.std[1];
    out[2 * plane + i] = (p.b / 255 - model.mean[2]) / model.std[2];
  }
  return out;
}

/// Source pixels with the upscaled mask as alpha, encoded as PNG.
SubjectCutout _compose(
  Uint8List bytes,
  Float32List mask,
  SegmentationModel model,
) {
  final size = model.size;
  if (model.logits) {
    for (var i = 0; i < mask.length; i++) {
      mask[i] = 1 / (1 + exp(-mask[i]));
    }
  }
  var lo = double.infinity, hi = -double.infinity;
  for (final v in mask) {
    lo = min(lo, v);
    hi = max(hi, v);
  }
  final range = hi - lo > 1e-6 ? hi - lo : 1.0;

  final source = _decode(bytes).convert(numChannels: 4);
  final sx = size / source.width, sy = size / source.height;
  double at(int x, int y) =>
      (mask[y.clamp(0, size - 1) * size + x.clamp(0, size - 1)] - lo) / range;

  for (final p in source) {
    final fx = (p.x + .5) * sx - .5, fy = (p.y + .5) * sy - .5;
    final x0 = fx.floor(), y0 = fy.floor();
    final tx = fx - x0, ty = fy - y0;
    final m =
        at(x0, y0) * (1 - tx) * (1 - ty) +
        at(x0 + 1, y0) * tx * (1 - ty) +
        at(x0, y0 + 1) * (1 - tx) * ty +
        at(x0 + 1, y0 + 1) * tx * ty;
    // Drop the faint haze around the subject, keep soft edges.
    p.a = (((m - .08) / .84).clamp(0.0, 1.0) * p.maxChannelValue).round();
  }
  return SubjectCutout(img.encodePng(source), source.width, source.height);
}
