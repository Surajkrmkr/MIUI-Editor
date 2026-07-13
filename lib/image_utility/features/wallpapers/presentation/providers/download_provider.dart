import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:miui_icon_generator/image_utility/core/config/app_config.dart';
import 'package:miui_icon_generator/image_utility/core/services/ai_service.dart';
import 'package:miui_icon_generator/image_utility/core/services/tags_service.dart';
import 'package:miui_icon_generator/image_utility/core/services/image_processing_service.dart';
import 'package:miui_icon_generator/image_utility/core/services/copyright_service.dart';
import 'package:miui_icon_generator/image_utility/core/providers/image_source_registry.dart';
import 'package:miui_icon_generator/image_utility/features/wallpapers/domain/entities/wallpaper.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;

/// Result of the complete download and processing workflow
class DownloadResult {
  final String aiName;
  final List<String> tags;
  /// Tags present in both the wallpaper's own tags and tags.json — shown as
  /// quick-add suggestions in the rename dialog.
  final List<String> suggestedTags;
  /// The full canonical tag list from tags.json — used to power autocomplete
  /// when the user types a new tag in the rename dialog.
  final List<String> allValidTags;
  final String imagePath;
  final String tagsFilePath;
  final String copyrightZipPath;

  DownloadResult({
    required this.aiName,
    required this.tags,
    this.suggestedTags = const [],
    this.allValidTags = const [],
    required this.imagePath,
    required this.tagsFilePath,
    required this.copyrightZipPath,
  });
}

/// Service that handles the complete download workflow
class DownloadService {
  final AppConfig config;
  final AIService aiService;
  final TagsService tagsService;
  final ImageProcessingService imageProcessing;
  final CopyrightService copyrightService;
  final ImageSourceRegistry registry;

  DownloadService({
    required this.config,
    required this.aiService,
    required this.tagsService,
    required this.imageProcessing,
    required this.copyrightService,
    required this.registry,
  });

  /// Download and process wallpaper with AI naming and tagging.
  /// Set [aiNaming] to false to skip Gemini and use the fallback name instead.
  /// [croppedImageBytes], if provided, is the already-cropped image data from
  /// the manual crop dialog — it's used as-is (only resized to the target
  /// resolution) instead of re-downloading and center-cropping the original.
  Future<DownloadResult> downloadAndProcessWallpaper(
    Wallpaper wallpaper, {
    bool aiNaming = true,
    Uint8List? croppedImageBytes,
  }) async {
    // 1. Ensure paths exist
    await _ensurePathsExist();

    // 2. Load tags if not already loaded
    if (!tagsService.isLoaded) {
      final tagsPath = config.tagsPath;
      if (tagsPath != null && tagsPath.isNotEmpty) {
        await tagsService.loadTagsFromAssets();
      } else {
        // Use default tags if path not configured
        tagsService.getAllTags();
      }
    }

    // 3. Download original image (skipped if a manually-cropped image was supplied)
    final tempImagePath =
        croppedImageBytes == null ? await _downloadOriginalImage(wallpaper) : null;

    // 4. Compute mutual tags (wallpaper tags ∩ tags.json) and generate metadata
    final validTags = tagsService.getAllTags();
    final mutualTags = tagsService.matchTags(wallpaper.tags ?? [], validTags);

    final metadata = aiNaming
        ? await _generateMetadata(wallpaper, validTags, mutualTags)
        : AIGeneratedMetadata(
            name: _generateFallbackName(wallpaper),
            tags: _selectFallbackTags(validTags, mutualTags),
          );

    // 4b. Ensure the generated name is unique in the download path
    final uniqueName = await _ensureUniqueName(metadata.name);
    final uniqueMetadata = uniqueName == metadata.name
        ? metadata
        : AIGeneratedMetadata(name: uniqueName, tags: metadata.tags);

    // 5. Resize (and, if needed, crop) image to 1080x2340
    final processedImagePath = await _processImage(
      inputPath: tempImagePath,
      preCroppedBytes: croppedImageBytes,
      aiName: uniqueMetadata.name,
    );

    // 6. Save tags to txt file
    final tagsFilePath = await _saveTagsFile(
      uniqueMetadata.name,
      uniqueMetadata.tags,
    );

    // 7. Generate copyright zip
    final copyrightZipPath = await _generateCopyrightZip(
      uniqueMetadata.name,
      wallpaper.photographerUrl,
    );

    // 8. Cleanup temp file
    if (tempImagePath != null) {
      await File(tempImagePath).delete();
    }

    return DownloadResult(
      aiName: uniqueMetadata.name,
      tags: uniqueMetadata.tags,
      suggestedTags: mutualTags,
      allValidTags: validTags,
      imagePath: processedImagePath,
      tagsFilePath: tagsFilePath,
      copyrightZipPath: copyrightZipPath,
    );
  }

