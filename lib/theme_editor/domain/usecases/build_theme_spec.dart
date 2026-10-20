import 'package:theme_core/theme_core.dart';
import '../entities/element_widget.dart';
import '../entities/lock_element_spec_bridge.dart';
import '../entities/user_profile.dart';

/// Describes the editor's current theme as a [ThemeSpec].
///
/// Designer and author tag must already be resolved (the profile's values when
/// the settings are blank), so the spec holds exactly what gets written to
/// `description.xml`.
ThemeSpec buildThemeSpec({
  required String themeName,
  required String wallpaperPath,
  String? homeWallpaperPath,
  required String designer,
  required String authorTag,
  required String uiVersion,
  required UserProfile profile,
  required IconStyle style,
  required List<LockElement> elements,
  required double bgAlpha,
  String? week,
  String? folder,
  String? lockscreenAssetsDir,
  String? outputDir,
}) {
  final specs = [for (final e in elements) e.toSpec()];
  final fontRefs = {
    for (final e in specs)
      if (FontRef.parse(e.font).needsFile) e.font,
  };
  return ThemeSpec(
    meta: MetaSpec(
      title: themeName,
      designer: designer,
      authorTag: authorTag,
      uiVersion: int.tryParse(uiVersion) ?? 17,
      profile: profile.type.name,
    ),
    workspace: week == null && folder == null
        ? null
        : WorkspaceSpec(week: week, folder: folder),
    wallpaper: WallpaperSpec(
      home: homeWallpaperPath ?? wallpaperPath,
      lock: homeWallpaperPath == null ? null : wallpaperPath,
    ),
    icons: IconsSpec.fromStyle(style, pack: profile.iconFolder),
    systemUi: SystemUiSpec(
      accent: style.accent,
      controlCenterTemplate: style.ccTemplate,
    ),
    lockscreen: LockscreenSpec(
      bgAlpha: bgAlpha,
      assetsDir: lockscreenAssetsDir,
      elements: specs,
    ),
    fonts: [for (final ref in fontRefs) FontSpec(ref: ref)],
    output: OutputSpec(name: themeName, dir: outputDir),
  );
}
