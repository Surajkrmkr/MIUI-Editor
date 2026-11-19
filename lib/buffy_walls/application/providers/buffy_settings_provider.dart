import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../theme_editor/presentation/providers/service_providers.dart';

class BuffySettings {
  final String admobPublisherId;
  final String playPackageName;

  BuffySettings({
    this.admobPublisherId = '',
    this.playPackageName = '',
  });

  BuffySettings copyWith({
    String? admobPublisherId,
    String? playPackageName,
  }) {
    return BuffySettings(
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
      admobPublisherId: prefs.getString('buffy_admob_publisher_id') ?? '',
      playPackageName: prefs.getString('buffy_play_package_name') ?? '',
    );
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
