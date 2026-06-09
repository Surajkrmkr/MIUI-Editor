import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../theme_editor/presentation/providers/service_providers.dart';

class UpscalerSettings {
  final String? customBinaryPath;
  final String? customModelsPath;
  final String? lastUsedFolder;

  UpscalerSettings({
    this.customBinaryPath,
    this.customModelsPath,
    this.lastUsedFolder,
  });

  UpscalerSettings copyWith({
    String? customBinaryPath,
    String? customModelsPath,
    String? lastUsedFolder,
  }) {
    return UpscalerSettings(
      customBinaryPath: customBinaryPath ?? this.customBinaryPath,
      customModelsPath: customModelsPath ?? this.customModelsPath,
      lastUsedFolder: lastUsedFolder ?? this.lastUsedFolder,
    );
  }
}

class UpscalerSettingsNotifier extends Notifier<UpscalerSettings> {
  static const _binaryKey = 'upscaler_binary_path';
  static const _modelsKey = 'upscaler_models_path';
  static const _folderKey = 'upscaler_last_folder';

  @override
  UpscalerSettings build() {
    final prefs = ref.watch(sharedPrefsProvider);
    return UpscalerSettings(
      customBinaryPath: prefs.getString(_binaryKey),
      customModelsPath: prefs.getString(_modelsKey),
      lastUsedFolder: prefs.getString(_folderKey),
    );
  }

  Future<void> updateBinaryPath(String path) async {
    final prefs = ref.read(sharedPrefsProvider);
    await prefs.setString(_binaryKey, path);
    state = state.copyWith(customBinaryPath: path);
  }

  Future<void> updateModelsPath(String path) async {
    final prefs = ref.read(sharedPrefsProvider);
    await prefs.setString(_modelsKey, path);
    state = state.copyWith(customModelsPath: path);
  }

  Future<void> updateLastFolder(String path) async {
    final prefs = ref.read(sharedPrefsProvider);
    await prefs.setString(_folderKey, path);
    state = state.copyWith(lastUsedFolder: path);
  }
}

final upscalerSettingsProvider =
    NotifierProvider<UpscalerSettingsNotifier, UpscalerSettings>(() {
  return UpscalerSettingsNotifier();
});
