import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:code_text_field/code_text_field.dart';
import 'package:highlight/languages/xml.dart';
import 'package:flutter_highlight/themes/vs2015.dart';
import 'package:miui_icon_generator/core/theme/app_theme.dart';
import '../../../../core/constants/path_constants.dart';
import '../../../providers/wallpaper_provider.dart';
import '../../../providers/service_providers.dart';

class ManifestEditorDialog extends ConsumerStatefulWidget {
  const ManifestEditorDialog({super.key});

  @override
  ConsumerState<ManifestEditorDialog> createState() => _ManifestEditorDialogState();
}

class _ManifestEditorDialogState extends ConsumerState<ManifestEditorDialog> {
  late CodeController _codeController;
  bool _isLoading = true;
  String? _filePath;

  @override
  void initState() {
    super.initState();
    _codeController = CodeController(
      language: xml,
    );
    _loadManifest();
  }

  Future<void> _loadManifest() async {
    final ws = ref.read(wallpaperProvider);
    if (ws.weekNum == null || ws.currentThemeName == null) {
      setState(() => _isLoading = false);
      return;
    }
    final tp = PathConstants.themePath(ws.weekNum!, ws.currentThemeName!);
    _filePath = '${PathConstants.lockscreenAdvance(tp)}manifest.xml';

    final fs = ref.read(fileServiceProvider);
    if (await fs.exists(_filePath!)) {
      final content = await fs.readString(_filePath!);
      _codeController.text = content;
    } else {
      _codeController.text = '<!-- manifest.xml not found. Please export first. -->';
    }
    setState(() => _isLoading = false);
  }

  Future<void> _saveManifest() async {
    if (_filePath == null) return;
    final fs = ref.read(fileServiceProvider);
    await fs.writeString(_filePath!, _codeController.text);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Manifest saved')),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    
    // Customizing theme to match app's navy style and rose accent
    final customTheme = Map<String, TextStyle>.from(vs2015Theme);
    customTheme['root'] = TextStyle(
      backgroundColor: AppTheme.scaffoldDark,
      color: Colors.white.withAlpha(220),
    );
    customTheme['tag'] = const TextStyle(color: AppTheme.accent);
    customTheme['keyword'] = const TextStyle(color: AppTheme.accent);
    customTheme['selector-tag'] = const TextStyle(color: AppTheme.accent);
    customTheme['attr'] = const TextStyle(color: Color(0xFF569CD6)); // VS Code blue for attributes
    customTheme['string'] = const TextStyle(color: Color(0xFFCE9178)); // VS Code orange for strings

    return AlertDialog(
      title: const Text('Manifest Editor'),
      backgroundColor: AppTheme.cardDark,
      surfaceTintColor: Colors.transparent,
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.9,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  Expanded(
                    child: Container(
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(
                        color: AppTheme.scaffoldDark,
                        border: Border.all(color: Colors.white.withAlpha(15)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: CodeTheme(
                        data: CodeThemeData(styles: customTheme),
                        child: CodeField(
                          controller: _codeController,
                          textStyle: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 14,
                            height: 1.5,
                          ),
                          lineNumberStyle: LineNumberStyle(
                            width: 65,
                            margin: 15,
                            textAlign: TextAlign.right,
                            textStyle: TextStyle(
                              color: Colors.white.withAlpha(40),
                              fontSize: 13,
                              height: 1.5,
                            ),
                          ),
                          background: AppTheme.scaffoldDark,
                          expands: true,
                          maxLines: null,
                          wrap: false,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
      ),
      actions: [
        TextButton.icon(
          onPressed: _loadManifest,
          icon: const Icon(Icons.refresh_rounded, size: 18),
          label: const Text('Reload'),
        ),
        const Spacer(),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            'Cancel',
            style: TextStyle(color: scheme.onSurfaceVariant),
          ),
        ),
        const SizedBox(width: 8),
        FilledButton.icon(
          onPressed: _saveManifest,
          icon: const Icon(Icons.save_rounded, size: 18),
          label: const Text('Save Changes'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }
}

