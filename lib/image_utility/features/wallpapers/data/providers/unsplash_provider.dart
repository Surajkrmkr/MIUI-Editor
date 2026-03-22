import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:miui_icon_generator/image_utility/core/providers/image_source_provider.dart';
import 'package:miui_icon_generator/image_utility/features/wallpapers/domain/entities/search_params.dart';
import 'package:miui_icon_generator/image_utility/features/wallpapers/domain/entities/wallpaper.dart';
import 'package:miui_icon_generator/image_utility/core/utils/attribution_tracker.dart';
import 'package:path/path.dart' as path;

class UnsplashProvider implements ImageSourceProvider {
  final String apiKey;
  final String baseUrl = 'https://api.unsplash.com';

  UnsplashProvider({required this.apiKey});

  @override
  String get sourceId => 'unsplash';

  @override
  String get sourceName => 'Unsplash';

  @override
  bool isConfigured() => apiKey.isNotEmpty;

  @override
  Future<List<Wallpaper>> searchImages({
    required String query,
    SearchParams? params,
  }) async {
    if (!isConfigured()) throw Exception('Unsplash API key not configured');

    final queryParams = {
      'query': query,
      'per_page': (params?.perPage ?? 20).toString(),
      'page': (params?.page ?? 1).toString(),
      if (params?.orientation != null) 'orientation': params!.orientation!,
      if (params?.color != null) 'color': params!.color!,
    };

    final uri = Uri.parse('$baseUrl/search/photos')
        .replace(queryParameters: queryParams);
    final response = await http.get(
      uri,
      headers: {'Authorization': 'Client-ID $apiKey'},
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final photos = data['results'] as List;
      return photos.map((photo) => _mapToWallpaper(photo)).toList();
    } else {
      throw Exception('Failed to search images: ${response.statusCode}');
    }
  }

  @override
  Future<List<Wallpaper>> getCuratedImages({SearchParams? params}) async {
    if (!isConfigured()) throw Exception('Unsplash API key not configured');

    final queryParams = {
      'per_page': (params?.perPage ?? 20).toString(),
      'page': (params?.page ?? 1).toString(),
    };

    final uri =
        Uri.parse('$baseUrl/photos').replace(queryParameters: queryParams);
    final response = await http.get(
      uri,
      headers: {'Authorization': 'Client-ID $apiKey'},
    );

    if (response.statusCode == 200) {
      final photos = json.decode(response.body) as List;
      return photos.map((photo) => _mapToWallpaper(photo)).toList();
    } else {
      throw Exception('Failed to get curated images: ${response.statusCode}');
    }
  }

  @override
  Future<Wallpaper?> getImageById(String id) async {
    if (!isConfigured()) throw Exception('Unsplash API key not configured');

    final uri = Uri.parse('$baseUrl/photos/$id');
    final response = await http.get(
      uri,
      headers: {'Authorization': 'Client-ID $apiKey'},
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
    // Trigger download tracking as per Unsplash API guidelines
    await _triggerDownload(wallpaper.id);

    final response = await http.get(Uri.parse(wallpaper.originalUrl));

    if (response.statusCode == 200) {
      final fileName = '${wallpaper.source}_${wallpaper.id}.jpg';
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

  Future<void> _triggerDownload(String photoId) async {
    final uri = Uri.parse('$baseUrl/photos/$photoId/download');
    await http.get(
      uri,
      headers: {'Authorization': 'Client-ID $apiKey'},
    );
  }

  Wallpaper _mapToWallpaper(Map<String, dynamic> photo) {
    final user = photo['user'] ?? {};
    final urls = photo['urls'] ?? {};
    final tags = photo['tags'] as List?;

    return Wallpaper(
      id: photo['id'] ?? '',
      source: sourceId,
      photographer: user['name'] ?? 'Unknown',
      photographerUrl: photo['links']?['html'] ?? '',
      originalUrl: urls['raw'] ?? urls['full'] ?? '',
      largeUrl: urls['full'] ?? '',
      mediumUrl: urls['regular'] ?? '',
      smallUrl: urls['small'] ?? '',
      width: photo['width'] ?? 0,
      height: photo['height'] ?? 0,
      description: photo['description'] ?? photo['alt_description'] ?? '',
      tags: tags?.map((tag) => tag['title']?.toString() ?? '').toList() ?? [],
    );
  }
}
