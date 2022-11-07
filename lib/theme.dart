import 'package:flutter/material.dart';

class AppThemeData {
  static ThemeData getLightTheme() => ThemeData(
      useMaterial3: true,
      backgroundColor: Colors.white,
      scaffoldBackgroundColor: Colors.white,
      sliderTheme: const SliderThemeData(
        showValueIndicator: ShowValueIndicator.always,
      ),
      radioTheme: RadioThemeData(
        fillColor: MaterialStateProperty.all(Colors.pinkAccent),
      ),
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
      useMaterial3: true,
      appBarTheme: const AppBarTheme(
          backgroundColor: Color.fromARGB(255, 30, 30, 30),
          foregroundColor: Colors.white),
      backgroundColor: const Color.fromARGB(255, 30, 30, 30),
      scaffoldBackgroundColor: const Color.fromARGB(255, 30, 30, 30),
      sliderTheme: const SliderThemeData(
        showValueIndicator: ShowValueIndicator.always,
      ),
      listTileTheme: ListTileThemeData(
        selectedColor: Colors.white,
        selectedTileColor: Colors.pinkAccent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      ),
      chipTheme: ChipThemeData(
          checkmarkColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          side: BorderSide.none,
          secondaryLabelStyle: const TextStyle(color: Colors.white),
          selectedColor: Colors.pinkAccent),
      colorScheme: const ColorScheme.light(primary: Colors.pinkAccent));
}
