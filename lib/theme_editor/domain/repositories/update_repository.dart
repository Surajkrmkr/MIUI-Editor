import '../../core/errors/failures.dart';
import '../entities/update_info.dart';

abstract interface class UpdateRepository {
  /// Returns null info when [currentVersion] is already the latest.
  Future<(UpdateInfo?, Failure?)> checkForUpdate({
    required String currentVersion,
    required String platform,
  });

  /// Downloads and checksum-verifies the release archive, returning its path.
  Future<(String?, Failure?)> download(
    UpdateInfo info, {
    void Function(double progress)? onProgress,
  });
}
