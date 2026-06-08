import '../models/wallpaper.dart';

abstract class WallpaperRepository {
  Future<RioData> loadData(String filePath);
  Future<void> saveData(String filePath, RioData data);
}
