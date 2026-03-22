import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import 'package:miui_icon_generator/theme_editor/domain/usecases/wallpaper_download_repository.dart';
import '../../core/errors/failures.dart';

class WallpaperDownloadRepositoryImpl implements WallpaperDownloadRepository {
  @override
  Future<(String?, Failure?)> download({
    required String url,
    required String destPath,
  }) async {
    try {
      final res = await http.get(Uri.parse(url));
      if (res.statusCode != 200) {
        return (null, NetworkFailure('HTTP ${res.statusCode}'));
      }
      var bytes = res.bodyBytes;

      // Pixabay sometimes returns PNG — convert to JPG for consistency
      if (url.toLowerCase().endsWith('.png')) {
        final decoded = img.decodeImage(bytes)!;
        bytes = img.encodeJpg(decoded);
      }

      final file = File(destPath);
      await file.parent.create(recursive: true);
      await file.writeAsBytes(bytes);
      return (destPath, null);
    } catch (e) {
      return (null, NetworkFailure(e.toString()));
    }
  }
}
