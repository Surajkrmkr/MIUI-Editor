import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:miui_icon_generator/core/theme/theme_extensions.dart';

import '../../application/providers/buffy_cms_provider.dart';
import '../../application/providers/buffy_storage_provider.dart';
import '../../domain/buffy_catalog_json.dart';
import '../../domain/buffy_storage_layout.dart';

typedef _Upload = Future<String?> Function();

/// Editors for every root field of buffy.json except the wallpaper list.
class BuffyCatalogFieldsView extends ConsumerWidget {
  const BuffyCatalogFieldsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.appColors;
    final state = ref.watch(buffyCmsProvider);
    final notifier = ref.read(buffyCmsProvider.notifier);
    final categories = state.wallpapers.map((w) => w.category).toSet().toList()..sort();
    final wallNames = {for (final w in state.wallpapers) w.id: w.name};

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 96),
      children: [
        Row(
          children: [
            Text(
              'Catalog fields',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: colors.textPrimary),
            ),
            const SizedBox(width: 12),
            Text(
              '${state.fields.length} fields in buffy.json',
              style: TextStyle(color: colors.textSecondary),
            ),
            const Spacer(),
            OutlinedButton.icon(
              onPressed: () async {
                final added = await _showJsonDialog(context, existingKeys: state.fields.keys.toSet());
                if (added != null) notifier.setField(added.key, added.value);
              },
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Add field'),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Edits stay local until you publish.',
          style: TextStyle(fontSize: 12, color: colors.textSecondary),
        ),
        const SizedBox(height: 16),
        for (final e in state.fields.entries)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _FieldCard(
              key: ValueKey(e.key),
              fieldKey: e.key,
              value: e.value,
              categories: categories,
              wallNames: wallNames,
              onChanged: (v) => notifier.setField(e.key, v),
              onRemove: () => notifier.removeField(e.key),
              onUpload: () => _pickAndUpload(context, ref),
            ),
          ),
      ],
    );
  }

  Future<String?> _pickAndUpload(BuildContext context, WidgetRef ref) async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    final path = result?.files.single.path;
    if (path == null || !context.mounted) return null;
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(const SnackBar(content: Text('Uploading image…')));
    try {
      final publisher = await ref.read(buffyCatalogPublisherProvider.future);
      final file = File(path);
      final url = await publisher.uploadImage(
        kBuffyBannersFolder,
        file.uri.pathSegments.last,
        await file.readAsBytes(),
      );
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('Uploaded. Publish to make it live.')));
      return url;
    } catch (e) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text('Upload failed: $e')));
      return null;
    }
  }
}

bool _isUrl(Object? v) => v is String && (v.startsWith('https://') || v.startsWith('http://'));

const _imageKeys = {'url', 'image', 'imageUrl', 'banner', 'thumbnail', 'compressUrl'};

class _FieldCard extends StatelessWidget {
  const _FieldCard({
    super.key,
    required this.fieldKey,
    required this.value,
    required this.categories,
    required this.wallNames,
    required this.onChanged,
    required this.onRemove,
    required this.onUpload,
  });

