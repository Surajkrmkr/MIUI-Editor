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
  final bool aiNamingEnabled;
  final bool autoRetryEnabled;
  final String? lastQuery;
  final String? lastSourceId;
  final String? lastOrientation;
  final String? lastColor;
  final List<Wallpaper> wallpapers;
  final Set<String> selectedWallpaperIds;
  final bool isFetching;
  final String? fetchError;
  // Pagination
  final int currentPage;
  final bool isLoadingMore;
  final bool hasMorePages;
  // Processing
  final int processingIndex;
  final List<BulkProcessResult> results;
  final String? processingStatus;
  final Wallpaper? currentWallpaper;

  const BulkDownloadState({
    this.step = BulkDownloadStep.criteria,
    this.batchSize = 25,
    this.aiNamingEnabled = true,
    this.autoRetryEnabled = false,
    this.lastQuery,
    this.lastSourceId,
    this.lastOrientation,
    this.lastColor,
    this.wallpapers = const [],
    this.selectedWallpaperIds = const {},
    this.isFetching = false,
    this.fetchError,
    this.currentPage = 1,
    this.isLoadingMore = false,
    this.hasMorePages = true,
    this.processingIndex = -1,
    this.results = const [],
    this.processingStatus,
    this.currentWallpaper,
  });

  bool get isComplete => step == BulkDownloadStep.complete;
  int get failedCount => results.where((r) => !r.success).length;
  List<Wallpaper> get selectedWallpapers =>
      wallpapers.where((w) => selectedWallpaperIds.contains(w.id)).toList();

  BulkDownloadState copyWith({
    BulkDownloadStep? step,
    int? batchSize,
    bool? aiNamingEnabled,
    bool? autoRetryEnabled,
    String? lastQuery,
    String? lastSourceId,
    String? lastOrientation,
    String? lastColor,
    List<Wallpaper>? wallpapers,
    Set<String>? selectedWallpaperIds,
    bool? isFetching,
    String? fetchError,
    bool clearFetchError = false,
    int? currentPage,
    bool? isLoadingMore,
    bool? hasMorePages,
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
      aiNamingEnabled: aiNamingEnabled ?? this.aiNamingEnabled,
      autoRetryEnabled: autoRetryEnabled ?? this.autoRetryEnabled,
      lastQuery: lastQuery ?? this.lastQuery,
      lastSourceId: lastSourceId ?? this.lastSourceId,
      lastOrientation: lastOrientation ?? this.lastOrientation,
      lastColor: lastColor ?? this.lastColor,
      wallpapers: wallpapers ?? this.wallpapers,
      selectedWallpaperIds: selectedWallpaperIds ?? this.selectedWallpaperIds,
      isFetching: isFetching ?? this.isFetching,
      fetchError: clearFetchError ? null : fetchError ?? this.fetchError,
      currentPage: currentPage ?? this.currentPage,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMorePages: hasMorePages ?? this.hasMorePages,
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

  void setBatchSize(int size) => state = state.copyWith(batchSize: size);
  void setAiNaming(bool v) => state = state.copyWith(aiNamingEnabled: v);
  void setAutoRetry(bool v) => state = state.copyWith(autoRetryEnabled: v);

  void toggleSelection(String id) {
    final updated = Set<String>.from(state.selectedWallpaperIds);
    if (updated.contains(id)) {
      updated.remove(id);
    } else {
      updated.add(id);
    }
    state = state.copyWith(selectedWallpaperIds: updated);
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

    try {
      await _ensureRegistryInitialized();

      final fetched = await _fetchFromSources(
        query: query,
        sourceId: sourceId,
        orientation: orientation,
        color: color,
        perPage: state.batchSize,
        page: 1,
      );

      if (fetched.isEmpty) {
        state = state.copyWith(
          isFetching: false,
          fetchError: 'No wallpapers found. Try different search criteria.',
        );
        return;
      }

      fetched.shuffle();

      state = state.copyWith(
        step: BulkDownloadStep.selection,
        wallpapers: fetched,
        selectedWallpaperIds: {},
        isFetching: false,
        currentPage: 1,
        hasMorePages: fetched.length >= state.batchSize,
        isLoadingMore: false,
        lastQuery: query,
        lastSourceId: sourceId,
        lastOrientation: orientation,
        lastColor: color,
      );
    } catch (e) {
      state = state.copyWith(
        isFetching: false,
        fetchError: 'Failed to fetch wallpapers: ${e.toString()}',
      );
    }
  }

  Future<void> loadMoreWallpapers() async {
    if (state.isLoadingMore || !state.hasMorePages) return;
    if (state.step != BulkDownloadStep.selection) return;

    state = state.copyWith(isLoadingMore: true);

    try {
      await _ensureRegistryInitialized();
      final nextPage = state.currentPage + 1;

      final fetched = await _fetchFromSources(
        query: state.lastQuery,
        sourceId: state.lastSourceId,
        orientation: state.lastOrientation,
        color: state.lastColor,
        perPage: state.batchSize,
        page: nextPage,
      );

      if (fetched.isEmpty) {
        state = state.copyWith(isLoadingMore: false, hasMorePages: false);
        return;
      }

      // De-duplicate against existing list.
      final existingIds = state.wallpapers.map((w) => w.id).toSet();
      final fresh =
          fetched.where((w) => !existingIds.contains(w.id)).toList();

      state = state.copyWith(
        wallpapers: [...state.wallpapers, ...fresh],
        currentPage: nextPage,
        isLoadingMore: false,
        hasMorePages: fresh.isNotEmpty,
      );
    } catch (_) {
      state = state.copyWith(isLoadingMore: false);
    }
  }

  Future<void> startProcessing() async {
    final wallpapers = state.selectedWallpapers;
    if (wallpapers.isEmpty) return;

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

    final results = <BulkProcessResult>[];
    final aiNaming = state.aiNamingEnabled;

    for (int i = 0; i < wallpapers.length; i++) {
      if (i > 0) await Future.delayed(const Duration(milliseconds: 800));

      final wallpaper = wallpapers[i];
      state = state.copyWith(
        processingIndex: i,
        currentWallpaper: wallpaper,
        processingStatus: 'Processing ${i + 1}/${wallpapers.length}...',
        results: List.from(results),
      );

      try {
        final result = await downloadService.downloadAndProcessWallpaper(
            wallpaper,
            aiNaming: aiNaming);
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

    if (state.autoRetryEnabled) {
      const maxAutoRetries = 3;
      for (int attempt = 1; attempt <= maxAutoRetries; attempt++) {
        final failedItems = results.where((r) => !r.success).toList();
        if (failedItems.isEmpty) break;

        for (int i = 0; i < failedItems.length; i++) {
          if (i > 0) await Future.delayed(const Duration(milliseconds: 800));

          final failed = failedItems[i];
          final resultIndex = results
              .indexWhere((r) => r.wallpaper.id == failed.wallpaper.id);

          state = state.copyWith(
            processingIndex: i,
            currentWallpaper: failed.wallpaper,
            processingStatus:
                'Auto-retry $attempt/$maxAutoRetries: ${i + 1}/${failedItems.length}...',
            results: List.from(results),
          );

          try {
            final result = await downloadService.downloadAndProcessWallpaper(
                failed.wallpaper,
                aiNaming: aiNaming);
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
      }
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
      if (i > 0) await Future.delayed(const Duration(milliseconds: 800));

      final failed = failedResults[i];
      final resultIndex =
          results.indexWhere((r) => r.wallpaper.id == failed.wallpaper.id);

      state = state.copyWith(
        processingIndex: i,
        currentWallpaper: failed.wallpaper,
        processingStatus: 'Retrying ${i + 1}/${failedResults.length}...',
      );

      try {
        final result = await downloadService.downloadAndProcessWallpaper(
            failed.wallpaper,
            aiNaming: state.aiNamingEnabled);
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

  /// Renames every successful result to `<baseName>_<n>` (1-based, in order).
  /// Failed items are skipped. Individual rename failures are ignored so the
  /// rest still get renamed.
  Future<void> bulkRename(String baseName) async {
    final base = baseName.trim();
    if (base.isEmpty) return;

    final downloadService = await ref.read(downloadServiceProvider.future);
    final updated = List<BulkProcessResult>.from(state.results);

    int n = 1;
    for (int i = 0; i < updated.length; i++) {
      final r = updated[i];
      if (!r.success || r.downloadResult == null) continue;

      final target = '${base}_$n';
      n++;
      try {
        final renamed =
            await downloadService.renameWallpaper(r.downloadResult!, target);
        updated[i] = BulkProcessResult(
          wallpaper: r.wallpaper,
          success: true,
          downloadResult: renamed,
        );
        state = state.copyWith(results: List.from(updated));
      } catch (_) {
        // Keep the original name for this item and continue.
      }
    }
  }

  void reset() => state = const BulkDownloadState();

  Future<List<Wallpaper>> _fetchFromSources({
    String? query,
    String? sourceId,
    String? orientation,
    String? color,
    int perPage = 20,
    int page = 1,
  }) async {
    final params = SearchParams(
      page: page,
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
    StateNotifierProvider<BulkDownloadNotifier, BulkDownloadState>(
  (ref) => BulkDownloadNotifier(ref),
);
