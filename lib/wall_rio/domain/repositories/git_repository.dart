import '../models/git_models.dart';

abstract class GitRepository {
  Future<GitStatus> getStatus(String workingDirectory);
  Future<GitCommitResult> commit(String workingDirectory, String message);
  Future<GitOperationResult> push(String workingDirectory);
  Future<GitOperationResult> pull(String workingDirectory);
  Future<bool> isGitRepository(String directory);
}

class GitOperationResult {
  final bool success;
  final String message;

  const GitOperationResult({required this.success, required this.message});
}
