import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:miui_icon_generator/core/theme/theme_extensions.dart';

import '../../application/providers/catalog_provider.dart';
import '../../application/services/catalog_service.dart';
import '../../domain/catalog_rules.dart';
import 'storage_image.dart';

const prettyJson = JsonEncoder.withIndent('  ');

/// Deep copy of a decoded JSON value, so edits don't touch the loaded catalog.
dynamic jsonCopy(Object? value) => jsonDecode(jsonEncode(value));

String jsonTypeLabel(Object? value) => switch (value) {
  List() => 'List · ${value.length} items',
  Map() => 'Object · ${value.length} keys',
  String() => 'Text',
  bool() => 'Boolean',
  num() => 'Number',
  null => 'null',
  _ => '${value.runtimeType}',
};

IconData jsonTypeIcon(Object? value) => switch (value) {
  List() => Icons.view_list_rounded,
  Map() => Icons.data_object_rounded,
  bool() => Icons.toggle_on_outlined,
  num() => Icons.tag_rounded,
  _ => Icons.text_fields_rounded,
};

/// Lists of objects (like `banners`) get a card per item; empty lists too.
bool isObjectList(Object? value) =>
    value is List && value.every((e) => e is Map);

bool isImageUrl(String value) => RegExp(
  r'\.(jpe?g|png|webp|gif)$',
  caseSensitive: false,
).hasMatch(Uri.tryParse(value)?.path ?? '');

bool _isImageKey(String key) => RegExp(
  r'image|img|banner|thumb|icon|poster|cover|photo|url',
  caseSensitive: false,
).hasMatch(key);

enum JsonType {
  text('Text'),
  number('Number'),
  boolean('Boolean'),
  object('Object'),
  list('List');

  const JsonType(this.label);
  final String label;

  Object get initial => switch (this) {
    text => '',
    number => 0,
    boolean => false,
    object => <String, dynamic>{},
    list => <dynamic>[],
  };
}

Object? _blankLike(Object? value) => switch (value) {
  String() => '',
  bool() => false,
  num() => 0,
  List() => <dynamic>[],
  Map() => <String, dynamic>{},
  _ => null,
};

/// Asks for a key name not in [taken] and the type of its starting value.
Future<(String, Object)?> showAddKeyDialog(
  BuildContext context, {
  required Set<String> taken,
  String title = 'Add key',
}) {
  final name = TextEditingController();
  var type = JsonType.text;
  String? error;
  return showDialog<(String, Object)>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) {
        void submit() {
          final key = name.text.trim();
          if (key.isEmpty) return setState(() => error = 'Enter a name');
          if (taken.contains(key))
            return setState(() => error = '"$key" already exists');
          Navigator.pop(context, (key, type.initial));
        }

        return AlertDialog(
          title: Text(title),
          content: SizedBox(
            width: 360,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: name,
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: 'Name',
                    errorText: error,
                  ),
                  onSubmitted: (_) => submit(),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<JsonType>(
                  initialValue: type,
                  decoration: const InputDecoration(labelText: 'Type'),
                  items: [
                    for (final t in JsonType.values)
                      DropdownMenuItem(value: t, child: Text(t.label)),
                  ],
                  onChanged: (t) => setState(() => type = t ?? type),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(onPressed: submit, child: const Text('Add')),
          ],
        );
      },
    ),
  );
}

/// Picks an image, uploads it to [folder] and returns its public URL.
Future<String?> pickAndUploadImage(WidgetRef ref, String folder) async {
  final result = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: CatalogService.imageExtensions,
  );
  final path = result?.files.single.path;
  if (path == null) return null;
  final service = await ref.read(catalogServiceProvider.future);
  return service.uploadImage(path, folder);
}

/// Shows an image URL: bucket objects through the signed-in client, others directly.
class UrlPreview extends ConsumerWidget {
  const UrlPreview(this.url, {super.key, this.fit = BoxFit.contain});

  final String url;
  final BoxFit fit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.appColors;
    final bucket = ref.watch(storageSettingsProvider).valueOrNull?.bucket;
    if (bucket != null && CatalogRules.objectPathFromUrl(bucket, url) != null) {
      return StorageImage(url, fit: fit);
    }
    final broken = ColoredBox(
      color: colors.bgSubtle,
      child: Center(
        child: Icon(Icons.broken_image_outlined, color: colors.textDisabled),
      ),
    );
    if (!url.startsWith('https://') && !url.startsWith('http://'))
      return broken;
    return Image.network(url, fit: fit, errorBuilder: (_, __, ___) => broken);
  }
}

