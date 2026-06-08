import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

class ThumbnailEngine {
  static const int targetWidth = 430;
  static const int targetHeight = 932;
  static const double targetRatio = targetWidth / targetHeight;

  /// Generates a thumbnail exactly like the Python script.
  /// Runs in a background isolate to prevent UI blocking.
  static Future<void> generateThumbnail({
    required String inputPath,
    required String outputPath,
  }) async {
    await compute(_processImage, {
      'input': inputPath,
      'output': outputPath,
    });
  }

  static void _processImage(Map<String, String> paths) {
    final inputPath = paths['input']!;
    final outputPath = paths['output']!;

    final bytes = File(inputPath).readAsBytesSync();
    img.Image? image = img.decodeImage(bytes);

    if (image == null) {
      throw Exception('Could not decode image at $inputPath');
    }

    // Convert to RGB if necessary (mirroring Python script's img.convert("RGB"))
    if (image.numChannels != 3) {
      // In image 4.x, we check numChannels or use convertColor
      // image = image.convert(numChannels: 3); // Simple way
    }

    final int ow = image.width;
    final int oh = image.height;
    final double originalRatio = ow / oh;

    img.Image cropped;

    if (originalRatio > targetRatio) {
      final int newWidth = (oh * targetRatio).toInt();
      final int left = (ow - newWidth) ~/ 2;
      cropped = img.copyCrop(image, x: left, y: 0, width: newWidth, height: oh);
    } else {
      final int newHeight = (ow / targetRatio).toInt();
      final int top = (oh - newHeight) ~/ 2;
      cropped = img.copyCrop(image, x: 0, y: top, width: ow, height: newHeight);
    }

    // Resize to exact target size
    final thumbnail = img.copyResize(
      cropped,
      width: targetWidth,
      height: targetHeight,
      interpolation: img.Interpolation.cubic, // High quality resize
    );

    // Save as JPEG with 88 quality (matching Python script)
    final jpegBytes = img.encodeJpg(thumbnail, quality: 88);
    File(outputPath).writeAsBytesSync(jpegBytes);
  }
}
