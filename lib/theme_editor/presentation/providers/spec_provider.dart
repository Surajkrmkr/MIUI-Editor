import 'dart:convert';

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
    await ref
        .read(fileServiceProvider)
        .writeString(
          path,
          '${const JsonEncoder.withIndent('  ').convert(spec.toJson())}\n',
        );
    return null;
  } catch (e) {
    return ExportFailure(e.toString());
  }
}

/// Writes the current spec next to the theme's other files and returns its
/// path, or a failure.
Future<(String?, Failure?)> saveThemeSpec(Ref ref) async {
  final spec = ref.read(themeSpecProvider);
  if (spec == null) {
    return (null, const ValidationFailure('No active theme'));
  }
  final ws = ref.read(wallpaperProvider);
  final layout = ThemeLayout(
    PathConstants.themePath(ws.weekNum!, ws.currentThemeName!),
  );
  final path = '${layout.root}${PathConstants.sep}$themeSpecFileName';
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
