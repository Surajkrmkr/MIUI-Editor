import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_settings.dart';

final settingsProvider =
    NotifierProvider<SettingsNotifier, AppSettings>(SettingsNotifier.new);

class SettingsNotifier extends Notifier<AppSettings> {
  // Prefixed keys to avoid SharedPreferences collisions with other sub-apps.
  static const _mode = 'svg_mode';
  static const _colorPrecision = 'svg_colorPrecision';
  static const _filterSpeckle = 'svg_filterSpeckle';
  static const _lastUsedFolder = 'svg_lastUsedFolder';
  static const _darkMode = 'svg_darkMode';

  @override
  AppSettings build() {
    _loadSettings();
    return AppSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    state = state.copyWith(
      mode: prefs.getString(_mode) ?? 'spline',
      colorPrecision: prefs.getInt(_colorPrecision) ?? 6,
      filterSpeckle: prefs.getInt(_filterSpeckle) ?? 8,
      lastUsedFolder: prefs.getString(_lastUsedFolder),
      darkMode: prefs.getBool(_darkMode) ?? true,
    );
  }

  Future<void> updateSettings({
    String? mode,
    int? colorPrecision,
    int? filterSpeckle,
    String? lastUsedFolder,
    bool? darkMode,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    if (mode != null) await prefs.setString(_mode, mode);
    if (colorPrecision != null) await prefs.setInt(_colorPrecision, colorPrecision);
    if (filterSpeckle != null) await prefs.setInt(_filterSpeckle, filterSpeckle);
    if (lastUsedFolder != null) await prefs.setString(_lastUsedFolder, lastUsedFolder);
    if (darkMode != null) await prefs.setBool(_darkMode, darkMode);

    state = state.copyWith(
      mode: mode,
      colorPrecision: colorPrecision,
      filterSpeckle: filterSpeckle,
      lastUsedFolder: lastUsedFolder,
      darkMode: darkMode,
    );
  }
}
