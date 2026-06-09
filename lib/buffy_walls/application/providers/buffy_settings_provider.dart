import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../theme_editor/presentation/providers/service_providers.dart';

class BuffySettings {
  final String localRepoPath;
  final String jsonFilePath;
  final String admobPublisherId;
  final String playPackageName;

  BuffySettings({
    this.localRepoPath = '',
    this.jsonFilePath = '',
    this.admobPublisherId = '',
    this.playPackageName = '',
  });

  BuffySettings copyWith({
    String? localRepoPath,
    String? jsonFilePath,
    String? admobPublisherId,
    String? playPackageName,
  }) {
    return BuffySettings(
      localRepoPath: localRepoPath ?? this.localRepoPath,
      jsonFilePath: jsonFilePath ?? this.jsonFilePath,
      admobPublisherId: admobPublisherId ?? this.admobPublisherId,
      playPackageName: playPackageName ?? this.playPackageName,
    );
  }
}

class BuffySettingsNotifier extends Notifier<BuffySettings> {
  @override
  BuffySettings build() {
    final prefs = ref.watch(sharedPrefsProvider);
    return BuffySettings(
      localRepoPath: prefs.getString('buffy_local_repo_path') ?? '',
      jsonFilePath: prefs.getString('buffy_json_file_path') ?? '',
      admobPublisherId: prefs.getString('buffy_admob_publisher_id') ?? '',
      playPackageName: prefs.getString('buffy_play_package_name') ?? '',
    );
  }

  Future<void> setLocalRepoPath(String path) async {
    final prefs = ref.read(sharedPrefsProvider);
    await prefs.setString('buffy_local_repo_path', path);
    state = state.copyWith(localRepoPath: path);
  }

  Future<void> setJsonFilePath(String path) async {
    final prefs = ref.read(sharedPrefsProvider);
    await prefs.setString('buffy_json_file_path', path);
    state = state.copyWith(jsonFilePath: path);
  }

  Future<void> setAdMobPublisherId(String id) async {
    final prefs = ref.read(sharedPrefsProvider);
    await prefs.setString('buffy_admob_publisher_id', id);
    state = state.copyWith(admobPublisherId: id);
  }

  Future<void> setPlayPackageName(String name) async {
    final prefs = ref.read(sharedPrefsProvider);
    await prefs.setString('buffy_play_package_name', name);
    state = state.copyWith(playPackageName: name);
  }
}

final buffySettingsProvider = NotifierProvider<BuffySettingsNotifier, BuffySettings>(() {
  return BuffySettingsNotifier();
});
