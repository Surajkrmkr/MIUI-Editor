import 'dart:io';
import '../../domain/models/git_models.dart';
import '../../domain/repositories/git_repository.dart';

class CliGitRepository implements GitRepository {
  @override
  Future<bool> isGitRepository(String directory) async {
    try {
      final result = await Process.run(
        'git',
        ['rev-parse', '--is-inside-work-tree'],
        workingDirectory: directory,
      );
      return result.exitCode == 0;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<GitStatus> getStatus(String workingDirectory) async {
    final isRepo = await isGitRepository(workingDirectory);
    if (!isRepo) {
      return const GitStatus(
        isRepository: false,
        modifiedFiles: [],
        untrackedFiles: [],
        stagedFiles: [],
      );
    }

    final branchResult = await Process.run(
      'git',
      ['rev-parse', '--abbrev-ref', 'HEAD'],
      workingDirectory: workingDirectory,
    );

    final statusResult = await Process.run(
      'git',
      ['status', '--porcelain', '-b'],
      workingDirectory: workingDirectory,
    );

    final List<String> modified = [];
    final List<String> untracked = [];
    final List<String> staged = [];
    int ahead = 0;
    int behind = 0;

    final lines = statusResult.stdout.toString().split('\n');
    for (var line in lines) {
      if (line.trim().isEmpty) continue;
      
      if (line.startsWith('##')) {
        // Parse ahead/behind from branch line if present
        final match = RegExp(r'\[ahead (\d+)(?:, behind (\d+))?\]').firstMatch(line);
        if (match != null) {
          ahead = int.parse(match.group(1)!);
          if (match.group(2) != null) {
            behind = int.parse(match.group(2)!);
          }
        } else {
          final behindMatch = RegExp(r'\[behind (\d+)\]').firstMatch(line);
          if (behindMatch != null) {
            behind = int.parse(behindMatch.group(1)!);
          }
        }
        continue;
      }

      final status = line.substring(0, 2);
      final file = line.substring(3).trim();

      if (status == 'M ' || status == 'A ' || status == 'D ') {
        staged.add(file);
      } else if (status == ' M' || status == ' D') {
        modified.add(file);
      } else if (status == '??') {
        untracked.add(file);
      } else if (status == 'AM' || status == 'MM') {
        staged.add(file);
        modified.add(file);
      }
    }

    return GitStatus(
      isRepository: true,
      currentBranch: branchResult.stdout.toString().trim(),
      modifiedFiles: modified,
      untrackedFiles: untracked,
      stagedFiles: staged,
      ahead: ahead,
      behind: behind,
    );
  }

  @override
  Future<GitCommitResult> commit(String workingDirectory, String message) async {
    try {
      final result = await Process.run(
        'git',
        ['commit', '-m', message],
        workingDirectory: workingDirectory,
      );

      if (result.exitCode == 0) {
        final hashResult = await Process.run(
          'git',
          ['rev-parse', 'HEAD'],
          workingDirectory: workingDirectory,
        );
        return GitCommitResult(
          success: true,
          message: 'Committed successfully',
          commitHash: hashResult.stdout.toString().trim(),
        );
      } else {
        return GitCommitResult(
          success: false,
          message: result.stderr.toString().trim().isEmpty 
              ? result.stdout.toString().trim() 
              : result.stderr.toString().trim(),
        );
      }
    } catch (e) {
      return GitCommitResult(success: false, message: e.toString());
    }
  }

  @override
  Future<GitOperationResult> push(String workingDirectory) async {
    try {
      final result = await Process.run(
        'git',
        ['push'],
        workingDirectory: workingDirectory,
      );
      return GitOperationResult(
        success: result.exitCode == 0,
        message: result.exitCode == 0 
            ? 'Pushed successfully' 
            : (result.stderr.toString().trim().isEmpty 
                ? result.stdout.toString().trim() 
                : result.stderr.toString().trim()),
      );
    } catch (e) {
      return GitOperationResult(success: false, message: e.toString());
    }
  }

  @override
  Future<GitOperationResult> pull(String workingDirectory) async {
    try {
      final result = await Process.run(
        'git',
        ['pull'],
        workingDirectory: workingDirectory,
      );
      return GitOperationResult(
        success: result.exitCode == 0,
        message: result.exitCode == 0 
            ? 'Pulled successfully' 
            : (result.stderr.toString().trim().isEmpty 
                ? result.stdout.toString().trim() 
                : result.stderr.toString().trim()),
      );
    } catch (e) {
      return GitOperationResult(success: false, message: e.toString());
    }
  }
}
