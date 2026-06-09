import '../models/buffy_wallpaper.dart';

abstract class BuffyWallpaperRepository {
  Future<List<BuffyWallpaper>> loadWallpapers(String filePath);
  Future<void> saveWallpapers(String filePath, List<BuffyWallpaper> wallpapers);
}
