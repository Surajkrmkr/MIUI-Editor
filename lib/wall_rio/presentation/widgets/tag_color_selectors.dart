import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/theme_extensions.dart';

class TagSelectionDialog extends StatefulWidget {
  final List<String> initialSelected;
  final List<String> existingTags;

  const TagSelectionDialog({
    super.key,
    required this.initialSelected,
    required this.existingTags,
  });

  @override
  State<TagSelectionDialog> createState() => _TagSelectionDialogState();
}

class _TagSelectionDialogState extends State<TagSelectionDialog> {
  late List<String> _selected;
  Map<String, List<String>> _categorizedTags = {};
  bool _isLoading = true;
  final TextEditingController _customTagController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selected = List.from(widget.initialSelected);
    _loadTags();
  }

  Future<void> _loadTags() async {
    try {
      final String response = await rootBundle.loadString('assets/tags/tags.json');
      final data = await json.decode(response);
      final List categories = data['data'];

      final Map<String, List<String>> categorized = {};
      for (var cat in categories) {
        final String name = cat['name'];
        final List subTags = cat['subTags'];
        categorized[name] = subTags.map((e) => e.toString()).toList();
      }

      // Add "Recent/Existing" category
      if (widget.existingTags.isNotEmpty) {
        categorized['In Use'] = widget.existingTags;
      }

      if (mounted) {
        setState(() {
          _categorizedTags = categorized;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    
    return AlertDialog(
      backgroundColor: colors.surface,
      title: Text('Select Tags', style: TextStyle(color: colors.textPrimary)),
      content: SizedBox(
        width: 600,
        height: 500,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _customTagController,
                          decoration: InputDecoration(
                            hintText: 'Add custom tag...',
                            hintStyle: TextStyle(color: colors.textDisabled),
                            isDense: true,
                          ),
                          style: TextStyle(color: colors.textPrimary),
                          onSubmitted: (val) {
                            if (val.trim().isNotEmpty && !_selected.contains(val.trim())) {
                              setState(() {
                                _selected.add(val.trim());
                                _customTagController.clear();
                              });
                            }
                          },
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.add, color: colors.primary),
                        onPressed: () {
                          final val = _customTagController.text;
                          if (val.trim().isNotEmpty && !_selected.contains(val.trim())) {
                            setState(() {
                              _selected.add(val.trim());
                              _customTagController.clear();
                            });
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: _categorizedTags.entries.map((entry) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  entry.key,
                                  style: TextStyle(
                                    color: colors.textSecondary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: entry.value.map((tag) {
                                    final isSelected = _selected.contains(tag);
                                    return FilterChip(
                                      label: Text(tag),
                                      selected: isSelected,
                                      onSelected: (selected) {
                                        setState(() {
                                          if (selected) {
                                            _selected.add(tag);
                                          } else {
                                            _selected.remove(tag);
                                          }
                                        });
                                      },
                                      backgroundColor: colors.bg,
                                      selectedColor: colors.primary.withAlpha(50),
                                      labelStyle: TextStyle(
                                        color: isSelected ? colors.primary : colors.textPrimary,
                                        fontSize: 11,
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ],
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel', style: TextStyle(color: colors.textSecondary)),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, _selected),
          style: ElevatedButton.styleFrom(backgroundColor: colors.primary),
          child: const Text('Confirm'),
        ),
      ],
    );
  }
}

const Map<String, Color> _colorMapping = {
  'Black': Colors.black,
  'White': Colors.white,
  'Red': Colors.red,
  'Blue': Colors.blue,
  'Green': Colors.green,
  'Yellow': Colors.yellow,
  'Orange': Colors.orange,
  'Purple': Colors.purple,
  'Pink': Colors.pink,
  'Brown': Colors.brown,
  'Grey': Colors.grey,
  'Silver': Color(0xFFC0C0C0),
  'Gold': Color(0xFFFFD700),
  'Cyan': Colors.cyan,
  'Teal': Colors.teal,
  'Lime': Colors.lime,
  'Neon': Color(0xFF39FF14),
  'Indigo': Colors.indigo,
  'Amber': Colors.amber,
};

class ColorSelectionDialog extends StatefulWidget {
  final List<String> initialSelected;

  const ColorSelectionDialog({super.key, required this.initialSelected});

  @override
  State<ColorSelectionDialog> createState() => _ColorSelectionDialogState();
}

class _ColorSelectionDialogState extends State<ColorSelectionDialog> {
  late List<String> _selected;
  List<String> _availableColors = [];
  bool _isLoading = true;
  final TextEditingController _customColorController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selected = List.from(widget.initialSelected);
    _loadAvailableColors();
  }

  Future<void> _loadAvailableColors() async {
    try {
      final String response = await rootBundle.loadString('assets/tags/tags.json');
      final data = await json.decode(response);
      final List categories = data['data'];
      
      final colorCat = categories.firstWhere((c) => c['name'] == 'Color', orElse: () => null);
      if (colorCat != null) {
        final List subTags = colorCat['subTags'];
        _availableColors = subTags.map((e) => e.toString()).toList();
      }

      if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return AlertDialog(
      backgroundColor: colors.surface,
      title: Text('Select Colors', style: TextStyle(color: colors.textPrimary)),
      content: SizedBox(
        width: 500,
        height: 400,
        child: _isLoading 
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _customColorController,
                          decoration: InputDecoration(
                            hintText: 'Add custom color name...',
                            hintStyle: TextStyle(color: colors.textDisabled),
                            isDense: true,
                          ),
                          style: TextStyle(color: colors.textPrimary),
                          onSubmitted: (val) {
                            if (val.trim().isNotEmpty && !_selected.contains(val.trim())) {
                              setState(() {
                                _selected.add(val.trim());
                                _customColorController.clear();
                              });
                            }
                          },
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.add, color: colors.primary),
                        onPressed: () {
                          final val = _customColorController.text;
                          if (val.trim().isNotEmpty && !_selected.contains(val.trim())) {
                            setState(() {
                              _selected.add(val.trim());
                              _customColorController.clear();
                            });
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _availableColors.map((name) {
                          final isSelected = _selected.contains(name);
                          final colorPreview = _colorMapping[name] ?? Colors.grey;
                          
                          return FilterChip(
                            avatar: CircleAvatar(backgroundColor: colorPreview, radius: 8),
                            label: Text(name),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() {
                                if (selected) {
                                  _selected.add(name);
                                } else {
                                  _selected.remove(name);
                                }
                              });
                            },
                            backgroundColor: colors.bg,
                            selectedColor: colors.primary.withAlpha(50),
                            labelStyle: TextStyle(
                              color: isSelected ? colors.primary : colors.textPrimary,
                              fontSize: 11,
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ],
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel', style: TextStyle(color: colors.textSecondary)),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, _selected),
          style: ElevatedButton.styleFrom(backgroundColor: colors.primary),
          child: const Text('Confirm'),
        ),
      ],
    );
  }
}

class MultiSelectChipField extends StatefulWidget {
  final String label;
  final List<String> selectedItems;
  final List<String> suggestions;
  final VoidCallback onAddPressed;
  final Function(String) onDeleted;
  final Function(String) onAdded;
  final bool isColor;

  const MultiSelectChipField({
    super.key,
    required this.label,
    required this.selectedItems,
    this.suggestions = const [],
    required this.onAddPressed,
    required this.onDeleted,
    required this.onAdded,
    this.isColor = false,
  });

  @override
  State<MultiSelectChipField> createState() => _MultiSelectChipFieldState();
}

class _MultiSelectChipFieldState extends State<MultiSelectChipField> {
  final FocusNode _focusNode = FocusNode();
  final TextEditingController _textController = TextEditingController();

  @override
  void dispose() {
    _focusNode.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              widget.label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: colors.textSecondary,
                  ),
            ),
            TextButton.icon(
              onPressed: widget.onAddPressed,
              icon: const Icon(Icons.add, size: 14),
              label: const Text('Browse All', style: TextStyle(fontSize: 12)),
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                foregroundColor: colors.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: colors.bg,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: colors.borderSubtle),
          ),
          constraints: const BoxConstraints(minHeight: 56),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.selectedItems.isNotEmpty) ...[
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: widget.selectedItems.map((item) {
                    Color? chipColor;
                    Color? textColor;
                    if (widget.isColor) {
                      chipColor = _colorMapping[item];
                      if (chipColor != null) {
                        textColor = chipColor.computeLuminance() > 0.5 ? Colors.black : Colors.white;
                      }
                    }

                    return InputChip(
                      avatar: widget.isColor && chipColor != null 
                        ? CircleAvatar(backgroundColor: chipColor, radius: 8)
                        : null,
                      label: Text(
                        item,
                        style: TextStyle(
                          fontSize: 11,
                          color: textColor ?? colors.textPrimary,
                        ),
                      ),
                      backgroundColor: chipColor ?? colors.surfaceOverlay,
                      deleteIconColor: textColor ?? colors.textSecondary,
                      onDeleted: () => widget.onDeleted(item),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                Divider(height: 1, color: colors.borderSubtle.withAlpha(100)),
                const SizedBox(height: 8),
              ],
              
              // Search and Add field - Now Full Width
              RawAutocomplete<String>(
                focusNode: _focusNode,
                textEditingController: _textController,
                optionsBuilder: (TextEditingValue textEditingValue) {
                  if (textEditingValue.text == '') {
                    return const Iterable<String>.empty();
                  }
                  return widget.suggestions.where((String option) {
                    return option.toLowerCase().contains(textEditingValue.text.toLowerCase());
                  }).where((option) => !widget.selectedItems.contains(option));
                },
                onSelected: (String selection) {
                  widget.onAdded(selection);
                  _textController.clear();
                },
                fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                  return TextField(
                    controller: controller,
                    focusNode: focusNode,
                    style: TextStyle(color: colors.textPrimary, fontSize: 13),
                    decoration: InputDecoration(
                      hintText: widget.selectedItems.isEmpty ? 'Type to search or add custom ${widget.label.toLowerCase()}...' : 'Add more...',
                      hintStyle: TextStyle(color: colors.textDisabled, fontSize: 12),
                      border: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    onSubmitted: (value) {
                      if (value.trim().isNotEmpty && !widget.selectedItems.contains(value.trim())) {
                        widget.onAdded(value.trim());
                        controller.clear();
                      }
                    },
                  );
                },
                optionsViewBuilder: (context, onSelected, options) {
                  return Align(
                    alignment: Alignment.topLeft,
                    child: Material(
                      elevation: 4,
                      color: colors.surfaceElevated,
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        width: 300,
                        constraints: const BoxConstraints(maxHeight: 250),
                        child: ListView.builder(
                          padding: EdgeInsets.zero,
                          shrinkWrap: true,
                          itemCount: options.length,
                          itemBuilder: (BuildContext context, int index) {
                            final String option = options.elementAt(index);
                            Color? optColor;
                            if (widget.isColor) optColor = _colorMapping[option];

                            return ListTile(
                              leading: widget.isColor && optColor != null
                                ? CircleAvatar(backgroundColor: optColor, radius: 6)
                                : null,
                              title: Text(option, style: TextStyle(color: colors.textPrimary, fontSize: 12)),
                              onTap: () {
                                onSelected(option);
                              },
                            );
                          },
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        if (widget.suggestions.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            'POPULAR ${widget.label.toUpperCase()}',
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: colors.textSecondary.withAlpha(150),
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: widget.suggestions.take(20).map((item) {
                final isSelected = widget.selectedItems.contains(item);
                Color? dotColor;
                if (widget.isColor) {
                  dotColor = _colorMapping[item];
                }

                return InkWell(
                  onTap: () => isSelected ? widget.onDeleted(item) : widget.onAdded(item),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isSelected ? colors.primary.withAlpha(40) : colors.bg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected ? colors.primary.withAlpha(120) : colors.borderSubtle,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (widget.isColor && dotColor != null) ...[
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
                          ),
                          const SizedBox(width: 6),
                        ],
                        Text(
                          item,
                          style: TextStyle(
                            fontSize: 10,
                            color: isSelected ? colors.primary : colors.textSecondary,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ],
    );
  }
}
