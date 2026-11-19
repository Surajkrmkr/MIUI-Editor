import 'dart:io';

import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:miui_icon_generator/core/theme/theme_extensions.dart';
import 'package:uuid/uuid.dart';

import '../../../wall_rio/application/providers/ai_provider.dart';
import '../../../wall_rio/domain/bulk_details.dart';
import '../../../wall_rio/domain/catalog_rules.dart';
import '../../../wall_rio/domain/models/catalog.dart';
import '../../../wall_rio/infrastructure/services/thumbnail_engine.dart';
import '../../../wall_rio/presentation/widgets/bulk_details_dialog.dart';
import '../../../wall_rio/presentation/widgets/wallpaper_fields.dart';
import '../../application/providers/buffy_cms_provider.dart';
import '../../application/services/buffy_wallpaper_import_service.dart';
import '../../domain/buffy_storage_layout.dart';
import '../../shared/utils/constants.dart';

const _extensions = ['jpg', 'jpeg', 'png'];
const _defaultDesigner = 'Buffy';

/// Upload several wallpapers at once, like Wall Rio's upload dialog: drop or
/// pick files, fill each one in (or all of them from JSON), then add them.
/// They join the catalog as unpublished edits; Publish sends them live.
Future<void> showBuffyUploadDialog(BuildContext context) => showDialog(
  context: context,
  barrierDismissible: false,
  builder: (_) => const BuffyUploadDialog(),
);

/// A picked file: either a draft ready to fill in, or the reason it's refused.
class _PickedFile {
  _PickedFile.valid(this.draft) : error = null, _path = null;
  _PickedFile.invalid(String path, this.error) : draft = null, _path = path;

  final WallpaperDraft? draft;
  final String? error;
  final String? _path;

  String get path => draft?.localPath ?? _path!;
  final String key = const Uuid().v4();
}

/// Where a draft's image will live in the bucket.
String _imageObject(WallpaperDraft d) {
  final ext = d.localPath.substring(d.localPath.lastIndexOf('.')).toLowerCase();
  return buffyImageObject(d.category.trim(), '${d.name.trim()}$ext');
}

class BuffyUploadDialog extends ConsumerStatefulWidget {
  const BuffyUploadDialog({super.key});

  @override
  ConsumerState<BuffyUploadDialog> createState() => _BuffyUploadDialogState();
}

class _BuffyUploadDialogState extends ConsumerState<BuffyUploadDialog> {
  final _formKey = GlobalKey<FormState>();
  final List<_PickedFile> _files = [];
  late final CatalogSuggestions _suggestions = _buildSuggestions();

  String _lastCategory = '';
  bool _dragging = false;
  bool _uploading = false;
  String? _status;
  String? _error;

  /// Details from the JSON editor; also applied to files dropped afterwards.
  BulkDetails? _bulk;
  String? _bulkText;
  String? _bulkSummary;

  /// Bumped when drafts change from outside the fields (JSON, AI) so the
  /// field widgets rebuild with the new values.
  int _revision = 0;

  List<WallpaperDraft> get _drafts => [
    for (final f in _files)
      if (f.draft != null) f.draft!,
  ];

  CatalogSuggestions _buildSuggestions() {
    final walls = ref.read(buffyCmsProvider).wallpapers;
    return CatalogSuggestions.fromWalls([
      for (final c in kBuffyCategories) {'category': c},
      for (final w in walls)
        {'category': w.category, 'tags': w.tags, 'color': w.colors},
    ]);
  }

