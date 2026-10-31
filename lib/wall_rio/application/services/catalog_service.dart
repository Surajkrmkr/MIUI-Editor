import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:uuid/uuid.dart';

import '../../domain/catalog_rules.dart';
import '../../domain/models/catalog.dart';
import '../../infrastructure/services/storage_client.dart';
import '../../infrastructure/services/thumbnail_engine.dart';
import '../../infrastructure/services/video_engine.dart';

/// A save was blocked because the edited catalog failed validation.
class CatalogValidationException implements Exception {
  CatalogValidationException(this.problems);
  final List<String> problems;
  @override
  String toString() => problems.join('\n');
}

/// One or more uploads would overwrite existing files. Phones cache media for
/// a year, so files are never replaced: the wallpaper needs another name.
class NameTakenException implements Exception {
  NameTakenException(this.paths);
  final List<String> paths;
  @override
  String toString() => 'Already in the bucket:\n${paths.join('\n')}';
}

/// Returns the new wall list and the entries that changed (for validation).
typedef CatalogEdit = ({
  List<Map<String, dynamic>> walls,
  List<Map<String, dynamic>> changed,
}) Function(List<Map<String, dynamic>> walls);

/// Reads and writes the WallRio catalogs in Firebase Storage.
///
/// Every save backs up the previous version to `<jsonFolder>/history/` and is
/// conditional on the generation it was read at, so two editors can't silently
/// overwrite each other: on a conflict the edit is re-applied to the latest copy.
///
/// For [CatalogKind.collections], wallpaper actions take the id of the
/// collection they apply to.
class CatalogService {
  CatalogService(this._storage, this.settings);

  final StorageClient _storage;
  final StorageSettings settings;

  static const _mediaCacheControl = 'public, max-age=31536000, immutable';
  static const _jsonCacheControl = 'public, max-age=300';
  static const _maxSaveAttempts = 3;

  Future<CatalogDocument> load(CatalogKind kind) async {
    final file = await _storage.download(settings.jsonPath(kind));
    final root = jsonDecode(utf8.decode(file.bytes)) as Map<String, dynamic>;
    return CatalogDocument(kind: kind, root: root, generation: file.generation);
  }

  /// Uploads each draft's media (and generated thumbnail/preview), then adds
  /// the entries to the catalog. Media goes first so the app never sees an
  /// entry whose file is missing.
  Future<CatalogDocument> publish(
    CatalogDocument doc,
    List<WallpaperDraft> drafts, {
    String? collectionId,
    void Function(String status)? onProgress,
  }) async {
    final kind = doc.kind;
    final collectionName =
        kind.hasCollections ? '${doc.collection(collectionId)?['name'] ?? ''}' : null;
    if (kind.hasCollections && (collectionName ?? '').isEmpty) {
      throw CatalogValidationException(['Pick a collection to upload into']);
    }
    final planned = [
      for (final draft in drafts)
        (
          draft: draft,
          paths: CatalogRules.objectPaths(
            settings: settings,
            kind: kind,
            folder: collectionName ?? draft.category,
            name: draft.name,
            extension: CatalogRules.extensionOf(draft.localPath),
          ),
          subjectId: const Uuid().v4(),
        ),
    ];

    // Refuse before uploading anything if a name collides.
    final mainField = kind.identityField;
    final mainPaths = planned.map((p) => p.paths[mainField]!).toList();
    final taken = <String>{
      ...mainPaths.where((p) => mainPaths.indexOf(p) != mainPaths.lastIndexOf(p)),
    };
    for (final path in mainPaths) {
      if (await _storage.stat(path) != null) taken.add(path);
    }
    if (taken.isNotEmpty) throw NameTakenException(taken.toList());

    for (final (i, p) in planned.indexed) {
      final label = '${i + 1}/${planned.length} "${p.draft.name}"';
      final files = await _mediaFor(kind, p.draft, label, onProgress);
      onProgress?.call('Uploading $label');
      for (final MapEntry(key: field, value: file) in files.entries) {
        await _storage.upload(
          p.paths[field]!,
          file.bytes,
          contentType: file.contentType,
          cacheControl: _mediaCacheControl,
          ifGenerationMatch: '0',
        );
      }
    }

    onProgress?.call('Updating ${kind.jsonFile}');
    return save(doc, collectionId: collectionId, (walls) {
      // Ids are assigned here so a retry after a conflict picks fresh ones.
      var id = CatalogRules.nextId(walls);
      final entries = [
        for (final p in planned)
          CatalogRules.buildEntry(
            kind: kind,
            id: id++,
            draft: p.draft,
            media: {
              for (final e in p.paths.entries)
                e.key: CatalogRules.storageUrl(settings.bucket, e.value),
            },
            subjectId: p.subjectId,
          ),
      ];
      // Follow the list's existing order; new ones in the order they were picked.
      final next = CatalogRules.newestFirst(walls)
          ? [...entries.reversed, ...walls]
          : [...walls, ...entries];
      return (walls: next, changed: entries);
    });
  }

