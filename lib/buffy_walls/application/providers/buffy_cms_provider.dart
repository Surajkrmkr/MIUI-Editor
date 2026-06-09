import 'dart:async';

import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:miui_icon_generator/wall_rio/domain/models/git_models.dart';
import 'package:miui_icon_generator/wall_rio/domain/repositories/git_repository.dart';
import 'package:miui_icon_generator/wall_rio/infrastructure/repositories/cli_git_repository.dart';
import '../../domain/models/buffy_wallpaper.dart';
import '../../infrastructure/repositories/local_buffy_repository.dart';
import 'buffy_settings_provider.dart';

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
  final String? currentFilePath;
  final GitStatus? gitStatus;

  BuffyCmsState({
    this.wallpapers = const [],
    this.isLoading = false,
    this.error,
    this.currentFilePath,
    this.gitStatus,
  });

  BuffyCmsState copyWith({
    List<BuffyWallpaper>? wallpapers,
    bool? isLoading,
    String? error,
    String? currentFilePath,
    GitStatus? gitStatus,
  }) {
    return BuffyCmsState(
      wallpapers: wallpapers ?? this.wallpapers,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      currentFilePath: currentFilePath ?? this.currentFilePath,
      gitStatus: gitStatus ?? this.gitStatus,
    );
  }
}

class BuffyCmsNotifier extends Notifier<BuffyCmsState> {
  @override
  BuffyCmsState build() {
    final settings = ref.watch(buffySettingsProvider);
    if (settings.jsonFilePath.isNotEmpty) {
      Future.microtask(() => loadFile(settings.jsonFilePath));
    }
    return BuffyCmsState();
  }

  final _repository = LocalBuffyRepository();
  final _gitRepository = CliGitRepository();

  String? _getWorkingDir() {
    final target = ref.read(activeBuffyGitTargetProvider);
    final settings = ref.read(buffySettingsProvider);
    if (target == BuffyGitRepoTarget.json) {
      return settings.jsonFilePath.isNotEmpty ? File(settings.jsonFilePath).parent.path : null;
    } else {
      return settings.localRepoPath.isNotEmpty ? settings.localRepoPath : null;
    }
  }

  Future<void> loadFile(String filePath) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final walls = await _repository.loadWallpapers(filePath);
      state = state.copyWith(
        wallpapers: walls,
        isLoading: false,
        currentFilePath: filePath,
      );
      await refreshGitStatus();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
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

  Future<void> saveFile() async {
    if (state.currentFilePath == null) return;
    state = state.copyWith(isLoading: true);
    try {
      await _repository.saveWallpapers(state.currentFilePath!, state.wallpapers);
      state = state.copyWith(isLoading: false);
      await refreshGitStatus();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void addWallpaper(BuffyWallpaper wallpaper) {
    state = state.copyWith(wallpapers: [wallpaper, ...state.wallpapers]);
  }

  void updateWallpaper(BuffyWallpaper wallpaper) {
    state = state.copyWith(
      wallpapers: state.wallpapers.map((w) => w.id == wallpaper.id ? wallpaper : w).toList(),
    );
  }

  void deleteWallpaper(int id) {
    state = state.copyWith(
      wallpapers: state.wallpapers.where((w) => w.id != id).toList(),
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
      if (state.currentFilePath != null && ref.read(activeBuffyGitTargetProvider) == BuffyGitRepoTarget.json) {
        await loadFile(state.currentFilePath!);
      } else {
        await refreshGitStatus();
        state = state.copyWith(isLoading: false);
      }
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
