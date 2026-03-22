import 'package:flutter/material.dart';

class AppTheme {
  static const Color _accent     = Color(0xFFD27685);
  static const Color _accentDark = Color(0xFF6D5D6E);
  static const Color _scaffold   = Color(0xFF282A3A);

  static ThemeData light() => ThemeData(
    useMaterial3: true,
    colorScheme: const ColorScheme.light(primary: _accent),
    scaffoldBackgroundColor: Colors.white,
    sliderTheme: const SliderThemeData(showValueIndicator: ShowValueIndicator.alwaysVisible),
    dialogTheme: const DialogThemeData(backgroundColor: Colors.white, surfaceTintColor: Colors.transparent),
    chipTheme: ChipThemeData(
      checkmarkColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      side: BorderSide.none,
      selectedColor: _accent,
    ),
  );

  static ThemeData dark() => ThemeData.dark().copyWith(
    colorScheme: const ColorScheme.dark(primary: _accent),
    appBarTheme: const AppBarTheme(backgroundColor: _accentDark, foregroundColor: Colors.white),
    scaffoldBackgroundColor: _scaffold,
    sliderTheme: const SliderThemeData(showValueIndicator: ShowValueIndicator.alwaysVisible),
    listTileTheme: ListTileThemeData(
      selectedColor: Colors.white,
      selectedTileColor: _accent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(200)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(backgroundColor: _accent, foregroundColor: Colors.white),
    ),
    chipTheme: ChipThemeData(
      checkmarkColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      side: BorderSide.none,
      selectedColor: _accent,
    ),
  );
}
