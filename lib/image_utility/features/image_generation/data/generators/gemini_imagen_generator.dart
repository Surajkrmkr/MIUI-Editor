import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'image_generator.dart';

/// Gemini Imagen 3 ("banana" / preview model) implementation.
///
/// Uses the Vertex-AI–compatible REST endpoint that is available through the
/// standard Google AI Studio / Gemini API key.  No extra SDK dependency is
/// needed—we call the REST endpoint directly so this file compiles without any
/// additional pubspec entry beyond `http`.
class GeminiImagenGenerator implements ImageGenerator {
  final String apiKey;

  // imagen-3.0-generate-002 is the current GA Imagen 3 model.
  // Use 'imagen-3.0-fast-generate-001' for faster / cheaper preview quality.
  static const String _model = 'gemini-2.5-flash-image';
  static const String _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models';

  GeminiImagenGenerator({required this.apiKey});

  @override
  String get id => 'gemini_imagen';

  @override
  String get displayName => 'Gemini Imagen';

  @override
  bool get isConfigured => apiKey.isNotEmpty;

  @override
  List<String> get supportedStyles => [
        'Photorealistic',
        'Anime',
        'Digital Art',
        'Fantasy Art',
        'Neon Punk',
        'Watercolor',
        'Cinematic',
        'Oil Painting',
      ];

  @override
  Future<Uint8List> generate({
    required String prompt,
    String? style,
  }) async {
    if (!isConfigured) throw Exception('Gemini API key is not configured.');

    final enhancedPrompt =
        style != null ? '$prompt, ${style.toLowerCase()} style' : prompt;

    final uri = Uri.parse('$_baseUrl/$_model:generateContent');

    final body = jsonEncode({
      'contents': [
        {
          'parts': [
            {'text': enhancedPrompt},
          ],
        },
      ],
    });

    final response = await http.post(
      uri,
      headers: {
        'x-goog-api-key': apiKey,
        'Content-Type': 'application/json',
      },
      body: body,
    );

    if (response.statusCode != 200) {
      throw Exception(
          'Gemini Imagen error ${response.statusCode}: ${response.body}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final predictions = data['predictions'] as List<dynamic>;
    if (predictions.isEmpty) throw Exception('Gemini returned no images.');

    final base64Str = predictions.first['bytesBase64Encoded'] as String;
    return base64Decode(base64Str);
  }
}
