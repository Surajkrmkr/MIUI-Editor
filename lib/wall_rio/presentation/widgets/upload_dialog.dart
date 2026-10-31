import 'dart:io';
import 'dart:typed_data';

import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:miui_icon_generator/core/theme/theme_extensions.dart';
import 'package:uuid/uuid.dart';

import '../../application/providers/ai_provider.dart';
import '../../application/providers/catalog_provider.dart';
import '../../application/services/catalog_service.dart';
import '../../domain/bulk_details.dart';
import '../../domain/catalog_rules.dart';
import '../../domain/models/catalog.dart';
import '../../infrastructure/services/thumbnail_engine.dart';
import '../../infrastructure/services/video_engine.dart';
import 'bulk_details_dialog.dart';
import 'wallpaper_fields.dart';

/// [collectionId] is the collection to upload into, for [CatalogKind.collections].
Future<void> showUploadDialog(
  BuildContext context,
  CatalogDocument doc, {
  String? collectionId,
}) => showDialog(
  context: context,
  barrierDismissible: false,
  builder: (_) => UploadDialog(doc: doc, collectionId: collectionId),
);

/// A picked file: either a draft ready to fill in, or the reason it's refused.
class _PickedFile {
  _PickedFile.valid(this.draft, {this.preview}) : error = null, _path = null;
  _PickedFile.invalid(String path, this.error)
    : draft = null,
      preview = null,
      _path = path;

  final WallpaperDraft? draft;
  final String? error;
  final String? _path;

  /// A frame of a video, since Image.file can't show an MP4.
  final Uint8List? preview;

  String get path => draft?.localPath ?? _path!;
  final String key = const Uuid().v4();
}

class UploadDialog extends ConsumerStatefulWidget {
  const UploadDialog({super.key, required this.doc, this.collectionId});

  final CatalogDocument doc;
  final String? collectionId;

  @override
  ConsumerState<UploadDialog> createState() => _UploadDialogState();
}

class _UploadDialogState extends ConsumerState<UploadDialog> {
  final _formKey = GlobalKey<FormState>();
  final List<_PickedFile> _files = [];
  late final _suggestions = CatalogSuggestions.fromWalls(widget.doc.allWalls);
  late final _defaultAuthor = CatalogRules.defaultAuthor(
    widget.doc.wallsOf(widget.collectionId),
  );

  /// Collection uploads default to the collection name as category.
  late String _lastCategory = _collectionName ?? '';
  bool _dragging = false;
  bool _publishing = false;
  String? _status;
  String? _error;

  /// Details from the JSON editor; also applied to files dropped afterwards.
  BulkDetails? _bulk;
  String? _bulkText;
  String? _bulkSummary;

  /// Bumped when drafts change from outside the fields (JSON, AI) so the
  /// field widgets rebuild with the new values.
  int _revision = 0;

  CatalogKind get _kind => widget.doc.kind;

  String? get _collectionName => _kind.hasCollections
      ? '${widget.doc.collection(widget.collectionId)?['name'] ?? ''}'
      : null;
  List<WallpaperDraft> get _drafts => [
    for (final f in _files)
      if (f.draft != null) f.draft!,
  ];

