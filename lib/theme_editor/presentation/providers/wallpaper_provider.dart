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
  });

  final String folderNum;
  final String? weekNum;
  final List<String> paths;
  final int index;
  final List<Color> colorPalette;
  final int themeCount;
  final bool isLoading;

  WallpaperState copyWith({
    String? folderNum,
    String? weekNum,
    List<String>? paths,
    int? index,
    List<Color>? colorPalette,
    int? themeCount,
    bool? isLoading,
  }) =>
      WallpaperState(
        folderNum: folderNum ?? this.folderNum,
        weekNum: weekNum ?? this.weekNum,
        paths: paths ?? this.paths,
        index: index ?? this.index,
        colorPalette: colorPalette ?? this.colorPalette,
        themeCount: themeCount ?? this.themeCount,
        isLoading: isLoading ?? this.isLoading,
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
    return WallpaperState(themeCount: settings.themeCount);
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
      // ✅ Create directories for the FIRST theme in the folder
      await _onThemeActivated(weekNum, paths[0]);
    }
  }

  // ── Navigate to a different wallpaper / theme ─────────────────────────────

  Future<void> setIndex(int i) async {
    if (i < 0 || i >= state.paths.length) return;
    state = state.copyWith(index: i);

    // ✅ Create directories for the newly selected theme
    if (state.weekNum != null) {
      await _onThemeActivated(state.weekNum!, state.paths[i]);
    }
  }

  // ── Core: everything that must happen when the active theme changes ────────
  //
  // Original behaviour from WallpaperProvider.setIndex():
  //   1. fetchColorPalette  → update icon editor colors
  //   2. createThemeDirectory → ensure all subdirs exist on disk
  //   3. getTagsFromFile    → load saved tags for this theme
  //   4. checkExported      → update icon/module "already exported" badges

  Future<void> _onThemeActivated(String weekNum, String wallPath) async {
    final themeName =
        wallPath.split(Platform.isWindows ? r'\' : '/').last.split('.').first;

    // ✅ Reset ALL export states immediately — before any async checks.
    // This ensures the UI shows clean (unexported) state the moment
    // the user taps next/prev, not after the async checks complete.
    ref.read(exportProvider.notifier).resetExportState();
    ref.read(lockscreenProvider.notifier).resetExportState();

    // Palette → icon editor colors
    await _updatePalette(wallPath);

    // Create theme directory tree
    await ref
        .read(directoryProvider.notifier)
        .createThemeDirectories(weekNum, themeName);

    // Load saved tags for this theme
    await ref
        .read(directoryProvider.notifier)
        .loadTagsFromFile(weekNum, themeName);

    // Check what's actually exported on disk and update badges
    // (runs AFTER reset so there's no flicker of stale state)
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
    prefs.setString('themeSettings', ThemeSettings(themeCount: count).encode());
    state = state.copyWith(themeCount: count);
  }
}

final wallpaperProvider =
    NotifierProvider<WallpaperNotifier, WallpaperState>(WallpaperNotifier.new);
