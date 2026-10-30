import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:miui_icon_generator/theme_editor/presentation/providers/export_provider.dart';
import 'package:miui_icon_generator/theme_editor/presentation/providers/lockscreen_provider.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:path/path.dart' as p;
import '../../core/constants/path_constants.dart';
import '../../data/models/theme_settings_model.dart';
import 'service_providers.dart';
import 'icon_editor_provider.dart';
import 'directory_provider.dart'; // ← needed for createThemeDirectories
import 'spec_loader.dart';

class WallpaperState {
  const WallpaperState({
    this.folderNum = '1',
    this.weekNum,
    this.paths = const [],
    this.index = 0,
    this.colorPalette = const [],
    this.accentColor,
    this.themeCount = 25,
    this.isLoading = false,
    this.designerName = '',
    this.authorTag = '',
    this.uiVersion = '',
    this.namedTheme,
    this.homeWallpaperEnabled = false,
    this.homeWallpaperPath,
  });

  final String folderNum;
  final String? weekNum;
  final List<String> paths;
  final int index;
  final List<Color> colorPalette;
  final Color? accentColor;
  final int themeCount;
  final bool isLoading;
  final String designerName;
  final String authorTag;
  final String uiVersion;

  /// A name for the wallpaper at `path` that replaces its file name, e.g. a
  /// spec's title; ignored once another wallpaper is selected.
  final ({String path, String name})? namedTheme;
  final bool homeWallpaperEnabled;
  final String? homeWallpaperPath;

  WallpaperState copyWith({
    String? folderNum,
    String? weekNum,
    List<String>? paths,
    int? index,
    List<Color>? colorPalette,
    Color? accentColor,
    int? themeCount,
    bool? isLoading,
    String? designerName,
    String? authorTag,
    String? uiVersion,
    ({String path, String name})? namedTheme,
    bool? homeWallpaperEnabled,
    String? homeWallpaperPath,
    bool clearHomeWallpaper = false,
  }) => WallpaperState(
    folderNum: folderNum ?? this.folderNum,
    weekNum: weekNum ?? this.weekNum,
    paths: paths ?? this.paths,
    index: index ?? this.index,
    colorPalette: colorPalette ?? this.colorPalette,
    accentColor: accentColor ?? this.accentColor,
    themeCount: themeCount ?? this.themeCount,
    isLoading: isLoading ?? this.isLoading,
    designerName: designerName ?? this.designerName,
    authorTag: authorTag ?? this.authorTag,
    uiVersion: uiVersion ?? this.uiVersion,
    namedTheme: namedTheme ?? this.namedTheme,
    homeWallpaperEnabled: homeWallpaperEnabled ?? this.homeWallpaperEnabled,
    homeWallpaperPath: clearHomeWallpaper
        ? null
        : homeWallpaperPath ?? this.homeWallpaperPath,
  );

  String? get currentPath => paths.isNotEmpty ? paths[index] : null;

  String? get currentThemeName {
    final p = currentPath;
    if (p == null) return null;
    if (namedTheme?.path == p) return namedTheme!.name;
    return p.split(Platform.isWindows ? r'\' : '/').last.split('.').first;
  }
}

class WallpaperNotifier extends Notifier<WallpaperState> {
  bool _activating = false;
  int _activation = 0;

  void _setActivating(bool value) {
    _activating = value;
    ref.read(themeOpeningProvider.notifier).state = value;
  }

  /// True while a theme is being opened; its design changes then are not
  /// the designer's edits.
  bool get isActivating => _activating;

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

  void setHomeWallpaperEnabled(bool enabled) {
    state = state.copyWith(homeWallpaperEnabled: enabled);
  }

  void setHomeWallpaper(String path) {
    state = state.copyWith(homeWallpaperEnabled: true, homeWallpaperPath: path);
  }

  void clearHomeWallpaper() {
    state = state.copyWith(
      homeWallpaperEnabled: false,
      clearHomeWallpaper: true,
    );
  }

  // ── Load a folder (called once from HomeScreen init) ──────────────────────

  Future<void> loadFolder(String folderNum, String weekNum) async {
    state = state.copyWith(
      isLoading: true,
      folderNum: folderNum,
      weekNum: weekNum,
      homeWallpaperEnabled: false,
      clearHomeWallpaper: true,
    );

    final dir = Directory(
      PathConstants.p('${PathConstants.wallBasePath}$folderNum'),
    );

    if (!await dir.exists()) {
      state = state.copyWith(isLoading: false, paths: []);
      return;
    }

    final entities = await dir.list().toList();
    final paths = entities
        .whereType<File>()
        .where((f) {
          final lower = f.path.toLowerCase();
          return lower.endsWith('.jpg') ||
              lower.endsWith('.jpeg') ||
              lower.endsWith('.png');
        })
        .map((f) => f.path)
        .toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

    if (paths.isNotEmpty) _setActivating(true);
    state = state.copyWith(isLoading: false, paths: paths, index: 0);

    if (paths.isNotEmpty) {
      await _onThemeActivated(weekNum, paths[0]);
    }
  }

