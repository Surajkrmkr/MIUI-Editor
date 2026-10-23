import 'package:theme_core/theme_core.dart';
import '../../core/extensions/core_value_adapters.dart';
import '../../domain/entities/user_profile.dart';
import 'export_icons_usecase.dart';
import 'export_module_usecase.dart';
import 'export_system_modules_usecase.dart';

/// Runs icon export → module export → system modules in sequence.
/// The UI only needs to call this one use case.
/// Progress is forwarded through [onProgress].
class ExportCombinedUseCase {
  const ExportCombinedUseCase({
    required this.exportIcons,
    required this.exportModule,
    this.exportSystemModules = const ExportSystemModulesUseCase(),
  });

  final ExportIconsUseCase exportIcons;
  final ExportModuleUseCase exportModule;
  final ExportSystemModulesUseCase exportSystemModules;

  Future<Failure?> call({
    required IconStyle style,
    required UserProfile profile,
    required ThemeLayout layout,
    required String themeName,
    required String wallpaperSourcePath,
    String? lockWallpaperSourcePath,
    required List<String> iconNames,
    required void Function(int done, int total) onProgress,
    String? designerName,
    String? authorTag,
    String uiVersion = '17',
  }) async {
    // Phase 1 — Icons
    final iconFailure = await exportIcons.call(
      style: style,
      profile: profile,
      layout: layout,
      iconNames: iconNames,
      onProgress: onProgress,
    );
    if (iconFailure != null) return iconFailure;

    // Phase 2 — Module (description, clock, colors, wallpaper)
    final moduleFailure = await exportModule.call(
      profile: profile,
      layout: layout,
      themeName: themeName,
      wallpaperSourcePath: wallpaperSourcePath,
      lockWallpaperSourcePath: lockWallpaperSourcePath,
      designerName: designerName,
      authorTag: authorTag,
      uiVersion: uiVersion,
    );
    if (moduleFailure != null) return moduleFailure;

    // Phase 3 — HyperOS 3 control center, notifications, dialer, messaging
    return exportSystemModules.call(
      accent: style.accent.toColor(),
      layout: layout,
      wallpaperSourcePath: wallpaperSourcePath,
      style: style,
      iconFolder: profile.iconFolder,
    );
  }
}
