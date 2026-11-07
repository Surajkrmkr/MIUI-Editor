import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import '../../../wall_rio/infrastructure/services/thumbnail_engine.dart';
import '../../domain/buffy_storage_layout.dart';
import '../../domain/models/buffy_wallpaper.dart';
import '../providers/buffy_cms_provider.dart';
import '../providers/buffy_settings_provider.dart';
import '../providers/buffy_storage_provider.dart';

class BuffyWallpaperImportServiceNotifier extends Notifier<void> {
  @override
  void build() {}

  /// Makes [file]'s thumbnail and uploads both to Firebase, keeping a copy in
  /// the local repo if one is set. Returns the URLs for the catalog.
  Future<({String imageUrl, String thumbUrl})> uploadMedia({
    required File file,
    required String category,
    required String name,
  }) async {
    final repoPath = ref.read(buffySettingsProvider).localRepoPath;
    if (repoPath.isNotEmpty) {
      return _prepareAndUpload(repoPath, file, category, name, stage: true);
    }
    final temp = await Directory.systemTemp.createTemp('buffy_upload');
    try {
      return await _prepareAndUpload(temp.path, file, category, name, stage: false);
    } finally {
      await temp.delete(recursive: true);
    }
  }

  Future<({String imageUrl, String thumbUrl})> _prepareAndUpload(
    String repoPath,
    File file,
    String category,
    String name, {
    required bool stage,
  }) async {
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

    final publisher = await ref.read(buffyCatalogPublisherProvider.future);
    final imageObject = buffyImageObject(category, fileName);
    final thumbObject = buffyThumbObject(category, name);
    await publisher.uploadNewMedia(imageObject, await File(targetPath).readAsBytes());
    await publisher.uploadNewMedia(thumbObject, await File(thumbPath).readAsBytes());

    if (stage) {
      try {
        final relImagePath = p.relative(targetPath, from: repoPath);
        final relThumbPath = p.relative(thumbPath, from: repoPath);
        await Process.run('git', ['add', relImagePath], workingDirectory: repoPath);
        await Process.run('git', ['add', relThumbPath], workingDirectory: repoPath);
        await ref.read(buffyCmsProvider.notifier).refreshGitStatus();
      } catch (_) {}
    }

    return (
      imageUrl: buffyDownloadUrl(imageObject),
      thumbUrl: buffyDownloadUrl(thumbObject),
    );
  }

  Future<void> importWallpaper({
    required File file,
    required String category,
    required String name,
    required List<String> tags,
    required List<String> colors,
    required bool isPremium,
  }) async {
    final urls = await uploadMedia(file: file, category: category, name: name);

    final cmsState = ref.read(buffyCmsProvider);
    final walls = cmsState.wallpapers;

    // A retried batch uploads the same files again; don't list them twice.
    if (walls.any((w) => w.imageUrl == urls.imageUrl)) return;

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
      imageUrl: urls.imageUrl,
      compressUrl: urls.thumbUrl,
      tags: tags,
      colors: colors,
      isPremium: isPremium,
    );

    ref.read(buffyCmsProvider.notifier).addWallpaper(newWall);
  }
}

final buffyWallpaperImportServiceProvider =
    NotifierProvider<BuffyWallpaperImportServiceNotifier, void>(
  BuffyWallpaperImportServiceNotifier.new,
);
