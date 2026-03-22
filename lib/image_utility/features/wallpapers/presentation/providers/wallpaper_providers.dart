import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:miui_icon_generator/image_utility/core/config/app_config.dart';
import 'package:miui_icon_generator/image_utility/core/providers/image_source_provider.dart';
import 'package:miui_icon_generator/image_utility/core/providers/image_source_registry.dart';
import 'package:miui_icon_generator/image_utility/features/wallpapers/domain/entities/search_params.dart';
import 'package:miui_icon_generator/image_utility/features/wallpapers/domain/entities/wallpaper.dart';
import 'package:path_provider/path_provider.dart';

// Selected source provider
final selectedSourceProvider = StateProvider<String?>((ref) => null);

// Available sources provider
final availableSourcesProvider =
    FutureProvider<List<ImageSourceProvider>>((ref) async {
  final config = await AppConfig.initialize();
  final registry = ImageSourceRegistry();

  registry.initialize(
    pexelsApiKey: config.pexelsApiKey,
    unsplashApiKey: config.unsplashApiKey,
    pixabayApiKey: config.pixabayApiKey,
  );

  return registry.getAvailableProviders();
});

// Wallpaper state
class WallpaperState {
  final List<Wallpaper> wallpapers;
  final bool isLoading;
  final bool hasMore;
  final int currentPage;
  final String? currentQuery;

  WallpaperState({
    this.wallpapers = const [],
    this.isLoading = false,
    this.hasMore = true,
    this.currentPage = 1,
    this.currentQuery,
  });

  WallpaperState copyWith({
    List<Wallpaper>? wallpapers,
    bool? isLoading,
    bool? hasMore,
    int? currentPage,
    String? currentQuery,
  }) {
    return WallpaperState(
      wallpapers: wallpapers ?? this.wallpapers,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
      currentQuery: currentQuery ?? this.currentQuery,
    );
  }
}

// Wallpaper notifier
class WallpaperNotifier extends StateNotifier<AsyncValue<List<Wallpaper>>> {
  WallpaperNotifier(this.ref) : super(const AsyncValue.loading()) {
    initializeProviders();
  }

  final Ref ref;
  final ImageSourceRegistry _registry = ImageSourceRegistry();
  int _currentPage = 1;
  String? _currentQuery;
  bool _hasMore = true;
  bool _isLoadingMore = false;

  Future<void> initializeProviders() async {
    final config = await AppConfig.initialize();

    _registry.initialize(
      pexelsApiKey: config.pexelsApiKey,
      unsplashApiKey: config.unsplashApiKey,
      pixabayApiKey: config.pixabayApiKey,
    );

    // Load initial curated images
    await loadCurated();
  }

  Future<void> loadCurated() async {
    state = const AsyncValue.loading();
    _currentPage = 1;
    _currentQuery = null;
    _hasMore = true;

    try {
      final selectedSource = ref.read(selectedSourceProvider);
      final wallpapers = await _fetchWallpapers(
        query: null,
        page: _currentPage,
        sourceId: selectedSource,
      );

      state = AsyncValue.data(wallpapers);
    } catch (error, stack) {
      state = AsyncValue.error(error, stack);
    }
  }

  Future<void> searchWallpapers(String query) async {
    state = const AsyncValue.loading();
    _currentPage = 1;
    _currentQuery = query;
    _hasMore = true;

    try {
      final selectedSource = ref.read(selectedSourceProvider);
      final wallpapers = await _fetchWallpapers(
        query: query,
        page: _currentPage,
        sourceId: selectedSource,
      );

      state = AsyncValue.data(wallpapers);
    } catch (error, stack) {
      state = AsyncValue.error(error, stack);
    }
  }

  Future<void> loadMore() async {
    if (_isLoadingMore || !_hasMore) return;

    _isLoadingMore = true;
    _currentPage++;

    try {
      final selectedSource = ref.read(selectedSourceProvider);
      final newWallpapers = await _fetchWallpapers(
        query: _currentQuery,
        page: _currentPage,
        sourceId: selectedSource,
      );

      if (newWallpapers.isEmpty) {
        _hasMore = false;
      } else {
        state.whenData((currentWallpapers) {
          state = AsyncValue.data([...currentWallpapers, ...newWallpapers]);
        });
      }
    } catch (error) {
      // Silently fail for pagination
      _currentPage--;
    } finally {
      _isLoadingMore = false;
    }
  }

  Future<List<Wallpaper>> _fetchWallpapers({
    String? query,
    required int page,
    String? sourceId,
  }) async {
    final params = SearchParams(page: page, perPage: 20);

    if (sourceId != null) {
      // Fetch from specific source
      final provider = _registry.getProvider(sourceId);
      if (provider == null) {
        throw Exception('Provider not configured: $sourceId');
      }

      if (query != null && query.isNotEmpty) {
        return await provider.searchImages(query: query, params: params);
      } else {
        return await provider.getCuratedImages(params: params);
      }
    } else {
      // Fetch from all sources
      final providers = _registry.getAvailableProviders();
      final List<Wallpaper> allWallpapers = [];

      for (final provider in providers) {
        try {
          final wallpapers = query != null && query.isNotEmpty
              ? await provider.searchImages(query: query, params: params)
              : await provider.getCuratedImages(params: params);
          allWallpapers.addAll(wallpapers);
        } catch (e) {
          // Continue with other providers if one fails
          continue;
        }
      }

      // Shuffle to mix sources
      allWallpapers.shuffle();
      return allWallpapers;
    }
  }

  Future<void> downloadWallpaper(Wallpaper wallpaper) async {
    final provider = _registry.getProvider(wallpaper.source);
    if (provider == null) {
      throw Exception('Provider not found: ${wallpaper.source}');
    }

    final config = await AppConfig.initialize();
    final appDir = await getApplicationDocumentsDirectory();
    final downloadPath = config.downloadPath ?? '${appDir.path}/wallpapers';

    await provider.downloadImage(
      wallpaper: wallpaper,
      savePath: downloadPath,
    );
  }
}

// Wallpaper notifier provider
final wallpaperNotifierProvider =
    StateNotifierProvider<WallpaperNotifier, AsyncValue<List<Wallpaper>>>(
        (ref) {
  return WallpaperNotifier(ref);
});

// Get wallpaper by ID provider
final wallpaperByIdProvider =
    FutureProvider.family<Wallpaper?, ({String id, String source})>(
  (ref, params) async {
    final registry = ImageSourceRegistry();
    final config = await AppConfig.initialize();

    registry.initialize(
      pexelsApiKey: config.pexelsApiKey,
      unsplashApiKey: config.unsplashApiKey,
      pixabayApiKey: config.pixabayApiKey,
    );

    final provider = registry.getProvider(params.source);
    if (provider == null) return null;

    return await provider.getImageById(params.id);
  },
);
