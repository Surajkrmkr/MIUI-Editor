import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:miui_icon_generator/image_utility/core/config/app_config.dart';
import 'package:miui_icon_generator/image_utility/core/providers/image_source_registry.dart';
import 'package:miui_icon_generator/image_utility/features/wallpapers/domain/entities/search_params.dart';
import 'package:miui_icon_generator/image_utility/features/wallpapers/domain/entities/wallpaper.dart';
import 'package:miui_icon_generator/image_utility/features/wallpapers/presentation/providers/download_provider.dart';

enum BulkDownloadStep { criteria, selection, processing, complete }

class BulkProcessResult {
  final Wallpaper wallpaper;
  final bool success;
  final String? error;
  final DownloadResult? downloadResult;

  const BulkProcessResult({
    required this.wallpaper,
    required this.success,
    this.error,
    this.downloadResult,
  });
}

class BulkDownloadState {
  final BulkDownloadStep step;
  final int batchSize;
  final List<Wallpaper> wallpapers;
  final Set<int> replacingIndices;
  final bool isFetching;
  final String? fetchError;
  final int processingIndex;
  final List<BulkProcessResult> results;
  final String? processingStatus;
  final Wallpaper? currentWallpaper;

  const BulkDownloadState({
    this.step = BulkDownloadStep.criteria,
    this.batchSize = 25,
    this.wallpapers = const [],
    this.replacingIndices = const {},
    this.isFetching = false,
    this.fetchError,
    this.processingIndex = -1,
    this.results = const [],
    this.processingStatus,
    this.currentWallpaper,
  });

  bool get isComplete => step == BulkDownloadStep.complete;
  int get failedCount => results.where((r) => !r.success).length;

  BulkDownloadState copyWith({
    BulkDownloadStep? step,
    int? batchSize,
    List<Wallpaper>? wallpapers,
    Set<int>? replacingIndices,
    bool? isFetching,
    String? fetchError,
    bool clearFetchError = false,
    int? processingIndex,
    List<BulkProcessResult>? results,
    String? processingStatus,
    bool clearProcessingStatus = false,
    Wallpaper? currentWallpaper,
    bool clearCurrentWallpaper = false,
  }) {
    return BulkDownloadState(
      step: step ?? this.step,
      batchSize: batchSize ?? this.batchSize,
      wallpapers: wallpapers ?? this.wallpapers,
      replacingIndices: replacingIndices ?? this.replacingIndices,
      isFetching: isFetching ?? this.isFetching,
      fetchError: clearFetchError ? null : fetchError ?? this.fetchError,
      processingIndex: processingIndex ?? this.processingIndex,
      results: results ?? this.results,
      processingStatus: clearProcessingStatus
          ? null
          : processingStatus ?? this.processingStatus,
      currentWallpaper: clearCurrentWallpaper
          ? null
          : currentWallpaper ?? this.currentWallpaper,
    );
  }
}

class BulkDownloadNotifier extends StateNotifier<BulkDownloadState> {
  BulkDownloadNotifier(this.ref) : super(const BulkDownloadState());

  final Ref ref;
  final ImageSourceRegistry _registry = ImageSourceRegistry();
  final List<Wallpaper> _reservoir = [];

  void setBatchSize(int size) {
    state = state.copyWith(batchSize: size);
  }

  Future<void> _ensureRegistryInitialized() async {
    final config = await AppConfig.initialize();
    _registry.initialize(
      pexelsApiKey: config.pexelsApiKey,
      unsplashApiKey: config.unsplashApiKey,
      pixabayApiKey: config.pixabayApiKey,
    );
  }

  Future<void> fetchWallpapers({
    String? query,
    String? sourceId,
    String? orientation,
    String? color,
  }) async {
    state = state.copyWith(isFetching: true, clearFetchError: true);
    _reservoir.clear();

    try {
      await _ensureRegistryInitialized();

      final batchSize = state.batchSize;
      final fetchCount = batchSize + 15; // fetch extra to fill reservoir

      final fetched = await _fetchFromSources(
        query: query,
        sourceId: sourceId,
        orientation: orientation,
        color: color,
        perPage: fetchCount,
      );

      if (fetched.isEmpty) {
        state = state.copyWith(
          isFetching: false,
          fetchError: 'No wallpapers found. Try different search criteria.',
        );
        return;
      }

      fetched.shuffle();
      final displayed = fetched.take(batchSize).toList();
      _reservoir.addAll(fetched.skip(batchSize));

      state = state.copyWith(
        step: BulkDownloadStep.selection,
        wallpapers: displayed,
        isFetching: false,
        replacingIndices: {},
      );
    } catch (e) {
      state = state.copyWith(
        isFetching: false,
        fetchError: 'Failed to fetch wallpapers: ${e.toString()}',
      );
    }
  }

  Future<void> replaceWallpaper(int index) async {
    if (index < 0 || index >= state.wallpapers.length) return;
    if (state.replacingIndices.contains(index)) return;

    state = state.copyWith(
      replacingIndices: {...state.replacingIndices, index},
    );

    try {
      Wallpaper? replacement;

      if (_reservoir.isNotEmpty) {
        replacement = _reservoir.removeAt(0);
      } else {
        // Fetch more wallpapers
        await _ensureRegistryInitialized();
        final more = await _fetchFromSources(perPage: 20);
        more.shuffle();
        if (more.isNotEmpty) {
          replacement = more.first;
          _reservoir.addAll(more.skip(1));
        }
      }

      if (replacement != null) {
        final updated = List<Wallpaper>.from(state.wallpapers);
        updated[index] = replacement;
        state = state.copyWith(
          wallpapers: updated,
          replacingIndices: Set.from(state.replacingIndices)..remove(index),
        );
      } else {
        state = state.copyWith(
          replacingIndices: Set.from(state.replacingIndices)..remove(index),
        );
      }
    } catch (_) {
      state = state.copyWith(
        replacingIndices: Set.from(state.replacingIndices)..remove(index),
      );
    }
  }

