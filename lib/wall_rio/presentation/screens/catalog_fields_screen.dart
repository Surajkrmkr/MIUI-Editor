import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:miui_icon_generator/core/theme/theme_extensions.dart';
import 'package:miui_icon_generator/widgets/app_icon_button.dart';

import '../../application/providers/catalog_provider.dart';
import '../../application/services/catalog_service.dart';
import '../../domain/models/catalog.dart';
import '../widgets/json_value_editor.dart';

/// Edits the root fields of a catalog JSON other than its wallpaper list:
/// banners, subscription, search, pop-up and any others.
class CatalogFieldsScreen extends ConsumerStatefulWidget {
  const CatalogFieldsScreen({super.key});

  @override
  ConsumerState<CatalogFieldsScreen> createState() => _CatalogFieldsScreenState();
}

class _CatalogFieldsScreenState extends ConsumerState<CatalogFieldsScreen> {
  String? _selected;

  /// Fields added here but not saved yet.
  final Map<String, Object?> _added = {};

  Future<void> _addField(CatalogDocument doc, Set<String> taken) async {
    final added = await showAddKeyDialog(
      context,
      taken: {...taken, doc.kind.listKey},
      title: 'Add field to ${doc.kind.jsonFile}',
    );
    if (added == null) return;
    setState(() {
      _added[added.$1] = added.$2;
      _selected = added.$1;
    });
  }

  @override
  Widget build(BuildContext context) {
    final kind = ref.watch(selectedKindProvider);
    final catalog = ref.watch(catalogProvider(kind));
    final colors = context.appColors;

    return Scaffold(
      appBar: AppBar(
        leading: AppBackButton(onPressed: () => context.go('/')),
        title: Text('JSON fields · ${kind.jsonFile}'),
        actions: [
          SegmentedButton<CatalogKind>(
            showSelectedIcon: false,
            segments: [
              for (final k in CatalogKind.values) ButtonSegment(value: k, label: Text(k.label)),
            ],
            selected: {kind},
            onSelectionChanged: (s) {
              setState(() {
                _selected = null;
                _added.clear();
              });
              ref.read(selectedKindProvider.notifier).select(s.first);
            },
          ),
          IconButton(
            tooltip: 'Reload ${kind.jsonFile}',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.read(catalogProvider(kind).notifier).reload(),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: catalog.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: SelectableText('$err', style: TextStyle(color: colors.error))),
        data: (doc) => _buildBody(context, doc),
      ),
    );
  }

  Widget _buildBody(BuildContext context, CatalogDocument doc) {
    final colors = context.appColors;
    final fields = {
      ...doc.extraFields,
      for (final e in _added.entries)
        if (!doc.root.containsKey(e.key)) e.key: e.value,
    };
    final selected = fields.containsKey(_selected)
        ? _selected
        : fields.containsKey('banners')
            ? 'banners'
            : fields.keys.firstOrNull;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          width: 280,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  children: [
                    for (final MapEntry(:key, :value) in fields.entries)
                      ListTile(
                        dense: true,
                        selected: key == selected,
                        leading: Icon(jsonTypeIcon(value), size: 18),
                        title: Text(key, style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text(
                          doc.root.containsKey(key) ? jsonTypeLabel(value) : 'New · not saved',
                          style: TextStyle(fontSize: 11, color: colors.textSecondary),
                        ),
                        onTap: () => setState(() => _selected = key),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: OutlinedButton.icon(
                  onPressed: () => _addField(doc, fields.keys.toSet()),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add field'),
                ),
              ),
            ],
          ),
        ),
        VerticalDivider(width: 1, color: colors.borderSubtle),
        Expanded(
          child: selected == null
              ? Center(
                  child: Text('${doc.kind.jsonFile} has no fields besides "${doc.kind.listKey}"',
                      style: TextStyle(color: colors.textSecondary)),
                )
              : _FieldEditor(
                  key: ValueKey('${doc.kind.name}/$selected/${doc.generation}'),
                  kind: doc.kind,
                  field: selected,
                  value: fields[selected],
                  isNew: !doc.root.containsKey(selected),
                  onDone: () => setState(() => _added.remove(selected)),
                ),
        ),
      ],
    );
  }
}

/// Edits one root field on a copy and saves just that field.
class _FieldEditor extends ConsumerStatefulWidget {
  const _FieldEditor({
    super.key,
    required this.kind,
    required this.field,
    required this.value,
    required this.isNew,
    required this.onDone,
  });

  final CatalogKind kind;
  final String field;
  final Object? value;
  final bool isNew;

  /// Called after the field is saved or removed.
  final VoidCallback onDone;

  @override
  ConsumerState<_FieldEditor> createState() => _FieldEditorState();
}

