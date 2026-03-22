import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:miui_icon_generator/image_utility/core/providers/image_source_provider.dart';
import 'package:miui_icon_generator/image_utility/features/wallpapers/domain/entities/search_params.dart';
import 'package:miui_icon_generator/image_utility/features/wallpapers/domain/entities/wallpaper.dart';
import 'package:miui_icon_generator/image_utility/core/utils/attribution_tracker.dart';
import 'package:path/path.dart' as path;

class PexelsProvider implements ImageSourceProvider {
  final String apiKey;
  final String baseUrl = 'https://api.pexels.com/v1';

  PexelsProvider({required this.apiKey});

  @override
  String get sourceId => 'pexels';

  @override
  String get sourceName => 'Pexels';

  @override
  bool isConfigured() => apiKey.isNotEmpty;

  @override
  Future<List<Wallpaper>> searchImages({
    required String query,
    SearchParams? params,
  }) async {
    if (!isConfigured()) throw Exception('Pexels API key not configured');

    final queryParams = {
      'per_page': (params?.perPage ?? 20).toString(),
      'page': (params?.page ?? 1).toString(),
      if (params?.orientation != null) 'orientation': params!.orientation!,
      if (params?.locale != null) 'locale': params!.locale!,
    };

    final uri =
        Uri.parse('$baseUrl/search').replace(queryParameters: queryParams);
    final response = await http.get(
      uri,
      headers: {'Authorization': apiKey},
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final photos = data['photos'] as List;
      return photos.map((photo) => _mapToWallpaper(photo)).toList();
    } else {
      throw Exception('Failed to search images: ${response.statusCode}');
    }
  }

  @override
  Future<List<Wallpaper>> getCuratedImages({SearchParams? params}) async {
    if (!isConfigured()) throw Exception('Pexels API key not configured');

    final queryParams = {
      'per_page': (params?.perPage ?? 20).toString(),
      'page': (params?.page ?? 1).toString(),
    };

    final uri =
        Uri.parse('$baseUrl/curated').replace(queryParameters: queryParams);
    final response = await http.get(
      uri,
      headers: {'Authorization': apiKey},
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final photos = data['photos'] as List;
      return photos.map((photo) => _mapToWallpaper(photo)).toList();
    } else {
      throw Exception('Failed to get curated images: ${response.statusCode}');
    }
  }

  @override
  Future<Wallpaper?> getImageById(String id) async {
    if (!isConfigured()) throw Exception('Pexels API key not configured');

    final uri = Uri.parse('$baseUrl/photos/$id');
    final response = await http.get(
      uri,
      headers: {'Authorization': apiKey},
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return _mapToWallpaper(data);
    }
    return null;
  }

  @override
  Future<String> downloadImage({
    required Wallpaper wallpaper,
    required String savePath,
  }) async {
    final response = await http.get(Uri.parse(wallpaper.originalUrl));

    if (response.statusCode == 200) {
      final fileName =
          '${wallpaper.source}_${wallpaper.id}${path.extension(wallpaper.originalUrl)}';
      final filePath = path.join(savePath, fileName);
      final file = File(filePath);
      await file.writeAsBytes(response.bodyBytes);

      // Track attribution
      await AttributionTracker.saveAttribution(
        wallpaper: wallpaper,
        localPath: filePath,
      );

      return filePath;
    } else {
      throw Exception('Failed to download image');
    }
  }

  Wallpaper _mapToWallpaper(Map<String, dynamic> photo) {
    return Wallpaper(
      id: photo['id'].toString(),
      source: sourceId,
      photographer: photo['photographer'] ?? 'Unknown',
      photographerUrl: photo['url'] ?? '',
      originalUrl: photo['src']['original'] ?? '',
      largeUrl: photo['src']['large2x'] ?? photo['src']['large'] ?? '',
      mediumUrl: photo['src']['medium'] ?? '',
      smallUrl: photo['src']['small'] ?? '',
      width: photo['width'] ?? 0,
      height: photo['height'] ?? 0,
      description: photo['alt'] ?? '',
      tags: [],
    );
  }
}
