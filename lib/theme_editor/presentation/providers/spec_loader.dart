import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:theme_core/theme_core.dart';

import '../../core/constants/path_constants.dart';
import '../../domain/entities/lock_element_spec_bridge.dart';
import '../../domain/entities/user_profile.dart';
import 'element_provider.dart';
import 'icon_editor_provider.dart';
import 'spec_provider.dart';
import 'user_profile_provider.dart';
import 'wallpaper_provider.dart';

/// Reads and parses a spec file; the failure lists every error found.
Future<(ThemeSpec?, Failure?)> readThemeSpecFile(String path) async {
  final Object? json;
  try {
    json = jsonDecode(await File(path).readAsString());
  } on FileSystemException catch (e) {
    return (null, ExportFailure('Cannot read $path: ${e.message}'));
  } on FormatException catch (e) {
    return (null, ValidationFailure('$path is not valid JSON: ${e.message}'));
  }
  final parsed = ThemeSpec.parse(json);
  final spec = parsed.spec;
  if (spec == null) {
    final errors = parsed.issues.where(
      (i) => i.severity == IssueSeverity.error,
    );
    return (null, ValidationFailure(errors.join('\n')));
  }
  return (spec, null);
}

/// The design saved for a theme: the spec in its workspace, else a full spec
/// of the same title in `Preset/<themeName>/` (where theme-cli builds keep
/// theirs). Null when there is none or it can't be read.
Future<ThemeSpec?> readSavedDesign(String weekNum, String themeName) async {
  final workspace = p.join(
    PathConstants.themePath(weekNum, themeName),
    themeSpecFileName,
  );
  if (File(workspace).existsSync()) {
    final (spec, _) = await readThemeSpecFile(workspace);
    if (spec != null) return spec;
  }
  final preset = p.join(PathConstants.presetPath, themeName, 'preset.json');
  if (!File(preset).existsSync()) return null;
  final (spec, _) = await readThemeSpecFile(preset);
  return spec?.meta.title == themeName ? spec : null;
}

/// Puts [spec]'s profile, icon style and lockscreen into the editor.
void applyDesign(Ref ref, ThemeSpec spec) {
  final type = UserProfileType.values.asNameMap()[spec.meta.profile];
  if (type != null) ref.read(userProfileProvider.notifier).select(type);
  if (kUserProfiles[ref.read(userProfileProvider)]?.iconFolder !=
      spec.icons.pack) {
    ref.read(iconStyleOverrideProvider.notifier).select(spec.icons.pack);
  }
  ref.read(iconEditorProvider.notifier).loadStyle(spec.iconStyle);
  ref.read(elementProvider.notifier)
    ..setAll([for (final e in spec.lockscreen.elements) e.toLockElement()])
    ..setBgAlpha(spec.lockscreen.bgAlpha);
}

/// Opens [spec] in the editor: wallpaper, name, profile, icon style and
/// lockscreen elements. Relative paths resolve against [baseDir].
///
/// A spec without a workspace week needs [week]. Fonts, the lockscreen assets
/// folder and the output folder aren't applied: the editor resolves fonts by
/// name and keeps its own workspace layout.
Future<Failure?> applyThemeSpec(
  Ref ref,
  ThemeSpec spec, {
  required String baseDir,
  String? week,
}) async {
  final weekNum = week ?? spec.workspace?.week;
  if (weekNum == null || weekNum.isEmpty) {
    return const ValidationFailure(
      'The spec has no workspace week; give one to open it.',
    );
  }
  final wallpaper = p.normalize(p.absolute(baseDir, spec.wallpaper.lockOrHome));
  final homeWallpaper = p.normalize(p.absolute(baseDir, spec.wallpaper.home));
  if (!File(wallpaper).existsSync()) {
    return ValidationFailure('Wallpaper not found: $wallpaper');
  }
  if (!File(homeWallpaper).existsSync()) {
    return ValidationFailure('Wallpaper not found: $homeWallpaper');
  }

  // Opening the theme extracts a palette that recolors the icons, so the
  // spec's design goes on afterwards.
  await ref
      .read(wallpaperProvider.notifier)
      .openTheme(
        wallpaperPath: wallpaper,
        weekNum: weekNum,
        folderNum: spec.workspace?.folder ?? '1',
        themeName: spec.meta.title,
        designerName: spec.meta.designer,
        authorTag: spec.meta.authorTag,
        uiVersion: '${spec.meta.uiVersion}',
      );
  if (spec.wallpaper.lock != null && homeWallpaper != wallpaper) {
    ref.read(wallpaperProvider.notifier).setHomeWallpaper(homeWallpaper);
  }
  applyDesign(ref, spec);
  return null;
}

/// Lets widgets call [applyThemeSpec] without a [Ref].
final themeSpecLoaderProvider =
    Provider<
      Future<Failure?> Function(
        ThemeSpec spec, {
        required String baseDir,
        String? week,
      })
    >(
      (ref) =>
          (spec, {required baseDir, week}) =>
              applyThemeSpec(ref, spec, baseDir: baseDir, week: week),
    );
