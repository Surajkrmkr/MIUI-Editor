import 'dart:convert';
import 'dart:io';
import 'package:miui_icon_generator/image_utility/features/wallpapers/domain/entities/wallpaper.dart';
import 'package:path/path.dart' as path;

/// Tracks attribution information for downloaded images
class AttributionTracker {
  static const String attributionFileName = 'COPYRIGHT.json';

  /// Save attribution information for a downloaded wallpaper
  static Future<void> saveAttribution({
    required Wallpaper wallpaper,
    required String localPath,
  }) async {
    final directory = path.dirname(localPath);
    final attributionFile = File(path.join(directory, attributionFileName));

    Map<String, dynamic> attributions = {};

    // Load existing attributions if file exists
    if (await attributionFile.exists()) {
      final content = await attributionFile.readAsString();
      attributions = json.decode(content) as Map<String, dynamic>;
    }

    // Add new attribution
    final fileName = path.basename(localPath);
    attributions[fileName] = {
      'source': wallpaper.source,
      'photographer': wallpaper.photographer,
      'photographer_url': wallpaper.photographerUrl,
      'original_url': wallpaper.originalUrl,
      'image_url': wallpaper.photographerUrl,
      'downloaded_at': DateTime.now().toIso8601String(),
      'description': wallpaper.description,
      'tags': wallpaper.tags,
      'license': _getLicenseInfo(wallpaper.source),
    };

    // Save attributions
    await attributionFile.writeAsString(
      const JsonEncoder.withIndent('  ').convert(attributions),
    );
  }

  /// Get all attributions from a directory
  static Future<Map<String, dynamic>> getAttributions(String directory) async {
    final attributionFile = File(path.join(directory, attributionFileName));

    if (await attributionFile.exists()) {
      final content = await attributionFile.readAsString();
      return json.decode(content) as Map<String, dynamic>;
    }

    return {};
  }

  /// Remove attribution for a specific file
  static Future<void> removeAttribution({
    required String directory,
    required String fileName,
  }) async {
    final attributionFile = File(path.join(directory, attributionFileName));

    if (await attributionFile.exists()) {
      final content = await attributionFile.readAsString();
      final attributions = json.decode(content) as Map<String, dynamic>;

      attributions.remove(fileName);

      await attributionFile.writeAsString(
        const JsonEncoder.withIndent('  ').convert(attributions),
      );
    }
  }

  /// Get license information for a source
  static Map<String, String> _getLicenseInfo(String source) {
    switch (source.toLowerCase()) {
      case 'pexels':
        return {
          'name': 'Pexels License',
          'url': 'https://www.pexels.com/license/',
          'terms': 'Free to use. No attribution required.',
        };
      case 'unsplash':
        return {
          'name': 'Unsplash License',
          'url': 'https://unsplash.com/license',
          'terms': 'Free to use. Attribution appreciated but not required.',
        };
      case 'pixabay':
        return {
          'name': 'Pixabay License',
          'url': 'https://pixabay.com/service/license/',
          'terms': 'Free for commercial use. No attribution required.',
        };
      case 'firefly':
        return {
          'name': 'Adobe Firefly Terms',
          'url':
              'https://www.adobe.com/legal/licenses-terms/adobe-gen-ai-user-guidelines.html',
          'terms': 'Subject to Adobe Firefly user terms.',
        };
      default:
        return {
          'name': 'Unknown License',
          'url': '',
          'terms': 'Please verify license terms.',
        };
    }
  }

  /// Generate attribution text for display
  static String generateAttributionText(Map<String, dynamic> attribution) {
    final photographer = attribution['photographer'] ?? 'Unknown';
    final source = attribution['source'] ?? 'Unknown';
    final photographerUrl = attribution['photographer_url'] ?? '';

    return 'Photo by $photographer on $source${photographerUrl.isNotEmpty ? '\n$photographerUrl' : ''}';
  }
}
