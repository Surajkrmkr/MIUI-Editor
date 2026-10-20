import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:theme_core/theme_core.dart';

import '../../core/constants/path_constants.dart';
import '../../domain/usecases/build_theme_spec.dart';
import 'element_provider.dart';
import 'icon_editor_provider.dart';
import 'service_providers.dart';
import 'user_profile_provider.dart';
import 'wallpaper_provider.dart';

/// File name of the spec written into a theme's workspace.
const themeSpecFileName = 'theme.spec.json';

/// The spec for the theme currently open in the editor, or null when no
/// profile, wallpaper or week is selected yet.
final themeSpecProvider = Provider<ThemeSpec?>((ref) {
  final ws = ref.watch(wallpaperProvider);
  final profile = ref.watch(activeUserProfileProvider);
  final name = ws.currentThemeName;
  final wallpaper = ws.currentPath;
  final week = ws.weekNum;
  if (profile == null || name == null || wallpaper == null || week == null) {
    return null;
  }
  final layout = ThemeLayout(PathConstants.themePath(week, name));
  final els = ref.watch(elementProvider);
  return buildThemeSpec(
    themeName: name,
    wallpaperPath: wallpaper,
    homeWallpaperPath: ws.homeWallpaperEnabled ? ws.homeWallpaperPath : null,
    designer: ws.designerName.isNotEmpty
        ? ws.designerName
        : profile.displayName,
    authorTag: ws.authorTag.isNotEmpty ? ws.authorTag : profile.authorTag,
    uiVersion: ws.uiVersion.isNotEmpty ? ws.uiVersion : '17',
    profile: profile,
    style: ref.watch(iconEditorProvider).toStyle(),
    elements: els.elements,
    bgAlpha: els.bgAlpha,
    week: week,
    folder: ws.folderNum,
    lockscreenAssetsDir: layout.lockscreenAdvance,
    outputDir: layout.parentDir,
  );
});

Future<Failure?> _writeSpec(Ref ref, ThemeSpec spec, String path) async {
  try {
    await ref.read(fileServiceProvider).writeString(path, _encode(spec));
    return null;
  } catch (e) {
    return ExportFailure(e.toString());
  }
}

String _encode(ThemeSpec spec) =>
    '${const JsonEncoder.withIndent('  ').convert(spec.toJson())}\n';

String _specPathOf(String week, String themeName) =>
    '${ThemeLayout(PathConstants.themePath(week, themeName)).root}'
    '${PathConstants.sep}$themeSpecFileName';

/// Keeps the open theme's spec file up to date: every design change is
/// written shortly after it happens. Watch it while the editor is open.
final themeSpecAutoSaveProvider = Provider.autoDispose<void>((ref) {
  final files = ref.read(fileServiceProvider);
  Timer? timer;
  String? pendingPath, pendingText, lastWritten;

  void flush() {
    timer?.cancel();
    final path = pendingPath, text = pendingText;
    pendingPath = pendingText = null;
    if (path == null || text == null) return;
    lastWritten = '$path\n$text';
    unawaited(
      files
          .writeString(path, text)
          .then<void>(
            (_) {},
            onError: (Object e) => debugPrint('Theme spec autosave failed: $e'),
          ),
    );
  }

  // Listens to the editing notifiers themselves: they report changes at once,
  // while the opening of a theme is still flagged.
  void changed(Object? previous, Object? next) {
    if (ref.read(wallpaperProvider.notifier).isActivating) return;
    final spec = ref.read(themeSpecProvider);
    if (spec == null) return;
    final ws = ref.read(wallpaperProvider);
    final path = _specPathOf(ws.weekNum!, ws.currentThemeName!);
    final text = _encode(spec);
    if (pendingPath != null && pendingPath != path) flush();
    if (pendingPath == null && lastWritten == '$path\n$text') return;
    pendingPath = path;
    pendingText = text;
    timer?.cancel();
    timer = Timer(const Duration(milliseconds: 400), flush);
  }

  ref.onDispose(flush);
  ref.listen<Object?>(elementProvider, changed);
  ref.listen<Object?>(iconEditorProvider, changed);
  ref.listen<Object?>(userProfileProvider, changed);
  ref.listen<Object?>(iconStyleOverrideProvider, changed);
  ref.listen<Object?>(wallpaperProvider, changed);
});

/// Writes the current spec next to the theme's other files and returns its
/// path, or a failure.
Future<(String?, Failure?)> saveThemeSpec(Ref ref) async {
  final spec = ref.read(themeSpecProvider);
  if (spec == null) {
    return (null, const ValidationFailure('No active theme'));
  }
  final ws = ref.read(wallpaperProvider);
  final path = _specPathOf(ws.weekNum!, ws.currentThemeName!);
  final failure = await _writeSpec(ref, spec, path);
  return failure == null ? (path, null) : (null, failure);
}

/// Writes the current spec to [path], wherever the user chose.
Future<Failure?> saveThemeSpecAs(Ref ref, String path) async {
  final spec = ref.read(themeSpecProvider);
  if (spec == null) return const ValidationFailure('No active theme');
  return _writeSpec(ref, spec, path);
}

/// Lets widgets call [saveThemeSpecAs] without a [Ref].
final themeSpecSaveAsProvider = Provider<Future<Failure?> Function(String)>(
  (ref) =>
      (path) => saveThemeSpecAs(ref, path),
);

/// Lets widgets call [saveThemeSpec] without a [Ref].
final themeSpecSaverProvider = Provider<Future<(String?, Failure?)> Function()>(
  (ref) =>
      () => saveThemeSpec(ref),
);
