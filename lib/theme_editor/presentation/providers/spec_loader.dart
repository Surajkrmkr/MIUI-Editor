import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:theme_core/theme_core.dart';

import '../../domain/entities/lock_element_spec_bridge.dart';
import '../../domain/entities/user_profile.dart';
import 'element_provider.dart';
import 'icon_editor_provider.dart';
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
  final wallpaper = p.normalize(p.absolute(baseDir, spec.wallpaper.home));
  if (!File(wallpaper).existsSync()) {
    return ValidationFailure('Wallpaper not found: $wallpaper');
  }

  final profile = ref.read(userProfileProvider.notifier);
  final type = UserProfileType.values.asNameMap()[spec.meta.profile];
  if (type != null) profile.select(type);
  if (kUserProfiles[ref.read(userProfileProvider)]?.iconFolder !=
      spec.icons.pack) {
    ref.read(iconStyleOverrideProvider.notifier).select(spec.icons.pack);
  }

  // Opening the theme extracts a palette that recolors the icons, so the
  // spec's style goes on afterwards.
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
  ref.read(iconEditorProvider.notifier).loadStyle(spec.iconStyle);
  ref.read(elementProvider.notifier)
    ..setAll([for (final e in spec.lockscreen.elements) e.toLockElement()])
    ..setBgAlpha(spec.lockscreen.bgAlpha);
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
