import 'package:flutter/material.dart';

class AppThemeData {
  static Color accentColor = const Color(0xFF6B728E);
  static Color accentColorDark = const Color(0xFF404258);
  static ThemeData getLightTheme() => ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: Colors.white,
      sliderTheme: const SliderThemeData(
        showValueIndicator: ShowValueIndicator.always,
      ),
      radioTheme: RadioThemeData(
        fillColor: MaterialStateProperty.all(Colors.pinkAccent),
      ),
      dialogTheme: const DialogTheme(
          backgroundColor: Colors.white, surfaceTintColor: Colors.transparent),
      listTileTheme: ListTileThemeData(
        selectedColor: Colors.white,
        selectedTileColor: Colors.pinkAccent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      ),
      scrollbarTheme: ScrollbarThemeData(
          thumbColor: MaterialStateProperty.all(Colors.pinkAccent)),
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
          backgroundColor: Color(0xFF404258), foregroundColor: Colors.white),
      scaffoldBackgroundColor: const Color(0xFF282A3A),
      sliderTheme: const SliderThemeData(
        showValueIndicator: ShowValueIndicator.always,
      ),
      listTileTheme: ListTileThemeData(
        selectedColor: Colors.white,
        selectedTileColor: const Color(0xFF6B728E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      ),
      dialogBackgroundColor: const Color(0xFF404258),
      elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6B728E),
              foregroundColor: Colors.white)),
      chipTheme: ChipThemeData(
          checkmarkColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          side: BorderSide.none,
          secondaryLabelStyle: const TextStyle(color: Colors.white),
          selectedColor: const Color(0xFF6B728E)),
      colorScheme: const ColorScheme.dark(primary: Color(0xFF6B728E)));
}
