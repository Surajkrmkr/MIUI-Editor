import 'dart:convert';
import '../../core/constants/app_constants.dart';

class ThemeSettings {
  const ThemeSettings({
    this.themeCount = AppConstants.defaultThemeCount,
    this.basePath,
    this.designerName = '',
    this.authorTag = '',
    this.uiVersion = '',
  });

  final int themeCount;
  final String? basePath;
  final String designerName;
  final String authorTag;
  final String uiVersion;

  factory ThemeSettings.fromJson(Map<String, dynamic> j) => ThemeSettings(
        themeCount: j['themeCount'] as int? ?? AppConstants.defaultThemeCount,
        basePath: j['basePath'] as String?,
        designerName: j['designerName'] as String? ?? '',
        authorTag: j['authorTag'] as String? ?? '',
        uiVersion: j['uiVersion'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {
        'themeCount': themeCount,
        if (basePath != null && basePath!.isNotEmpty) 'basePath': basePath,
        'designerName': designerName,
        'authorTag': authorTag,
        'uiVersion': uiVersion,
      };

  String encode() => jsonEncode(toJson());

  static ThemeSettings decode(String s) {
    try {
      return ThemeSettings.fromJson(jsonDecode(s) as Map<String, dynamic>);
    } catch (_) {
      return const ThemeSettings();
    }
  }

  ThemeSettings copyWith({
    int? themeCount,
    String? basePath,
    String? designerName,
    String? authorTag,
    String? uiVersion,
  }) =>
      ThemeSettings(
        themeCount: themeCount ?? this.themeCount,
        basePath: basePath ?? this.basePath,
        designerName: designerName ?? this.designerName,
        authorTag: authorTag ?? this.authorTag,
        uiVersion: uiVersion ?? this.uiVersion,
      );
}
