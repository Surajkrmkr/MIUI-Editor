import 'dart:io';
import 'package:image/image.dart' as img;

/// Service for image processing operations
class ImageProcessingService {
  /// Target resolution for wallpapers
  static const int targetWidth = 1080;
  static const int targetHeight = 2340;
  static const double aspectRatio = 6.0 / 13.0; // 0.4615

  /// Crop and resize image to 1080x2340 (6:13 aspect ratio)
  Future<File> cropAndResize({
    required File inputFile,
    required String outputPath,
  }) async {
    // Read the image
    final bytes = await inputFile.readAsBytes();
    img.Image? image = img.decodeImage(bytes);

    if (image == null) {
      throw Exception('Failed to decode image');
    }

    // Calculate crop dimensions to maintain aspect ratio
    final imageAspectRatio = image.width / image.height;
    
    int cropWidth;
    int cropHeight;
    int cropX = 0;
    int cropY = 0;

    if (imageAspectRatio > aspectRatio) {
      // Image is wider, crop width
      cropHeight = image.height;
      cropWidth = (cropHeight * aspectRatio).round();
      cropX = ((image.width - cropWidth) / 2).round();
    } else {
      // Image is taller, crop height
      cropWidth = image.width;
      cropHeight = (cropWidth / aspectRatio).round();
      cropY = ((image.height - cropHeight) / 2).round();
    }

    // Crop the image
    img.Image cropped = img.copyCrop(
      image,
      x: cropX,
      y: cropY,
      width: cropWidth,
      height: cropHeight,
    );

    // Resize to target resolution
    img.Image resized = img.copyResize(
      cropped,
      width: targetWidth,
      height: targetHeight,
      interpolation: img.Interpolation.cubic,
    );

    // Encode as JPEG with high quality
    final jpegBytes = img.encodeJpg(resized, quality: 95);

    // Save to file
    final outputFile = File(outputPath);
    await outputFile.writeAsBytes(jpegBytes);

    return outputFile;
  }

  /// Get image dimensions
  Future<ImageDimensions> getImageDimensions(File imageFile) async {
    final bytes = await imageFile.readAsBytes();
    img.Image? image = img.decodeImage(bytes);

    if (image == null) {
      throw Exception('Failed to decode image');
    }

    return ImageDimensions(
      width: image.width,
      height: image.height,
    );
  }

  /// Check if image needs cropping
  Future<bool> needsCropping(File imageFile) async {
    final dimensions = await getImageDimensions(imageFile);
    final currentRatio = dimensions.width / dimensions.height;
    
    // Allow small tolerance
    return (currentRatio - aspectRatio).abs() > 0.01;
  }

  /// Get preview of cropped area (for UI display)
  Future<CropPreview> getCropPreview(File imageFile) async {
    final bytes = await imageFile.readAsBytes();
    img.Image? image = img.decodeImage(bytes);

    if (image == null) {
      throw Exception('Failed to decode image');
    }

    final imageAspectRatio = image.width / image.height;
    
    int cropWidth;
    int cropHeight;
    int cropX = 0;
    int cropY = 0;

    if (imageAspectRatio > aspectRatio) {
      cropHeight = image.height;
      cropWidth = (cropHeight * aspectRatio).round();
      cropX = ((image.width - cropWidth) / 2).round();
    } else {
      cropWidth = image.width;
      cropHeight = (cropWidth / aspectRatio).round();
      cropY = ((image.height - cropHeight) / 2).round();
    }

    return CropPreview(
      originalWidth: image.width,
      originalHeight: image.height,
      cropX: cropX,
      cropY: cropY,
      cropWidth: cropWidth,
      cropHeight: cropHeight,
    );
  }
}

class ImageDimensions {
  final int width;
  final int height;

  ImageDimensions({required this.width, required this.height});

  double get aspectRatio => width / height;
}

class CropPreview {
  final int originalWidth;
  final int originalHeight;
  final int cropX;
  final int cropY;
  final int cropWidth;
  final int cropHeight;

  CropPreview({
    required this.originalWidth,
    required this.originalHeight,
    required this.cropX,
    required this.cropY,
    required this.cropWidth,
    required this.cropHeight,
  });
}
