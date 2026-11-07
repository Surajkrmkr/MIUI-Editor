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

const kBuffyWallpapersKey = 'popular';

/// The root keys other than the wallpaper list (banners, titles, …), in order.
Map<String, dynamic> parseBuffyCatalogFields(String json) {
  final root = jsonDecode(json) as Map<String, dynamic>;
  return {
    for (final e in root.entries)
      if (e.key != kBuffyWallpapersKey) e.key: e.value,
  };
}

/// Rebuilds [args]' `catalog` with the edited `fields` and `wallpapers`.
/// Keys keep their order, keys missing from `fields` are dropped and new ones
/// go last. Takes one argument so it can run through `compute`.
String encodeBuffyCatalog(
  ({
    String catalog,
    Map<String, dynamic> fields,
    List<Map<String, dynamic>> wallpapers,
  })
  args,
) {
  final root = jsonDecode(args.catalog) as Map<String, dynamic>;
  final out = <String, dynamic>{
    for (final key in root.keys)
      if (key == kBuffyWallpapersKey)
        key: args.wallpapers
      else if (args.fields.containsKey(key))
        key: args.fields[key],
    for (final e in args.fields.entries)
      if (!root.containsKey(e.key) && e.key != kBuffyWallpapersKey)
        e.key: e.value,
  };
  out.putIfAbsent(kBuffyWallpapersKey, () => args.wallpapers);
  return const JsonEncoder.withIndent('  ').convert(out);
}

/// What changes between two catalog JSONs.
class BuffyCatalogDiff {
  const BuffyCatalogDiff({
    required this.added,
    required this.removed,
    required this.edited,
    required this.fieldsChanged,
  });

  final List<BuffyWallpaper> added;
  final List<BuffyWallpaper> removed;
  final List<BuffyWallpaper> edited;
  final List<String> fieldsChanged;

  bool get isEmpty =>
      added.isEmpty &&
      removed.isEmpty &&
      edited.isEmpty &&
      fieldsChanged.isEmpty;
}

/// Takes one argument so it can run through `compute`.
BuffyCatalogDiff diffBuffyCatalog(({String before, String after}) args) {
  final before = {for (final w in parseBuffyCatalog(args.before)) w.id: w};
  final after = {for (final w in parseBuffyCatalog(args.after)) w.id: w};
  final beforeFields = parseBuffyCatalogFields(args.before);
  final afterFields = parseBuffyCatalogFields(args.after);
  return BuffyCatalogDiff(
    added: [
      for (final e in after.entries)
        if (!before.containsKey(e.key)) e.value,
    ],
    removed: [
      for (final e in before.entries)
        if (!after.containsKey(e.key)) e.value,
    ],
    edited: [
      for (final e in after.entries)
        if (before.containsKey(e.key) &&
            jsonEncode(before[e.key]!.toJson()) != jsonEncode(e.value.toJson()))
          e.value,
    ],
    fieldsChanged: [
      for (final key in {...beforeFields.keys, ...afterFields.keys})
        if (jsonEncode(beforeFields[key]) != jsonEncode(afterFields[key])) key,
    ],
  );
}