/// Edits a list of objects (e.g. `banners`) in place, one card per item.
class JsonObjectListEditor extends StatefulWidget {
  const JsonObjectListEditor({
    super.key,
    required this.items,
    required this.onChanged,
    required this.uploadFolder,
  });

  final List<dynamic> items;
  final VoidCallback onChanged;
  final String uploadFolder;

  @override
  State<JsonObjectListEditor> createState() => _JsonObjectListEditorState();
}

class _JsonObjectListEditorState extends State<JsonObjectListEditor> {
  List<dynamic> get _items => widget.items;

  void _changed(VoidCallback edit) {
    setState(edit);
    widget.onChanged();
  }

  void _add() => _changed(() {
    final first = _items.isEmpty ? null : _items.first as Map;
    _items.add(<String, dynamic>{
      if (first != null)
        for (final e in first.entries) '${e.key}': _blankLike(e.value),
    });
  });

  void _move(int from, int to) =>
      _changed(() => _items.insert(to, _items.removeAt(from)));

  String _titleOf(Map item) {
    for (final key in const ['title', 'name', 'id', 'type']) {
      final v = item[key];
      if (v != null && '$v'.isNotEmpty) return '$v';
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text(
              '${_items.length} items',
              style: TextStyle(color: colors.textSecondary),
            ),
            const Spacer(),
            FilledButton.tonalIcon(
              onPressed: _add,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add item'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        for (final (i, item) in _items.indexed)
          Card(
            key: ObjectKey(item),
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 8, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Text(
                        '#${i + 1}',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: colors.primary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _titleOf(item as Map),
                          style: TextStyle(
                            color: colors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        tooltip: 'Move up',
                        icon: const Icon(Icons.arrow_upward_rounded, size: 18),
                        onPressed: i == 0 ? null : () => _move(i, i - 1),
                      ),
                      IconButton(
                        tooltip: 'Move down',
                        icon: const Icon(
                          Icons.arrow_downward_rounded,
                          size: 18,
                        ),
                        onPressed: i == _items.length - 1
                            ? null
                            : () => _move(i, i + 1),
                      ),
                      IconButton(
                        tooltip: 'Duplicate',
                        icon: const Icon(Icons.copy_rounded, size: 18),
                        onPressed: () => _changed(
                          () => _items.insert(i + 1, jsonCopy(item)),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Remove',
                        icon: Icon(
                          Icons.delete_outline,
                          size: 18,
                          color: colors.error,
                        ),
                        onPressed: () => _changed(() => _items.removeAt(i)),
                      ),
                    ],
                  ),
                  JsonObjectEditor(
                    map: item as Map<String, dynamic>,
                    onChanged: () => setState(widget.onChanged),
                    uploadFolder: widget.uploadFolder,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

/// Edits an object's values in place with a typed input per key.
class JsonObjectEditor extends StatefulWidget {
  const JsonObjectEditor({
    super.key,
    required this.map,
    required this.onChanged,
    required this.uploadFolder,
    this.fixedKeys = false,
  });

  final Map<String, dynamic> map;
  final VoidCallback onChanged;
  final String uploadFolder;

  /// Hides adding and removing keys.
  final bool fixedKeys;

  @override
  State<JsonObjectEditor> createState() => _JsonObjectEditorState();
}

class _JsonObjectEditorState extends State<JsonObjectEditor> {
  Map<String, dynamic> get _map => widget.map;

  void _set(String key, Object? value) {
    _map[key] = value;
    widget.onChanged();
  }

  Future<void> _addKey() async {
    final added = await showAddKeyDialog(context, taken: _map.keys.toSet());
    if (added == null) return;
    setState(() => _map[added.$1] = added.$2);
    widget.onChanged();
  }

  Widget _input(String key) {
    final value = _map[key];
    final colors = context.appColors;
    return switch (value) {
      bool() => Row(
        children: [
          Text(key, style: TextStyle(color: colors.textPrimary)),
          const Spacer(),
          Switch(value: value, onChanged: (v) => setState(() => _set(key, v))),
        ],
      ),
      num() => TextFormField(
        initialValue: '$value',
        decoration: InputDecoration(labelText: key, isDense: true),
        keyboardType: const TextInputType.numberWithOptions(
          decimal: true,
          signed: true,
        ),
        autovalidateMode: AutovalidateMode.onUserInteraction,
        validator: (t) =>
            num.tryParse(t?.trim() ?? '') == null ? 'Not a number' : null,
        onChanged: (t) {
          final n = num.tryParse(t.trim());
          if (n != null) _set(key, n);
        },
      ),
      String() || null => _StringField(
        label: key,
        initial: value as String?,
        canUpload: _isImageKey(key) || isImageUrl(value ?? ''),
        uploadFolder: widget.uploadFolder,
        onChanged: (t) => _set(key, t),
      ),
      _ => JsonTextField(
        label: key,
        value: value,
        onParsed: (v) => _set(key, v),
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final key in _map.keys.toList())
          Padding(
            key: ValueKey(key),
            padding: const EdgeInsets.only(top: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _input(key)),
                if (!widget.fixedKeys)
                  IconButton(
                    tooltip: 'Remove "$key"',
                    icon: Icon(
                      Icons.close_rounded,
                      size: 18,
                      color: colors.textSecondary,
                    ),
                    onPressed: () {
                      setState(() => _map.remove(key));
                      widget.onChanged();
                    },
                  ),
              ],
            ),
          ),
        if (!widget.fixedKeys)
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: TextButton.icon(
                onPressed: _addKey,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add key'),
              ),
            ),
          ),
      ],
    );
  }
}

/// Text value with an upload button and preview for image fields. A null
/// value stays null while the field is empty.
class _StringField extends ConsumerStatefulWidget {
  const _StringField({
    required this.label,
    required this.initial,
    required this.canUpload,
    required this.uploadFolder,
    required this.onChanged,
  });

