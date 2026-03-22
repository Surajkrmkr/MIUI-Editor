import '../../core/errors/failures.dart';

abstract interface class WallpaperDownloadRepository {
  /// Downloads [url] and saves it as [destPath].
  /// Returns the final saved path or a failure.
  Future<(String?, Failure?)> download({
    required String url,
    required String destPath,
  });
}