  Future<void> _ensurePathsExist() async {
    final paths = [
      config.downloadPath,
      config.copyrightPath,
    ];

    for (final dirPath in paths) {
      if (dirPath != null && dirPath.isNotEmpty) {
        final dir = Directory(dirPath);
        if (!await dir.exists()) {
          await dir.create(recursive: true);
        }
      }
    }
  }

  Future<String> _downloadOriginalImage(Wallpaper wallpaper) async {
    const maxRetries = 4;
    // Backoff delays: 2s → 5s → 12s between attempts.
    const backoffs = [
      Duration(seconds: 2),
      Duration(seconds: 5),
      Duration(seconds: 12),
    ];

    for (int attempt = 0; attempt < maxRetries; attempt++) {
      if (attempt > 0) {
        await Future.delayed(backoffs[attempt - 1]);
      }

      final response = await http.get(Uri.parse(wallpaper.originalUrl));

      if (response.statusCode == 200) {
        final tempDir = Directory.systemTemp;
        final tempPath = path.join(
          tempDir.path,
          'temp_${DateTime.now().millisecondsSinceEpoch}.jpg',
        );
        await File(tempPath).writeAsBytes(response.bodyBytes);
        return tempPath;
      }

      if (response.statusCode == 429) {
        // Check for Retry-After header (seconds).
        final retryAfter = response.headers['retry-after'];
        if (retryAfter != null) {
          final seconds = int.tryParse(retryAfter);
          if (seconds != null && seconds > 0) {
            await Future.delayed(Duration(seconds: seconds));
          }
        }
        if (attempt == maxRetries - 1) {
          throw Exception('Rate limited (429) after $maxRetries attempts');
        }
        // else: loop will sleep via backoffs on the next iteration.
        continue;
      }

      throw Exception('Failed to download image: ${response.statusCode}');
    }

    throw Exception('Failed to download image after $maxRetries attempts');
  }

  Future<AIGeneratedMetadata> _generateMetadata(
    Wallpaper wallpaper,
    List<String> validTags,
    List<String> mutualTags,
  ) async {
    // Prepare description for AI
    final description =
        wallpaper.description ?? wallpaper.tags?.join(' ') ?? 'wallpaper';

    // Generate metadata using AI
    try {
      return await aiService.generateMetadata(
        imageDescription: description,
        validTags: validTags,
        imageTags: wallpaper.tags ?? [],
        mutualTags: mutualTags,
      );
    } catch (e) {
      // Fallback to simple generation if AI fails
      return AIGeneratedMetadata(
        name: _generateFallbackName(wallpaper),
        tags: _selectFallbackTags(validTags, mutualTags),
      );
    }
  }

  String _generateFallbackName(Wallpaper wallpaper) {
    final timestamp = DateTime.now().millisecondsSinceEpoch % 100000;
    return 'wall$timestamp';
  }

  /// Mutual tags (wallpaper tags ∩ tags.json) always come first, padded with
  /// random valid tags up to 6 if needed.
  List<String> _selectFallbackTags(
      List<String> validTags, List<String> mutualTags) {
    final matchedTags = <String>[...mutualTags];

    // Fill remaining with random valid tags
    final shuffled = List<String>.from(validTags)..shuffle();
    for (final tag in shuffled) {
      if (!matchedTags.contains(tag)) {
        matchedTags.add(tag);
        if (matchedTags.length >= 6) break;
      }
    }

    return matchedTags.take(6).toList();
  }

  /// Returns a name that doesn't already exist as a .jpg in the download path.
  /// [excludePath] is an existing file path that should be ignored in the check
  /// (useful when renaming a file to avoid colliding with itself).
  Future<String> _ensureUniqueName(String baseName,
      {String? excludePath}) async {
    final downloadPath = config.downloadPath;
    if (downloadPath == null || downloadPath.isEmpty) return baseName;

    String candidate = baseName;
    int suffix = 2;
    while (true) {
      final filePath = path.join(downloadPath, '$candidate.jpg');
      if (filePath == excludePath || !await File(filePath).exists()) break;
      candidate = '${baseName}_$suffix';
      suffix++;
    }
    return candidate;
  }

