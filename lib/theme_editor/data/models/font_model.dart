import 'package:dynamic_cached_fonts/dynamic_cached_fonts.dart';

class FontEntry {
  FontEntry({required this.id, required this.name, required this.url})
      : dynamicFont = DynamicCachedFonts(fontFamily: name, url: url)..load();

  final int id;
  final String name;
  final String url;
  final DynamicCachedFonts dynamicFont;

  String get fontFamily => dynamicFont.fontFamily;

  factory FontEntry.fromJson(Map<String, dynamic> j) =>
      FontEntry(id: j['id'] as int, name: j['name'] as String, url: j['url'] as String);
}

class FontListModel {
  const FontListModel({required this.fonts});
  final List<FontEntry> fonts;

  factory FontListModel.fromJson(Map<String, dynamic> j) => FontListModel(
    fonts: (j['fonts'] as List<dynamic>?)
            ?.map((e) => FontEntry.fromJson(e as Map<String, dynamic>))
            .toList() ?? [],
  );
}
