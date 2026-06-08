import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme_editor/presentation/providers/service_providers.dart';

const _kThemeModeKey = 'app_theme_mode';

/// Exposes the current [ThemeMode] and a toggle/setter.
/// Persists the user's selection across restarts via SharedPreferences.
class ThemeModeNotifier extends Notifier<ThemeMode> {
  static const _dark  = 'dark';
  static const _light = 'light';

  @override
  ThemeMode build() {
    final prefs = ref.read(sharedPrefsProvider);
    final stored = prefs.getString(_kThemeModeKey);
    return stored == _light ? ThemeMode.light : ThemeMode.dark;
  }

  void setDark()  => _set(ThemeMode.dark);
  void setLight() => _set(ThemeMode.light);

  void toggle() =>
      state == ThemeMode.dark ? setLight() : setDark();

  void _set(ThemeMode mode) {
    state = mode;
    ref
        .read(sharedPrefsProvider)
        .setString(_kThemeModeKey, mode == ThemeMode.light ? _light : _dark);
  }
}

final themeModeProvider =
    NotifierProvider<ThemeModeNotifier, ThemeMode>(ThemeModeNotifier.new);
