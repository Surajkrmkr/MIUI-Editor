import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path/path.dart' as p;
import 'package:image/image.dart' as img;
import 'package:miui_icon_generator/image_utility/core/config/app_config.dart';
import 'package:miui_icon_generator/image_utility/features/image_generation/data/generators/image_generator.dart';
import 'package:miui_icon_generator/image_utility/features/image_generation/data/generators/gemini_imagen_generator.dart';
import 'package:miui_icon_generator/image_utility/features/image_generation/data/generators/firefly_generator.dart';
import 'package:miui_icon_generator/image_utility/features/image_generation/data/generators/upscayl_service.dart';
import 'package:miui_icon_generator/image_utility/features/wallpapers/presentation/providers/download_provider.dart'
    show sharedPreferencesProvider;

// ─── State model ─────────────────────────────────────────────────────────────

enum GenerationStep {
  idle,
  generating,
  awaitingApproval, // preview ready, waiting for user to approve
  upscaling,
  saving,
  done,
  error,
}

class GenerationState {
  final GenerationStep step;
  final String? statusMessage;
  final Uint8List? previewBytes; // raw bytes from generator (before upscale)
  final Uint8List? finalBytes; // after upscale + crop
  final String? savedPath;
  final String? errorMessage;

  const GenerationState({
    this.step = GenerationStep.idle,
    this.statusMessage,
    this.previewBytes,
    this.finalBytes,
    this.savedPath,
    this.errorMessage,
  });

  GenerationState copyWith({
    GenerationStep? step,
    String? statusMessage,
    Uint8List? previewBytes,
    Uint8List? finalBytes,
    String? savedPath,
    String? errorMessage,
  }) =>
      GenerationState(
        step: step ?? this.step,
        statusMessage: statusMessage ?? this.statusMessage,
        previewBytes: previewBytes ?? this.previewBytes,
        finalBytes: finalBytes ?? this.finalBytes,
        savedPath: savedPath ?? this.savedPath,
        errorMessage: errorMessage ?? this.errorMessage,
      );
}

// ─── Notifier ─────────────────────────────────────────────────────────────────

class GenerationNotifier extends StateNotifier<GenerationState> {
  final AppConfig _config;

  GenerationNotifier(this._config) : super(const GenerationState());

  // ── Available generators ────────────────────────────────────────────────

  List<ImageGenerator> buildGenerators() => [
        GeminiImagenGenerator(apiKey: _config.geminiApiKey ?? ''),
        // Firefly needs both API key and client-id; stored in fireflyApiKey
        // as "apiKey||clientId" for simplicity (split on '||').
        _buildFirefly(),
      ];

  FireflyImageGenerator _buildFirefly() {
    final raw = _config.fireflyApiKey ?? '';
    final parts = raw.split('||');
    return FireflyImageGenerator(
      apiKey: parts.isNotEmpty ? parts[0] : '',
      clientId: parts.length > 1 ? parts[1] : '',
    );
  }

  // ── Step 1: Generate preview ─────────────────────────────────────────────

  Future<void> generatePreview({
    required ImageGenerator generator,
    required String prompt,
    String? style,
  }) async {
    if (prompt.trim().isEmpty) {
      state = state.copyWith(
        step: GenerationStep.error,
        errorMessage: 'Please enter a prompt.',
      );
      return;
    }

    state = GenerationState(
      step: GenerationStep.generating,
      statusMessage: 'Generating image with ${generator.displayName}…',
    );

    try {
      final bytes = await generator.generate(prompt: prompt, style: style);
      state = state.copyWith(
        step: GenerationStep.awaitingApproval,
        previewBytes: bytes,
        statusMessage: 'Preview ready — approve to upscale & save.',
      );
    } catch (e) {
      state = state.copyWith(
        step: GenerationStep.error,
        errorMessage: e.toString(),
      );
    }
  }

  // ── Step 2: Approve → upscale → crop → save ─────────────────────────────

