import 'dart:typed_data';

/// Abstract contract every image-generation backend must implement.
/// Adding a new generator (e.g. Stability AI, Midjourney) only requires
/// implementing this interface and registering it in [ImageGeneratorRegistry].
abstract class ImageGenerator {
  /// Short machine-readable id, e.g. 'gemini_imagen', 'firefly'.
  String get id;

  /// Human-readable display name shown in the UI.
  String get displayName;

  /// Returns true when the necessary API key(s) are present.
  bool get isConfigured;

  /// Style options the generator supports (may be empty).
  List<String> get supportedStyles;

  /// Generate an image from [prompt] and return raw PNG/JPEG bytes.
  Future<Uint8List> generate({
    required String prompt,
    String? style,
  });
}
