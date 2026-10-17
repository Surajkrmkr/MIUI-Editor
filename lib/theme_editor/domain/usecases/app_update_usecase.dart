import '../../core/errors/failures.dart';
import '../entities/update_info.dart';
import '../repositories/update_repository.dart';

class AppUpdateUseCase {
  const AppUpdateUseCase(this._repository);
  final UpdateRepository _repository;

  Future<(UpdateInfo?, Failure?)> check(
    String currentVersion,
    String platform,
  ) => _repository.checkForUpdate(
    currentVersion: currentVersion,
    platform: platform,
  );

  Future<(String?, Failure?)> download(
    UpdateInfo info, {
    void Function(double progress)? onProgress,
  }) => _repository.download(info, onProgress: onProgress);
}
