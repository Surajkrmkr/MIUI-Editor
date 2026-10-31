/// The wallpaper catalogs the WallRio app reads from Firebase Storage.
///
/// Each catalog is one JSON file under the JSON folder (default `wallriojson/`).
/// Images live under the images root (default `wallrio_wall_data/`), live
/// videos under the live root (default `wallrio_live/`).
enum CatalogKind {
  mobile(
    label: 'Mobile',
    jsonFile: 'rio.Json',
    minWidth: 1720,
    minHeight: 3728,
    thumbWidth: 430,
    thumbHeight: 932,
  ),
  desktop(
    label: 'Desktop',
    jsonFile: 'desktop.json',
    minWidth: 3840,
    minHeight: 2160,
    thumbWidth: 640,
    thumbHeight: 360,
  ),
  live(
    label: 'Live',
    jsonFile: 'live_wall.json',
    minWidth: 1080,
    minHeight: 1920,
    // Fits the frame inside 960×540 like process_videos.py (304×540 for 9:16).
    thumbWidth: 304,
    thumbHeight: 540,
  ),
  collections(
    label: 'Collections',
    jsonFile: 'collections.json',
    minWidth: 1720,
    minHeight: 3728,
    thumbWidth: 430,
    thumbHeight: 932,
  );

  const CatalogKind({
    required this.label,
    required this.jsonFile,
    required this.minWidth,
    required this.minHeight,
    required this.thumbWidth,
    required this.thumbHeight,
  });

  final String label;
  final String jsonFile;

  /// Smallest accepted upload resolution (width × height).
  final int minWidth;
  final int minHeight;

  /// Thumbnail size; images are center-cropped to it, video frames fit inside it.
  final int thumbWidth;
  final int thumbHeight;

  bool get isVideo => this == live;

  /// Wallpapers live inside one of several collections.
  bool get hasCollections => this == collections;

  /// Fields holding Storage URLs; all must point to existing files.
  List<String> get mediaFields =>
      isVideo ? const ['videoUrl', 'previewVideo', 'thumbnail'] : const ['url', 'thumbnail'];

  /// The field that identifies an entry (ids are not unique in the data).
  String get identityField => isVideo ? 'videoUrl' : 'url';

  /// Collections store ids as strings, the others as ints.
  bool get stringIds => this == collections;

  List<String> get uploadExtensions => isVideo ? const ['mp4'] : const ['jpg', 'jpeg', 'png'];
}

/// A catalog JSON as downloaded, plus the Storage generation it was read at.
///
/// The root map is kept as-is so fields the CMS doesn't edit (banners,
/// subscription, search, pop-up…) survive a save untouched.
class CatalogDocument {
  CatalogDocument({
    required this.kind,
    required this.root,
    required this.generation,
  });

  final CatalogKind kind;
  final Map<String, dynamic> root;

  /// Storage object generation; the save only succeeds if it is unchanged.
  final String generation;

  /// The collections (with their `walls`), for [CatalogKind.collections].
  List<Map<String, dynamic>> get collections {
    final list = root['collections'];
    if (list is! List) throw const FormatException('Catalog has no "collections" list');
    return list.cast<Map<String, dynamic>>();
  }

  Map<String, dynamic>? collection(String? id) {
    for (final c in collections) {
      if ('${c['id']}' == id) return c;
    }
    return null;
  }

  /// The wallpaper list in display order. For collections, the list of the
  /// collection with [collectionId].
  ///
  /// `rio.Json`/`live_wall.json` have `walls: [...]`; `desktop.json` nests it
  /// as `walls: [[...]]`.
  List<Map<String, dynamic>> wallsOf([String? collectionId]) {
    if (kind.hasCollections) {
      final c = collection(collectionId);
      if (c == null) throw FormatException('No collection with id $collectionId');
      return (c['walls'] as List? ?? const []).cast<Map<String, dynamic>>();
    }
    final walls = root['walls'];
    if (walls is! List) {
      throw const FormatException('Catalog has no "walls" list');
    }
    final list = kind == CatalogKind.desktop && walls.isNotEmpty && walls.first is List
        ? walls.first as List
        : walls;
    return list.cast<Map<String, dynamic>>();
  }

  /// All wallpapers across collections (for suggestions and stats).
  List<Map<String, dynamic>> get allWalls => kind.hasCollections
      ? [for (final c in collections) ...wallsOf('${c['id']}')]
      : wallsOf();

  CatalogDocument copyWithWalls(List<Map<String, dynamic>> walls, [String? collectionId]) {
    final newRoot = Map<String, dynamic>.from(root);
    if (kind.hasCollections) {
      newRoot['collections'] = [
        for (final c in collections)
          '${c['id']}' == collectionId ? {...c, 'walls': walls} : c,
      ];
    } else {
      final current = root['walls'];
      newRoot['walls'] = kind == CatalogKind.desktop && current is List &&
              current.isNotEmpty && current.first is List
          ? [walls, ...current.skip(1)]
          : walls;
    }
    return CatalogDocument(kind: kind, root: newRoot, generation: generation);
  }

  CatalogDocument copyWithCollections(List<Map<String, dynamic>> collections) =>
      CatalogDocument(
        kind: kind,
        root: {...root, 'collections': collections},
        generation: generation,
      );
}

/// A wallpaper the user has picked and filled in, ready to publish.
class WallpaperDraft {
  WallpaperDraft({
    required this.localPath,
    required this.width,
    required this.height,
    required this.name,
    required this.author,
    required this.category,
    this.tags = const [],
    this.colors = const [],
    this.isPremium = false,
  });

  final String localPath;
  final int width;
  final int height;
  String name;
  String author;
  String category;
  List<String> tags;
  List<String> colors;
  bool isPremium;
}

/// Where the CMS reads and writes in the bucket.
class StorageSettings {
  const StorageSettings({
    this.bucket = 'wallrio-e551b.firebasestorage.app',
    this.jsonFolder = 'wallriojson',
    this.imagesRoot = 'wallrio_wall_data',
    this.liveRoot = 'wallrio_live',
  });

  final String bucket;
  final String jsonFolder;
  final String imagesRoot;
  final String liveRoot;

  String jsonPath(CatalogKind kind) => '$jsonFolder/${kind.jsonFile}';

  String historyPrefix(CatalogKind kind) => '$jsonFolder/history/${kind.name}/';
}
