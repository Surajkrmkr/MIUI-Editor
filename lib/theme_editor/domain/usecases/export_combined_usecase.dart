import 'package:flutter/material.dart';
import '../../core/errors/failures.dart';
import '../../domain/entities/user_profile.dart';
import '../../presentation/providers/icon_editor_provider.dart';
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
    required BuildContext context,
    required IconEditorState editorState,
    required UserProfile profile,
    required String themePath,
    required String themeName,
    required String wallpaperSourcePath,
    required List<String> iconNames,
    required void Function(int done, int total) onProgress,
    String? designerName,
    String? authorTag,
    String uiVersion = '17',
  }) async {
    // Phase 1 — Icons
    final iconFailure = await exportIcons.call(
      context: context,
      editorState: editorState,
      profile: profile,
      themePath: themePath,
      iconNames: iconNames,
      onProgress: onProgress,
    );
    if (iconFailure != null) return iconFailure;

    // Phase 2 — Module (description, clock, colors, wallpaper)
    final moduleFailure = await exportModule.call(
      accentColor: editorState.accentColor,
      profile: profile,
      themePath: themePath,
      themeName: themeName,
      wallpaperSourcePath: wallpaperSourcePath,
      designerName: designerName,
      authorTag: authorTag,
      uiVersion: uiVersion,
    );
    if (moduleFailure != null) return moduleFailure;

    // Phase 3 — HyperOS 3 control center, notifications, dialer, messaging
    return exportSystemModules.call(
      accent: editorState.accentColor,
      themePath: themePath,
      wallpaperSourcePath: wallpaperSourcePath,
      style: editorState,
      iconFolder: profile.iconFolder,
    );
  }
}
