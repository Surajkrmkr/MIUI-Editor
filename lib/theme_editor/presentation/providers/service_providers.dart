import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/services/archive_service.dart';
import '../../core/services/file_service.dart';

final fileServiceProvider    = Provider<FileService>((_)    => FileService());
final archiveServiceProvider = Provider<ArchiveService>((_) => ArchiveService());

final sharedPrefsProvider = Provider<SharedPreferences>(
  (_) => throw UnimplementedError('Override sharedPrefsProvider in ProviderScope'),
);

final geminiApiKeyProvider = StateProvider<String>((ref) {
  final prefs = ref.watch(sharedPrefsProvider);
  return prefs.getString('gemini_api_key') ?? '';
});