  Future<void> _pick() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: _kind.uploadExtensions,
      allowMultiple: true,
    );
    final paths =
        result?.files.map((f) => f.path).whereType<String>() ?? const [];
    await _addFiles(paths);
  }

  Future<void> _addFiles(Iterable<String> paths) async {
    for (final path in paths) {
      if (_files.any((f) => f.path == path)) continue;
      final ext = CatalogRules.extensionOf(path);
      final allowed = _kind.uploadExtensions
          .map(CatalogRules.extensionOf)
          .toSet();
      if (!allowed.contains(ext)) {
        setState(
          () => _files.add(_PickedFile.invalid(path, 'Only ${_typesLabel()}')),
        );
        continue;
      }
      ImageSize? size;
      Uint8List? preview;
      String? problem;
      try {
        size = _kind.isVideo
            ? await VideoEngine.probe(path)
            : await ThumbnailEngine.readSize(path);
        problem = size == null
            ? 'Not a readable ${_kind.isVideo ? 'video' : 'image'}'
            : CatalogRules.resolutionError(_kind, size.width, size.height);
        if (problem == null && _kind.isVideo) {
          preview = await VideoEngine.thumbnail(path);
        }
      } on VideoEngineException catch (e) {
        problem = e.message;
      }
      if (problem != null) {
        setState(() => _files.add(_PickedFile.invalid(path, problem!)));
        continue;
      }
      final draft = WallpaperDraft(
        localPath: path,
        width: size!.width,
        height: size.height,
        name: CatalogRules.nameFromFilename(
          path.split(Platform.pathSeparator).last,
        ),
        author: _defaultAuthor,
        category: _kind == CatalogKind.desktop ? '' : _lastCategory,
        // Every existing collection wallpaper is premium.
        isPremium: _kind.hasCollections,
      );
      _bulk?.applyTo(draft);
      setState(() => _files.add(_PickedFile.valid(draft, preview: preview)));
    }
    if (_bulk != null) setState(_summarizeBulk);
  }

  Future<void> _editBulkDetails() async {
    final result = await showBulkDetailsDialog(
      context,
      initialText:
          _bulkText ??
          (_drafts.isEmpty
              ? bulkDetailsSample
              : BulkDetails.template(_drafts, author: _defaultAuthor)),
    );
    if (result == null || !mounted) return;
    setState(() {
      _bulk = result.details;
      _bulkText = result.text;
      for (final draft in _drafts) {
        result.details.applyTo(draft);
      }
      _revision++;
      _summarizeBulk();
    });
  }

  /// Says which files the JSON matched, and which entries matched nothing.
  void _summarizeBulk() {
    final bulk = _bulk!;
    final matched = _drafts
        .where((d) => bulk.entryFor(d.localPath) != null)
        .length;
    final unmatched = bulk.unmatched(_files.map((f) => f.path));
    _bulkSummary =
        'JSON details: $matched of ${_drafts.length} file(s) matched an entry'
        '${_drafts.length > matched ? ', the rest got only "defaults"' : ''}.'
        '${unmatched.isEmpty ? '' : ' No file for: ${unmatched.join(', ')}'}';
  }

  Future<void> _suggestWithAi(WallpaperDraft draft) async {
    final taskId = const Uuid().v4();
    try {
      await ref
          .read(aiStateProvider.notifier)
          .analyzeImage(taskId, draft.localPath);
      final result = ref.read(aiStateProvider)[taskId]?.result;
      if (result == null || !mounted) return;
      setState(() {
        draft.name = result.name;
        draft.tags = List.of(result.tags);
        // AI colors may be hex codes; only keep named colors like the catalog uses.
        final named = result.colors.where((c) => !c.startsWith('#')).toList();
        if (named.isNotEmpty) draft.colors = named;
        if (result.category != null && _kind == CatalogKind.mobile) {
          draft.category = result.category!;
        }
        _revision++;
      });
    } catch (e) {
      if (mounted) setState(() => _error = 'AI suggestion failed: $e');
    }
  }

  Future<void> _publish() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _publishing = true;
      _error = null;
    });
    try {
      await ref
          .read(catalogProvider(_kind).notifier)
          .publish(
            _drafts,
            collectionId: widget.collectionId,
            onProgress: (status) {
              if (mounted) setState(() => _status = status);
            },
          );
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Published ${_drafts.length} wallpaper(s) to '
            '${_collectionName ?? _kind.jsonFile}. '
            'The app picks it up within ~5 minutes.',
          ),
        ),
      );
    } on NameTakenException catch (e) {
      setState(
        () => _error =
            'These names are already used, rename them:\n'
            '${e.paths.map((p) => p.split('/').last).join('\n')}',
      );
    } on CatalogValidationException catch (e) {
      setState(() => _error = 'Not saved:\n$e');
    } catch (e) {
      setState(() => _error = 'Upload failed: $e');
    } finally {
      if (mounted) setState(() => _publishing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final validCount = _drafts.length;

    return Dialog(
      insetPadding: const EdgeInsets.all(32),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 980, maxHeight: 820),
        child: DropTarget(
          enable: !_publishing,
          onDragEntered: (_) => setState(() => _dragging = true),
          onDragExited: (_) => setState(() => _dragging = false),
          onDragDone: (details) {
            setState(() => _dragging = false);
            _addFiles(details.files.map((f) => f.path));
          },
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 16, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _kind.hasCollections
                                  ? 'Upload to collection "$_collectionName"'
                                  : 'Upload ${_kind.label} wallpapers',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: colors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _kind.isVideo
                                  ? 'MP4, at least ${_kind.minWidth} × ${_kind.minHeight}. '
                                        'The preview clip (720p, 2 Mbps) and thumbnail are made '
                                        'with ffmpeg, like process_videos.py.'
                                  : '${_typesLabel()}, at least ${_kind.minWidth} × ${_kind.minHeight}. '
                                        'Thumbnails (${_kind.thumbWidth} × ${_kind.thumbHeight}) '
                                        'are generated automatically.',
                              style: TextStyle(
                                fontSize: 12,
                                color: colors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Close',
                        onPressed: _publishing
                            ? null
                            : () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                ),
                Divider(color: colors.borderSubtle, height: 1),
                Expanded(
                  child: _files.isEmpty
                      ? _buildDropZone(colors)
                      : _buildFileList(colors),
                ),
                if (_bulkSummary != null && !_publishing)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
                    child: Text(
                      _bulkSummary!,
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ),
                if (_error != null)
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.fromLTRB(24, 8, 24, 0),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colors.error.withAlpha(25),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: SelectableText(
                      _error!,
                      style: TextStyle(color: colors.error, fontSize: 12),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
                  child: Row(
                    children: [
                      OutlinedButton.icon(
                        onPressed: _publishing ? null : _pick,
                        icon: const Icon(Icons.add_photo_alternate_outlined),
                        label: const Text('Add files'),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        onPressed: _publishing ? null : _editBulkDetails,
                        icon: const Icon(Icons.data_object_rounded),
                        label: Text(
                          _bulk == null ? 'Fill from JSON' : 'Edit JSON',
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          _publishing ? (_status ?? 'Starting…') : _summary(),
                          style: TextStyle(
                            fontSize: 12,
                            color: colors.textSecondary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (_publishing)
                        const Padding(
                          padding: EdgeInsets.only(right: 12),
                          child: SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      FilledButton.icon(
                        onPressed: _publishing || validCount == 0
                            ? null
                            : _publish,
                        icon: const Icon(Icons.cloud_upload_outlined),
                        label: Text(
                          validCount == 0 ? 'Publish' : 'Publish $validCount',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _typesLabel() => _kind.isVideo ? 'MP4' : 'JPG or PNG';

  String _summary() {
    final invalid = _files.length - _drafts.length;
    if (_files.isEmpty) return 'Drop files here or click Add files';
    return '${_drafts.length} ready'
        '${invalid > 0 ? ' · $invalid refused (remove them or replace with higher resolution)' : ''}';
  }

  Widget _buildDropZone(AppColorScheme colors) {
    return Container(
      margin: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _dragging ? colors.primarySelection : colors.bgSubtle,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _dragging ? colors.primary : colors.border),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_upload_outlined,
              size: 48,
              color: colors.textDisabled,
            ),
            const SizedBox(height: 12),
            Text(
              'Drop wallpapers here',
              style: TextStyle(color: colors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFileList(AppColorScheme colors) {
    return ListView.separated(
      padding: const EdgeInsets.all(24),
      itemCount: _files.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final file = _files[index];
        final draft = file.draft;
        final previewWidth = _kind == CatalogKind.desktop ? 240.0 : 120.0;
        // A Material (not a colored Container) so the Premium switch's ink shows.
        return Material(
          key: ValueKey(file.key),
          color: colors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: draft == null ? colors.error : colors.borderSubtle,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox(
                    width: previewWidth,
                    child: AspectRatio(
                      aspectRatio: _kind.thumbWidth / _kind.thumbHeight,
                      child: file.preview != null
                          ? Image.memory(file.preview!, fit: BoxFit.cover)
                          : _kind.isVideo
                          ? ColoredBox(
                              color: colors.bgSubtle,
                              child: Icon(
                                Icons.movie_outlined,
                                color: colors.textDisabled,
                              ),
                            )
                          : Image.file(
                              File(file.path),
                              fit: BoxFit.cover,
                              cacheWidth: 480,
                            ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              file.path.split(Platform.pathSeparator).last,
                              style: TextStyle(
                                fontSize: 12,
                                color: colors.textSecondary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (draft != null) ...[
                            _Chip(
                              label: '${draft.width} × ${draft.height}',
                              color: colors.success,
                            ),
                            if (!_kind.isVideo)
                              IconButton(
                                tooltip:
                                    'Suggest name, tags and colors with AI',
                                icon: const Icon(
                                  Icons.auto_awesome_outlined,
                                  size: 18,
                                ),
                                onPressed: _publishing
                                    ? null
                                    : () => _suggestWithAi(draft),
                              ),
                          ],
                          IconButton(
                            tooltip: 'Remove',
                            icon: const Icon(Icons.delete_outline, size: 18),
                            onPressed: _publishing
                                ? null
                                : () => setState(() {
                                    _files.removeAt(index);
                                    if (_bulk != null) _summarizeBulk();
                                  }),
                          ),
                        ],
                      ),
                      if (draft == null)
                        Text(file.error!, style: TextStyle(color: colors.error))
                      else
                        WallpaperFields(
                          key: ValueKey('${file.key}-$_revision'),
                          draft: draft,
                          suggestions: _suggestions,
                          onChanged: () {
                            if (draft.category.trim().isNotEmpty) {
                              _lastCategory = draft.category;
                            }
                          },
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
