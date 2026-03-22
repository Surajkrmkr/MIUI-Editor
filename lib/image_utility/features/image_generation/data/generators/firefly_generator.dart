import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'image_generator.dart';

/// Adobe Firefly image-generation backend.
///
/// Docs: https://developer.adobe.com/firefly-services/docs/firefly-api/
/// Requires:
///   - [apiKey]  → OAuth access token (Bearer)
///   - [clientId] → X-Api-Key header value
///
/// Both values come from AppConfig so the user configures them in Settings.
class FireflyImageGenerator implements ImageGenerator {
  final String apiKey;    // Bearer token
  final String clientId;  // X-Api-Key

  static const String _baseUrl =
      'https://firefly-api.adobe.io/v3/images/generate';

  FireflyImageGenerator({required this.apiKey, required this.clientId});

  @override
  String get id => 'firefly';

  @override
  String get displayName => 'Adobe Firefly';

  @override
  bool get isConfigured => apiKey.isNotEmpty && clientId.isNotEmpty;

  @override
  List<String> get supportedStyles => [
        'Photo',
        'Art',
        'Graphic',
        'Black & White',
        'Warm Tone',
        'Cool Tone',
        'Landscape Photography',
        'Portrait Photography',
      ];

  @override
  Future<Uint8List> generate({
    required String prompt,
    String? style,
  }) async {
    if (!isConfigured) {
      throw Exception(
          'Adobe Firefly API key and Client ID are not configured.');
    }

    final body = jsonEncode({
      'prompt': prompt,
      'contentClass': 'photo',
      'size': {'width': 1080, 'height': 2340},
      'n': 1,
      if (style != null) 'styles': [_mapStyle(style)],
      'negativePrompt': 'blurry, low quality, watermark, text',
    });

    final response = await http.post(
      Uri.parse(_baseUrl),
      headers: {
        'Authorization': 'Bearer $apiKey',
        'X-Api-Key': clientId,
        'Content-Type': 'application/json',
      },
      body: body,
    );

    if (response.statusCode != 200) {
      throw Exception(
          'Firefly error ${response.statusCode}: ${response.body}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final outputs = data['outputs'] as List<dynamic>;
    if (outputs.isEmpty) throw Exception('Firefly returned no images.');

    // Firefly returns a URL; download the image bytes
    final imageUrl = outputs.first['image']['url'] as String;
    final imgResponse = await http.get(Uri.parse(imageUrl));
    if (imgResponse.statusCode != 200) {
      throw Exception('Failed to download Firefly image.');
    }
    return imgResponse.bodyBytes;
  }

  String _mapStyle(String style) {
    const map = {
      'Photo': 'photo',
      'Art': 'art',
      'Graphic': 'graphic',
      'Black & White': 'bw',
      'Warm Tone': 'warm_tone',
      'Cool Tone': 'cool_tone',
      'Landscape Photography': 'landscape_photography',
      'Portrait Photography': 'portrait_photography',
    };
    return map[style] ?? 'photo';
  }
}
