import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:image/image.dart' as img;

class ImageSize {
  const ImageSize(this.width, this.height);
  final int width;
  final int height;
}

class ThumbnailEngine {
  /// JPEG quality for thumbnails: keeps grid thumbnails around 40–70 KB.
  static const int quality = 80;

  /// Reads only the image header, so 4K PNGs don't need a full decode.
  /// Null when the file isn't a supported image.
  static Future<ImageSize?> readSize(String path) async {
    final bytes = await File(path).readAsBytes();
    final decoder = img.findDecoderForData(bytes);
    final info = decoder?.startDecode(bytes);
    if (info == null || info.width == 0 || info.height == 0) return null;
    return ImageSize(info.width, info.height);
  }

  /// Center-crops [inputPath] to [width]:[height], resizes and returns JPEG
  /// bytes. Runs in a background isolate to keep the UI responsive.
  static Future<Uint8List> generate({
    required String inputPath,
    required int width,
    required int height,
  }) {
    return Isolate.run(() => _generate(inputPath, width, height, quality));
  }

  /// The original 430 × 932, quality-88 thumbnail written to a file; still used
  /// by the BuffyWalls importer.
  static Future<void> generateThumbnail({
    required String inputPath,
    required String outputPath,
  }) async {
    final bytes = await Isolate.run(() => _generate(inputPath, 430, 932, 88));
    await File(outputPath).writeAsBytes(bytes);
  }

  static Uint8List _generate(String inputPath, int width, int height, int quality) {
    final image = img.decodeImage(File(inputPath).readAsBytesSync());
    if (image == null) {
      throw Exception('Could not decode image at $inputPath');
    }

    final targetRatio = width / height;
    final ratio = image.width / image.height;
    final img.Image cropped;
    if (ratio > targetRatio) {
      final newWidth = (image.height * targetRatio).round();
      cropped = img.copyCrop(image,
          x: (image.width - newWidth) ~/ 2, y: 0, width: newWidth, height: image.height);
    } else {
      final newHeight = (image.width / targetRatio).round();
      cropped = img.copyCrop(image,
          x: 0, y: (image.height - newHeight) ~/ 2, width: image.width, height: newHeight);
    }

    final thumbnail = img.copyResize(
      cropped,
      width: width,
      height: height,
      interpolation: img.Interpolation.cubic,
    );
    // JPEG has no alpha; flatten transparent PNGs onto black like the app shows them.
    final flattened = thumbnail.numChannels == 4
        ? img.compositeImage(img.Image(width: width, height: height), thumbnail)
        : thumbnail;
    return img.encodeJpg(flattened, quality: quality);
  }
}
