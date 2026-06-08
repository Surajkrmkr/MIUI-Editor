import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:miui_icon_generator/core/theme/theme_extensions.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';
import '../../application/providers/ai_provider.dart';
import '../../application/providers/cms_provider.dart';
import '../../application/services/wallpaper_import_service.dart';
import '../../domain/models/ai_models.dart';
import '../../domain/models/wallpaper.dart';

class WallpaperForm extends ConsumerStatefulWidget {
  final Wallpaper? initialWallpaper;
  final List<String> existingCategories;
  final List<String> existingTags;
  final List<String> existingColors;

  const WallpaperForm({
    super.key,
    this.initialWallpaper,
    required this.existingCategories,
    required this.existingTags,
    required this.existingColors,
  });

  @override
  ConsumerState<WallpaperForm> createState() => _WallpaperFormState();
}

class _WallpaperFormState extends ConsumerState<WallpaperForm> {
  final _formKey = GlobalKey<FormState>();
  bool _isImporting = false;
  late TextEditingController _nameController;
  late TextEditingController _urlController;
  late TextEditingController _thumbnailController;
  late TextEditingController _tagsController;
  late TextEditingController _categoryController;
  late TextEditingController _authorController;
  late TextEditingController _colorsController;
  late TextEditingController _videoUrlController;
  late TextEditingController _previewVideoController;
  late TextEditingController _typeController;
  late bool _isPremium;
  late bool _isLive;
  
  final _tagsFocusNode = FocusNode();
  final _colorsFocusNode = FocusNode();

  File? _localFile;
  File? _localThumbnailFile;
  
  final String _taskId = const Uuid().v4();

  @override
  void initState() {
    super.initState();
    final w = widget.initialWallpaper;
    _nameController = TextEditingController(text: w?.name ?? '');
    _urlController = TextEditingController(text: w?.url ?? '');
    _thumbnailController = TextEditingController(text: w?.thumbnail ?? '');
    _tagsController = TextEditingController(text: w?.tags.join(', ') ?? '');
    _categoryController = TextEditingController(text: w?.category ?? '');
    _authorController = TextEditingController(text: w?.author ?? 'WallRio');
    _colorsController = TextEditingController(text: w?.color.join(', ') ?? '');
    _videoUrlController = TextEditingController(text: w?.videoUrl ?? '');
    _previewVideoController = TextEditingController(text: w?.previewVideo ?? '');
    _typeController = TextEditingController(text: w?.type ?? '');
    _isPremium = w?.isPremium ?? false;
    _isLive = w?.videoUrl != null && w!.videoUrl!.isNotEmpty || w?.type == 'video' || w?.type == 'live';

    // Add listeners for real-time autofill
    _nameController.addListener(_onFieldsChanged);
    _categoryController.addListener(_onFieldsChanged);
  }

