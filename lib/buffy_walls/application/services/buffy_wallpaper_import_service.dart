import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import '../../../wall_rio/infrastructure/services/thumbnail_engine.dart';
import '../../domain/buffy_storage_layout.dart';
import '../../domain/models/buffy_wallpaper.dart';
import '../providers/buffy_cms_provider.dart';
import '../providers/buffy_storage_provider.dart';

class BuffyWallpaperImportServiceNotifier extends Notifier<void> {
  @override
  void build() {}

  /// Makes [file]'s thumbnail and uploads both to Cloudflare R2. Returns the
  /// URLs for the catalog.
  Future<({String imageUrl, String thumbUrl})> uploadMedia({
    required File file,
    required String category,
    required String name,
  }) async {
    final temp = await Directory.systemTemp.createTemp('buffy_upload');
    try {
      final ext = p.extension(file.path).toLowerCase();
      final fileName = '$name$ext';
      final thumbPath = p.join(temp.path, 'thumb.jpg');
      await ThumbnailEngine.generateThumbnail(
        inputPath: file.path,
        outputPath: thumbPath,
      );

      final publisher = await ref.read(buffyCatalogPublisherProvider.future);
      final imageObject = buffyImageObject(category, fileName);
      final thumbObject = buffyThumbObject(category, name);
      await publisher.uploadNewMedia(imageObject, await file.readAsBytes());
      await publisher.uploadNewMedia(
        thumbObject,
        await File(thumbPath).readAsBytes(),
      );
      return (
        imageUrl: buffyDownloadUrl(imageObject),
        thumbUrl: buffyDownloadUrl(thumbObject),
      );
    } finally {
      await temp.delete(recursive: true);
    }
  }

  /// Uploads [file] and adds it to the catalog as an unpublished edit.
  Future<void> importWallpaper({
    required File file,
    required String category,
    required String name,
    String designer = 'Buffy',
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
        : walls.map((w) => w.id).reduce((a, b) => a > b ? a : b) + 1;

    final newWall = BuffyWallpaper(
      id: nextId,
      name: name,
      designer: designer,
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
