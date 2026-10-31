import 'package:flutter/material.dart';
import 'package:miui_icon_generator/core/theme/theme_extensions.dart';

import '../../domain/models/catalog.dart';
import 'tag_color_selectors.dart';

/// Suggestions for the metadata fields, collected from the loaded catalog.
class CatalogSuggestions {
  CatalogSuggestions.fromWalls(List<Map<String, dynamic>> walls)
      : categories = _distinct(walls.map((w) => w['category'])),
        tags = _distinct(walls.expand((w) => (w['tags'] as List? ?? const []))),
        colors = _distinct(walls.expand((w) => (w['color'] as List? ?? const [])));

  final List<String> categories;
  final List<String> tags;
  final List<String> colors;

  static List<String> _distinct(Iterable<dynamic> values) => values
      .map((v) => '${v ?? ''}'.trim())
      .where((v) => v.isNotEmpty)
      .toSet()
      .toList()
    ..sort();
}

/// Name, author, category, tags, colors and premium for one wallpaper.
/// Edits [draft] in place and calls [onChanged] after each change.
class WallpaperFields extends StatefulWidget {
  const WallpaperFields({
    super.key,
    required this.draft,
    required this.suggestions,
    required this.onChanged,
    this.showCategory = true,
  });

  final WallpaperDraft draft;
  final CatalogSuggestions suggestions;
  final VoidCallback onChanged;
  final bool showCategory;

  @override
  State<WallpaperFields> createState() => _WallpaperFieldsState();
}

class _WallpaperFieldsState extends State<WallpaperFields> {
  late final _name = TextEditingController(text: widget.draft.name);
  late final _author = TextEditingController(text: widget.draft.author);

  WallpaperDraft get _draft => widget.draft;

  @override
  void didUpdateWidget(WallpaperFields oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Values set from outside (e.g. AI suggestions) show up in the fields.
    if (_name.text != _draft.name) _name.text = _draft.name;
    if (_author.text != _draft.author) _author.text = _draft.author;
  }

  @override
  void dispose() {
    _name.dispose();
    _author.dispose();
    super.dispose();
  }

  void _update(VoidCallback change) {
    setState(change);
    widget.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _name,
                decoration: const InputDecoration(labelText: 'Name', isDense: true),
                validator: (v) => (v ?? '').trim().isEmpty ? 'Required' : null,
                onChanged: (v) => _update(() => _draft.name = v),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _author,
                decoration: const InputDecoration(labelText: 'Author', isDense: true),
                validator: (v) => (v ?? '').trim().isEmpty ? 'Required' : null,
                onChanged: (v) => _update(() => _draft.author = v),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (widget.showCategory) ...[
          Autocomplete<String>(
            initialValue: TextEditingValue(text: _draft.category),
            optionsBuilder: (value) => widget.suggestions.categories.where(
              (c) => c.toLowerCase().contains(value.text.toLowerCase()),
            ),
            onSelected: (v) => _update(() => _draft.category = v),
            fieldViewBuilder: (context, controller, focusNode, onSubmit) => TextFormField(
              controller: controller,
              focusNode: focusNode,
              decoration: InputDecoration(
                labelText: 'Category',
                isDense: true,
                helperText: widget.suggestions.categories.contains(_draft.category.trim()) ||
                        _draft.category.trim().isEmpty
                    ? null
                    : 'New category',
              ),
              validator: (v) => (v ?? '').trim().isEmpty ? 'Required' : null,
              onChanged: (v) => _update(() => _draft.category = v),
            ),
          ),
          const SizedBox(height: 12),
        ],
        MultiSelectChipField(
          label: 'Tags',
          selectedItems: _draft.tags,
          suggestions: widget.suggestions.tags,
          onAdded: (tag) => _update(() => _draft.tags = [..._draft.tags, tag]),
          onDeleted: (tag) => _update(() => _draft.tags = [..._draft.tags]..remove(tag)),
          onAddPressed: () async {
            final result = await showDialog<List<String>>(
              context: context,
              builder: (_) => TagSelectionDialog(
                initialSelected: _draft.tags,
                existingTags: widget.suggestions.tags,
              ),
            );
            if (result != null) _update(() => _draft.tags = result);
          },
        ),
        const SizedBox(height: 12),
        MultiSelectChipField(
          label: 'Colors',
          isColor: true,
          selectedItems: _draft.colors,
          suggestions: widget.suggestions.colors,
          onAdded: (c) => _update(() => _draft.colors = [..._draft.colors, c]),
          onDeleted: (c) => _update(() => _draft.colors = [..._draft.colors]..remove(c)),
          onAddPressed: () async {
            final result = await showDialog<List<String>>(
              context: context,
              builder: (_) => ColorSelectionDialog(initialSelected: _draft.colors),
            );
            if (result != null) _update(() => _draft.colors = result);
          },
        ),
        const SizedBox(height: 4),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          dense: true,
          title: Text('Premium', style: TextStyle(color: colors.textPrimary)),
          value: _draft.isPremium,
          onChanged: (v) => _update(() => _draft.isPremium = v),
        ),
      ],
    );
  }
}
