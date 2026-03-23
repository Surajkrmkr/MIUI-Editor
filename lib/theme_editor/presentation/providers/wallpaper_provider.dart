import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:miui_icon_generator/theme_editor/presentation/providers/export_provider.dart';
import 'package:miui_icon_generator/theme_editor/presentation/providers/lockscreen_provider.dart';
import 'package:palette_generator/palette_generator.dart';
import '../../core/constants/path_constants.dart';
import '../../data/models/theme_settings_model.dart';
import 'service_providers.dart';
import 'icon_editor_provider.dart';
import 'directory_provider.dart'; // ← needed for createThemeDirectories

class WallpaperState {
  const WallpaperState({
    this.folderNum = '1',
    this.weekNum,
    this.paths = const [],
    this.index = 0,
    this.colorPalette = const [],
    this.themeCount = 25,
    this.isLoading = false,
    this.designerName = '',
    this.authorTag = '',
    this.uiVersion = '',
  });

  final String folderNum;
  final String? weekNum;
  final List<String> paths;
  final int index;
  final List<Color> colorPalette;
  final int themeCount;
  final bool isLoading;
  final String designerName;
  final String authorTag;
  final String uiVersion;

  WallpaperState copyWith({
    String? folderNum,
    String? weekNum,
    List<String>? paths,
    int? index,
    List<Color>? colorPalette,
    int? themeCount,
    bool? isLoading,
    String? designerName,
    String? authorTag,
    String? uiVersion,
  }) =>
      WallpaperState(
        folderNum: folderNum ?? this.folderNum,
        weekNum: weekNum ?? this.weekNum,
        paths: paths ?? this.paths,
        index: index ?? this.index,
        colorPalette: colorPalette ?? this.colorPalette,
        themeCount: themeCount ?? this.themeCount,
        isLoading: isLoading ?? this.isLoading,
        designerName: designerName ?? this.designerName,
        authorTag: authorTag ?? this.authorTag,
        uiVersion: uiVersion ?? this.uiVersion,
      );

  String? get currentPath => paths.isNotEmpty ? paths[index] : null;

  String? get currentThemeName {
    final p = currentPath;
    if (p == null) return null;
    return p.split(Platform.isWindows ? r'\' : '/').last.split('.').first;
  }
}

class WallpaperNotifier extends Notifier<WallpaperState> {
  @override
  WallpaperState build() {
    final prefs = ref.read(sharedPrefsProvider);
    final raw = prefs.getString('themeSettings') ?? '{}';
    final settings = ThemeSettings.decode(raw);

    // Apply saved basePath so PathConstants picks it up for all subsequent calls
    if (settings.basePath != null && settings.basePath!.isNotEmpty) {
      PathConstants.customBasePath = settings.basePath!;
    }

    return WallpaperState(
      themeCount: settings.themeCount,
      designerName: settings.designerName,
      authorTag: settings.authorTag,
      uiVersion: settings.uiVersion,
    );
  }

  // ── Load a folder (called once from HomeScreen init) ──────────────────────

  Future<void> loadFolder(String folderNum, String weekNum) async {
    state =
        state.copyWith(isLoading: true, folderNum: folderNum, weekNum: weekNum);

    final dir =
        Directory(PathConstants.p('${PathConstants.wallBasePath}$folderNum'));

    if (!await dir.exists()) {
      state = state.copyWith(isLoading: false, paths: []);
      return;
    }

    final entities = await dir.list().toList();
    final paths = entities
        .whereType<File>()
        .where((f) => f.path.endsWith('.jpg') || f.path.endsWith('.png'))
        .map((f) => f.path)
        .toList();

    state = state.copyWith(isLoading: false, paths: paths, index: 0);

    if (paths.isNotEmpty) {
      await _onThemeActivated(weekNum, paths[0]);
    }
  }

  // ── Navigate to a different wallpaper / theme ─────────────────────────────

  Future<void> setIndex(int i) async {
    if (i < 0 || i >= state.paths.length) return;
    state = state.copyWith(index: i);

    if (state.weekNum != null) {
      await _onThemeActivated(state.weekNum!, state.paths[i]);
    }
  }

  // ── Core: everything that must happen when the active theme changes ────────

  Future<void> _onThemeActivated(String weekNum, String wallPath) async {
    final themeName =
        wallPath.split(Platform.isWindows ? r'\' : '/').last.split('.').first;

    ref.read(exportProvider.notifier).resetExportState();
    ref.read(lockscreenProvider.notifier).resetExportState();

    await _updatePalette(wallPath);

    await ref
        .read(directoryProvider.notifier)
        .createThemeDirectories(weekNum, themeName);

    await ref
        .read(directoryProvider.notifier)
        .loadTagsFromFile(weekNum, themeName);

    await ref.read(exportProvider.notifier).checkExported();
    await ref.read(lockscreenProvider.notifier).checkExported();
  }

  // ── Palette extraction ────────────────────────────────────────────────────

  Future<void> _updatePalette(String wallPath) async {
    try {
      final gen =
          await PaletteGenerator.fromImageProvider(FileImage(File(wallPath)));
      final colors = gen.colors.toList();
      state = state.copyWith(colorPalette: colors);

      final icon = ref.read(iconEditorProvider.notifier);
      if (ref.read(iconEditorProvider).randomColors) {
        final dark = colors
            .where((c) =>
                ThemeData.estimateBrightnessForColor(c) == Brightness.dark)
            .toList();
        if (dark.isNotEmpty) icon.setBgColors(dark);
      } else {
        icon.setBgColor((gen.lightVibrantColor ?? gen.dominantColor)!.color);
        icon.setBgColor2((gen.darkVibrantColor ?? gen.dominantColor)!.color);
      }
      icon.setAccentColor(gen.dominantColor!.color);
    } catch (_) {
      // Palette extraction can fail on unsupported image formats — safe to ignore
    }
  }

  // ── Settings ──────────────────────────────────────────────────────────────

  void updateThemeCount(int count) {
    final prefs = ref.read(sharedPrefsProvider);
    final current = _currentSettings();
    prefs.setString('themeSettings', current.copyWith(themeCount: count).encode());
    state = state.copyWith(themeCount: count);
  }

  void updateSettings({
    String? basePath,
    String? designerName,
    String? authorTag,
    String? uiVersion,
    int? themeCount,
  }) {
    final prefs = ref.read(sharedPrefsProvider);
    final updated = _currentSettings().copyWith(
      basePath: basePath,
      designerName: designerName,
      authorTag: authorTag,
      uiVersion: uiVersion,
      themeCount: themeCount,
    );
    prefs.setString('themeSettings', updated.encode());

    if (basePath != null && basePath.isNotEmpty) {
      PathConstants.customBasePath = basePath;
    }

    state = state.copyWith(
      designerName: designerName,
      authorTag: authorTag,
      uiVersion: uiVersion,
      themeCount: themeCount,
    );
  }

  ThemeSettings _currentSettings() {
    final prefs = ref.read(sharedPrefsProvider);
    return ThemeSettings.decode(prefs.getString('themeSettings') ?? '{}');
  }
}

final wallpaperProvider =
    NotifierProvider<WallpaperNotifier, WallpaperState>(WallpaperNotifier.new);
