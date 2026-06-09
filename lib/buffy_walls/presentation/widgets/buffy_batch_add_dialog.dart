import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:miui_icon_generator/core/theme/theme_extensions.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';
import '../../application/providers/buffy_cms_provider.dart';
import '../../application/services/buffy_wallpaper_import_service.dart';
import '../../domain/models/buffy_wallpaper.dart';

class BuffyBatchAddDialog extends ConsumerStatefulWidget {
  final List<String> existingCategories;
  final List<String> existingTags;
  final List<String> existingColors;

  const BuffyBatchAddDialog({
    super.key,
    required this.existingCategories,
    required this.existingTags,
    required this.existingColors,
  });

  @override
  ConsumerState<BuffyBatchAddDialog> createState() => _BuffyBatchAddDialogState();
}

class _BuffyBatchAddDialogState extends ConsumerState<BuffyBatchAddDialog> {
  final List<_BatchItem> _items = [];
  bool _isImporting = false;

  Future<void> _pickFiles() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'webp'],
      allowMultiple: true,
    );

    if (result != null) {
      setState(() {
        for (final file in result.files) {
          if (file.path != null) {
            final f = File(file.path!);
            
            final name = p.basenameWithoutExtension(f.path)
                .split(RegExp(r'[-_ ]'))
                .map((s) => s.isNotEmpty ? s[0].toUpperCase() + s.substring(1) : '')
                .join(' ');
                
            final item = _BatchItem(
              file: f,
              nameController: TextEditingController(text: name),
              tagsController: TextEditingController(),
              colorsController: TextEditingController(),
              categoryController: TextEditingController(
                text: widget.existingCategories.isNotEmpty ? widget.existingCategories.first : ''
              ),
            );
            
            _items.add(item);
          }
        }
      });
    }
  }

  Future<void> _submit() async {
    if (_items.isEmpty) return;

    setState(() => _isImporting = true);
    try {
      final importService = ref.read(buffyWallpaperImportServiceProvider.notifier);
      for (final item in _items) {
        await importService.importWallpaper(
          file: item.file,
          category: item.categoryController.text.trim(),
          name: item.nameController.text.trim(),
          tags: item.tagsController.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
          colors: item.colorsController.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
          isPremium: item.isPremium,
        );
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Imported ${_items.length} wallpapers successfully.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Import Error: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isImporting = false);
      }
    }
  }

  @override
  void dispose() {
    for (var item in _items) {
      item.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final colors = context.appColors;
    return Dialog(
      backgroundColor: colors.bg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SizedBox(
        width: 1000,
        height: 800,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                children: [
                  Text('Buffy Batch Add', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: cs.onSurface)),
                  const Spacer(),
                  ElevatedButton.icon(
                    onPressed: _pickFiles,
                    icon: const Icon(Icons.add_photo_alternate),
                    label: const Text('Add Files'),
                  ),
                ],
              ),
            ),
            if (_isImporting)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 16),
                      Text('Importing wallpapers...', style: TextStyle(color: cs.onSurface, fontSize: 18)),
                      Text('Copying files and generating thumbnails. This may take a while.', style: TextStyle(color: cs.onSurfaceVariant)),
                    ],
                  ),
                ),
              )
            else
            Expanded(
              child: _items.isEmpty
                  ? Center(child: Text('No files added yet.', style: TextStyle(color: cs.onSurfaceVariant)))
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      itemCount: _items.length,
                      separatorBuilder: (_, __) => Divider(height: 32, color: cs.onSurface.withValues(alpha: 0.1)),
                      itemBuilder: (context, index) => _buildItemRow(_items[index]),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Cancel', style: TextStyle(color: cs.onSurfaceVariant)),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: _items.isEmpty || _isImporting ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: cs.primary,
                      foregroundColor: cs.onPrimary,
                      padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 20),
                    ),
                    child: const Text('Import All'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemRow(_BatchItem item) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 80,
          height: 120,
          decoration: BoxDecoration(
            color: cs.onSurface.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            image: DecorationImage(image: FileImage(item.file), fit: BoxFit.cover),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(child: _buildItemTextField(item.nameController, 'Name')),
                  const SizedBox(width: 16),
                  Expanded(child: _buildItemCategoryDropdown(item.categoryController)),
                  const SizedBox(width: 16),
                  Column(
                    children: [
                      Text('Premium', style: TextStyle(fontSize: 10, color: cs.onSurfaceVariant)),
                      Checkbox(
                        value: item.isPremium,
                        onChanged: (v) => setState(() => item.isPremium = v ?? false),
                        activeColor: cs.primary,
                      ),
                    ],
                  ),
                  IconButton(
                    icon: Icon(Icons.delete_outline, color: cs.error),
                    onPressed: () => setState(() => _items.remove(item)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _buildItemSuggestionField(item.tagsController, 'Tags', widget.existingTags, item.tagsFocusNode)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildItemSuggestionField(item.colorsController, 'Colors', widget.existingColors, item.colorsFocusNode)),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildItemTextField(TextEditingController controller, String label) {
    return TextField(
      controller: controller,
      style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurface),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 12),
        isDense: true,
      ),
    );
  }

  Widget _buildItemCategoryDropdown(TextEditingController controller) {
    return Autocomplete<String>(
      optionsBuilder: (value) => widget.existingCategories.where((c) => c.toLowerCase().contains(value.text.toLowerCase())),
      initialValue: TextEditingValue(text: controller.text),
      onSelected: (v) => controller.text = v,
      fieldViewBuilder: (context, textController, focusNode, onFieldSubmitted) {
        textController.addListener(() => controller.text = textController.text);
        return TextField(
          controller: textController,
          focusNode: focusNode,
          style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurface),
          decoration: const InputDecoration(labelText: 'Category', isDense: true),
        );
      },
    );
  }

  Widget _buildItemSuggestionField(TextEditingController controller, String label, List<String> suggestions, FocusNode focusNode) {
    return RawAutocomplete<String>(
      textEditingController: controller,
      focusNode: focusNode,
      optionsBuilder: (TextEditingValue value) {
        if (value.text.isEmpty) return const Iterable<String>.empty();
        final parts = value.text.split(RegExp(r',\s*'));
        final lastPart = parts.last.trim();
        if (lastPart.isEmpty) return const Iterable<String>.empty();
        return suggestions.where((s) => s.toLowerCase().contains(lastPart.toLowerCase()));
      },
      onSelected: (String selection) {
        final text = controller.text;
        final lastCommaIndex = text.lastIndexOf(',');
        if (lastCommaIndex == -1) {
          controller.text = '$selection, ';
        } else {
          controller.text = '${text.substring(0, lastCommaIndex).trim()}, $selection, ';
        }
        controller.selection = TextSelection.fromPosition(TextPosition(offset: controller.text.length));
      },
      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
        return TextField(
          controller: controller,
          focusNode: focusNode,
          style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurface),
          decoration: InputDecoration(
            labelText: label,
            isDense: true,
            labelStyle: const TextStyle(fontSize: 12),
          ),
        );
      },
      optionsViewBuilder: (context, onSelected, options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 4,
            color: Theme.of(context).colorScheme.surface,
            child: SizedBox(
              height: 200,
              width: 250,
              child: ListView.builder(
                padding: EdgeInsets.zero,
                itemCount: options.length,
                itemBuilder: (context, index) {
                  final option = options.elementAt(index);
                  return ListTile(
                    title: Text(option, style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 12)),
                    onTap: () => onSelected(option),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}

class _BatchItem {
  final File file;
  final TextEditingController nameController;
  final TextEditingController tagsController;
  final TextEditingController colorsController;
  final TextEditingController categoryController;
  final FocusNode tagsFocusNode = FocusNode();
  final FocusNode colorsFocusNode = FocusNode();
  bool isPremium = false;

  _BatchItem({
    required this.file,
    required this.nameController,
    required this.tagsController,
    required this.colorsController,
    required this.categoryController,
  });

  void dispose() {
    nameController.dispose();
    tagsController.dispose();
    colorsController.dispose();
    categoryController.dispose();
    tagsFocusNode.dispose();
    colorsFocusNode.dispose();
  }
}