  final String fieldKey;
  final Object? value;
  final List<String> categories;
  final Map<int, String> wallNames;
  final ValueChanged<Object?> onChanged;
  final VoidCallback onRemove;
  final _Upload onUpload;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final value = this.value;
    final (icon, type) = switch (value) {
      Map() => (Icons.data_object_rounded, 'object · ${value.length} keys'),
      List() => (Icons.list_rounded, 'list · ${value.length} items'),
      String() => (Icons.text_fields_rounded, 'text'),
      num() => (Icons.numbers_rounded, 'number'),
      bool() => (Icons.toggle_on_outlined, 'switch'),
      _ => (Icons.help_outline_rounded, 'null'),
    };

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.borderSubtle),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 12, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: colors.primary),
              const SizedBox(width: 10),
              Text(
                fieldKey,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'monospace',
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(width: 10),
              Text(type, style: TextStyle(fontSize: 12, color: colors.textSecondary)),
              const Spacer(),
              IconButton(
                tooltip: 'Edit JSON',
                icon: const Icon(Icons.code_rounded, size: 18),
                onPressed: () async {
                  final edited = await _showJsonDialog(context, key: fieldKey, value: value);
                  if (edited != null) onChanged(edited.value);
                },
              ),
              IconButton(
                tooltip: 'Remove field',
                icon: Icon(Icons.delete_outline_rounded, size: 18, color: colors.error),
                onPressed: () async {
                  final ok = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: Text('Remove "$fieldKey"?'),
                      content: const Text('The app may rely on it. You can reload to undo before publishing.'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                        FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Remove')),
                      ],
                    ),
                  );
                  if (ok == true) onRemove();
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          _editor(context, value),
        ],
      ),
    );
  }

  Widget _editor(BuildContext context, Object? value) {
    if (value is Map && value.values.every((v) => v is String)) {
      return _StringMapEditor(
        map: value.cast<String, String>(),
        onChanged: onChanged,
        onUpload: onUpload,
      );
    }
    if (value is List && value.isNotEmpty && value.every((e) => e is Map)) {
      return _MapListEditor(
        items: value.cast<Map>().map((m) => m.cast<String, dynamic>()).toList(),
        categories: categories,
        onChanged: onChanged,
        onUpload: onUpload,
      );
    }
    if (value is List && value.every((e) => e is String || e is num)) {
      return _ChipListEditor(items: value, wallNames: wallNames, onChanged: onChanged);
    }
    if (value is String || value is num || value is bool) {
      return _ScalarField(value: value, onChanged: onChanged);
    }
    return _JsonPreview(value: value);
  }
}

/// `{"free": "https://…", "paid": "https://…"}`: one image tile per key.
class _StringMapEditor extends StatelessWidget {
  const _StringMapEditor({required this.map, required this.onChanged, required this.onUpload});

  final Map<String, String> map;
  final ValueChanged<Object?> onChanged;
  final _Upload onUpload;

  void _set(String key, String value) => onChanged({...map, key: value});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      crossAxisAlignment: WrapCrossAlignment.end,
      children: [
        for (final e in map.entries)
          SizedBox(
            width: 320,
            child: _ImageSlot(
              title: e.key,
              url: e.value,
              onChanged: (v) => _set(e.key, v),
              onUpload: () async {
                final url = await onUpload();
                if (url != null) _set(e.key, url);
              },
              onRemove: () => onChanged({...map}..remove(e.key)),
            ),
          ),
        OutlinedButton.icon(
          onPressed: () async {
            final key = await _promptText(context, 'New key');
            if (key != null && key.isNotEmpty && !map.containsKey(key)) _set(key, '');
          },
          icon: const Icon(Icons.add_rounded, size: 18),
          label: const Text('Add entry'),
        ),
      ],
    );
  }
}

/// A list of objects such as `adBanners`: one card per item.
class _MapListEditor extends StatelessWidget {
  const _MapListEditor({
    required this.items,
    required this.categories,
    required this.onChanged,
    required this.onUpload,
  });

  final List<Map<String, dynamic>> items;
  final List<String> categories;
  final ValueChanged<Object?> onChanged;
  final _Upload onUpload;

  void _replace(int index, Map<String, dynamic> item) =>
      onChanged([...items]..[index] = item);

  void _move(int from, int to) {
    final list = [...items];
    list.insert(to, list.removeAt(from));
    onChanged(list);
  }

