import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../domain/models/cms_models.dart';
import '../../domain/models/wallpaper.dart';
import 'repository_providers.dart';

class CmsNotifier extends AsyncNotifier<RioData?> {
  @override
  FutureOr<RioData?> build() async {
    return null;
  }

  Future<void> loadFile(String filePath) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(wallRioWallpaperRepositoryProvider);
      final data = await repository.loadData(filePath);
      ref.read(wallRioSettingsRepositoryProvider).updateLastOpened(filePath);
      return data;
    });
  }

  Future<void> saveFile(String filePath, String commitMessage) async {
    final data = state.value;
    if (data == null) return;

    await AsyncValue.guard(() async {
      final repository = ref.read(wallRioWallpaperRepositoryProvider);
      final versionRepo = ref.read(wallRioVersionRepositoryProvider);

      final currentJson = await repository.loadData(filePath);
      
      // Filter data if it's rio.json (JSON 3)
      // These 3 values (videoUrl, previewVideo, type) are only for JSON 2 (live_json)
      RioData dataToSave = data;
      final fileName = filePath.split('/').last.split('\\').last.toLowerCase();
      if (fileName.contains('rio.json')) {
        dataToSave = data.copyWith(
          walls: data.walls.map((w) => w.copyWith(
            videoUrl: null,
            previewVideo: null,
            type: null,
          )).toList(),
        );
      }

      final snapshot = LocalVersion(
        id: const Uuid().v4(),
        filePath: filePath,
        timestamp: DateTime.now(),
        commitMessage: 'Auto-backup: $commitMessage',
        jsonData: jsonEncode(currentJson.toJson()),
      );
      await versionRepo.saveVersion(snapshot);
      await repository.saveData(filePath, dataToSave);
    });
  }

  void updateData(RioData? newData) {
    state = AsyncValue.data(newData);
  }

  void addWallpaper(Wallpaper wallpaper) {
    final currentData = state.value;
    if (currentData == null) return;
    updateData(currentData.copyWith(walls: [wallpaper, ...currentData.walls]));
  }

  void addWallpapersBatch(List<Wallpaper> wallpapers) {
    final currentData = state.value;
    if (currentData == null) return;
    updateData(currentData.copyWith(walls: [...wallpapers, ...currentData.walls]));
  }

  void editWallpaper(Wallpaper wallpaper) {
    final currentData = state.value;
    if (currentData == null) return;
    final updated = currentData.walls.map((w) => w.id == wallpaper.id ? wallpaper : w).toList();
    updateData(currentData.copyWith(walls: updated));
  }

  void deleteWallpaper(int id) {
    final currentData = state.value;
    if (currentData == null) return;
    updateData(currentData.copyWith(walls: currentData.walls.where((w) => w.id != id).toList()));
  }
}

final cmsProvider = AsyncNotifierProvider<CmsNotifier, RioData?>(CmsNotifier.new);

// Tracks the currently opened JSON file path
class CurrentFilePathNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void set(String? path) => state = path;
}

final currentFilePathProvider = NotifierProvider<CurrentFilePathNotifier, String?>(
  CurrentFilePathNotifier.new,
);
