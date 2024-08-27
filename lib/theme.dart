import 'package:flutter/material.dart';

class AppThemeData {
  static Color accentColor = const Color(0xFFD27685);
  static Color accentColorDark = const Color(0xFF6D5D6E);
  static ThemeData getLightTheme() => ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: Colors.white,
      sliderTheme: const SliderThemeData(
        showValueIndicator: ShowValueIndicator.always,
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.all(Colors.pinkAccent),
      ),
      dialogTheme: const DialogTheme(
          backgroundColor: Colors.white, surfaceTintColor: Colors.transparent),
      listTileTheme: ListTileThemeData(
        selectedColor: Colors.white,
        selectedTileColor: Colors.pinkAccent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      ),
      scrollbarTheme: ScrollbarThemeData(
          thumbColor: WidgetStateProperty.all(Colors.pinkAccent)),
      chipTheme: ChipThemeData(
          checkmarkColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          side: BorderSide.none,
          secondaryLabelStyle: const TextStyle(color: Colors.white),
          selectedColor: Colors.pinkAccent),
      colorScheme: const ColorScheme.light(primary: Colors.pinkAccent));

  static ThemeData getDarkTheme() => ThemeData.dark().copyWith(
      appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF6D5D6E), foregroundColor: Colors.white),
      scaffoldBackgroundColor: const Color(0xFF282A3A),
      sliderTheme: const SliderThemeData(
        showValueIndicator: ShowValueIndicator.always,
      ),
      listTileTheme: ListTileThemeData(
        selectedColor: Colors.white,
        selectedTileColor: const Color(0xFFD27685),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(200)),
      ),
      dialogBackgroundColor: const Color(0xFF6D5D6E),
      elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD27685),
              foregroundColor: Colors.white)),
      chipTheme: ChipThemeData(
          checkmarkColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          side: BorderSide.none,
          secondaryLabelStyle: const TextStyle(color: Colors.white),
          selectedColor: const Color(0xFFD27685)),
      colorScheme: const ColorScheme.dark(primary: Color(0xFFD27685)));
}