  Future<void> approveAndSave({
    required String prompt,
    bool upscale = true,
  }) async {
    final preview = state.previewBytes;
    if (preview == null) return;

    try {
      Uint8List working = preview;

      // ── 2a. Upscale ──────────────────────────────────────────────────────
      if (upscale && (_config.upscaylApiKey?.isNotEmpty ?? false)) {
        state = state.copyWith(
          step: GenerationStep.upscaling,
          statusMessage: 'Submitting upscale task…',
        );

        final svc = UpscaylService(apiKey: _config.upscaylApiKey!);
        working = await svc.upscale(
          imageBytes: working,
          onStatus: (msg) => state = state.copyWith(statusMessage: msg),
        );
      }

      // ── 2b. Crop to 6:13 → 1080×2340 ────────────────────────────────────
      state = state.copyWith(
        step: GenerationStep.saving,
        statusMessage: 'Cropping to phone ratio & saving…',
      );

      final cropped = _cropAndResize(working);

      // ── 2c. Save to download path ─────────────────────────────────────────
      final downloadPath = _config.downloadPath ?? Directory.systemTemp.path;
      final dir = Directory(downloadPath);
      if (!await dir.exists()) await dir.create(recursive: true);

      final fileName = 'generated_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final filePath = p.join(downloadPath, fileName);
      await File(filePath).writeAsBytes(cropped);

      state = state.copyWith(
        step: GenerationStep.done,
        finalBytes: cropped,
        savedPath: filePath,
        statusMessage: 'Saved as $fileName',
      );
    } catch (e) {
      state = state.copyWith(
        step: GenerationStep.error,
        errorMessage: e.toString(),
      );
    }
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  Uint8List _cropAndResize(Uint8List input) {
    final image = img.decodeImage(input);
    if (image == null) throw Exception('Cannot decode generated image.');

    const targetW = 1080, targetH = 2340;
    const targetRatio = 6.0 / 13.0;

    final srcRatio = image.width / image.height;
    int cx, cy, cw, ch;
    if (srcRatio > targetRatio) {
      ch = image.height;
      cw = (ch * targetRatio).round();
      cx = ((image.width - cw) / 2).round();
      cy = 0;
    } else {
      cw = image.width;
      ch = (cw / targetRatio).round();
      cx = 0;
      cy = ((image.height - ch) / 2).round();
    }

    final cropped = img.copyCrop(image, x: cx, y: cy, width: cw, height: ch);
    final resized = img.copyResize(cropped,
        width: targetW,
        height: targetH,
        interpolation: img.Interpolation.cubic);

    return Uint8List.fromList(img.encodeJpg(resized, quality: 95));
  }

  void reset() => state = const GenerationState();
}

// ─── Providers ───────────────────────────────────────────────────────────────

final _appConfigProvider = FutureProvider<AppConfig>((ref) async {
  final prefs = await ref.watch(sharedPreferencesProvider.future);
  return AppConfig(prefs);
});

final generationNotifierProvider =
    StateNotifierProvider<GenerationNotifier, GenerationState>((ref) {
  // Use synchronous fallback; config is loaded lazily from prefs.
  final prefsAsync = ref.watch(sharedPreferencesProvider);
  final prefs = prefsAsync.maybeWhen(
    data: (p) => p,
    orElse: () => null,
  );
  // Build a minimal config. If prefs are not ready yet the keys are empty
  // and the user cannot trigger generation until they are.
  final config = prefs != null ? AppConfig(prefs) : AppConfig(_EmptyPrefs());
  return GenerationNotifier(config);
});

/// Lightweight no-op SharedPreferences used only before real prefs load.
class _EmptyPrefs implements SharedPreferences {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
  @override
  String? getString(String key) => null;
  @override
  bool containsKey(String key) => false;
  @override
  Future<bool> setString(String key, String value) async => false;
  @override
  Set<String> getKeys() => {};
  @override
  Object? get(String key) => null;
  @override
  bool? getBool(String key) => null;
  @override
  int? getInt(String key) => null;
  @override
  double? getDouble(String key) => null;
  @override
  List<String>? getStringList(String key) => null;
  @override
  Future<bool> setBool(String key, bool value) async => false;
  @override
  Future<bool> setInt(String key, int value) async => false;
  @override
  Future<bool> setDouble(String key, double value) async => false;
  @override
  Future<bool> setStringList(String key, List<String> value) async => false;
  @override
  Future<bool> remove(String key) async => false;
  @override
  Future<bool> clear() async => false;
  @override
  Future<void> reload() async {}
}
