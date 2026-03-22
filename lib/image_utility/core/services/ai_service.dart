import 'package:google_generative_ai/google_generative_ai.dart';
import 'dart:convert';

/// Service to generate AI-powered names and tags using Gemini SDK
class AIService {
  final String apiKey;
  late final GenerativeModel _model;

  AIService({required this.apiKey}) {
    _model = GenerativeModel(
      model: 'gemini-3-flash-preview',
      apiKey: apiKey,
    );
  }

  /// Generate a short name (max 10 chars) and 6 tags for a wallpaper
  /// Tags must match the provided valid tags list
  Future<AIGeneratedMetadata> generateMetadata({
    required String imageDescription,
    required List<String> validTags,
    required List<String> imageTags,
  }) async {
    if (apiKey.isEmpty) {
      throw Exception('Gemini API key not configured');
    }

    final validTagsString = validTags.join(', ');

    final prompt = '''
      Given this wallpaper description: "$imageDescription"

      1. Generate a creative file name based on wallpaper context (max 10 characters, only alpha, Pascal case with one space allowed) 
        Example: "Sunset", "Beach View", "City Light"

      2. Select exactly 6 tags from this list that best match the wallpaper: $validTagsString

      Respond ONLY with valid JSON in this exact format:
      {
        "name": "Your Name",
        "tags": ["tag1", "tag2", "tag3", "tag4", "tag5", "tag6"]
      }

      Rules:
      - Name must be max 10 chars, Pascal case, one space allowed
      - All tags MUST be from the provided list
      - Return exactly 6 tags
      ''';

    try {
      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);

      if (response.text == null || response.text!.isEmpty) {
        throw Exception('Empty response from Gemini');
      }

      // Clean the response text (remove markdown code blocks if present)
      String responseText = response.text!.trim();
      responseText =
          responseText.replaceAll('```json', '').replaceAll('```', '').trim();

      // Parse the JSON response
      final metadataJson = json.decode(responseText);

      return AIGeneratedMetadata(
        name: _sanitizeName(metadataJson['name'] as String),
        tags: (metadataJson['tags'] as List).cast<String>().take(6).toList(),
      );
    } catch (e) {
      // Fallback to basic generation if AI fails
      return _generateFallbackMetadata(imageDescription, validTags, imageTags);
    }
  }

  /// Sanitize name to ensure it meets requirements
  String _sanitizeName(String name) {
    // Allow spaces and letters only (no numbers), keep first letter capital
    final sanitized = name.replaceAll(RegExp(r'[^a-zA-Z ]'), '').trim();

    if (sanitized.isEmpty) return 'Wallpaper';

    // Limit to 10 characters
    final limited =
        sanitized.length > 10 ? sanitized.substring(0, 10) : sanitized;

    // Capitalize first letter
    return limited[0].toUpperCase() + limited.substring(1);
  }

  /// Fallback generation if AI fails
  AIGeneratedMetadata _generateFallbackMetadata(
    String description,
    List<String> validTags,
    List<String> imageTags,
  ) {
    // Generate simple name from description or image tags
    final name = imageTags.isNotEmpty && imageTags.first.isNotEmpty
        ? _sanitizeName(imageTags.first.split(" ").first)
        : 'Wallpaper';

    // Match image tags with valid tags
    final matchedTags = <String>[];

    for (final tag in imageTags) {
      final match = validTags.firstWhere(
        (validTag) => validTag.toLowerCase() == tag.toLowerCase(),
        orElse: () => '',
      );
      if (match.isNotEmpty && !matchedTags.contains(match)) {
        matchedTags.add(match);
        if (matchedTags.length >= 6) break;
      }
    }

    // Fill remaining with random valid tags if needed
    if (matchedTags.length < 6) {
      final shuffled = List<String>.from(validTags)..shuffle();
      for (final tag in shuffled) {
        if (!matchedTags.contains(tag)) {
          matchedTags.add(tag);
          if (matchedTags.length >= 6) break;
        }
      }
    }

    return AIGeneratedMetadata(
      name: name,
      tags: matchedTags.take(6).toList(),
    );
  }
}

class AIGeneratedMetadata {
  final String name;
  final List<String> tags;

  AIGeneratedMetadata({
    required this.name,
    required this.tags,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'tags': tags,
      };
}
