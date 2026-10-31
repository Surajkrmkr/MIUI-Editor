import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:miui_icon_generator/core/theme/theme_extensions.dart';

import '../../application/providers/catalog_provider.dart';
import '../../domain/models/catalog.dart';
import 'storage_image.dart';
import 'wallpaper_fields.dart';

/// [collectionId] is the entry's collection, for [CatalogKind.collections].
Future<void> showEntryEditDialog(
  BuildContext context,
  CatalogDocument doc,
  Map<String, dynamic> entry, {
  String? collectionId,
}) =>
    showDialog(
      context: context,
      builder: (_) => EntryEditDialog(doc: doc, entry: entry, collectionId: collectionId),
    );

/// Edits an entry's metadata. The image files stay where they are, since the
/// app caches them by URL; changing the picture means uploading a new entry.
class EntryEditDialog extends ConsumerStatefulWidget {
  const EntryEditDialog({
    super.key,
    required this.doc,
    required this.entry,
    this.collectionId,
  });

  final CatalogDocument doc;
  final Map<String, dynamic> entry;
  final String? collectionId;

  @override
  ConsumerState<EntryEditDialog> createState() => _EntryEditDialogState();
}

class _EntryEditDialogState extends ConsumerState<EntryEditDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _suggestions = CatalogSuggestions.fromWalls(widget.doc.allWalls);
  late final WallpaperDraft _draft = WallpaperDraft(
    localPath: '',
    width: 0,
    height: 0,
    name: '${widget.entry['name'] ?? ''}',
    author: '${widget.entry['author'] ?? ''}',
    category: '${widget.entry['category'] ?? ''}',
    tags: [for (final t in widget.entry['tags'] as List? ?? const []) '$t'],
    colors: [for (final c in widget.entry['color'] as List? ?? const []) '$c'],
    isPremium: widget.entry['isPremium'] == true,
  );
  bool _busy = false;
  String? _error;

  CatalogKind get _kind => widget.doc.kind;

  Future<void> _run(Future<void> Function() action, String done) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action();
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(done)));
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final updated = {
      ...widget.entry,
      'name': _draft.name.trim(),
      'author': _draft.author.trim(),
      'category': _draft.category.trim(),
      'tags': _draft.tags,
      'color': _draft.colors,
      'isPremium': _draft.isPremium,
    };
    await _run(
      () => ref
          .read(catalogProvider(_kind).notifier)
          .updateEntry(updated, collectionId: widget.collectionId),
      'Saved "${updated['name']}"',
    );
  }

  Future<void> _delete() async {
    var deleteFiles = false;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Delete wallpaper'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Remove "${widget.entry['name']}" from ${_kind.jsonFile}?'),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: deleteFiles,
                onChanged: (v) => setDialogState(() => deleteFiles = v ?? false),
                title: Text(_kind.isVideo
                    ? 'Also delete its video, preview and thumbnail'
                    : 'Also delete its image and thumbnail'),
                subtitle: const Text('Skipped if another catalog still uses them. '
                    'Restoring a backup later would then show a broken image.'),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: context.appColors.error),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete'),
            ),
          ],
        ),
      ),
    );
    if (confirmed != true) return;
    await _run(
      () => ref
          .read(catalogProvider(_kind).notifier)
          .deleteEntry(
            widget.entry,
            collectionId: widget.collectionId,
            deleteFiles: deleteFiles,
          ),
      'Deleted "${widget.entry['name']}"',
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final ratio = _kind.thumbWidth / _kind.thumbHeight;
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 820, maxHeight: 760),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Edit wallpaper #${widget.entry['id']}',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: colors.textPrimary)),
                const SizedBox(height: 16),
                Flexible(
                  child: SingleChildScrollView(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: SizedBox(
                            width: _kind == CatalogKind.desktop ? 260 : 150,
                            child: AspectRatio(
                              aspectRatio: ratio,
                              child: StorageImage('${widget.entry['thumbnail'] ?? ''}'),
                            ),
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: WallpaperFields(
                            draft: _draft,
                            suggestions: _suggestions,
                            onChanged: () {},
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  SelectableText(_error!, style: TextStyle(color: colors.error, fontSize: 12)),
                ],
                const SizedBox(height: 16),
                Row(
                  children: [
                    TextButton.icon(
                      onPressed: _busy ? null : _delete,
                      icon: Icon(Icons.delete_outline, color: colors.error),
                      label: Text('Delete', style: TextStyle(color: colors.error)),
                    ),
                    const Spacer(),
                    if (_busy)
                      const Padding(
                        padding: EdgeInsets.only(right: 12),
                        child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
                      ),
                    TextButton(
                      onPressed: _busy ? null : () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(onPressed: _busy ? null : _save, child: const Text('Save')),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
