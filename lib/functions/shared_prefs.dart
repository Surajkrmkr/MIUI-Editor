import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class SharedPrefs {
  static SharedPreferences? prefs;
  static const String key = "themeSettings";

  init() async {
    prefs = await SharedPreferences.getInstance();
  }

  static ThemeSettings getDataFromSF() {
    String sfData = prefs!.getString(key) ?? "{}";
    return ThemeSettings.fromJson(json.decode(sfData));
  }

  static setDataToSF(ThemeSettings themeSettings) async {
    await prefs!.setString(key, json.encode(themeSettings.toJson()));
  }
}

class ThemeSettings {
  final int themeCount;
  ThemeSettings({required this.themeCount});

  factory ThemeSettings.fromJson(Map<String, dynamic> json) {
    return ThemeSettings(
      themeCount: json['themeCount'] ?? 25,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'themeCount': themeCount,
    };
  }
}