  /// The files to upload for one draft, keyed by entry field.
  Future<Map<String, ({List<int> bytes, String contentType})>> _mediaFor(
    CatalogKind kind,
    WallpaperDraft draft,
    String label,
    void Function(String status)? onProgress,
  ) async {
    final original = await File(draft.localPath).readAsBytes();
    if (kind.isVideo) {
      onProgress?.call('Making preview clip $label');
      final preview = await VideoEngine.preview(draft.localPath);
      onProgress?.call('Making thumbnail $label');
      final thumbnail = await VideoEngine.thumbnail(draft.localPath);
      return {
        'videoUrl': (bytes: original, contentType: 'video/mp4'),
        'previewVideo': (bytes: preview, contentType: 'video/mp4'),
        'thumbnail': (bytes: thumbnail, contentType: 'image/jpeg'),
      };
    }
    onProgress?.call('Creating thumbnail $label');
    final Uint8List thumbnail = await ThumbnailEngine.generate(
      inputPath: draft.localPath,
      width: kind.thumbWidth,
      height: kind.thumbHeight,
    );
    return {
      'url': (bytes: original, contentType: _imageContentType(draft.localPath)),
      'thumbnail': (bytes: thumbnail, contentType: 'image/jpeg'),
    };
  }

  /// Replaces the entry with the same media URL (ids are not unique in the data).
  Future<CatalogDocument> updateEntry(
    CatalogDocument doc,
    Map<String, dynamic> updated, {
    String? collectionId,
  }) {
    final key = doc.kind.identityField;
    return save(doc, collectionId: collectionId, (walls) {
      final index = walls.indexWhere((w) => w[key] == updated[key]);
      if (index == -1) {
        throw CatalogValidationException(['"${updated['name']}" is no longer in the catalog']);
      }
      final next = [...walls]..[index] = updated;
      return (walls: next, changed: [updated]);
    });
  }

  /// Removes the entry. Its files are deleted only if [deleteFiles] and no
  /// catalog JSON still references them.
  Future<CatalogDocument> deleteEntry(
    CatalogDocument doc,
    Map<String, dynamic> entry, {
    String? collectionId,
    bool deleteFiles = false,
  }) async {
    final key = doc.kind.identityField;
    final saved = await save(doc, collectionId: collectionId, (walls) {
      final next = walls.where((w) => w[key] != entry[key]).toList();
      return (walls: next, changed: const []);
    });
    if (deleteFiles) {
      final referenced = await _allCatalogText();
      for (final field in doc.kind.mediaFields) {
        final url = '${entry[field] ?? ''}';
        final path = CatalogRules.objectPathFromUrl(settings.bucket, url);
        if (path != null && !referenced.contains(url)) await _storage.delete(path);
      }
    }
    return saved;
  }

  /// Adds an empty collection at the top. Its in-app product ([productId])
  /// must be set up in Play Console / App Store Connect separately.
  Future<CatalogDocument> createCollection(
    CatalogDocument doc, {
    required String name,
    required String productId,
    bool hideForIOS = false,
  }) {
    return _saveRoot(doc, (current) {
      final collections = current.collections;
      final problems = CatalogRules.validateCollection(
        collections: collections,
        name: name,
        productId: productId,
      );
      if (problems.isNotEmpty) throw CatalogValidationException(problems);
      final created = {
        'id': '${CatalogRules.nextId(collections)}',
        'productId': productId,
        'name': name.trim(),
        if (hideForIOS) 'hideForIOS': true,
        'walls': <Map<String, dynamic>>[],
      };
      return current.copyWithCollections([created, ...collections]);
    });
  }

  /// Renames a collection or changes its product / iOS visibility. Existing
  /// image files keep their folder; new uploads use the new name.
  Future<CatalogDocument> updateCollection(
    CatalogDocument doc,
    String id, {
    required String name,
    required String productId,
    required bool hideForIOS,
  }) {
    return _saveRoot(doc, (current) {
      final collections = current.collections;
      if (current.collection(id) == null) {
        throw CatalogValidationException(['Collection $id is no longer in the catalog']);
      }
      final problems = CatalogRules.validateCollection(
        collections: collections,
        name: name,
        productId: productId,
        editingId: id,
      );
      if (problems.isNotEmpty) throw CatalogValidationException(problems);
      return current.copyWithCollections([
        for (final c in collections)
          if ('${c['id']}' == id)
            {
              for (final e in c.entries)
                if (e.key != 'hideForIOS') e.key: e.value,
              'name': name.trim(),
              'productId': productId,
              if (hideForIOS) 'hideForIOS': true,
            }
          else
            c,
      ]);
    });
  }