  void _onFieldsChanged() {
    if (_urlController.text.isEmpty || _urlController.text.contains(_categoryController.text) || _urlController.text.contains(_nameController.text)) {
      _autofillUrls();
    }
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'webp', 'mp4'],
      allowMultiple: false,
    );

    if (result != null && result.files.single.path != null) {
      final path = result.files.single.path!;
      final extension = p.extension(path).toLowerCase();
      
      setState(() {
        if (extension == '.mp4') {
          _isLive = true;
          _typeController.text = 'live';
          _localFile = File(path);
        } else {
          _localFile = File(path);
        }
        
        if (_nameController.text.isEmpty) {
          _nameController.text = p.basenameWithoutExtension(_localFile!.path)
              .split(RegExp(r'[-_ ]'))
              .map((s) => s.isNotEmpty ? s[0].toUpperCase() + s.substring(1) : '')
              .join(' ');
        }
        _autofillUrls();
      });
    }
  }

  Future<void> _pickThumbnail() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'webp'],
      allowMultiple: false,
    );

    if (result != null && result.files.single.path != null) {
      setState(() {
        _localThumbnailFile = File(result.files.single.path!);
      });
    }
  }

  void _autofillUrls() {
    final name = _nameController.text.trim();
    final category = _categoryController.text.trim();
    
    final cmsState = ref.read(cmsProvider);
    if (cmsState.value == null) return;

    final data = cmsState.value!;
    final baseUrl = _deduceBaseUrl(data.walls, false);
    final baseThumbUrl = _deduceBaseUrl(data.walls, true);

    if (baseUrl != null) {
      final ext = _isLive ? '.mp4' : _deduceExtension(data.walls);
      final includeCategory = _shouldIncludeCategory(data.walls);
      
      final normalizedName = Uri.encodeComponent(name);
      final normalizedCategory = Uri.encodeComponent(category);

      if (name.isNotEmpty) {
        String newUrl;
        if (includeCategory && category.isNotEmpty) {
          newUrl = '$baseUrl/$normalizedCategory/$normalizedName$ext';
        } else {
          newUrl = '$baseUrl/$normalizedName$ext';
        }
        
        if (_isLive) {
          if (_videoUrlController.text != newUrl) {
            _videoUrlController.text = newUrl;
          }
          if (_previewVideoController.text != newUrl) {
            _previewVideoController.text = newUrl;
          }
        } else {
          if (_urlController.text != newUrl) {
            _urlController.text = newUrl;
          }
        }

        if (baseThumbUrl != null) {
          String newThumbUrl;
          final thumbExt = _deduceExtension(data.walls, forThumbnail: true);
          if (includeCategory && category.isNotEmpty) {
            newThumbUrl = '$baseThumbUrl/$normalizedCategory/$normalizedName$thumbExt';
          } else {
            newThumbUrl = '$baseThumbUrl/$normalizedName$thumbExt';
          }
          if (_thumbnailController.text != newThumbUrl) {
            _thumbnailController.text = newThumbUrl;
            setState(() {}); 
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

  bool _shouldIncludeCategory(List<Wallpaper> walls) {
    if (walls.isEmpty) return true;
    int count = 0;
    for (final w in walls) {
      final pathToCheck = _isLive ? w.videoUrl ?? '' : w.url;
      if (w.category.isNotEmpty && pathToCheck.contains(w.category.replaceAll(' ', '%20'))) {
        count++;
      }
    }
    return count > walls.length / 2;
  }

  String? _deduceBaseUrl(List<Wallpaper> walls, bool isThumbnail) {
    final urls = walls
        .map((w) {
          if (isThumbnail) return w.thumbnail;
          if (_isLive) return w.videoUrl ?? w.url;
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

  @override
  void dispose() {
    _nameController.dispose();
    _urlController.dispose();
    _thumbnailController.dispose();
    _tagsController.dispose();
    _categoryController.dispose();
    _authorController.dispose();
    _colorsController.dispose();
    _videoUrlController.dispose();
    _previewVideoController.dispose();
    _typeController.dispose();
    _tagsFocusNode.dispose();
    _colorsFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final aiState = ref.watch(aiStateProvider);
    final task = aiState[_taskId];
    final colors = context.appColors;

    return Dialog(
      backgroundColor: colors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SizedBox(
        width: 960,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Header ───────────────────────────────────────────────────────
            _buildDialogHeader(colors),

            // ── Body ─────────────────────────────────────────────────────────
            if (_isImporting)
              _buildImportingState(colors)
            else
              SizedBox(
                height: 540,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Left: preview panel
                    _buildPreviewPanel(colors),
                    // Divider
                    VerticalDivider(width: 1, color: colors.borderSubtle),
                    // Right: form fields
                    Expanded(child: _buildFormPanel(colors)),
                  ],
                ),
              ),

            // ── Footer ───────────────────────────────────────────────────────
            _buildDialogFooter(task, colors),
          ],
        ),
      ),
    );
  }

  Widget _buildDialogHeader(AppColorScheme colors) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 18, 16, 14),
      decoration: BoxDecoration(
        color: colors.primary.withAlpha(18),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        border: Border(bottom: BorderSide(color: colors.borderSubtle)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colors.primary.withAlpha(25),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.wallpaper_rounded, color: colors.primary, size: 18),
          ),
          const SizedBox(width: 14),
          Text(
            widget.initialWallpaper == null ? 'Add Wallpaper' : 'Edit Wallpaper',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: colors.textPrimary,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: Icon(Icons.close_rounded, color: colors.textSecondary, size: 20),
            onPressed: () => Navigator.pop(context),
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }

  Widget _buildImportingState(AppColorScheme colors) {
    return SizedBox(
      height: 180,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(strokeWidth: 2),
            const SizedBox(height: 16),
            Text(
              'Processing Wallpaper...',
              style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              'Generating thumbnail and copying files.',
              style: TextStyle(color: colors.textSecondary, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewPanel(AppColorScheme colors) {
    return SizedBox(
      width: 280,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'PREVIEW',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: colors.textSecondary,
                letterSpacing: 1.1,
              ),
            ),
            const SizedBox(height: 12),

            // Main image / video preview — takes available height
            Expanded(
              flex: _isLive ? 2 : 3,
              child: _buildImagePreview(),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: _pickFile,
              icon: Icon(
                _isLive ? Icons.video_library_rounded : Icons.image_rounded,
                size: 15,
              ),
              label: Text(
                _localFile == null
                    ? (_isLive ? 'Select Video' : 'Select Image')
                    : 'Change File',
                style: const TextStyle(fontSize: 12),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: colors.primary,
                side: BorderSide(color: colors.primary.withAlpha(120)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(vertical: 8),
                visualDensity: VisualDensity.compact,
              ),
            ),

            if (_isLive) ...[
              const SizedBox(height: 14),
              Text(
                'THUMBNAIL',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: colors.textSecondary,
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                flex: 1,
                child: _buildThumbnailPreview(),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: _pickThumbnail,
                icon: const Icon(Icons.add_a_photo_rounded, size: 15),
                label: Text(
                  _localThumbnailFile == null ? 'Select Thumbnail' : 'Change Thumbnail',
                  style: const TextStyle(fontSize: 12),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.orangeAccent,
                  side: const BorderSide(color: Colors.orangeAccent),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ],

            const Spacer(),
            Divider(color: colors.borderSubtle),
            const SizedBox(height: 4),

            // Live toggle
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Live Wallpaper',
                    style: TextStyle(color: colors.textSecondary, fontSize: 12)),
                Transform.scale(
                  scale: 0.82,
                  alignment: Alignment.centerRight,
                  child: Switch(
                    value: _isLive,
                    activeTrackColor: colors.primary,
                    onChanged: (v) => setState(() {
                      _isLive = v;
                      if (v && _typeController.text.isEmpty) {
                        _typeController.text = 'live';
                      }
                      _autofillUrls();
                    }),
                  ),
                ),
              ],
            ),

            // Premium toggle
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Premium',
                    style: TextStyle(color: colors.textSecondary, fontSize: 12)),
                Transform.scale(
                  scale: 0.82,
                  alignment: Alignment.centerRight,
                  child: Switch(
                    value: _isPremium,
                    activeTrackColor: colors.primary,
                    onChanged: (v) => setState(() => _isPremium = v),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormPanel(AppColorScheme colors) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'DETAILS',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: colors.textSecondary,
                letterSpacing: 1.1,
              ),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: _buildTextField(
                    controller: _nameController,
                    label: 'Name',
                    hint: 'Wallpaper Name',
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: _buildCategoryDropdown(),
                ),
              ],
            ),
            const SizedBox(height: 16),

            if (!_isLive)
              _buildTextField(
                controller: _urlController,
                label: 'Image URL',
                hint: 'Direct link to the high-resolution image',
              ),

            if (_isLive) ...[
              _buildTextField(
                controller: _videoUrlController,
                label: 'Video URL (.mp4)',
                hint: 'URL to the full video file',
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _previewVideoController,
                label: 'Preview Video URL',
                hint: 'Often same as Video URL or a shorter version',
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _typeController,
                label: 'Type',
                hint: 'e.g. video',
              ),
            ],

            const SizedBox(height: 16),
            _buildTextField(
              controller: _thumbnailController,
              label: 'Thumbnail URL',
              onChanged: (v) => setState(() {}),
            ),
            const SizedBox(height: 16),
            _buildTagsField(),
            const SizedBox(height: 16),
            _buildColorsField(),
            const SizedBox(height: 16),
            _buildTextField(controller: _authorController, label: 'Author'),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildDialogFooter(dynamic task, AppColorScheme colors) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 18),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: colors.borderSubtle)),
      ),
      child: Row(
        children: [
          if (!_isLive)
            TextButton.icon(
              onPressed: _runAIAnalysis,
              icon: Icon(Icons.auto_awesome_rounded, color: colors.primary, size: 16),
              label: Text(
                task?.status == AITaskStatus.analyzing ? 'Analyzing...' : 'AI Auto-fill',
                style: TextStyle(color: colors.primary, fontSize: 13),
              ),
            ),
          if (task?.status == AITaskStatus.analyzing) ...[
            const SizedBox(width: 8),
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2, color: colors.primary),
            ),
          ],
          const Spacer(),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: colors.textSecondary)),
          ),
          const SizedBox(width: 12),
          SizedBox(
            height: 40,
            child: FilledButton.icon(
              onPressed: _isImporting ? null : _submit,
              icon: const Icon(Icons.check_rounded, size: 17),
              label: const Text('Save Wallpaper'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePreview() {
    final colors = context.appColors;
    return Container(
      decoration: BoxDecoration(
        color: colors.bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.borderSubtle),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (_localFile != null && !_isLive)
            Image.file(_localFile!, fit: BoxFit.cover)
          else if (_thumbnailController.text.isNotEmpty)
            Image.network(
              _thumbnailController.text,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Center(
                child: Icon(Icons.broken_image_rounded,
                    color: colors.textDisabled, size: 36),
              ),
            )
          else
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.image_outlined, color: colors.textDisabled, size: 36),
                  const SizedBox(height: 8),
                  Text('No preview',
                      style: TextStyle(color: colors.textDisabled, fontSize: 11)),
                ],
              ),
            ),
          if (_isLive)
            Positioned(
              top: 8,
              left: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: colors.primary.withAlpha(210),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.videocam_rounded, color: colors.onPrimary, size: 11),
                    const SizedBox(width: 4),
                    Text(
                      'LIVE',
                      style: TextStyle(
                        color: colors.onPrimary,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (_localFile != null && _isLive)
            Positioned(
              bottom: 8,
              left: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: colors.surfaceOverlay,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  p.basename(_localFile!.path),
                  style: TextStyle(color: colors.textPrimary, fontSize: 10),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildThumbnailPreview() {
    final colors = context.appColors;
    return Container(
      decoration: BoxDecoration(
        color: colors.bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colors.borderSubtle),
      ),
      clipBehavior: Clip.antiAlias,
      child: _localThumbnailFile != null
          ? Image.file(_localThumbnailFile!, fit: BoxFit.cover)
          : Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add_a_photo_rounded,
                      color: colors.textDisabled, size: 28),
                  const SizedBox(height: 6),
                  Text('No thumbnail',
                      style: TextStyle(color: colors.textDisabled, fontSize: 10)),
                ],
              ),
            ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    String? helper,
    Function(String)? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: context.appColors.textSecondary,
              ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: hint,
            helperText: helper,
          ),
          validator: (v) {
            if (_isLive && controller == _urlController) return null;
            return v?.isEmpty == true ? 'Required' : null;
          },
        ),
      ],
    );
  }

  Widget _buildCategoryDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Category',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: context.appColors.textSecondary,
              ),
        ),
        const SizedBox(height: 6),
        Autocomplete<String>(
          optionsBuilder: (TextEditingValue value) {
            if (value.text.isEmpty) return widget.existingCategories;
            return widget.existingCategories.where(
                (c) => c.toLowerCase().contains(value.text.toLowerCase()));
          },
          initialValue: TextEditingValue(text: _categoryController.text),
          onSelected: (v) => _categoryController.text = v,
          fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
            controller.addListener(() {
              _categoryController.text = controller.text;
            });
            return TextFormField(
              controller: controller,
              focusNode: focusNode,
              decoration: const InputDecoration(),
              onFieldSubmitted: (v) => onFieldSubmitted(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildTagsField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tags (comma separated)',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: context.appColors.textSecondary,
              ),
        ),
        const SizedBox(height: 6),
        _buildTextFieldWithSuggestions(
          controller: _tagsController,
          suggestions: widget.existingTags,
          focusNode: _tagsFocusNode,
        ),
      ],
    );
  }

  Widget _buildColorsField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Colors (comma separated hex)',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: context.appColors.textSecondary,
              ),
        ),
        const SizedBox(height: 6),
        _buildTextFieldWithSuggestions(
          controller: _colorsController,
          suggestions: widget.existingColors,
          focusNode: _colorsFocusNode,
        ),
      ],
    );
  }

  Widget _buildTextFieldWithSuggestions({
    required TextEditingController controller,
    required List<String> suggestions,
    required FocusNode focusNode,
  }) {
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
        return TextFormField(
          controller: controller,
          focusNode: focusNode,
          decoration: const InputDecoration(),
        );
      },
      optionsViewBuilder: (context, onSelected, options) {
        final colors = context.appColors;
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 4,
            color: colors.surfaceElevated,
            child: SizedBox(
              height: 200,
              width: 300,
              child: ListView.builder(
                padding: EdgeInsets.zero,
                itemCount: options.length,
                itemBuilder: (context, index) {
                  final option = options.elementAt(index);
                  return ListTile(
                    title: Text(option, style: TextStyle(color: colors.textPrimary)),
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

  Future<void> _runAIAnalysis() async {
    if (_localFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a local image first for AI analysis.')),
      );
      return;
    }

    try {
      await ref.read(aiStateProvider.notifier).analyzeImage(_taskId, _localFile!.path);
      final result = ref.read(aiStateProvider)[_taskId]?.result;
      
      if (result != null && mounted) {
        setState(() {
          _nameController.text = result.name;
          _tagsController.text = result.tags.join(', ');
          _colorsController.text = result.colors.join(', ');
          if (result.category != null) {
            _categoryController.text = result.category!;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('AI Error: $e')));
      }
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isImporting = true);
    try {
      if (_localFile != null && widget.initialWallpaper == null) {
        await ref.read(wallpaperImportServiceProvider.notifier).importWallpaper(
          file: _localFile!,
          category: _categoryController.text.trim(),
          name: _nameController.text.trim(),
          tags: _tagsController.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
          colors: _colorsController.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
          isPremium: _isPremium,
        );
      } else {
        final cmsState = ref.read(cmsProvider);
        final walls = cmsState.value?.walls ?? [];
        final nextId = walls.isEmpty ? 1 : walls.map((w) => (w.id is int) ? (w.id as int) : int.tryParse(w.id.toString()) ?? 0).reduce((a, b) => a > b ? a : b) + 1;

        final wallpaper = Wallpaper(
          id: widget.initialWallpaper?.id ?? nextId,
          name: _nameController.text.trim(),
          author: _authorController.text.trim(),
          url: _urlController.text.trim(),
          thumbnail: _thumbnailController.text.trim(),
          tags: _tagsController.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
          category: _categoryController.text.trim(),
          color: _colorsController.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
          isPremium: _isPremium,
          subjectId: widget.initialWallpaper?.subjectId ?? const Uuid().v4(),
          videoUrl: _isLive ? _videoUrlController.text.trim() : null,
          previewVideo: _isLive ? _previewVideoController.text.trim() : null,
          type: _isLive ? _typeController.text.trim() : null,
        );

        if (widget.initialWallpaper == null) {
          ref.read(cmsProvider.notifier).addWallpaper(wallpaper);
        } else {
          ref.read(cmsProvider.notifier).editWallpaper(wallpaper);
        }
      }
      
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isImporting = false);
      }
    }
  }
}
