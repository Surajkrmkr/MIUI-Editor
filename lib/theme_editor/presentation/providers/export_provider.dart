import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/usecases/export_combined_usecase.dart';
import '../../domain/usecases/export_icons_usecase.dart';
import '../../domain/usecases/export_module_usecase.dart';
import 'icon_editor_provider.dart';
import 'user_profile_provider.dart';
import 'wallpaper_provider.dart';
import '../../core/constants/path_constants.dart';

// ── Use case providers (singletons — no deps that change) ─────────────────────

final exportIconsUseCaseProvider =
    Provider<ExportIconsUseCase>((_) => const ExportIconsUseCase());

final exportModuleUseCaseProvider =
    Provider<ExportModuleUseCase>((_) => const ExportModuleUseCase());

final exportCombinedUseCaseProvider = Provider<ExportCombinedUseCase>((ref) =>
    ExportCombinedUseCase(
      exportIcons:  ref.read(exportIconsUseCaseProvider),
      exportModule: ref.read(exportModuleUseCaseProvider),
    ));

// ── Export state ──────────────────────────────────────────────────────────────

enum ExportPhase { idle, icons, module, done, error }

class ExportState {
  const ExportState({
    this.phase = ExportPhase.idle,
    this.iconsDone = 0,
    this.iconsTotal = 0,
    this.isExported = false,
    this.error,
  });

  final ExportPhase phase;
  final int iconsDone;
  final int iconsTotal;
  final bool isExported;
  final String? error;

  bool get isRunning =>
      phase == ExportPhase.icons || phase == ExportPhase.module;

  double get progress =>
      iconsTotal == 0 ? 0 : iconsDone / iconsTotal;

  String get statusLabel => switch (phase) {
        ExportPhase.idle   => '',
        ExportPhase.icons  => 'Icons $iconsDone/$iconsTotal',
        ExportPhase.module => 'Module & Description...',
        ExportPhase.done   => 'Done ✅',
        ExportPhase.error  => error ?? 'Error',
      };

  ExportState copyWith({
    ExportPhase? phase,
    int? iconsDone,
    int? iconsTotal,
    bool? isExported,
    String? error,
  }) =>
      ExportState(
        phase:       phase       ?? this.phase,
        iconsDone:   iconsDone   ?? this.iconsDone,
        iconsTotal:  iconsTotal  ?? this.iconsTotal,
        isExported:  isExported  ?? this.isExported,
        error:       error,
      );
}

class ExportNotifier extends Notifier<ExportState> {
  @override
  ExportState build() => const ExportState();

  void resetExportState() {
    state = state.copyWith(
      phase:      ExportPhase.idle,
      isExported: false,
      iconsDone:  0,
      iconsTotal: 0,
      error:      null,
    );
  }

  /// Checks disk and updates isExported badge.
  /// Called after reset so the badge reflects the NEW theme, not the old one.
  Future<void> checkExported() async {
    final ws = ref.read(wallpaperProvider);
    if (ws.weekNum == null || ws.currentThemeName == null) return;
    final tp = PathConstants.themePath(ws.weekNum!, ws.currentThemeName!);
    // Consider exported if description.xml exists (written by module export)
    final exists = await File(
        PathConstants.p('${tp}description.xml')).exists();
    state = state.copyWith(isExported: exists);
  }

  // ── Main export entry point ────────────────────────────────────────────────

  Future<void> exportAll(BuildContext context) async {
    final ws      = ref.read(wallpaperProvider);
    final editor  = ref.read(iconEditorProvider);
    final profile = ref.read(activeUserProfileProvider);

    // ── Guards ────────────────────────────────────────────────────────────────
    if (profile == null) {
      state = state.copyWith(
          phase: ExportPhase.error, error: 'No user profile selected');
      return;
    }
    if (ws.weekNum == null || ws.currentThemeName == null) {
      state = state.copyWith(
          phase: ExportPhase.error, error: 'No active theme');
      return;
    }
    if (ws.currentPath == null) {
      state = state.copyWith(
          phase: ExportPhase.error, error: 'No wallpaper selected');
      return;
    }
    if (editor.iconAssetsPath.isEmpty) {
      state = state.copyWith(
          phase: ExportPhase.error, error: 'Icon list is empty — did you select a user profile?');
      return;
    }

    final themePath   = PathConstants.themePath(ws.weekNum!, ws.currentThemeName!);
    final iconNames   = editor.iconAssetsPath.cast<String>();

    state = state.copyWith(
      phase:      ExportPhase.icons,
      iconsTotal: iconNames.length,
      iconsDone:  0,
      error:      null,
    );

    final useCase = ref.read(exportCombinedUseCaseProvider);
    final failure = await useCase.call(
      context:             context,
      editorState:         editor,
      profile:             profile,
      themePath:           themePath,
      themeName:           ws.currentThemeName!,
      wallpaperSourcePath: ws.currentPath!,
      iconNames:           iconNames,
      designerName:        ws.designerName.isNotEmpty ? ws.designerName : null,
      authorTag:           ws.authorTag.isNotEmpty ? ws.authorTag : null,
      uiVersion:           ws.uiVersion.isNotEmpty ? ws.uiVersion : '17',
      onProgress:          (done, total) {
        state = state.copyWith(
          phase:     ExportPhase.icons,
          iconsDone: done,
        );
        // Flip to module phase when icons are complete
        if (done == total) {
          state = state.copyWith(phase: ExportPhase.module);
        }
      },
    );

    if (failure != null) {
      state = state.copyWith(
          phase: ExportPhase.error, error: failure.message);
    } else {
      state = state.copyWith(phase: ExportPhase.done, isExported: true);
      // Auto-reset status label after 3 seconds
      Future.delayed(const Duration(seconds: 3), () {
        if (state.phase == ExportPhase.done) {
          state = state.copyWith(phase: ExportPhase.idle);
        }
      });
    }
  }
}

final exportProvider =
    NotifierProvider<ExportNotifier, ExportState>(ExportNotifier.new);
