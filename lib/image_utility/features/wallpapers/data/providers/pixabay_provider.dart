import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:miui_icon_generator/image_utility/core/providers/image_source_provider.dart';
import 'package:miui_icon_generator/image_utility/features/wallpapers/domain/entities/search_params.dart';
import 'package:miui_icon_generator/image_utility/features/wallpapers/domain/entities/wallpaper.dart';
import 'package:miui_icon_generator/image_utility/core/utils/attribution_tracker.dart';
import 'package:path/path.dart' as path;

class PixabayProvider implements ImageSourceProvider {
  final String apiKey;
  final String baseUrl = 'https://pixabay.com/api';

  PixabayProvider({required this.apiKey});

  @override
  String get sourceId => 'pixabay';

  @override
  String get sourceName => 'Pixabay';

  @override
  bool isConfigured() => apiKey.isNotEmpty;

  @override
  Future<List<Wallpaper>> searchImages({
    required String query,
    SearchParams? params,
  }) async {
    if (!isConfigured()) throw Exception('Pixabay API key not configured');

    final queryParams = {
      'key': apiKey,
      'q': query,
      'image_type': 'photo',
      'per_page': (params?.perPage ?? 20).toString(),
      'page': (params?.page ?? 1).toString(),
      if (params?.orientation != null) 'orientation': params!.orientation!,
      if (params?.color != null) 'colors': params!.color!,
    };

    final uri = Uri.parse(baseUrl).replace(queryParameters: queryParams);
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final hits = data['hits'] as List;
      return hits.map((photo) => _mapToWallpaper(photo)).toList();
    } else {
      throw Exception('Failed to search images: ${response.statusCode}');
    }
  }

  @override
  Future<List<Wallpaper>> getCuratedImages({SearchParams? params}) async {
    if (!isConfigured()) throw Exception('Pixabay API key not configured');

    // Pixabay doesn't have a dedicated curated endpoint, so we use editors_choice
    final queryParams = {
      'key': apiKey,
      'editors_choice': 'true',
      'image_type': 'photo',
      'per_page': (params?.perPage ?? 20).toString(),
      'page': (params?.page ?? 1).toString(),
    };

    final uri = Uri.parse(baseUrl).replace(queryParameters: queryParams);
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final hits = data['hits'] as List;
      return hits.map((photo) => _mapToWallpaper(photo)).toList();
    } else {
      throw Exception('Failed to get curated images: ${response.statusCode}');
    }
  }

  @override
  Future<Wallpaper?> getImageById(String id) async {
    if (!isConfigured()) throw Exception('Pixabay API key not configured');

    final queryParams = {
      'key': apiKey,
      'id': id,
    };

    final uri = Uri.parse(baseUrl).replace(queryParameters: queryParams);
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final hits = data['hits'] as List;
      if (hits.isNotEmpty) {
        return _mapToWallpaper(hits.first);
      }
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

  Wallpaper _mapToWallpaper(Map<String, dynamic> photo) {
    final tags = (photo['tags'] as String?)?.split(', ') ?? [];

    return Wallpaper(
      id: photo['id'].toString(),
      source: sourceId,
      photographer: photo['user'] ?? 'Unknown',
      photographerUrl: photo['pageURL'] ?? '',
      originalUrl: photo['largeImageURL'] ?? photo['webformatURL'] ?? '',
      largeUrl: photo['largeImageURL'] ?? '',
      mediumUrl: photo['webformatURL'] ?? '',
      smallUrl: photo['previewURL'] ?? '',
      width: photo['imageWidth'] ?? 0,
      height: photo['imageHeight'] ?? 0,
      description: tags.join(', '),
      tags: tags,
    );
  }
}
