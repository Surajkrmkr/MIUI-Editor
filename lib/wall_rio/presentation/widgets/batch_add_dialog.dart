import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';
import '../../application/providers/ai_provider.dart';
import '../../application/providers/cms_provider.dart';
import '../../application/services/wallpaper_import_service.dart';
import '../../domain/models/wallpaper.dart';

class BatchAddDialog extends ConsumerStatefulWidget {
  final List<String> existingCategories;
  final List<String> existingTags;
  final List<String> existingColors;

  const BatchAddDialog({
    super.key,
    required this.existingCategories,
    required this.existingTags,
    required this.existingColors,
  });

  @override
  ConsumerState<BatchAddDialog> createState() => _BatchAddDialogState();
}

class _BatchAddDialogState extends ConsumerState<BatchAddDialog> {
  final List<_BatchItem> _items = [];
  bool _isImporting = false;

  Future<void> _pickFiles() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'webp', 'mp4'],
      allowMultiple: true,
    );

    if (result != null) {
      setState(() {
        for (final file in result.files) {
          if (file.path != null) {
            final f = File(file.path!);
            final extension = p.extension(f.path).toLowerCase();
            final isVideo = extension == '.mp4';
            
            final name = p.basenameWithoutExtension(f.path)
                .split(RegExp(r'[-_ ]'))
                .map((s) => s.isNotEmpty ? s[0].toUpperCase() + s.substring(1) : '')
                .join(' ');
                
            final item = _BatchItem(
              file: f,
              nameController: TextEditingController(text: name),
              tagsController: TextEditingController(),
              urlController: TextEditingController(),
              thumbnailController: TextEditingController(),
              colorsController: TextEditingController(),
              videoUrlController: TextEditingController(),
              previewVideoController: TextEditingController(),
              typeController: TextEditingController(text: isVideo ? 'live' : ''),
              categoryController: TextEditingController(
                text: widget.existingCategories.isNotEmpty ? widget.existingCategories.first : ''
              ),
              taskId: const Uuid().v4(),
              isLive: isVideo,
            );
            
            item.nameController.addListener(() => _autofillItemUrls(item));
            item.categoryController.addListener(() => _autofillItemUrls(item));
            
            _items.add(item);
            _autofillItemUrls(item);
          }
        }
      });
    }
  }

  void _autofillItemUrls(_BatchItem item) {
    final name = item.nameController.text.trim();
    final category = item.categoryController.text.trim();
    
    final cmsState = ref.read(cmsProvider);
    if (cmsState.value == null) return;

    final data = cmsState.value!;
    final baseUrl = _deduceBaseUrl(data.walls, false, item.isLive);
    final baseThumbUrl = _deduceBaseUrl(data.walls, true, item.isLive);

    if (baseUrl != null) {
      final ext = item.isLive ? '.mp4' : _deduceExtension(data.walls);
      final includeCategory = _shouldIncludeCategory(data.walls, item.isLive);
      
      final normalizedName = Uri.encodeComponent(name);
      final normalizedCategory = Uri.encodeComponent(category);

      if (name.isNotEmpty) {
        String newUrl;
        if (includeCategory && category.isNotEmpty) {
          newUrl = '$baseUrl/$normalizedCategory/$normalizedName$ext';
        } else {
          newUrl = '$baseUrl/$normalizedName$ext';
        }
        
        if (item.isLive) {
          item.videoUrlController.text = newUrl;
          item.previewVideoController.text = newUrl;
        } else {
          item.urlController.text = newUrl;
        }

        if (baseThumbUrl != null) {
          final thumbExt = _deduceExtension(data.walls, forThumbnail: true);
          if (includeCategory && category.isNotEmpty) {
            item.thumbnailController.text = '$baseThumbUrl/$normalizedCategory/$normalizedName$thumbExt';
          } else {
            item.thumbnailController.text = '$baseThumbUrl/$normalizedName$thumbExt';
          }
        }
      }
    }
  }

  String _deduceExtension(List<Wallpaper> walls, {bool forThumbnail = false}) {
    if (walls.isEmpty) return forThumbnail ? '.jpg' : '.png';
    final exts = walls.map((w) => p.extension(forThumbnail ? w.thumbnail : w.url)).where((e) => e.isNotEmpty).toList();
    if (exts.isEmpty) return forThumbnail ? '.jpg' : '.png';
    
    final counts = <String, int>{};
    for (final e in exts) {
      counts[e] = (counts[e] ?? 0) + 1;
    }
    return counts.entries.reduce((a, b) => a.value > b.value ? a : b).key;
  }

  bool _shouldIncludeCategory(List<Wallpaper> walls, bool isLive) {
    if (walls.isEmpty) return true;
    int count = 0;
    for (final w in walls) {
      final pathToCheck = isLive ? w.videoUrl ?? '' : w.url;
      if (w.category.isNotEmpty && pathToCheck.contains(w.category.replaceAll(' ', '%20'))) {
        count++;
      }
    }
    return count > walls.length / 2;
  }

  String? _deduceBaseUrl(List<Wallpaper> walls, bool isThumbnail, bool isLive) {
    final urls = walls
        .map((w) {
          if (isThumbnail) return w.thumbnail;
          if (isLive) return w.videoUrl ?? w.url;
          return w.url;
        })
        .where((u) => u.startsWith('http'))
        .toList();
    
    if (urls.isEmpty) return null;

    String prefix = urls[0];
    for (var i = 1; i < urls.length && i < 20; i++) {
      int j = 0;
      while (j < prefix.length && j < urls[i].length && prefix[j] == urls[i][j]) {
        j++;
      }
      prefix = prefix.substring(0, j);
    }

    final lastSlash = prefix.lastIndexOf('/');
    if (lastSlash > 8) {
      prefix = prefix.substring(0, lastSlash);
    }
    return prefix;
  }

  Future<void> _analyzeAll() async {
    for (var item in _items) {
      if (!item.isProcessed && !item.isAnalyzing && !item.isLive) {
        setState(() => item.isAnalyzing = true);
        try {
          await ref.read(aiStateProvider.notifier).analyzeImage(item.taskId, item.file.path);
          final result = ref.read(aiStateProvider)[item.taskId]?.result;
          if (result != null) {
            item.nameController.text = result.name;
            item.tagsController.text = result.tags.join(', ');
            item.colorsController.text = result.colors.join(', ');
            if (result.category != null) {
              item.categoryController.text = result.category!;
            }
            item.isProcessed = true;
          }
        } catch (_) {} finally {
          setState(() => item.isAnalyzing = false);
        }
      }
    }
  }

  Future<void> _submit() async {
    if (_items.isEmpty) return;

    setState(() => _isImporting = true);
    try {
      final importService = ref.read(wallpaperImportServiceProvider.notifier);
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
    return Dialog(
      backgroundColor: const Color(0xFF121212),
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
                  const Text('Batch Add Wallpapers', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                  const Spacer(),
                  if (_items.isNotEmpty)
                    TextButton.icon(
                      onPressed: _analyzeAll,
                      icon: const Icon(Icons.auto_awesome, color: Colors.purpleAccent),
                      label: const Text('AI Auto-fill All', style: TextStyle(color: Colors.purpleAccent)),
                    ),
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    onPressed: _pickFiles,
                    icon: const Icon(Icons.add_photo_alternate),
                    label: const Text('Add Files'),
                  ),
                ],
              ),
            ),
            if (_isImporting)
              const Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Importing wallpapers...', style: TextStyle(color: Colors.white, fontSize: 18)),
                      Text('Copying files and generating thumbnails. This may take a while.', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                ),
              )
            else
            Expanded(
              child: _items.isEmpty
                  ? Center(child: Text('No files added yet.', style: TextStyle(color: Colors.grey[600])))
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      itemCount: _items.length,
                      separatorBuilder: (_, __) => const Divider(height: 32, color: Colors.white10),
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
                    child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: _items.isEmpty || _isImporting ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purpleAccent,
                      foregroundColor: Colors.white,
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
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 80,
          height: 120,
          decoration: BoxDecoration(
            color: Colors.white10,
            borderRadius: BorderRadius.circular(8),
            image: !item.isLive ? DecorationImage(image: FileImage(item.file), fit: BoxFit.cover) : null,
          ),
          child: item.isLive ? const Icon(Icons.videocam, color: Colors.white24) : null,
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
                      const Text('Premium', style: TextStyle(fontSize: 10, color: Colors.grey)),
                      Checkbox(
                        value: item.isPremium,
                        onChanged: (v) => setState(() => item.isPremium = v ?? false),
                        activeColor: Colors.purpleAccent,
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
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
      style: const TextStyle(fontSize: 13, color: Colors.white),
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
          style: const TextStyle(fontSize: 13, color: Colors.white),
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
          style: const TextStyle(fontSize: 13, color: Colors.white),
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
            color: const Color(0xFF1E1E1E),
            child: SizedBox(
              height: 200,
              width: 250,
              child: ListView.builder(
                padding: EdgeInsets.zero,
                itemCount: options.length,
                itemBuilder: (context, index) {
                  final option = options.elementAt(index);
                  return ListTile(
                    title: Text(option, style: const TextStyle(color: Colors.white, fontSize: 12)),
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
  final TextEditingController urlController;
  final TextEditingController thumbnailController;
  final TextEditingController colorsController;
  final TextEditingController videoUrlController;
  final TextEditingController previewVideoController;
  final TextEditingController typeController;
  final TextEditingController categoryController;
  final FocusNode tagsFocusNode = FocusNode();
  final FocusNode colorsFocusNode = FocusNode();
  bool isPremium;
  bool isAnalyzing;
  bool isProcessed;
  bool isLive;
  final String taskId;

  _BatchItem({
    required this.file,
    required this.nameController,
    required this.tagsController,
    required this.urlController,
    required this.thumbnailController,
    required this.colorsController,
    required this.videoUrlController,
    required this.previewVideoController,
    required this.typeController,
    required this.categoryController,
    this.isPremium = false,
    this.isAnalyzing = false,
    this.isProcessed = false,
    this.isLive = false,
    required this.taskId,
  });

  void dispose() {
    nameController.dispose();
    tagsController.dispose();
    urlController.dispose();
    thumbnailController.dispose();
    colorsController.dispose();
    categoryController.dispose();
    videoUrlController.dispose();
    previewVideoController.dispose();
    typeController.dispose();
    tagsFocusNode.dispose();
    colorsFocusNode.dispose();
  }
}