  final String label;
  final String? initial;
  final bool canUpload;
  final String uploadFolder;
  final ValueChanged<String?> onChanged;

  @override
  ConsumerState<_StringField> createState() => _StringFieldState();
}

class _StringFieldState extends ConsumerState<_StringField> {
  late final _controller = TextEditingController(text: widget.initial ?? '');
  bool _uploading = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _changed(String text) =>
      widget.onChanged(text.isEmpty && widget.initial == null ? null : text);

  Future<void> _upload() async {
    setState(() {
      _uploading = true;
      _error = null;
    });
    try {
      final url = await pickAndUploadImage(ref, widget.uploadFolder);
      if (url != null && mounted) {
        _controller.text = url;
        _changed(url);
      }
    } catch (e) {
      if (mounted) setState(() => _error = 'Upload failed: $e');
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: _controller,
      builder: (context, text, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _controller,
            minLines: 1,
            maxLines: 4,
            decoration: InputDecoration(
              labelText: widget.label,
              hintText: widget.initial == null ? 'null' : null,
              errorText: _error,
              isDense: true,
              suffixIcon: !widget.canUpload
                  ? null
                  : _uploading
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox.square(
                        dimension: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : IconButton(
                      tooltip: 'Upload image',
                      icon: const Icon(Icons.upload_file_rounded, size: 18),
                      onPressed: _upload,
                    ),
            ),
            onChanged: _changed,
          ),
          if (isImageUrl(text.text))
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(height: 120, child: UrlPreview(text.text)),
              ),
            ),
        ],
      ),
    );
  }
}

/// Nested values edited as JSON text; [onParsed] gets each valid version.
class JsonTextField extends StatefulWidget {
  const JsonTextField({
    super.key,
    required this.label,
    required this.value,
    required this.onParsed,
  });

  final String label;
  final Object? value;
  final ValueChanged<Object?> onParsed;

  @override
  State<JsonTextField> createState() => _JsonTextFieldState();
}

class _JsonTextFieldState extends State<JsonTextField> {
  late final _controller = TextEditingController(
    text: prettyJson.convert(widget.value),
  );
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      minLines: 2,
      maxLines: 12,
      style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
      decoration: InputDecoration(
        labelText: widget.label,
        helperText: 'JSON',
        errorText: _error,
        border: const OutlineInputBorder(),
        isDense: true,
      ),
      onChanged: (text) {
        try {
          widget.onParsed(jsonDecode(text));
          if (_error != null) setState(() => _error = null);
        } on FormatException catch (e) {
          setState(() => _error = 'Invalid JSON: ${e.message}');
        }
      },
    );
  }
}
