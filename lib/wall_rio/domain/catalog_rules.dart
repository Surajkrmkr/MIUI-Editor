import 'package:uuid/uuid.dart';

import 'models/catalog.dart';

/// Pure rules for building and checking catalog entries. No I/O, so they are
/// unit-tested directly.
class CatalogRules {
  const CatalogRules._();

  static const _firebaseHost = 'https://firebasestorage.googleapis.com/v0/b/';

  /// The URL format the app loads (Firebase Storage, token-authenticated).
  static String storageUrl(String bucket, String objectPath) =>
      '$_firebaseHost$bucket/o/${Uri.encodeComponent(objectPath)}?alt=media';

  /// Object path for a Firebase Storage URL in [bucket], or null if it is not one.
  static String? objectPathFromUrl(String bucket, String url) {
    final prefix = '$_firebaseHost$bucket/o/';
    if (!url.startsWith(prefix)) return null;
    final encoded = url.substring(prefix.length).split('?').first;
    return Uri.decodeComponent(encoded);
  }

  /// Ids are numbers (ints, or strings in collections); some are duplicated,
  /// so use max + 1.
  static int nextId(List<Map<String, dynamic>> walls) {
    var maxId = 0;
    for (final wall in walls) {
      final id = int.tryParse('${wall['id']}');
      if (id != null && id > maxId) maxId = id;
    }
    return maxId + 1;
  }

  /// Whether [walls] are listed newest first. Most catalogs are, but some
  /// collections list their oldest wallpaper first; new entries follow suit.
  static bool newestFirst(List<Map<String, dynamic>> walls) {
    if (walls.length < 2) return true;
    final first = int.tryParse('${walls.first['id']}') ?? 0;
    final last = int.tryParse('${walls.last['id']}') ?? 0;
    return first >= last;
  }

  /// Author of the newest entry, so uploads default to the current team name.
  static String defaultAuthor(List<Map<String, dynamic>> walls) {
    final ordered = newestFirst(walls) ? walls : walls.reversed;
    for (final wall in ordered) {
      final author = '${wall['author'] ?? ''}'.trim();
      if (author.isNotEmpty) return author;
    }
    return 'WallRio';
  }

  /// "golden_fields-2.jpg" → "Golden Fields 2".
  static String nameFromFilename(String filename) {
    final base = filename.contains('.')
        ? filename.substring(0, filename.lastIndexOf('.'))
        : filename;
    return base
        .split(RegExp(r'[-_\s]+'))
        .where((part) => part.isNotEmpty)
        .map((part) => part[0].toUpperCase() + part.substring(1))
        .join(' ');
  }

  /// Makes a name safe as a path segment; keeps spaces like the existing data.
  static String pathSegment(String value) => value
      .replaceAll(RegExp(r'[/\\:*?"<>|#%\[\]]'), '')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();

  /// Null when [width] × [height] meets the catalog minimum, else the reason.
  static String? resolutionError(CatalogKind kind, int width, int height) {
    if (width >= kind.minWidth && height >= kind.minHeight) return null;
    return '$width × $height is below the ${kind.label.toLowerCase()} minimum '
        'of ${kind.minWidth} × ${kind.minHeight}';
  }

  static String extensionOf(String path) {
    final dot = path.lastIndexOf('.');
    final ext = dot == -1 ? '' : path.substring(dot + 1).toLowerCase();
    return ext == 'jpeg' ? 'jpg' : ext;
  }

  /// Storage paths for a new wallpaper, keyed by the entry field they fill.
  /// [folder] is the category (mobile) or the collection name (collections).
  static Map<String, String> objectPaths({
    required StorageSettings settings,
    required CatalogKind kind,
    required String folder,
    required String name,
    required String extension,
  }) {
    final file = pathSegment(name);
    switch (kind) {
      case CatalogKind.live:
        final base = settings.liveRoot;
        return {
          'videoUrl': '$base/livewalls/$file.mp4',
          'previewVideo': '$base/previews/${file}_preview.mp4',
          'thumbnail': '$base/thumbnails/$file.jpg',
        };
      case CatalogKind.desktop:
        final base = '${settings.imagesRoot}/Desktop';
        return {
          'url': '$base/$file.$extension',
          'thumbnail': '$base/Thumbnail/$file-small.jpg',
        };
      case CatalogKind.mobile:
      case CatalogKind.collections:
        final base = '${settings.imagesRoot}/${pathSegment(folder)}';
        return {
          'url': '$base/$file.$extension',
          'thumbnail': '$base/Thumbnails/$file-small.jpg',
        };
    }
  }

