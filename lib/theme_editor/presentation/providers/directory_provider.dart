import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:miui_icon_generator/theme_editor/presentation/providers/usecase_providers.dart';
import '../../core/constants/path_constants.dart';
import 'service_providers.dart';
import 'tag_provider.dart';
import 'wallpaper_provider.dart';

class DirectoryState {
  const DirectoryState({
    this.preLockFolders = const [],
    this.previewWallPaths = const [],
    this.presetPaths = const [],
    this.isLoadingFolders = false,
    this.isLoadingWalls = false,
    this.isLoadingPresets = false,
    this.isCreatingDirs = false,
    this.status = '',
    this.selectedFolder = '1',
  });

  final List<String> preLockFolders;
  final List<String> previewWallPaths;
  final List<String> presetPaths;
  final bool isLoadingFolders, isLoadingWalls, isLoadingPresets, isCreatingDirs;
  final String status;
  final String selectedFolder;

  DirectoryState copyWith({
    List<String>? preLockFolders,
    List<String>? previewWallPaths,
    List<String>? presetPaths,
    bool? isLoadingFolders,
    bool? isLoadingWalls,
    bool? isLoadingPresets,
    bool? isCreatingDirs,
    String? status,
    String? selectedFolder,
  }) =>
      DirectoryState(
        preLockFolders: preLockFolders ?? this.preLockFolders,
        previewWallPaths: previewWallPaths ?? this.previewWallPaths,
        presetPaths: presetPaths ?? this.presetPaths,
        isLoadingFolders: isLoadingFolders ?? this.isLoadingFolders,
        isLoadingWalls: isLoadingWalls ?? this.isLoadingWalls,
        isLoadingPresets: isLoadingPresets ?? this.isLoadingPresets,
        isCreatingDirs: isCreatingDirs ?? this.isCreatingDirs,
        status: status ?? this.status,
        selectedFolder: selectedFolder ?? this.selectedFolder,
      );
}

class DirectoryNotifier extends Notifier<DirectoryState> {
  @override
  DirectoryState build() => const DirectoryState();

  // ── Folder listing ─────────────────────────────────────────────────────────

  Future<void> loadPreLockFolders() async {
    state = state.copyWith(isLoadingFolders: true);
    try {
      final dir = Directory(PathConstants.wallBasePath);
      if (!await dir.exists()) await dir.create(recursive: true);
      final entities = await dir.list().toList();
      final folders = entities
          .whereType<Directory>()
          .map((d) => d.path.split(Platform.isWindows ? r'\' : '/').last)
          .toList();
      state = state.copyWith(preLockFolders: folders, isLoadingFolders: false);
    } catch (_) {
      state = state.copyWith(isLoadingFolders: false);
    }
  }

  Future<void> loadPreviewWalls(String folderNum) async {
    state = state.copyWith(isLoadingWalls: true, status: 'Analysing...🤨');
    try {
      final dir =
          Directory(PathConstants.p('${PathConstants.wallBasePath}$folderNum'));
      if (!await dir.exists()) {
        state = state.copyWith(
            isLoadingWalls: false, previewWallPaths: [], status: '');
        return;
      }
      final entities = await dir.list().toList();
      final walls = entities
          .whereType<File>()
          .where((f) => f.path.endsWith('.jpg') || f.path.endsWith('.png'))
          .map((f) => f.path)
          .toList();
      final allJpg = walls.every((p) => p.endsWith('.jpg'));
      final themeCount = ref.read(wallpaperProvider).themeCount;
      String status;
      if (!allJpg) {
        status = 'Nahh All Walls are not in JPG...😥';
      } else if (walls.length != themeCount) {
        status = 'Walls are missing in counts...😶‍🌫️';
      } else {
        status = 'Superb All Looks Fine...😍';
      }
      state = state.copyWith(
          isLoadingWalls: false, previewWallPaths: walls, status: status);
    } catch (_) {
      state = state.copyWith(isLoadingWalls: false);
    }
  }

  Future<void> loadPresetPaths() async {
    state = state.copyWith(isLoadingPresets: true);
    try {
      final dir = Directory(PathConstants.presetPath);
      if (!await dir.exists()) await dir.create(recursive: true);
      final entities = await dir.list().toList();
      final paths = entities.whereType<Directory>().map((d) => d.path).toList()
        ..sort();
      state = state.copyWith(presetPaths: paths, isLoadingPresets: false);
    } catch (_) {
      state = state.copyWith(isLoadingPresets: false);
    }
  }

  void selectFolder(String f) => state = state.copyWith(selectedFolder: f);

  // ── Directory creation ─────────────────────────────────────────────────────

  Future<void> createThemeDirectories(String weekNum, String themeName) async {
    state = state.copyWith(isCreatingDirs: true);
    final tp = PathConstants.themePath(weekNum, themeName);
    final fs = ref.read(fileServiceProvider);
    for (final sub in PathConstants.themeDirectories) {
      await fs.createDir(PathConstants.p('$tp$sub'));
    }
    await _createTagFile(weekNum, themeName);
    state = state.copyWith(isCreatingDirs: false);
  }

  Future<void> _createTagFile(String weekNum, String themeName) async {
    final tagDir = PathConstants.tagDirectory(weekNum);
    final fs = ref.read(fileServiceProvider);
    await fs.createDir(tagDir);
    final tagFile = PathConstants.p('$tagDir$themeName.txt');
    if (!await fs.exists(tagFile)) {
      final tags = ref.read(tagProvider).appliedTags.join(',');
      await fs.writeString(tagFile, tags);
    }
  }

  Future<void> saveTagFile(
          String weekNum, String themeName, List<String> tags) =>
      ref
          .read(saveTagFileUseCaseProvider)
          .call(weekNum, themeName, tags)
          .then((_) {}); // swallow Failure — UI doesn't need it here

  Future<void> loadTagsFromFile(String weekNum, String themeName) =>
      ref.read(tagProvider.notifier).loadFromFile(weekNum, themeName);
}

final directoryProvider =
    NotifierProvider<DirectoryNotifier, DirectoryState>(DirectoryNotifier.new);