  /// Applies [edit] to the latest wall list (of [collectionId] for
  /// collections), validates and saves it.
  Future<CatalogDocument> save(
    CatalogDocument doc,
    CatalogEdit edit, {
    String? collectionId,
  }) async {
    final kind = doc.kind;
    // Validation needs async stats, so it runs outside the pure root edit.
    var current = doc;
    for (var attempt = 1; ; attempt++) {
      final result = edit(List.of(current.wallsOf(collectionId)));
      final problems = CatalogRules.validate(
        bucket: settings.bucket,
        kind: kind,
        walls: result.walls,
        changed: result.changed,
        existingObjects: await _existingObjects(kind, result.changed),
      );
      if (problems.isNotEmpty) throw CatalogValidationException(problems);
      try {
        return await _writeRoot(current, current.copyWithWalls(result.walls, collectionId).root);
      } on StoragePreconditionFailed {
        if (attempt >= _maxSaveAttempts) rethrow;
        current = await load(kind);
      }
    }
  }

  /// Saves the document [build] makes from the latest catalog, retrying on conflict.
  Future<CatalogDocument> _saveRoot(
    CatalogDocument doc,
    CatalogDocument Function(CatalogDocument current) build,
  ) async {
    var current = doc;
    for (var attempt = 1; ; attempt++) {
      try {
        return await _writeRoot(current, build(current).root);
      } on StoragePreconditionFailed {
        if (attempt >= _maxSaveAttempts) rethrow;
        current = await load(doc.kind);
      }
    }
  }

  Future<List<StorageObject>> history(CatalogKind kind) async {
    final items = await _storage.list(settings.historyPrefix(kind));
    return items..sort((a, b) => b.path.compareTo(a.path));
  }

  /// Makes a backup the live catalog again (itself backed up first).
  Future<CatalogDocument> restore(CatalogKind kind, StorageObject backup) async {
    final file = await _storage.download(backup.path);
    final root = jsonDecode(utf8.decode(file.bytes)) as Map<String, dynamic>;
    // Make sure the backup is a usable catalog before it goes live.
    CatalogDocument(kind: kind, root: root, generation: file.generation).allWalls;
    for (var attempt = 1; ; attempt++) {
      final current = await load(kind);
      try {
        return await _writeRoot(current, root);
      } on StoragePreconditionFailed {
        if (attempt >= _maxSaveAttempts) rethrow;
      }
    }
  }

  /// Backs up [current], then uploads [root] gzipped, only if the catalog is
  /// still at [current]'s generation.
  Future<CatalogDocument> _writeRoot(
    CatalogDocument current,
    Map<String, dynamic> root,
  ) async {
    final path = settings.jsonPath(current.kind);
    final stamp = DateTime.now().toUtc().toIso8601String().replaceAll(':', '-');
    // Fails with a conflict if someone saved since [current] was read; the
    // bucket keeps no old versions, so this is the last chance to back it up.
    await _storage.copy(
      path,
      '${settings.historyPrefix(current.kind)}$stamp.json',
      ifSourceGenerationMatch: current.generation,
    );
    final json = '${const JsonEncoder.withIndent('  ').convert(root)}\n';
    final uploaded = await _storage.upload(
      path,
      gzip.encode(utf8.encode(json)),
      contentType: 'application/json',
      contentEncoding: 'gzip',
      cacheControl: _jsonCacheControl,
      ifGenerationMatch: current.generation,
    );
    return CatalogDocument(kind: current.kind, root: root, generation: uploaded.generation);
  }

  Future<Set<String>> _existingObjects(
    CatalogKind kind,
    List<Map<String, dynamic>> entries,
  ) async {
    final existing = <String>{};
    for (final entry in entries) {
      for (final field in kind.mediaFields) {
        final path = CatalogRules.objectPathFromUrl(settings.bucket, '${entry[field] ?? ''}');
        if (path != null && await _storage.stat(path) != null) existing.add(path);
      }
    }
    return existing;
  }

  /// Concatenated text of every catalog JSON, for reference checks.
  Future<String> _allCatalogText() async {
    final objects = await _storage.list('${settings.jsonFolder}/');
    final buffer = StringBuffer();
    for (final object in objects) {
      if (object.path.contains('/history/')) continue;
      final file = await _storage.download(object.path);
      buffer.write(utf8.decode(file.bytes));
    }
    return buffer.toString();
  }

  static String _imageContentType(String path) =>
      CatalogRules.extensionOf(path) == 'png' ? 'image/png' : 'image/jpeg';
}
