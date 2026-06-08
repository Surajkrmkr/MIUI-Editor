import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/cms_models.dart';
import '../../infrastructure/services/app_settings_service.dart';
import 'repository_providers.dart';

class SavedPathsNotifier extends AsyncNotifier<List<SavedFilePath>> {
  @override
  FutureOr<List<SavedFilePath>> build() async {
    final repository = ref.watch(wallRioSettingsRepositoryProvider);
    return await repository.getSavedPaths();
  }

  Future<void> savePath(String path, String label) async {
    final repository = ref.read(wallRioSettingsRepositoryProvider);
    final savedPath = SavedFilePath(
      path: path,
      label: label,
      lastOpened: DateTime.now(),
    );
    await repository.savePath(savedPath);
    ref.invalidateSelf();
  }

  Future<void> removePath(String path) async {
    final repository = ref.read(wallRioSettingsRepositoryProvider);
    await repository.removePath(path);
    ref.invalidateSelf();
  }
}

final savedPathsProvider =
    AsyncNotifierProvider<SavedPathsNotifier, List<SavedFilePath>>(
  SavedPathsNotifier.new,
);

class JsonPathNotifier extends AsyncNotifier<String?> {
  @override
  FutureOr<String?> build() async {
    final paths = await ref.watch(savedPathsProvider.future);
    return paths.isNotEmpty ? paths.first.path : null;
  }

  Future<void> setPath(String path) async {
    state = AsyncValue.data(path);
  }
}

final jsonPathProvider = AsyncNotifierProvider<JsonPathNotifier, String?>(
  JsonPathNotifier.new,
);

class WallpaperRepoPathNotifier extends AsyncNotifier<String?> {
  @override
  FutureOr<String?> build() async {
    final service = AppSettingsService();
    final savedPath = await service.getWallpaperRepoPath();
    return savedPath ?? r'D:\Team Shadow\wallrio_wall_data-1';
  }

  Future<void> setPath(String path) async {
    final service = AppSettingsService();
    await service.setWallpaperRepoPath(path);
    ref.invalidateSelf();
  }
}

final wallpaperRepoPathProvider =
    AsyncNotifierProvider<WallpaperRepoPathNotifier, String?>(
  WallpaperRepoPathNotifier.new,
);