class _FieldEditorState extends ConsumerState<_FieldEditor> {
  /// Holds the value under its field name so every type goes through one editor.
  late Map<String, dynamic> _holder = {widget.field: jsonCopy(widget.value)};
  late bool _dirty = widget.isNew;
  bool _raw = false;
  bool _busy = false;
  String? _rawError;
  int _revision = 0;
  final _rawController = TextEditingController();

  Object? get _value => _holder[widget.field];

  @override
  void dispose() {
    _rawController.dispose();
    super.dispose();
  }

  void _changed() => setState(() => _dirty = true);

  bool _applyRaw() {
    try {
      _holder = {widget.field: jsonDecode(_rawController.text)};
      setState(() => _rawError = null);
      return true;
    } on FormatException catch (e) {
      setState(() => _rawError = 'Invalid JSON: ${e.message}');
      return false;
    }
  }

  void _toggleRaw() {
    if (!_raw) {
      _rawController.text = prettyJson.convert(_value);
      setState(() => _raw = true);
    } else if (_applyRaw()) {
      setState(() {
        _raw = false;
        _revision++;
      });
    }
  }

  void _discard() => setState(() {
        _holder = {widget.field: jsonCopy(widget.value)};
        _dirty = widget.isNew;
        _raw = false;
        _rawError = null;
        _revision++;
      });

  Future<void> _run(Future<void> Function() action, String done) async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);
    try {
      await action();
      messenger.showSnackBar(SnackBar(content: Text(done)));
      widget.onDone();
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Failed: $e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _save() async {
    if (_raw && !_applyRaw()) return;
    await _run(
      () => ref.read(catalogProvider(widget.kind).notifier).updateFields({widget.field: _value}),
      'Saved "${widget.field}" to ${widget.kind.jsonFile}. The app shows it within ~5 minutes.',
    );
  }

  Future<void> _delete() async {
    if (widget.isNew) {
      widget.onDone();
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Remove "${widget.field}"?'),
        content: Text('It is removed from ${widget.kind.jsonFile}. '
            'The current version is backed up first, so this can be undone from History.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: context.appColors.error),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await _run(
      () => ref
          .read(catalogProvider(widget.kind).notifier)
          .updateFields(const {}, removed: {widget.field}),
      'Removed "${widget.field}" from ${widget.kind.jsonFile}',
    );
  }

  Widget _editor() {
    final colors = context.appColors;
    if (_raw) {
      return TextField(
        controller: _rawController,
        maxLines: null,
        style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
        decoration: InputDecoration(
          errorText: _rawError,
          border: const OutlineInputBorder(),
        ),
        onChanged: (_) => _changed(),
      );
    }
    final value = _value;
    if (isObjectList(value)) {
      return JsonObjectListEditor(
        items: value as List,
        onChanged: _changed,
        uploadFolder: CatalogService.bannersFolder,
      );
    }
    if (value is Map<String, dynamic>) {
      return JsonObjectEditor(
        map: value,
        onChanged: _changed,
        uploadFolder: CatalogService.bannersFolder,
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Edit the value below.', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
        JsonObjectEditor(
          map: _holder,
          onChanged: _changed,
          uploadFolder: CatalogService.bannersFolder,
          fixedKeys: true,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 16, 12),
          child: Row(
            children: [
              Text(widget.field,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: colors.textPrimary)),
              const SizedBox(width: 12),
              Text(jsonTypeLabel(_value), style: TextStyle(color: colors.textSecondary, fontSize: 12)),
              if (_dirty) ...[
                const SizedBox(width: 12),
                Text('Unsaved changes', style: TextStyle(color: colors.warning, fontSize: 12)),
              ],
              const Spacer(),
              TextButton.icon(
                onPressed: _busy ? null : _toggleRaw,
                icon: Icon(_raw ? Icons.view_agenda_outlined : Icons.code_rounded, size: 18),
                label: Text(_raw ? 'Form' : 'Raw JSON'),
              ),
              TextButton(
                onPressed: _busy || !_dirty || widget.isNew ? null : _discard,
                child: const Text('Discard'),
              ),
              TextButton.icon(
                onPressed: _busy ? null : _delete,
                icon: Icon(Icons.delete_outline, size: 18, color: colors.error),
                label: Text('Remove field', style: TextStyle(color: colors.error)),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: _busy || !_dirty ? null : _save,
                icon: _busy
                    ? const SizedBox.square(dimension: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.cloud_upload_outlined, size: 18),
                label: const Text('Save'),
              ),
            ],
          ),
        ),
        Divider(height: 1, color: colors.borderSubtle),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: KeyedSubtree(key: ValueKey(_revision), child: _editor()),
          ),
        ),
      ],
    );
  }
}
