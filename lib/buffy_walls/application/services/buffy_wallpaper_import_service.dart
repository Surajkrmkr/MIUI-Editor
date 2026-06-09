import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import '../../../wall_rio/infrastructure/services/thumbnail_engine.dart';
import '../../domain/models/buffy_wallpaper.dart';
import '../providers/buffy_cms_provider.dart';
import '../providers/buffy_settings_provider.dart';

class BuffyWallpaperImportServiceNotifier extends Notifier<void> {
  @override
  void build() {}

  static const String gitlabBaseUrl =
      'https://gitlab.com/piyushkpv/buffy_wall_data/-/raw/main/';

  Future<void> importWallpaper({
    required File file,
    required String category,
    required String name,
    required List<String> tags,
    required List<String> colors,
    required bool isPremium,
  }) async {
    final settings = ref.read(buffySettingsProvider);
    final repoPath = settings.localRepoPath;
    if (repoPath.isEmpty) {
      throw Exception('Buffy Repository Path is not configured in Settings.');
    }

    final ext = p.extension(file.path).toLowerCase();
    final fileName = '$name$ext';

    final categoryDir = Directory(p.join(repoPath, category));
    if (!await categoryDir.exists()) {
      await categoryDir.create(recursive: true);
    }

    final thumbnailDir = Directory(p.join(categoryDir.path, 'Thumbnails'));
    if (!await thumbnailDir.exists()) {
      await thumbnailDir.create(recursive: true);
    }

    final targetPath = p.join(categoryDir.path, fileName);
    await file.copy(targetPath);

    final thumbPath = p.join(thumbnailDir.path, '$name-small.jpg');
    await ThumbnailEngine.generateThumbnail(
      inputPath: targetPath,
      outputPath: thumbPath,
    );

    final wallUrl =
        '$gitlabBaseUrl${Uri.encodeComponent(category)}/${Uri.encodeComponent(fileName)}';
    final thumbUrl =
        '$gitlabBaseUrl${Uri.encodeComponent(category)}/Thumbnails/${Uri.encodeComponent(name)}-small.jpg';

    final cmsState = ref.read(buffyCmsProvider);
    final walls = cmsState.wallpapers;

    final nextId = walls.isEmpty
        ? 1
        : walls
                .map((w) => w.id)
                .reduce((a, b) => a > b ? a : b) +
            1;

    final newWall = BuffyWallpaper(
      id: nextId,
      name: name,
      category: category,
      imageUrl: wallUrl,
      compressUrl: thumbUrl,
      tags: tags,
      colors: colors,
      isPremium: isPremium,
    );

    ref.read(buffyCmsProvider.notifier).addWallpaper(newWall);

    try {
      final relImagePath = p.relative(targetPath, from: repoPath);
      final relThumbPath = p.relative(thumbPath, from: repoPath);
      await Process.run('git', ['add', relImagePath], workingDirectory: repoPath);
      await Process.run('git', ['add', relThumbPath], workingDirectory: repoPath);
      await ref.read(buffyCmsProvider.notifier).refreshGitStatus();
    } catch (_) {}
  }
}

final buffyWallpaperImportServiceProvider =
    NotifierProvider<BuffyWallpaperImportServiceNotifier, void>(
  BuffyWallpaperImportServiceNotifier.new,
);
