import 'package:miui_icon_generator/image_utility/features/wallpapers/domain/entities/wallpaper.dart';
import 'package:miui_icon_generator/image_utility/features/wallpapers/domain/entities/search_params.dart';

/// Abstract interface for all image sources (Pexels, Unsplash, Pixabay, Adobe Firefly, etc.)
abstract class ImageSourceProvider {
  /// Unique identifier for the source
  String get sourceId;

  /// Display name for the source
  String get sourceName;

  /// Search for images
  Future<List<Wallpaper>> searchImages({
    required String query,
    SearchParams? params,
  });

  /// Get curated/featured images
  Future<List<Wallpaper>> getCuratedImages({
    SearchParams? params,
  });

  /// Get image by ID
  Future<Wallpaper?> getImageById(String id);

  /// Download image and track attribution
  Future<String> downloadImage({
    required Wallpaper wallpaper,
    required String savePath,
  });

  /// Check if API key is configured
  bool isConfigured();
}
