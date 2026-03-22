import 'dart:convert';
import '../../core/constants/app_constants.dart';

class ThemeSettings {
  const ThemeSettings({this.themeCount = AppConstants.defaultThemeCount});
  final int themeCount;

  factory ThemeSettings.fromJson(Map<String, dynamic> j) =>
      ThemeSettings(themeCount: j['themeCount'] as int? ?? AppConstants.defaultThemeCount);

  Map<String, dynamic> toJson() => {'themeCount': themeCount};

  String encode() => jsonEncode(toJson());

  static ThemeSettings decode(String s) {
    try {
      return ThemeSettings.fromJson(jsonDecode(s) as Map<String, dynamic>);
    } catch (_) {
      return const ThemeSettings();
    }
  }
}
