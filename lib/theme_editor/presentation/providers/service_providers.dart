import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_constants.dart';
import '../../core/services/archive_service.dart';
import '../../core/services/file_service.dart';

enum AiProvider { gemini, groq, ollama }

final fileServiceProvider    = Provider<FileService>((_)    => FileService());
final archiveServiceProvider = Provider<ArchiveService>((_) => ArchiveService());

final sharedPrefsProvider = Provider<SharedPreferences>(
  (_) => throw UnimplementedError('Override sharedPrefsProvider in ProviderScope'),
);

final aiProviderProvider = StateProvider<AiProvider>((ref) {
  final raw = ref.watch(sharedPrefsProvider).getString(AppConstants.prefsAiProvider);
  return AiProvider.values.firstWhere((e) => e.name == raw, orElse: () => AiProvider.groq);
});

final geminiApiKeyProvider = StateProvider<String>((ref) {
  return ref.watch(sharedPrefsProvider).getString(AppConstants.prefsGeminiKey) ?? '';
});

final groqApiKeyProvider = StateProvider<String>((ref) {
  return ref.watch(sharedPrefsProvider).getString(AppConstants.prefsGroqKey) ?? '';
});

final ollamaHostProvider = StateProvider<String>((ref) {
  return ref.watch(sharedPrefsProvider).getString(AppConstants.prefsOllamaHost)
      ?? AppConstants.ollamaDefaultHost;
});

final ollamaModelProvider = StateProvider<String>((ref) {
  return ref.watch(sharedPrefsProvider).getString(AppConstants.prefsOllamaModel)
      ?? AppConstants.ollamaDefaultModel;
});