  /// Renames the image, tags, and copyright zip files for a processed wallpaper.
  Future<DownloadResult> renameWallpaper(
      DownloadResult result, String newName) async {
    if (newName.trim().isEmpty) throw Exception('Name cannot be empty');
    newName = newName.trim();

    if (newName == result.aiName) return result; // nothing to do

    final uniqueName =
        await _ensureUniqueName(newName, excludePath: result.imagePath);

    // Rename image
    final imageDir = path.dirname(result.imagePath);
    final newImagePath = path.join(imageDir, '$uniqueName.jpg');
    await File(result.imagePath).rename(newImagePath);

    // Rename tags file
    final tagsDir = path.dirname(result.tagsFilePath);
    final newTagsPath = path.join(tagsDir, '$uniqueName.txt');
    await File(result.tagsFilePath).rename(newTagsPath);

    // Rename copyright zip
    final zipDir = path.dirname(result.copyrightZipPath);
    final newZipPath = path.join(zipDir, '$uniqueName.zip');
    await File(result.copyrightZipPath).rename(newZipPath);

    return DownloadResult(
      aiName: uniqueName,
      tags: result.tags,
      suggestedTags: result.suggestedTags,
      allValidTags: result.allValidTags,
      imagePath: newImagePath,
      tagsFilePath: newTagsPath,
      copyrightZipPath: newZipPath,
    );
  }

  Future<String> _processImage({
    String? inputPath,
    Uint8List? preCroppedBytes,
    required String aiName,
  }) async {
    final downloadPath = config.downloadPath;
    if (downloadPath == null || downloadPath.isEmpty) {
      throw Exception('Download path not configured');
    }

    final outputPath = path.join(downloadPath, '$aiName.jpg');

    if (preCroppedBytes != null) {
      // Already cropped to the target aspect ratio interactively — just resize.
      await imageProcessing.resizeToTarget(
        bytes: preCroppedBytes,
        outputPath: outputPath,
      );
    } else {
      await imageProcessing.cropAndResize(
        inputFile: File(inputPath!),
        outputPath: outputPath,
      );
    }

    return outputPath;
  }

  Future<String> _saveTagsFile(String aiName, List<String> tags) async {
    final tagsPath = config.tagsPath;
    if (tagsPath == null || tagsPath.isEmpty) {
      throw Exception('Tags path not configured');
    }

    final tagsFile = path.join(tagsPath, '$aiName.txt');
    final tagsF = File(tagsFile);

    // Save tags comma-separated
    await tagsF.writeAsString(tags.join(','));

    return tagsFile;
  }

  /// Updates the tags for an already-downloaded wallpaper, rewriting its tags
  /// file on disk.
  Future<DownloadResult> updateTags(
      DownloadResult result, List<String> newTags) async {
    final cleaned = newTags
        .map((t) => t.trim())
        .where((t) => t.isNotEmpty)
        .toSet()
        .toList();

    await File(result.tagsFilePath).writeAsString(cleaned.join(','));

    return DownloadResult(
      aiName: result.aiName,
      tags: cleaned,
      suggestedTags: result.suggestedTags,
      allValidTags: result.allValidTags,
      imagePath: result.imagePath,
      tagsFilePath: result.tagsFilePath,
      copyrightZipPath: result.copyrightZipPath,
    );
  }

  Future<String> _generateCopyrightZip(String aiName, String imageUrl) async {
    final copyrightPath = config.copyrightPath;
    if (copyrightPath == null || copyrightPath.isEmpty) {
      throw Exception('Copyright path not configured');
    }

    final zipFile = await copyrightService.generateCopyrightZip(
      name: aiName,
      imageUrl: imageUrl,
      outputPath: copyrightPath,
    );

    return zipFile.path;
  }
}

/// Provider for download service
final downloadServiceProvider = FutureProvider<DownloadService>((ref) async {
  final prefs = await ref.watch(sharedPreferencesProvider.future);
  return DownloadService(
    config: AppConfig(prefs),
    aiService: AIService(
      apiKey: ref.watch(geminiApiKeyProvider) ?? '',
    ),
    tagsService: TagsService(),
    imageProcessing: ImageProcessingService(),
    copyrightService: CopyrightService(),
    registry: ImageSourceRegistry(),
  );
});

// Helper providers
final sharedPreferencesProvider =
    FutureProvider<SharedPreferences>((ref) async {
  return await SharedPreferences.getInstance();
});

final geminiApiKeyProvider = Provider<String?>((ref) {
// Read API key from AppConfig when SharedPreferences is available
  final prefsAsync = ref.watch(sharedPreferencesProvider);
  if (prefsAsync is AsyncData<SharedPreferences>) {
    return AppConfig(prefsAsync.value).geminiApiKey;
  }
  return null;
});