  Future<void> startProcessing() async {
    if (state.wallpapers.isEmpty) return;

    state = state.copyWith(
      step: BulkDownloadStep.processing,
      processingIndex: 0,
      results: [],
    );

    final downloadServiceAsync = ref.read(downloadServiceProvider);
    final downloadService = await downloadServiceAsync.when(
      data: (s) async => s,
      loading: () async {
        state = state.copyWith(
            processingStatus: 'Initializing download service...');
        return await ref.read(downloadServiceProvider.future);
      },
      error: (e, _) => throw e,
    );

    final wallpapers = List<Wallpaper>.from(state.wallpapers);
    final results = <BulkProcessResult>[];

    for (int i = 0; i < wallpapers.length; i++) {
      final wallpaper = wallpapers[i];
      state = state.copyWith(
        processingIndex: i,
        currentWallpaper: wallpaper,
        processingStatus: 'Processing ${i + 1}/${wallpapers.length}...',
        results: List.from(results),
      );

      try {
        final result =
            await downloadService.downloadAndProcessWallpaper(wallpaper);
        results.add(BulkProcessResult(
          wallpaper: wallpaper,
          success: true,
          downloadResult: result,
        ));
      } catch (e) {
        results.add(BulkProcessResult(
          wallpaper: wallpaper,
          success: false,
          error: e.toString(),
        ));
      }

      state = state.copyWith(results: List.from(results));
    }

    state = state.copyWith(
      step: BulkDownloadStep.complete,
      processingIndex: wallpapers.length,
      results: results,
      clearProcessingStatus: true,
      clearCurrentWallpaper: true,
    );
  }

  Future<void> retryFailed() async {
    final failedResults = state.results.where((r) => !r.success).toList();
    if (failedResults.isEmpty) return;

    final downloadService = await ref.read(downloadServiceProvider.future);
    final results = List<BulkProcessResult>.from(state.results);

    state = state.copyWith(
      step: BulkDownloadStep.processing,
      processingIndex: 0,
      processingStatus: 'Retrying ${failedResults.length} failed items...',
    );

    for (int i = 0; i < failedResults.length; i++) {
      final failed = failedResults[i];
      final resultIndex =
          results.indexWhere((r) => r.wallpaper.id == failed.wallpaper.id);

      state = state.copyWith(
        processingIndex: i,
        currentWallpaper: failed.wallpaper,
        processingStatus: 'Retrying ${i + 1}/${failedResults.length}...',
      );

      try {
        final result =
            await downloadService.downloadAndProcessWallpaper(failed.wallpaper);
        if (resultIndex >= 0) {
          results[resultIndex] = BulkProcessResult(
            wallpaper: failed.wallpaper,
            success: true,
            downloadResult: result,
          );
        }
      } catch (e) {
        if (resultIndex >= 0) {
          results[resultIndex] = BulkProcessResult(
            wallpaper: failed.wallpaper,
            success: false,
            error: e.toString(),
          );
        }
      }

      state = state.copyWith(results: List.from(results));
    }

    state = state.copyWith(
      step: BulkDownloadStep.complete,
      processingIndex: failedResults.length,
      results: results,
      clearProcessingStatus: true,
      clearCurrentWallpaper: true,
    );
  }

  Future<void> renameResult(int index, String newName) async {
    if (index < 0 || index >= state.results.length) return;
    final result = state.results[index];
    if (!result.success || result.downloadResult == null) return;

    final downloadService = await ref.read(downloadServiceProvider.future);
    final renamed =
        await downloadService.renameWallpaper(result.downloadResult!, newName);

    final updated = List<BulkProcessResult>.from(state.results);
    updated[index] = BulkProcessResult(
      wallpaper: result.wallpaper,
      success: true,
      downloadResult: renamed,
    );
    state = state.copyWith(results: updated);
  }

  void reset() {
    _reservoir.clear();
    state = const BulkDownloadState();
  }

  Future<List<Wallpaper>> _fetchFromSources({
    String? query,
    String? sourceId,
    String? orientation,
    String? color,
    int perPage = 20,
  }) async {
    final params = SearchParams(
      page: 1,
      perPage: perPage,
      orientation: orientation,
      color: color,
    );

    if (sourceId != null) {
      final provider = _registry.getProvider(sourceId);
      if (provider == null) {
        throw Exception('Provider not configured: $sourceId');
      }

      return query != null && query.isNotEmpty
          ? await provider.searchImages(query: query, params: params)
          : await provider.getCuratedImages(params: params);
    } else {
      final providers = _registry.getAvailableProviders();
      final allWallpapers = <Wallpaper>[];

      for (final provider in providers) {
        try {
          final wallpapers = query != null && query.isNotEmpty
              ? await provider.searchImages(query: query, params: params)
              : await provider.getCuratedImages(params: params);
          allWallpapers.addAll(wallpapers);
        } catch (_) {
          continue;
        }
      }

      return allWallpapers;
    }
  }
}

final bulkDownloadProvider =
    StateNotifierProvider.autoDispose<BulkDownloadNotifier, BulkDownloadState>(
  (ref) => BulkDownloadNotifier(ref),
);