  /// A blank item shaped like the first one, with the next free `id`.
  Map<String, dynamic> _blank() {
    final ids = items.map((i) => i['id']).whereType<int>();
    return {
      for (final e in items.first.entries)
        e.key: switch (e.value) {
          int() when e.key == 'id' => ids.isEmpty ? 1 : ids.reduce((a, b) => a > b ? a : b) + 1,
          String() => '',
          bool() => false,
          num() => 0,
          List() => [],
          Map() => {},
          _ => null,
        },
    };
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      crossAxisAlignment: WrapCrossAlignment.end,
      children: [
        for (var i = 0; i < items.length; i++)
          SizedBox(
            width: 320,
            child: _MapItemCard(
              index: i,
              count: items.length,
              item: items[i],
              categories: categories,
              onChanged: (item) => _replace(i, item),
              onUpload: onUpload,
              onMove: (to) => _move(i, to),
              onRemove: () => onChanged([...items]..removeAt(i)),
            ),
          ),
        OutlinedButton.icon(
          onPressed: () => onChanged([...items, _blank()]),
          icon: const Icon(Icons.add_rounded, size: 18),
          label: const Text('Add item'),
        ),
      ],
    );
  }
}

class _MapItemCard extends StatelessWidget {
  const _MapItemCard({
    required this.index,
    required this.count,
    required this.item,
    required this.categories,
    required this.onChanged,
    required this.onUpload,
    required this.onMove,
    required this.onRemove,
  });

  final int index;
  final int count;
  final Map<String, dynamic> item;
  final List<String> categories;
  final ValueChanged<Map<String, dynamic>> onChanged;
  final _Upload onUpload;
  final ValueChanged<int> onMove;
  final VoidCallback onRemove;

  void _set(String key, Object? value) => onChanged({...item, key: value});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final imageKey = item.keys.where(_imageKeys.contains).firstOrNull;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.bgSubtle,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(
                '#${index + 1}${item['id'] == null ? '' : '  ·  id ${item['id']}'}',
                style: TextStyle(fontWeight: FontWeight.w700, color: colors.textPrimary),
              ),
              const Spacer(),
              _SmallIcon(Icons.arrow_back_rounded, 'Move earlier', index == 0 ? null : () => onMove(index - 1)),
              _SmallIcon(Icons.arrow_forward_rounded, 'Move later', index == count - 1 ? null : () => onMove(index + 1)),
              _SmallIcon(Icons.close_rounded, 'Remove item', onRemove, color: colors.error),
            ],
          ),
          const SizedBox(height: 8),
          if (imageKey != null) ...[
            _ImageSlot(
              title: imageKey,
              url: '${item[imageKey] ?? ''}',
              onChanged: (v) => _set(imageKey, v),
              onUpload: () async {
                final url = await onUpload();
                if (url != null) _set(imageKey, url);
              },
            ),
            const SizedBox(height: 8),
          ],
          for (final e in item.entries)
            if (e.key != imageKey)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: e.key == 'category' && e.value is String
                    ? _CategoryField(
                        key: ValueKey('category-$index-${e.value}'),
                        value: e.value as String,
                        categories: categories,
                        onChanged: (v) => _set(e.key, v),
                      )
                    : e.value is String || e.value is num || e.value is bool
                        ? _ScalarField(
                            label: e.key,
                            value: e.value,
                            onChanged: (v) => _set(e.key, v),
                          )
                        : Text(
                            '${e.key}: ${jsonEncode(e.value)}',
                            style: TextStyle(fontSize: 12, color: colors.textSecondary),
                          ),
              ),
        ],
      ),
    );
  }
}

class _CategoryField extends StatelessWidget {
  const _CategoryField({super.key, required this.value, required this.categories, required this.onChanged});

  final String value;
  final List<String> categories;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final options = {'', ...categories, value}.toList();
    return DropdownButtonFormField<String>(
      initialValue: value,
      isExpanded: true,
      isDense: true,
      decoration: const InputDecoration(labelText: 'category', isDense: true),
      items: [
        for (final c in options)
          DropdownMenuItem(
            value: c,
            child: Text(c.isEmpty ? 'None' : c, overflow: TextOverflow.ellipsis),
          ),
      ],
      onChanged: (v) => onChanged(v ?? ''),
    );
  }
}

/// Image preview, URL field and upload button.
class _ImageSlot extends StatelessWidget {
  const _ImageSlot({
    required this.title,
    required this.url,
    required this.onChanged,
    required this.onUpload,
    this.onRemove,
  });