  Future<void> _pick() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: _extensions,
      allowMultiple: true,
    );
    await _addFiles(
      result?.files.map((f) => f.path).whereType<String>() ?? const [],
    );
  }

  Future<void> _addFiles(Iterable<String> paths) async {
    for (final path in paths) {
      if (_files.any((f) => f.path == path)) continue;
      final ext = CatalogRules.extensionOf(path);
      if (!_extensions.contains(ext)) {
        setState(() => _files.add(_PickedFile.invalid(path, 'Only JPG or PNG')));
        continue;
      }
      final size = await ThumbnailEngine.readSize(path);
      if (size == null) {
        setState(
          () => _files.add(_PickedFile.invalid(path, 'Not a readable image')),
        );
        continue;
      }
      final draft = WallpaperDraft(
        localPath: path,
        width: size.width,
        height: size.height,
        name: CatalogRules.nameFromFilename(
          path.split(Platform.pathSeparator).last,
        ),
        author: _defaultDesigner,
        category: _lastCategory,
      );
      _bulk?.applyTo(draft);
      setState(() => _files.add(_PickedFile.valid(draft)));
    }
    if (_bulk != null) setState(_summarizeBulk);
  }

  Future<void> _editBulkDetails() async {
    final result = await showBulkDetailsDialog(
      context,
      initialText:
          _bulkText ??
          (_drafts.isEmpty
              ? bulkDetailsSample.replaceAll('"WallRio"', '"$_defaultDesigner"')
              : BulkDetails.template(_drafts, author: _defaultDesigner)),
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
        _revision++;
      });
    } catch (e) {
      if (mounted) setState(() => _error = 'AI suggestion failed: $e');
    }
  }

  /// Problems to fix before anything uploads.
  List<String> _problems() {
    final problems = <String>[];
    final existing = {
      for (final w in ref.read(buffyCmsProvider).wallpapers) w.imageUrl,
    };
    final seen = <String>{};
    for (final d in _drafts) {
      final name = d.name.trim();
      if (name.contains(RegExp(r'[/\\]')) ||
          d.category.trim().contains(RegExp(r'[/\\]'))) {
        problems.add('"$name": name and category can\'t contain / or \\');
        continue;
      }
      final object = _imageObject(d);
      if (!seen.add(object.toLowerCase())) {
        problems.add('"$name" is used twice in ${d.category.trim()}');
      } else if (existing.contains(buffyDownloadUrl(object))) {
        problems.add(
          '"$name" already exists in ${d.category.trim()}; rename it',
        );
      }
    }
    return problems;
  }

  Future<void> _upload() async {
    if (!_formKey.currentState!.validate()) return;
    final problems = _problems();
    if (problems.isNotEmpty) {
      setState(() => _error = 'Fix these first:\n${problems.join('\n')}');
      return;
    }
    setState(() {
      _uploading = true;
      _error = null;
    });
    final drafts = _drafts;
    final service = ref.read(buffyWallpaperImportServiceProvider.notifier);
    var done = 0;
    try {
      for (final d in drafts) {
        setState(
          () => _status =
              'Uploading ${done + 1}/${drafts.length} "${d.name.trim()}"',
        );
        await service.importWallpaper(
          file: File(d.localPath),
          category: d.category.trim(),
          name: d.name.trim(),
          designer: d.author.trim(),
          tags: d.tags,
          colors: d.colors,
          isPremium: d.isPremium,
        );
        done++;
      }
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Added ${drafts.length} wallpaper(s). Click Publish to send them live.',
          ),
        ),
      );
    } catch (e) {
      // Uploaded ones are already in the catalog; keep only the rest here.
      final added = drafts.take(done).toSet();
      setState(() {
        _files.removeWhere((f) => added.contains(f.draft));
        _error =
            '${done == 0 ? '' : 'Added $done; '}upload stopped: $e\n'
            'Fix it and click Add again to upload the rest.';
      });
    } finally {
      if (mounted) setState(() => _uploading = false);
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
          enable: !_uploading,
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
                              'Add Buffy wallpapers',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: colors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'JPG or PNG. Thumbnails are generated automatically. '
                              'Added wallpapers go live when you Publish.',
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
                        onPressed: _uploading
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
                if (_bulkSummary != null && !_uploading)
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
                        onPressed: _uploading ? null : _pick,
                        icon: const Icon(Icons.add_photo_alternate_outlined),
                        label: const Text('Add files'),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        onPressed: _uploading ? null : _editBulkDetails,
                        icon: const Icon(Icons.data_object_rounded),
                        label: Text(
                          _bulk == null ? 'Fill from JSON' : 'Edit JSON',
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          _uploading ? (_status ?? 'Starting…') : _summary(),
                          style: TextStyle(
                            fontSize: 12,
                            color: colors.textSecondary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (_uploading)
                        const Padding(
                          padding: EdgeInsets.only(right: 12),
                          child: SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      FilledButton.icon(
                        onPressed: _uploading || validCount == 0
                            ? null
                            : _upload,
                        icon: const Icon(Icons.cloud_upload_outlined),
                        label: Text(validCount == 0 ? 'Add' : 'Add $validCount'),
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

  String _summary() {
    final invalid = _files.length - _drafts.length;
    if (_files.isEmpty) return 'Drop files here or click Add files';
    return '${_drafts.length} ready'
        '${invalid > 0 ? ' · $invalid refused (remove them)' : ''}';
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
                    width: 120,
                    child: AspectRatio(
                      aspectRatio: 9 / 19.5,
                      child: Image.file(
                        File(file.path),
                        fit: BoxFit.cover,
                        cacheWidth: 480,
                        errorBuilder: (_, __, ___) => ColoredBox(
                          color: colors.bgSubtle,
                          child: Icon(
                            Icons.broken_image_outlined,
                            color: colors.textDisabled,
                          ),
                        ),
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
                            IconButton(
                              tooltip: 'Suggest name, tags and colors with AI',
                              icon: const Icon(
                                Icons.auto_awesome_outlined,
                                size: 18,
                              ),
                              onPressed: _uploading
                                  ? null
                                  : () => _suggestWithAi(draft),
                            ),
                          ],
                          IconButton(
                            tooltip: 'Remove',
                            icon: const Icon(Icons.delete_outline, size: 18),
                            onPressed: _uploading
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
                          authorLabel: 'Designer',
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