  /// A catalog entry in the field order each existing JSON uses. [media] maps
  /// the media fields (see [CatalogKind.mediaFields]) to their URLs.
  static Map<String, dynamic> buildEntry({
    required CatalogKind kind,
    required int id,
    required WallpaperDraft draft,
    required Map<String, String> media,
    String? subjectId,
  }) {
    final subject = subjectId ?? const Uuid().v4();
    final name = draft.name.trim();
    final author = draft.author.trim();
    final category = draft.category.trim();
    switch (kind) {
      case CatalogKind.live:
        return {
          'id': id,
          'type': 'live',
          'name': name,
          'author': author,
          'videoUrl': media['videoUrl'],
          'thumbnail': media['thumbnail'],
          'previewVideo': media['previewVideo'],
          'tags': draft.tags,
          'category': category,
          'color': draft.colors,
          'isPremium': draft.isPremium,
          'subjectId': subject,
        };
      case CatalogKind.collections:
        return {
          'id': '$id',
          'subjectId': subject,
          'name': name,
          'author': author,
          'url': media['url'],
          'thumbnail': media['thumbnail'],
          'tags': draft.tags,
          'category': category,
          'color': draft.colors,
          'isPremium': draft.isPremium,
        };
      case CatalogKind.mobile:
      case CatalogKind.desktop:
        return {
          'id': id,
          if (kind == CatalogKind.desktop) 'type': 'desktop',
          'name': name,
          'author': author,
          'url': media['url'],
          'thumbnail': media['thumbnail'],
          'tags': draft.tags,
          'category': category,
          'color': draft.colors,
          'isPremium': draft.isPremium,
          'subjectId': subject,
        };
    }
  }

  /// Problems that must block a save. [existingObjects] are the object paths
  /// known to exist; entries pointing anywhere else in the bucket are flagged.
  static List<String> validate({
    required String bucket,
    required CatalogKind kind,
    required List<Map<String, dynamic>> walls,
    required List<Map<String, dynamic>> changed,
    Set<String>? existingObjects,
  }) {
    final problems = <String>[];
    final ids = <String>{};
    for (final wall in walls) {
      final id = '${wall['id']}';
      if (!ids.add(id) && changed.any((c) => '${c['id']}' == id)) {
        problems.add('Duplicate id $id');
      }
    }
    for (final entry in changed) {
      final label = '"${entry['name']}"';
      for (final field in ['name', 'author', 'category', ...kind.mediaFields]) {
        if ('${entry[field] ?? ''}'.trim().isEmpty) {
          problems.add('$label is missing $field');
        }
      }
      if (existingObjects == null) continue;
      for (final field in kind.mediaFields) {
        final path = objectPathFromUrl(bucket, '${entry[field] ?? ''}');
        if (path != null && !existingObjects.contains(path)) {
          problems.add('$label $field points to a missing file: $path');
        }
      }
    }
    return problems;
  }

  /// "Bubu Dudu" → "com.wallrio.collection.bubududu", the existing pattern.
  static String defaultProductId(String name) =>
      'com.wallrio.collection.${name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '')}';

  /// Problems with a new or edited collection. [editingId] skips the
  /// collection being edited in the uniqueness checks.
  static List<String> validateCollection({
    required List<Map<String, dynamic>> collections,
    required String name,
    required String productId,
    String? editingId,
  }) {
    final problems = <String>[];
    final others = collections.where((c) => '${c['id']}' != editingId);
    if (pathSegment(name).isEmpty) problems.add('Collection name is required');
    if (!RegExp(r'^[a-z0-9_]+(\.[a-z0-9_]+)+$').hasMatch(productId)) {
      problems.add('Product id must look like com.wallrio.collection.name');
    }
    if (others.any((c) => '${c['name']}'.toLowerCase() == name.trim().toLowerCase())) {
      problems.add('A collection named "${name.trim()}" already exists');
    }
    if (others.any((c) => c['productId'] == productId)) {
      problems.add('Product id $productId is already used');
    }
    return problems;
  }
}
