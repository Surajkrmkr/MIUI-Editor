import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:miui_icon_generator/core/theme/theme_extensions.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';
import '../../application/providers/ai_provider.dart';
import '../../application/providers/cms_provider.dart';
import '../../application/services/wallpaper_import_service.dart';
import '../../domain/models/wallpaper.dart';
import 'tag_color_selectors.dart';

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
              selectedTags: [],
              urlController: TextEditingController(),
              thumbnailController: TextEditingController(),
              selectedColors: [],
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
            _detectItemTagsAndColors(item);
            _analyzeItem(item);
          }
        }
      });
    }
  }

  Future<void> _detectItemTagsAndColors(_BatchItem item) async {
    // 1. Detect Colors using PaletteGenerator
    if (!item.isLive) {
      try {
        final gen = await PaletteGenerator.fromImageProvider(FileImage(item.file));
        final detectedNames = <String>{};
        
        for (var paletteColor in gen.colors.take(5)) {
          final name = _findNearestColorName(paletteColor);
          if (name != null) detectedNames.add(name);
        }
        
        if (mounted) {
          setState(() {
            for (var colorName in detectedNames) {
              if (!item.selectedColors.contains(colorName)) {
                item.selectedColors.add(colorName);
              }
            }
          });
        }
      } catch (e) {
        debugPrint('Error detecting colors: $e');
      }
    }

    // 2. Detect Tags from Name
    final name = item.nameController.text;
    final words = name.toLowerCase().split(RegExp(r'[-_ ]'));
    final matchedTags = <String>{};
    
    // Check against existing tags
    for (var tag in widget.existingTags) {
      if (words.contains(tag.toLowerCase()) || name.toLowerCase().contains(tag.toLowerCase())) {
        matchedTags.add(tag);
      }
    }
    
    if (matchedTags.isNotEmpty && mounted) {
      setState(() {
        for (var tag in matchedTags) {
          if (!item.selectedTags.contains(tag)) {
            item.selectedTags.add(tag);
          }
        }
      });
    }
  }

  String? _findNearestColorName(Color color) {
    const mapping = {
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
      'Cyan': Colors.cyan,
      'Teal': Colors.teal,
      'Lime': Colors.lime,
      'Indigo': Colors.indigo,
      'Amber': Colors.amber,
    };

    String? nearestName;
    double minDistance = double.maxFinite;

    for (var entry in mapping.entries) {
      final dist = _colorDistance(color, entry.value);
      if (dist < minDistance) {
        minDistance = dist;
        nearestName = entry.key;
      }
    }

    return minDistance < 100 ? nearestName : null;
  }

  double _colorDistance(Color c1, Color c2) {
    return (c1.red - c2.red).abs() + 
           (c1.green - c2.green).abs() + 
           (c1.blue - c2.blue).abs().toDouble();
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

  Future<void> _analyzeItem(_BatchItem item) async {
    if (item.isProcessed || item.isAnalyzing || item.isLive) return;
    
    setState(() => item.isAnalyzing = true);
    try {
      await ref.read(aiStateProvider.notifier).analyzeImage(item.taskId, item.file.path);
      final result = ref.read(aiStateProvider)[item.taskId]?.result;
      if (result != null && mounted) {
        setState(() {
          item.nameController.text = result.name;
          item.selectedTags = List.from(result.tags);
          
          final aiColors = <String>[];
          for (var col in result.colors) {
            if (col.startsWith('#')) {
              try {
                final color = Color(int.parse(col.replaceFirst('#', '0xFF')));
                final name = _findNearestColorName(color);
                if (name != null) aiColors.add(name);
              } catch (_) {
                aiColors.add(col);
              }
            } else {
              aiColors.add(col);
            }
          }
          item.selectedColors = aiColors;

          if (result.category != null) {
            item.categoryController.text = result.category!;
          }
          item.isProcessed = true;
        });
      }
    } catch (_) {
    } finally {
      if (mounted) {
        setState(() => item.isAnalyzing = false);
      }
    }
  }

  Future<void> _analyzeAll() async {
    for (var item in _items) {
      await _analyzeItem(item);
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
          tags: item.selectedTags,
          colors: item.selectedColors,
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
                  Text('Batch Add Wallpapers', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: cs.onSurface)),
                  const Spacer(),
                  if (_items.isNotEmpty)
                    TextButton.icon(
                      onPressed: _analyzeAll,
                      icon: Icon(Icons.auto_awesome, color: colors.primary),
                      label: Text('AI Auto-fill All', style: TextStyle(color: colors.primary)),
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
                      separatorBuilder: (_, __) => Divider(height: 32, color: cs.onSurface.withAlpha(26)),
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
            color: cs.onSurface.withAlpha(26),
            borderRadius: BorderRadius.circular(8),
            image: !item.isLive ? DecorationImage(image: FileImage(item.file), fit: BoxFit.cover) : null,
          ),
          child: item.isLive ? Icon(Icons.videocam, color: cs.onSurface.withAlpha(60)) : null,
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
                  if (item.isAnalyzing) ...[
                    const SizedBox(width: 8),
                    const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                  ],
                  IconButton(
                    icon: Icon(Icons.delete_outline, color: cs.error),
                    onPressed: () => setState(() => _items.remove(item)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: MultiSelectChipField(
                      label: 'Tags',
                      selectedItems: item.selectedTags,
                      suggestions: widget.existingTags,
                      onAdded: (tag) => setState(() => item.selectedTags.add(tag)),
                      onAddPressed: () async {
                        final result = await showDialog<List<String>>(
                          context: context,
                          builder: (context) => TagSelectionDialog(
                            initialSelected: item.selectedTags,
                            existingTags: widget.existingTags,
                          ),
                        );
                        if (result != null) {
                          setState(() => item.selectedTags = result);
                        }
                      },
                      onDeleted: (tag) => setState(() => item.selectedTags.remove(tag)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: MultiSelectChipField(
                      label: 'Colors',
                      isColor: true,
                      selectedItems: item.selectedColors,
                      suggestions: widget.existingColors,
                      onAdded: (color) => setState(() => item.selectedColors.add(color)),
                      onAddPressed: () async {
                        final result = await showDialog<List<String>>(
                          context: context,
                          builder: (context) => ColorSelectionDialog(
                            initialSelected: item.selectedColors,
                          ),
                        );
                        if (result != null) {
                          setState(() => item.selectedColors = result);
                        }
                      },
                      onDeleted: (color) => setState(() => item.selectedColors.remove(color)),
                    ),
                  ),
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
}

class _BatchItem {
  final File file;
  final TextEditingController nameController;
  List<String> selectedTags;
  final TextEditingController urlController;
  final TextEditingController thumbnailController;
  List<String> selectedColors;
  final TextEditingController videoUrlController;
  final TextEditingController previewVideoController;
  final TextEditingController typeController;
  final TextEditingController categoryController;
  bool isPremium = false;
  bool isAnalyzing = false;
  bool isProcessed = false;
  bool isLive;
  final String taskId;

  _BatchItem({
    required this.file,
    required this.nameController,
    required this.selectedTags,
    required this.urlController,
    required this.thumbnailController,
    required this.selectedColors,
    required this.videoUrlController,
    required this.previewVideoController,
    required this.typeController,
    required this.categoryController,
    this.isLive = false,
    required this.taskId,
  });

  void dispose() {
    nameController.dispose();
    urlController.dispose();
    thumbnailController.dispose();
    categoryController.dispose();
    videoUrlController.dispose();
    previewVideoController.dispose();
    typeController.dispose();
  }
}
