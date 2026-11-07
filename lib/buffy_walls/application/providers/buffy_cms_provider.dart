import 'dart:async';

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:miui_icon_generator/wall_rio/domain/models/git_models.dart';
import 'package:miui_icon_generator/wall_rio/domain/repositories/git_repository.dart';
import 'package:miui_icon_generator/wall_rio/infrastructure/repositories/cli_git_repository.dart';
import '../../domain/buffy_catalog_json.dart';
import '../../domain/models/buffy_wallpaper.dart';
import 'buffy_settings_provider.dart';
import 'buffy_storage_provider.dart';

enum BuffyGitRepoTarget { json, wallpapers }

class ActiveBuffyGitTargetNotifier extends Notifier<BuffyGitRepoTarget> {
  @override
  BuffyGitRepoTarget build() => BuffyGitRepoTarget.json;

  void set(BuffyGitRepoTarget target) => state = target;
}

final activeBuffyGitTargetProvider = NotifierProvider<ActiveBuffyGitTargetNotifier, BuffyGitRepoTarget>(
  ActiveBuffyGitTargetNotifier.new,
);

class BuffyCmsState {
  final List<BuffyWallpaper> wallpapers;
  final bool isLoading;
  final String? error;
  /// The catalog as loaded from Firebase, and its generation. Null until loaded.
  final String? catalogJson;
  final String? generation;

  /// Edits not published yet; they exist only in memory.
  final bool isDirty;
  final GitStatus? gitStatus;

  BuffyCmsState({
    this.wallpapers = const [],
    this.isLoading = false,
    this.error,
    this.catalogJson,
    this.generation,
    this.isDirty = false,
    this.gitStatus,
  });

  BuffyCmsState copyWith({
    List<BuffyWallpaper>? wallpapers,
    bool? isLoading,
    String? error,
    String? catalogJson,
    String? generation,
    bool? isDirty,
    GitStatus? gitStatus,
  }) {
    return BuffyCmsState(
      wallpapers: wallpapers ?? this.wallpapers,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      catalogJson: catalogJson ?? this.catalogJson,
      generation: generation ?? this.generation,
      isDirty: isDirty ?? this.isDirty,
      gitStatus: gitStatus ?? this.gitStatus,
    );
  }
}

class BuffyCmsNotifier extends Notifier<BuffyCmsState> {
  @override
  BuffyCmsState build() {
    // Signing in rebuilds the publisher; pick up the catalog then.
    ref.listen(buffyCatalogPublisherProvider, (_, next) {
      if (next is AsyncData && !state.isDirty) load();
    });
    Future.microtask(load);
    return BuffyCmsState();
  }

  final _gitRepository = CliGitRepository();
  Future<void>? _loading;

  String? _getWorkingDir() {
    final target = ref.read(activeBuffyGitTargetProvider);
    final settings = ref.read(buffySettingsProvider);
    if (target == BuffyGitRepoTarget.json) {
      return settings.jsonFilePath.isNotEmpty ? File(settings.jsonFilePath).parent.path : null;
    } else {
      return settings.localRepoPath.isNotEmpty ? settings.localRepoPath : null;
    }
  }

  /// Loads the live catalog from Firebase, dropping unpublished edits.
  Future<void> load() =>
      _loading ??= _load().whenComplete(() => _loading = null);

  Future<void> _load() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final publisher = await ref.read(buffyCatalogPublisherProvider.future);
      final live = await publisher.load();
      final walls = await compute(parseBuffyCatalog, live.json);
      state = state.copyWith(
        wallpapers: walls,
        isLoading: false,
        catalogJson: live.json,
        generation: live.generation,
        isDirty: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return;
    }
    await refreshGitStatus();
  }

  /// The catalog with the current edits applied.
  Future<String> buildCatalogJson() => compute(encodeBuffyCatalog, (
        catalog: state.catalogJson!,
        wallpapers: state.wallpapers.map((w) => w.toJson()).toList(),
      ));

  void markPublished(String json, String generation) {
    state = state.copyWith(
      catalogJson: json,
      generation: generation,
      isDirty: false,
    );
  }

  Future<void> refreshGitStatus() async {
    final workingDir = _getWorkingDir();
    if (workingDir != null) {
      final status = await _gitRepository.getStatus(workingDir);
      state = state.copyWith(gitStatus: status);
    } else {
      state = state.copyWith(gitStatus: null);
    }
  }

  void addWallpaper(BuffyWallpaper wallpaper) {
    state = state.copyWith(
      wallpapers: [wallpaper, ...state.wallpapers],
      isDirty: true,
    );
  }

  void updateWallpaper(BuffyWallpaper wallpaper) {
    state = state.copyWith(
      wallpapers: state.wallpapers.map((w) => w.id == wallpaper.id ? wallpaper : w).toList(),
      isDirty: true,
    );
  }

  void deleteWallpaper(int id) {
    state = state.copyWith(
      wallpapers: state.wallpapers.where((w) => w.id != id).toList(),
      isDirty: true,
    );
  }

  Future<void> stageFile(String file) async {
    final workingDir = _getWorkingDir();
    if (workingDir != null) {
      await Process.run('git', ['add', file], workingDirectory: workingDir);
      await refreshGitStatus();
    }
  }

  Future<void> unstageFile(String file) async {
    final workingDir = _getWorkingDir();
    if (workingDir != null) {
      await Process.run('git', ['reset', 'HEAD', file], workingDirectory: workingDir);
      await refreshGitStatus();
    }
  }

  Future<GitOperationResult> pull() async {
    final workingDir = _getWorkingDir();
    if (workingDir == null) {
      return const GitOperationResult(success: false, message: 'No repo configured');
    }
    state = state.copyWith(isLoading: true);
    final result = await _gitRepository.pull(workingDir);
    if (result.success) {
      await refreshGitStatus();
      state = state.copyWith(isLoading: false);
    } else {
      state = state.copyWith(isLoading: false, error: result.message);
    }
    return result;
  }

  Future<GitCommitResult> commit(String message) async {
    final workingDir = _getWorkingDir();
    if (workingDir == null) {
      return const GitCommitResult(success: false, message: 'No repo configured');
    }
    state = state.copyWith(isLoading: true);
    final result = await _gitRepository.commit(workingDir, message);
    await refreshGitStatus();
    state = state.copyWith(isLoading: false);
    return result;
  }

  Future<GitOperationResult> push([String? message]) async {
    final workingDir = _getWorkingDir();
    if (workingDir == null) {
      return const GitOperationResult(success: false, message: 'No repo configured');
    }
    state = state.copyWith(isLoading: true);
    
    if (message != null && message.isNotEmpty) {
      await Process.run('git', ['add', '.'], workingDirectory: workingDir);
      await _gitRepository.commit(workingDir, message);
    }
    
    final result = await _gitRepository.push(workingDir);
    await refreshGitStatus();
    state = state.copyWith(isLoading: false);
    return result;
  }
}

final buffyCmsProvider = NotifierProvider<BuffyCmsNotifier, BuffyCmsState>(() {
  return BuffyCmsNotifier();
});
