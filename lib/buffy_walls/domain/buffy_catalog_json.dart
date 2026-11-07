import 'dart:convert';

import 'models/buffy_wallpaper.dart';

List<BuffyWallpaper> parseBuffyCatalog(String json) {
  final root = jsonDecode(json) as Map<String, dynamic>;
  final popular = root['popular'] as List<dynamic>?;
  if (popular == null) return [];
  return popular
      .map((e) => BuffyWallpaper.fromJson(e as Map<String, dynamic>))
      .toList();
}

/// Replaces the wallpaper list in [args]' `catalog`, keeping its other keys.
/// Takes one argument so it can run through `compute`.
String encodeBuffyCatalog(
  ({String catalog, List<Map<String, dynamic>> wallpapers}) args,
) {
  final root = jsonDecode(args.catalog) as Map<String, dynamic>;
  root['popular'] = args.wallpapers;
  return const JsonEncoder.withIndent('  ').convert(root);
}
