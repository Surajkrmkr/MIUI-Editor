import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:miui_icon_generator/core/theme/theme_extensions.dart';
import 'package:path/path.dart' as p;
import '../../application/providers/buffy_cms_provider.dart';
import '../../domain/models/buffy_wallpaper.dart';
import '../../shared/utils/constants.dart';

class BuffyWallpaperForm extends ConsumerStatefulWidget {
  final BuffyWallpaper? initialWallpaper;
  final List<String> existingTags;
  final List<String> existingColors;

  const BuffyWallpaperForm({
    super.key,
    this.initialWallpaper,
    this.existingTags = const [],
    this.existingColors = const [],
  });

  @override
  ConsumerState<BuffyWallpaperForm> createState() => _BuffyWallpaperFormState();
}

class _BuffyWallpaperFormState extends ConsumerState<BuffyWallpaperForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _idController;
  late TextEditingController _nameController;
  late TextEditingController _categoryController;
  late TextEditingController _designerController;
  late TextEditingController _imageUrlController;
  late TextEditingController _compressUrlController;
  late TextEditingController _tagsController;
  late TextEditingController _colorsController;
  late bool _isHot;
  late bool _isPremium;

  final _tagsFocusNode = FocusNode();
  final _colorsFocusNode = FocusNode();
  File? _localFile;

  @override
  void initState() {
    super.initState();
    final w = widget.initialWallpaper;
    _idController = TextEditingController(text: w?.id.toString() ?? '');
    _nameController = TextEditingController(text: w?.name ?? '');
    _categoryController = TextEditingController(text: w?.category ?? '');
    _designerController = TextEditingController(text: w?.designer ?? 'Buffy');
    _imageUrlController = TextEditingController(text: w?.imageUrl ?? '');
    _compressUrlController = TextEditingController(text: w?.compressUrl ?? '');
    _tagsController = TextEditingController(text: w?.tags.join(', ') ?? '');
    _colorsController = TextEditingController(text: w?.colors.join(', ') ?? '');
    _isHot = w?.isHot ?? false;
    _isPremium = w?.isPremium ?? false;

    _nameController.addListener(_autofillUrls);
    _categoryController.addListener(_autofillUrls);
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'webp'],
      allowMultiple: false,
    );

    if (result != null && result.files.single.path != null) {
      final path = result.files.single.path!;
      setState(() {
        _localFile = File(path);
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

  void _autofillUrls() {
    final name = _nameController.text.trim();
    final category = _categoryController.text.trim();
    if (name.isNotEmpty && category.isNotEmpty) {
      final normalizedName = Uri.encodeComponent(name);
      final normalizedCategory = Uri.encodeComponent(category);
      
      final expectedImg = 'https://gitlab.com/piyushkpv/buffy_wall_data/-/raw/main/$normalizedCategory/$normalizedName.jpg';
      final expectedThumb = 'https://gitlab.com/piyushkpv/buffy_wall_data/-/raw/main/$normalizedCategory/Thumbnails/$normalizedName-small.jpg';
      
      if (_imageUrlController.text != expectedImg) {
        _imageUrlController.text = expectedImg;
      }
      if (_compressUrlController.text != expectedThumb) {
        _compressUrlController.text = expectedThumb;
        setState(() {}); 
      }
    }
  }

  @override
  void dispose() {
    _idController.dispose();
    _nameController.dispose();
    _categoryController.dispose();
    _designerController.dispose();
    _imageUrlController.dispose();
    _compressUrlController.dispose();
    _tagsController.dispose();
    _colorsController.dispose();
    _tagsFocusNode.dispose();
    _colorsFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Dialog(
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SizedBox(
        width: 960,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildDialogHeader(colors),
            SizedBox(
              height: 540,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildPreviewPanel(colors),
                  VerticalDivider(width: 1, color: colors.borderSubtle),
                  Expanded(child: _buildFormPanel(colors)),
                ],
              ),
            ),
            _buildDialogFooter(colors),
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
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: colors.bg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: colors.borderSubtle),
                ),
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (_localFile != null)
                      Image.file(_localFile!, fit: BoxFit.cover)
                    else if (_compressUrlController.text.isNotEmpty)
                      Image.network(
                        _compressUrlController.text,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Center(
                          child: Icon(Icons.broken_image_rounded, color: colors.textDisabled, size: 36),
                        ),
                      )
                    else
                      Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.image_outlined, color: colors.textDisabled, size: 36),
                            const SizedBox(height: 8),
                            Text('No preview', style: TextStyle(color: colors.textDisabled, fontSize: 11)),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: _pickFile,
              icon: const Icon(Icons.image_rounded, size: 15),
              label: Text(
                _localFile == null ? 'Select Image' : 'Change File',
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
            const Spacer(),
            Divider(color: colors.borderSubtle),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Premium', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Hot', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
                Transform.scale(
                  scale: 0.82,
                  alignment: Alignment.centerRight,
                  child: Switch(
                    value: _isHot,
                    activeTrackColor: Colors.orange,
                    onChanged: (v) => setState(() => _isHot = v),
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
                  flex: 1,
                  child: _buildTextField(
                    controller: _idController,
                    label: 'ID',
                    hint: 'e.g. 1234',
                  ),
                ),
                const SizedBox(width: 16),
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
            _buildTextField(
              controller: _imageUrlController,
              label: 'Image URL',
              hint: 'Direct link to the high-resolution image',
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _compressUrlController,
              label: 'Thumbnail URL',
              onChanged: (v) => setState(() {}),
            ),
            const SizedBox(height: 16),
            _buildTagsField(),
            const SizedBox(height: 16),
            _buildColorsField(),
            const SizedBox(height: 16),
            _buildTextField(controller: _designerController, label: 'Designer'),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
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
          decoration: InputDecoration(hintText: hint),
          validator: (v) => v?.isEmpty == true ? 'Required' : null,
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
            if (value.text.isEmpty) return kBuffyCategories;
            return kBuffyCategories.where(
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
              validator: (v) => v?.isEmpty == true ? 'Required' : null,
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
            color: colors.surface,
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

  Widget _buildDialogFooter(AppColorScheme colors) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 18),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: colors.borderSubtle)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: colors.textSecondary)),
          ),
          const SizedBox(width: 12),
          SizedBox(
            height: 40,
            child: FilledButton.icon(
              onPressed: _submit,
              icon: const Icon(Icons.check_rounded, size: 17),
              label: const Text('Save Wallpaper'),
            ),
          ),
        ],
      ),
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    
    // We try to auto-calculate the ID if adding new
    int id = int.tryParse(_idController.text.trim()) ?? 0;
    if (id == 0 && widget.initialWallpaper == null) {
       final state = ref.read(buffyCmsProvider);
       if (state.wallpapers.isNotEmpty) {
           id = state.wallpapers.map((e) => e.id).reduce((a, b) => a > b ? a : b) + 1;
       } else {
           id = 1;
       }
    }

    final w = BuffyWallpaper(
      id: id,
      name: _nameController.text.trim(),
      category: _categoryController.text.trim(),
      designer: _designerController.text.trim(),
      imageUrl: _imageUrlController.text.trim(),
      compressUrl: _compressUrlController.text.trim(),
      tags: _tagsController.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
      colors: _colorsController.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
      isHot: _isHot,
      isPremium: _isPremium,
    );
    
    final notifier = ref.read(buffyCmsProvider.notifier);
    if (widget.initialWallpaper == null) {
      notifier.addWallpaper(w);
    } else {
      notifier.updateWallpaper(w);
    }
    
    Navigator.pop(context);
  }
}
