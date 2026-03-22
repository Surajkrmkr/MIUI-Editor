import 'package:miui_icon_generator/image_utility/core/providers/image_source_provider.dart';
import 'package:miui_icon_generator/image_utility/features/wallpapers/data/providers/pexels_provider.dart';
import 'package:miui_icon_generator/image_utility/features/wallpapers/data/providers/unsplash_provider.dart';
import 'package:miui_icon_generator/image_utility/features/wallpapers/data/providers/pixabay_provider.dart';

/// Registry for all available image source providers
/// This makes it easy to add new sources in the future
class ImageSourceRegistry {
  final Map<String, ImageSourceProvider> _providers = {};

  static final ImageSourceRegistry _instance = ImageSourceRegistry._internal();
  factory ImageSourceRegistry() => _instance;
  ImageSourceRegistry._internal();

  /// Initialize providers with API keys
  void initialize({
    String? pexelsApiKey,
    String? unsplashApiKey,
    String? pixabayApiKey,
    // Future: Add Adobe Firefly API key here
    // String? fireflyApiKey,
  }) {
    if (pexelsApiKey != null && pexelsApiKey.isNotEmpty) {
      _providers['pexels'] = PexelsProvider(apiKey: pexelsApiKey);
    }

    if (unsplashApiKey != null && unsplashApiKey.isNotEmpty) {
      _providers['unsplash'] = UnsplashProvider(apiKey: unsplashApiKey);
    }

    if (pixabayApiKey != null && pixabayApiKey.isNotEmpty) {
      _providers['pixabay'] = PixabayProvider(apiKey: pixabayApiKey);
    }

    // Future: Initialize Adobe Firefly provider
    // if (fireflyApiKey != null && fireflyApiKey.isNotEmpty) {
    //   _providers['firefly'] = FireflyProvider(apiKey: fireflyApiKey);
    // }
  }

  /// Get a specific provider by source ID
  ImageSourceProvider? getProvider(String sourceId) {
    return _providers[sourceId];
  }

  /// Get all available (configured) providers
  List<ImageSourceProvider> getAvailableProviders() {
    return _providers.values.toList();
  }

  /// Get all provider IDs
  List<String> getProviderIds() {
    return _providers.keys.toList();
  }

  /// Check if a provider is configured
  bool isProviderConfigured(String sourceId) {
    return _providers.containsKey(sourceId) &&
        _providers[sourceId]!.isConfigured();
  }

  /// Add a custom provider (for future extensibility)
  void addProvider(ImageSourceProvider provider) {
    _providers[provider.sourceId] = provider;
  }

  /// Remove a provider
  void removeProvider(String sourceId) {
    _providers.remove(sourceId);
  }

  /// Clear all providers
  void clear() {
    _providers.clear();
  }
}
