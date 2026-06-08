import 'dart:async';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/git_models.dart';
import '../../domain/repositories/git_repository.dart';
import 'cms_provider.dart';
import 'repository_providers.dart';
import 'settings_provider.dart';

enum GitRepoTarget { json, wallpapers }

class ActiveGitTargetNotifier extends Notifier<GitRepoTarget> {
  @override
  GitRepoTarget build() => GitRepoTarget.json;

  void set(GitRepoTarget target) => state = target;
}

final activeGitTargetProvider = NotifierProvider<ActiveGitTargetNotifier, GitRepoTarget>(
  ActiveGitTargetNotifier.new,
);

class GitStateNotifier extends AsyncNotifier<GitStatus?> {
  @override
  FutureOr<GitStatus?> build() async {
    final target = ref.watch(activeGitTargetProvider);
    String? workingDir;

    if (target == GitRepoTarget.json) {
      final path = ref.watch(currentFilePathProvider);
      if (path != null) workingDir = File(path).parent.path;
    } else {
      workingDir = await ref.watch(wallpaperRepoPathProvider.future);
    }

    if (workingDir == null || workingDir.isEmpty) return null;

    final repository = ref.read(wallRioGitRepositoryProvider);
    return await repository.getStatus(workingDir);
  }

  Future<String?> _getWorkingDir() async {
    final target = ref.read(activeGitTargetProvider);
    if (target == GitRepoTarget.json) {
      final path = ref.read(currentFilePathProvider);
      return path != null ? File(path).parent.path : null;
    } else {
      return await ref.read(wallpaperRepoPathProvider.future);
    }
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final workingDir = await _getWorkingDir();
      if (workingDir == null) return null;
      return await ref.read(wallRioGitRepositoryProvider).getStatus(workingDir);
    });
  }

  Future<GitCommitResult> commit(String message) async {
    final workingDir = await _getWorkingDir();
    if (workingDir == null) throw Exception('No repository path configured');
    final result = await ref.read(wallRioGitRepositoryProvider).commit(workingDir, message);
    if (result.success) await refresh();
    return result;
  }

  Future<GitOperationResult> push() async {
    final workingDir = await _getWorkingDir();
    if (workingDir == null) throw Exception('No repository path configured');
    final result = await ref.read(wallRioGitRepositoryProvider).push(workingDir);
    if (result.success) await refresh();
    return result;
  }

  Future<GitOperationResult> pull() async {
    final workingDir = await _getWorkingDir();
    if (workingDir == null) throw Exception('No repository path configured');
    final result = await ref.read(wallRioGitRepositoryProvider).pull(workingDir);
    if (result.success) await refresh();
    return result;
  }

  Future<void> stageFile(String relativePath) async {
    final workingDir = await _getWorkingDir();
    if (workingDir == null) return;
    await Process.run('git', ['add', relativePath], workingDirectory: workingDir);
    await refresh();
  }

  Future<void> unstageFile(String relativePath) async {
    final workingDir = await _getWorkingDir();
    if (workingDir == null) return;
    await Process.run('git', ['reset', 'HEAD', relativePath], workingDirectory: workingDir);
    await refresh();
  }

  Future<void> stageAll() async {
    final workingDir = await _getWorkingDir();
    if (workingDir == null) return;
    await Process.run('git', ['add', '.'], workingDirectory: workingDir);
    await refresh();
  }

  Future<void> unstageAll() async {
    final workingDir = await _getWorkingDir();
    if (workingDir == null) return;
    await Process.run('git', ['reset', 'HEAD'], workingDirectory: workingDir);
    await refresh();
  }
}

final gitStateProvider = AsyncNotifierProvider<GitStateNotifier, GitStatus?>(
  GitStateNotifier.new,
);
