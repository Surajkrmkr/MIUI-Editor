import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';
import '../../domain/models/wallpaper.dart';
import '../../infrastructure/services/thumbnail_engine.dart';
import '../providers/cms_provider.dart';
import '../providers/git_provider.dart';
import '../providers/settings_provider.dart';

class WallpaperImportServiceNotifier extends Notifier<void> {
  @override
  void build() {}

  static const String gitlabBaseUrl =
      'https://gitlab.com/piyushkpv/wallrio_wall_data/-/raw/main/';

  Future<void> importWallpaper({
    required File file,
    required String category,
    required String name,
    required List<String> tags,
    required List<String> colors,
    required bool isPremium,
  }) async {
    final repoPath = await ref.read(wallpaperRepoPathProvider.future);
    if (repoPath == null || repoPath.isEmpty) {
      throw Exception('Wallpaper Repository Path is not configured in Settings.');
    }

    final ext = p.extension(file.path).toLowerCase();
    final fileName = '$name$ext';

    final categoryDir = Directory(p.join(repoPath, category));
    if (!await categoryDir.exists()) {
      await categoryDir.create(recursive: true);
    }

    final thumbnailDir = Directory(p.join(categoryDir.path, 'Thumbnail'));
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
        '$gitlabBaseUrl${Uri.encodeComponent(category)}/Thumbnail/${Uri.encodeComponent(name)}-small.jpg';

    final cmsState = ref.read(cmsProvider);
    final walls = cmsState.value?.walls ?? [];

    final nextId = walls.isEmpty
        ? 1
        : walls
                .map((w) => (w.id is int)
                    ? (w.id as int)
                    : int.tryParse(w.id.toString()) ?? 0)
                .reduce((a, b) => a > b ? a : b) +
            1;

    final newWall = Wallpaper(
      id: nextId,
      name: name,
      author: 'WallRio',
      url: wallUrl,
      thumbnail: thumbUrl,
      tags: tags,
      category: category,
      color: colors,
      isPremium: isPremium,
      subjectId: const Uuid().v4(),
    );

    ref.read(cmsProvider.notifier).addWallpaper(newWall);

    try {
      final relImagePath = p.relative(targetPath, from: repoPath);
      final relThumbPath = p.relative(thumbPath, from: repoPath);
      await Process.run('git', ['add', relImagePath], workingDirectory: repoPath);
      await Process.run('git', ['add', relThumbPath], workingDirectory: repoPath);
      await ref.read(gitStateProvider.notifier).refresh();
    } catch (_) {}
  }

  Future<void> importBatch(List<Map<String, dynamic>> batch) async {
    for (final item in batch) {
      await importWallpaper(
        file: item['file'],
        category: item['category'],
        name: item['name'],
        tags: item['tags'],
        colors: item['colors'],
        isPremium: item['isPremium'],
      );
    }
  }
}

final wallpaperImportServiceProvider =
    NotifierProvider<WallpaperImportServiceNotifier, void>(
  WallpaperImportServiceNotifier.new,
);
