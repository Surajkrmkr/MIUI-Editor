import 'package:freezed_annotation/freezed_annotation.dart';

part 'git_models.freezed.dart';

@freezed
abstract class GitStatus with _$GitStatus {
  const factory GitStatus({
    required bool isRepository,
    required List<String> modifiedFiles,
    required List<String> untrackedFiles,
    required List<String> stagedFiles,
    String? currentBranch,
    @Default(0) int ahead,
    @Default(0) int behind,
  }) = _GitStatus;
}

@freezed
abstract class GitCommitResult with _$GitCommitResult {
  const factory GitCommitResult({
    required bool success,
    required String message,
    String? commitHash,
  }) = _GitCommitResult;
}
