import 'package:miui_icon_generator/theme_editor/domain/usecases/wallpaper_download_repository.dart';

import '../../core/errors/failures.dart';

class DownloadWallpaperUseCase {
  const DownloadWallpaperUseCase(this._repo);
  final WallpaperDownloadRepository _repo;

  Future<(String?, Failure?)> call({
    required String url,
    required String destPath,
  }) =>
      _repo.download(url: url, destPath: destPath);
}