  // ── Open a theme described by a spec ──────────────────────────────────────

  /// Makes [wallpaperPath] the only wallpaper and [themeName] the theme's
  /// name. Designer, author tag and UI version apply to this session only;
  /// they are not written to the saved settings.
  Future<void> openTheme({
    required String wallpaperPath,
    required String weekNum,
    required String folderNum,
    required String themeName,
    String designerName = '',
    String authorTag = '',
    String uiVersion = '',
  }) async {
    _setActivating(true);
    state = state.copyWith(
      isLoading: false,
      folderNum: folderNum,
      weekNum: weekNum,
      paths: [wallpaperPath],
      index: 0,
      namedTheme: (path: wallpaperPath, name: themeName),
      homeWallpaperEnabled: false,
      clearHomeWallpaper: true,
      designerName: designerName.isEmpty ? null : designerName,
      authorTag: authorTag.isEmpty ? null : authorTag,
      uiVersion: uiVersion.isEmpty ? null : uiVersion,
    );
    await _onThemeActivated(weekNum, wallpaperPath, restoreSaved: false);
  }

  // ── Navigate to a different wallpaper / theme ─────────────────────────────

  Future<void> setIndex(int i) async {
    if (i < 0 || i >= state.paths.length) return;
    if (state.weekNum != null) _setActivating(true);
    state = state.copyWith(
      index: i,
      homeWallpaperEnabled: false,
      clearHomeWallpaper: true,
    );

    if (state.weekNum != null) {
      await _onThemeActivated(state.weekNum!, state.paths[i]);
    }
  }

  // ── Core: everything that must happen when the active theme changes ────────

  Future<void> _onThemeActivated(
    String weekNum,
    String wallPath, {
    bool restoreSaved = true,
  }) async {
    _setActivating(true);
    final activation = ++_activation;
    try {
      // Let the loading overlay paint before the heavy work starts.
      await WidgetsBinding.instance.endOfFrame;
      if (activation != _activation) return;
      final themeName = state.currentThemeName!;

      ref.read(exportProvider.notifier).resetExportState();
      ref.read(lockscreenProvider.notifier).resetExportState();

      await _updatePalette(wallPath);

      await ref
          .read(directoryProvider.notifier)
          .createThemeDirectories(weekNum, themeName);

      // A theme designed before carries on where it was left.
      if (restoreSaved) {
        final saved = await readSavedDesign(weekNum, themeName);
        if (saved != null && activation == _activation) {
          if (saved.wallpaper.lock != null) {
            final homePath = p.isAbsolute(saved.wallpaper.home)
                ? p.normalize(saved.wallpaper.home)
                : p.normalize(
                    p.join(
                      PathConstants.themePath(weekNum, themeName),
                      saved.wallpaper.home,
                    ),
                  );
            if (File(homePath).existsSync() && homePath != wallPath) {
              setHomeWallpaper(homePath);
            }
          }
          applyDesign(ref, saved);
        }
      }

      await ref
          .read(directoryProvider.notifier)
          .loadTagsFromFile(weekNum, themeName);

      await ref.read(exportProvider.notifier).checkExported();
      await ref.read(lockscreenProvider.notifier).checkExported();
    } finally {
      if (activation == _activation) _setActivating(false);
    }
  }

  // ── Palette extraction ────────────────────────────────────────────────────

  Future<void> _updatePalette(String wallPath) async {
    try {
      // A small copy is enough for a palette and far cheaper to quantize.
      final gen = await PaletteGenerator.fromImageProvider(
        ResizeImage(FileImage(File(wallPath)), width: 200),
      );
      final colors = gen.colors.toList();
      state = state.copyWith(
        colorPalette: colors,
        accentColor: gen.dominantColor?.color,
      );

      final icon = ref.read(iconEditorProvider.notifier);
      if (ref.read(iconEditorProvider).randomColors) {
        final dark = colors
            .where(
              (c) => ThemeData.estimateBrightnessForColor(c) == Brightness.dark,
            )
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
    prefs.setString(
      'themeSettings',
      current.copyWith(themeCount: count).encode(),
    );
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

final wallpaperProvider = NotifierProvider<WallpaperNotifier, WallpaperState>(
  WallpaperNotifier.new,
);

/// True while a theme is being opened, for a loading overlay.
final themeOpeningProvider = StateProvider<bool>((_) => false);
