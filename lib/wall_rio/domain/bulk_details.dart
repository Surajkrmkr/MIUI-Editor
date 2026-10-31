import 'dart:convert';

import 'models/catalog.dart';

/// Metadata for many uploads at once, written as JSON in the upload dialog.
///
/// ```json
/// {
///   "defaults": { "author": "WallRio", "category": "Nature", "isPremium": false },
///   "walls": [
///     { "file": "golden_fields.jpg", "name": "Golden Fields",
///       "tags": ["Sunset", "Field"], "colors": ["Yellow", "Orange"] }
///   ]
/// }
/// ```
///
/// `defaults` apply to every file; a `walls` entry overrides them for the file
/// it names. `file` matches the dropped file's name, case-insensitively and
/// with or without the extension. A bare list is accepted as `walls`.
/// Schema: `docs/wallrio_bulk_details.schema.json`.
class BulkDetails {
  BulkDetails._(this.defaults, this.entries);

  final BulkFields defaults;
  final List<({String file, BulkFields fields})> entries;

  /// Parses [source]; throws [FormatException] with a message fit to show.
  factory BulkDetails.parse(String source) {
    final Object? json;
    try {
      json = jsonDecode(source);
    } on FormatException catch (e) {
      throw FormatException('Invalid JSON: ${e.message}');
    }

    final Map<String, dynamic> root;
    if (json is List) {
      root = {'walls': json};
    } else if (json is Map<String, dynamic>) {
      root = json;
    } else {
      throw const FormatException(
        'Expected an object with "defaults"/"walls", or a list',
      );
    }
    _rejectUnknown(root, const {'defaults', 'walls', r'$schema'}, 'top level');

    final defaults = root['defaults'] == null
        ? const BulkFields()
        : BulkFields._fromJson(root['defaults'], 'defaults', allowFile: false);

    final walls = root['walls'] ?? const [];
    if (walls is! List) throw const FormatException('"walls" must be a list');
    final entries = <({String file, BulkFields fields})>[];
    final seen = <String>{};
    for (final (i, item) in walls.indexed) {
      final where = 'walls[$i]';
      if (item is! Map<String, dynamic>) {
        throw FormatException('$where must be an object');
      }
      final file = item['file'];
      if (file is! String || file.trim().isEmpty) {
        throw FormatException('$where needs a "file" (the dropped file name)');
      }
      if (!seen.add(_key(file))) {
        throw FormatException('$where: "$file" is listed twice');
      }
      entries.add((
        file: file.trim(),
        fields: BulkFields._fromJson(item, where, allowFile: true),
      ));
    }
    return BulkDetails._(defaults, entries);
  }

  /// The `walls` entry for [path], if any.
  BulkFields? entryFor(String path) {
    final key = _key(path.split(RegExp(r'[/\\]')).last);
    for (final e in entries) {
      if (_key(e.file) == key) return e.fields;
    }
    return null;
  }

  /// Applies defaults, then the matching entry, to [draft]. Returns whether a
  /// `walls` entry matched it.
  bool applyTo(WallpaperDraft draft) {
    defaults.applyTo(draft);
    final entry = entryFor(draft.localPath);
    entry?.applyTo(draft);
    return entry != null;
  }

  /// `walls` entries that name none of [paths], to report likely typos.
  List<String> unmatched(Iterable<String> paths) {
    final keys = paths.map((p) => _key(p.split(RegExp(r'[/\\]')).last)).toSet();
    return [
      for (final e in entries)
        if (!keys.contains(_key(e.file))) e.file,
    ];
  }

  /// JSON for [drafts] as they are now, as a starting point to edit.
  static String template(List<WallpaperDraft> drafts, {String? author}) {
    final json = {
      'defaults': {
        'author':
            author ?? (drafts.isNotEmpty ? drafts.first.author : 'WallRio'),
        'category': '',
        'isPremium': false,
      },
      'walls': [
        for (final d in drafts)
          {
            'file': d.localPath.split(RegExp(r'[/\\]')).last,
            'name': d.name,
            'category': d.category,
            'tags': d.tags,
            'colors': d.colors,
            'isPremium': d.isPremium,
          },
      ],
    };
    return const JsonEncoder.withIndent('  ').convert(json);
  }

  /// File name without extension, lower-cased: "Golden_Fields.JPG" → "golden_fields".
  static String _key(String file) {
    final name = file.trim().toLowerCase();
    final dot = name.lastIndexOf('.');
    return dot > 0 ? name.substring(0, dot) : name;
  }

  static void _rejectUnknown(
    Map<String, dynamic> map,
    Set<String> allowed,
    String where,
  ) {
    final unknown = map.keys.where((k) => !allowed.contains(k)).toList();
    if (unknown.isNotEmpty) {
      throw FormatException(
        'Unknown field ${unknown.map((k) => '"$k"').join(', ')} in $where '
        '(allowed: ${allowed.where((k) => k != r'$schema').join(', ')})',
      );
    }
  }
}

/// The editable fields; null means "leave as it is".
class BulkFields {
  const BulkFields({
    this.name,
    this.author,
    this.category,
    this.tags,
    this.colors,
    this.isPremium,
  });

  final String? name;
  final String? author;
  final String? category;
  final List<String>? tags;
  final List<String>? colors;
  final bool? isPremium;

  static const _fields = {
    'name',
    'author',
    'category',
    'tags',
    'colors',
    'isPremium',
  };

  factory BulkFields._fromJson(
    Object? json,
    String where, {
    required bool allowFile,
  }) {
    if (json is! Map<String, dynamic>) {
      throw FormatException('$where must be an object');
    }
    BulkDetails._rejectUnknown(json, {
      ..._fields,
      if (allowFile) 'file',
    }, where);

    String? text(String key) {
      final v = json[key];
      if (v == null) return null;
      if (v is! String) throw FormatException('$where.$key must be text');
      return v.trim();
    }

    List<String>? list(String key) {
      final v = json[key];
      if (v == null) return null;
      if (v is! List || v.any((e) => e is! String)) {
        throw FormatException(
          '$where.$key must be a list of text, e.g. ["Red", "Blue"]',
        );
      }
      return [for (final e in v) (e as String).trim()]
        ..removeWhere((e) => e.isEmpty);
    }

    final premium = json['isPremium'];
    if (premium != null && premium is! bool) {
      throw FormatException('$where.isPremium must be true or false');
    }
    return BulkFields(
      name: text('name'),
      author: text('author'),
      category: text('category'),
      tags: list('tags'),
      colors: list('colors'),
      isPremium: premium as bool?,
    );
  }

  /// Copies the non-empty fields onto [draft].
  void applyTo(WallpaperDraft draft) {
    if (name?.isNotEmpty ?? false) draft.name = name!;
    if (author?.isNotEmpty ?? false) draft.author = author!;
    if (category?.isNotEmpty ?? false) draft.category = category!;
    if (tags != null) draft.tags = List.of(tags!);
    if (colors != null) draft.colors = List.of(colors!);
    if (isPremium != null) draft.isPremium = isPremium!;
  }
}