  final String title;
  final String url;
  final ValueChanged<String> onChanged;
  final VoidCallback onUpload;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Container(
            height: 140,
            color: colors.bg,
            child: _isUrl(url)
                ? Image.network(
                    url,
                    fit: BoxFit.contain,
                    errorBuilder: (_, _, _) =>
                        Center(child: Icon(Icons.broken_image_outlined, color: colors.textDisabled)),
                  )
                : Center(child: Icon(Icons.image_outlined, color: colors.textDisabled)),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _SyncedTextField(
                label: title,
                value: url,
                onChanged: onChanged,
              ),
            ),
            _SmallIcon(Icons.upload_rounded, 'Upload image', onUpload),
            _SmallIcon(Icons.copy_rounded, 'Copy URL', url.isEmpty
                ? null
                : () => Clipboard.setData(ClipboardData(text: url))),
            if (onRemove != null)
              _SmallIcon(Icons.close_rounded, 'Remove', onRemove, color: colors.error),
          ],
        ),
      ],
    );
  }
}

/// A list of strings / numbers as chips, e.g. `trendingTags` or `topWallpapers`.
class _ChipListEditor extends StatefulWidget {
  const _ChipListEditor({required this.items, required this.wallNames, required this.onChanged});

  final List items;
  final Map<int, String> wallNames;
  final ValueChanged<Object?> onChanged;

  @override
  State<_ChipListEditor> createState() => _ChipListEditorState();
}

class _ChipListEditorState extends State<_ChipListEditor> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _add() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    widget.onChanged([...widget.items, int.tryParse(text) ?? double.tryParse(text) ?? text]);
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.items;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (var i = 0; i < items.length; i++)
          InputChip(
            label: Text(
              items[i] is int && widget.wallNames.containsKey(items[i])
                  ? '${items[i]} · ${widget.wallNames[items[i]]}'
                  : '${items[i]}',
            ),
            onDeleted: () => widget.onChanged([...items]..removeAt(i)),
          ),
        SizedBox(
          width: 220,
          child: TextField(
            controller: _controller,
            decoration: InputDecoration(
              hintText: 'Add and press Enter',
              isDense: true,
              suffixIcon: IconButton(icon: const Icon(Icons.add_rounded, size: 18), onPressed: _add),
            ),
            onSubmitted: (_) => _add(),
          ),
        ),
      ],
    );
  }
}

/// Text, number or switch, keeping the value's JSON type.
class _ScalarField extends StatelessWidget {
  const _ScalarField({required this.value, required this.onChanged, this.label});

  final Object? value;
  final ValueChanged<Object?> onChanged;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final value = this.value;
    if (value is bool) {
      return SwitchListTile(
        contentPadding: EdgeInsets.zero,
        dense: true,
        title: Text(label ?? 'Enabled'),
        value: value,
        onChanged: onChanged,
      );
    }
    return _SyncedTextField(
      label: label,
      value: '$value',
      number: value is num,
      onChanged: (text) {
        if (value is! num) return onChanged(text);
        final parsed = value is int ? int.tryParse(text) : num.tryParse(text);
        if (parsed != null) onChanged(parsed);
      },
    );
  }
}

class _JsonPreview extends StatelessWidget {
  const _JsonPreview({required this.value});

  final Object? value;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final text = const JsonEncoder.withIndent('  ').convert(value);
    return Container(
      constraints: const BoxConstraints(maxHeight: 220),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: colors.bgSubtle, borderRadius: BorderRadius.circular(10)),
      child: SingleChildScrollView(
        child: SelectableText(
          text,
          style: TextStyle(fontFamily: 'monospace', fontSize: 12, color: colors.textSecondary),
        ),
      ),
    );
  }
}

/// A text field whose text follows [value] when it changes from outside.
class _SyncedTextField extends StatefulWidget {
  const _SyncedTextField({
    required this.value,
    required this.onChanged,
    this.label,
    this.number = false,
  });

  final String value;
  final ValueChanged<String> onChanged;
  final String? label;
  final bool number;

  @override
  State<_SyncedTextField> createState() => _SyncedTextFieldState();
}

class _SyncedTextFieldState extends State<_SyncedTextField> {
  late final _controller = TextEditingController(text: widget.value);

  @override
  void didUpdateWidget(_SyncedTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != _controller.text) _controller.text = widget.value;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      keyboardType: widget.number ? TextInputType.number : null,
      decoration: InputDecoration(labelText: widget.label, isDense: true),
      onChanged: widget.onChanged,
    );
  }
}

class _SmallIcon extends StatelessWidget {
  const _SmallIcon(this.icon, this.tooltip, this.onPressed, {this.color});

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final Color? color;

  @override
  Widget build(BuildContext context) => IconButton(
        tooltip: tooltip,
        visualDensity: VisualDensity.compact,
        icon: Icon(icon, size: 18, color: onPressed == null ? null : color),
        onPressed: onPressed,
      );
}

Future<String?> _promptText(BuildContext context, String label) {
  final controller = TextEditingController();
  return showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(label),
      content: TextField(
        controller: controller,
        autofocus: true,
        onSubmitted: (v) => Navigator.pop(ctx, v.trim()),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        FilledButton(onPressed: () => Navigator.pop(ctx, controller.text.trim()), child: const Text('Add')),
      ],
    ),
  ).whenComplete(controller.dispose);
}

/// Edits a field as raw JSON. Without [key] it also asks for a new key.
Future<MapEntry<String, Object?>?> _showJsonDialog(
  BuildContext context, {
  String? key,
  Object? value,
  Set<String> existingKeys = const {},
}) {
  return showDialog<MapEntry<String, Object?>>(
    context: context,
    builder: (_) => _JsonDialog(fieldKey: key, value: value, existingKeys: existingKeys),
  );
}

class _JsonDialog extends StatefulWidget {
  const _JsonDialog({required this.fieldKey, required this.value, required this.existingKeys});

  final String? fieldKey;
  final Object? value;
  final Set<String> existingKeys;

  @override
  State<_JsonDialog> createState() => _JsonDialogState();
}

class _JsonDialogState extends State<_JsonDialog> {
  late final _key = TextEditingController(text: widget.fieldKey ?? '');
  late final _json = TextEditingController(
    text: widget.fieldKey == null ? '""' : const JsonEncoder.withIndent('  ').convert(widget.value),
  );
  String? _error;

  @override
  void dispose() {
    _key.dispose();
    _json.dispose();
    super.dispose();
  }

  void _save() {
    final key = _key.text.trim();
    if (widget.fieldKey == null) {
      if (key.isEmpty) return setState(() => _error = 'Enter a key.');
      if (key == kBuffyWallpapersKey) {
        return setState(() => _error = '"$key" is edited in the Wallpapers tab.');
      }
      if (widget.existingKeys.contains(key)) {
        return setState(() => _error = '"$key" already exists.');
      }
    }
    try {
      Navigator.pop(context, MapEntry(key, jsonDecode(_json.text)));
    } on FormatException catch (e) {
      setState(() => _error = 'Not valid JSON: ${e.message}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return AlertDialog(
      title: Text(widget.fieldKey == null ? 'Add field' : 'Edit "${widget.fieldKey}"'),
      content: SizedBox(
        width: 640,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.fieldKey == null) ...[
              TextField(
                controller: _key,
                autofocus: true,
                decoration: const InputDecoration(labelText: 'Key', isDense: true),
              ),
              const SizedBox(height: 12),
            ],
            TextField(
              controller: _json,
              minLines: 8,
              maxLines: 20,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
              decoration: const InputDecoration(
                labelText: 'Value (JSON)',
                alignLabelWithHint: true,
                border: OutlineInputBorder(),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: TextStyle(color: colors.error, fontSize: 12)),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(onPressed: _save, child: Text(widget.fieldKey == null ? 'Add' : 'Apply')),
      ],
    );
  }
}
