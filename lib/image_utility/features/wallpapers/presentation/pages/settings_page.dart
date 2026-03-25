import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:miui_icon_generator/core/theme/app_theme.dart';
import 'package:miui_icon_generator/image_utility/core/config/app_config.dart';
import 'package:miui_icon_generator/image_utility/features/wallpapers/presentation/providers/wallpaper_providers.dart';
import 'package:path_provider/path_provider.dart';

// ── Provider ──────────────────────────────────────────────────────────────────

final appConfigProvider = FutureProvider<AppConfig>((ref) async {
  return await AppConfig.initialize();
});

// ── Public helper — show the dialog ──────────────────────────────────────────

Future<void> showImageUtilitySettings(BuildContext context) {
  return showDialog(
    context: context,
    builder: (_) => const _SettingsDialog(),
  );
}

// ── Keep the old SettingsPage class as a thin wrapper so the router doesn't break
class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Auto-show dialog and pop the route immediately
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showImageUtilitySettings(context);
    });
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}

// ── Dialog widget ─────────────────────────────────────────────────────────────

class _SettingsDialog extends ConsumerStatefulWidget {
  const _SettingsDialog();

  @override
  ConsumerState<_SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends ConsumerState<_SettingsDialog>
    with SingleTickerProviderStateMixin {
  final _pexelsCtrl     = TextEditingController();
  final _unsplashCtrl   = TextEditingController();
  final _pixabayCtrl    = TextEditingController();
  final _fireflyCtrl    = TextEditingController();
  final _geminiCtrl     = TextEditingController();
  final _upscaylCtrl    = TextEditingController();
  final _downloadCtrl   = TextEditingController();
  final _tagsCtrl       = TextEditingController();
  final _copyrightCtrl  = TextEditingController();

  bool _loaded = false;
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _pexelsCtrl.dispose();
    _unsplashCtrl.dispose();
    _pixabayCtrl.dispose();
    _fireflyCtrl.dispose();
    _geminiCtrl.dispose();
    _upscaylCtrl.dispose();
    _downloadCtrl.dispose();
    _tagsCtrl.dispose();
    _copyrightCtrl.dispose();
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _load(AppConfig config) async {
    if (_loaded) return;
    _loaded = true;
    _pexelsCtrl.text    = config.pexelsApiKey ?? '';
    _unsplashCtrl.text  = config.unsplashApiKey ?? '';
    _pixabayCtrl.text   = config.pixabayApiKey ?? '';
    _fireflyCtrl.text   = config.fireflyApiKey ?? '';
    _geminiCtrl.text    = config.geminiApiKey ?? '';
    _upscaylCtrl.text   = config.upscaylApiKey ?? '';
    final appDir = await getApplicationDocumentsDirectory();
    _downloadCtrl.text  = config.downloadPath  ?? '${appDir.path}/wallpapers';
    _tagsCtrl.text      = config.tagsPath      ?? '${appDir.path}/tags';
    _copyrightCtrl.text = config.copyrightPath ?? '${appDir.path}/copyright';
  }

  Future<void> _save(AppConfig config) async {
    await config.setPexelsApiKey(_pexelsCtrl.text.trim());
    await config.setUnsplashApiKey(_unsplashCtrl.text.trim());
    await config.setPixabayApiKey(_pixabayCtrl.text.trim());
    await config.setFireflyApiKey(_fireflyCtrl.text.trim());
    await config.setGeminiApiKey(_geminiCtrl.text.trim());
    await config.setUpscaylApiKey(_upscaylCtrl.text.trim());
    await config.setDownloadPath(_downloadCtrl.text.trim());
    await config.setTagsPath(_tagsCtrl.text.trim());
    await config.setCopyrightPath(_copyrightCtrl.text.trim());
    await _createDirs();
    ref.read(wallpaperNotifierProvider.notifier).initializeProviders();
    if (mounted) Navigator.pop(context);
  }

  Future<void> _createDirs() async {
    for (final p in [
      _downloadCtrl.text.trim(),
      _tagsCtrl.text.trim(),
      _copyrightCtrl.text.trim(),
    ]) {
      if (p.isNotEmpty) {
        final d = Directory(p);
        if (!await d.exists()) await d.create(recursive: true);
      }
    }
  }

  Future<void> _clearKeys(AppConfig config) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Clear All API Keys?'),
        content: const Text('This will remove all configured API keys.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Clear')),
        ],
      ),
    );
    if (confirmed == true) {
      await config.clearAllKeys();
      _pexelsCtrl.clear();
      _unsplashCtrl.clear();
      _pixabayCtrl.clear();
      _fireflyCtrl.clear();
      _geminiCtrl.clear();
      _upscaylCtrl.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final configAsync = ref.watch(appConfigProvider);
    final cs = Theme.of(context).colorScheme;

    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560, maxHeight: 700),
        child: Column(
          children: [
            // ── Header ───────────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(24, 20, 16, 0),
              decoration: BoxDecoration(
                color: AppTheme.accent.withAlpha(20),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
                border: Border(
                    bottom: BorderSide(color: cs.outline.withAlpha(40))),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.settings_rounded, color: AppTheme.accent),
                      const SizedBox(width: 12),
                      Text('Image Utility Settings',
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(fontWeight: FontWeight.w600)),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.pop(context),
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TabBar(
                    controller: _tabCtrl,
                    tabs: const [
                      Tab(icon: Icon(Icons.key_rounded, size: 16), text: 'API Keys'),
                      Tab(icon: Icon(Icons.folder_outlined, size: 16), text: 'File Paths'),
                    ],
                    labelColor: AppTheme.accent,
                    unselectedLabelColor: cs.onSurfaceVariant,
                    indicatorColor: AppTheme.accent,
                    dividerColor: Colors.transparent,
                    labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),

            // ── Body ─────────────────────────────────────────────────────────
            Expanded(
              child: configAsync.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Error: $e')),
                data: (config) {
                  Future.microtask(() => _load(config));
                  return TabBarView(
                    controller: _tabCtrl,
                    children: [
                      _ApiKeysTab(
                        pexels: _pexelsCtrl,
                        unsplash: _unsplashCtrl,
                        pixabay: _pixabayCtrl,
                        gemini: _geminiCtrl,
                        upscayl: _upscaylCtrl,
                        firefly: _fireflyCtrl,
                      ),
                      _FilePathsTab(
                        download: _downloadCtrl,
                        tags: _tagsCtrl,
                        copyright: _copyrightCtrl,
                      ),
                    ],
                  );
                },
              ),
            ),

            // ── Footer ───────────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: cs.outline.withAlpha(30))),
              ),
              child: configAsync.maybeWhen(
                data: (config) => Row(
                  children: [
                    OutlinedButton.icon(
                      icon: const Icon(Icons.delete_outline_rounded, size: 16),
                      label: const Text('Clear API Keys'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: cs.error,
                        side: BorderSide(color: cs.error.withAlpha(80)),
                      ),
                      onPressed: () => _clearKeys(config),
                    ),
                    const Spacer(),
                    FilledButton.icon(
                      icon: const Icon(Icons.check_rounded, size: 18),
                      label: const Text('Save & Close'),
                      onPressed: () => _save(config),
                    ),
                  ],
                ),
                orElse: () => const SizedBox.shrink(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── API Keys tab ──────────────────────────────────────────────────────────────

class _ApiKeysTab extends StatelessWidget {
  const _ApiKeysTab({
    required this.pexels,
    required this.unsplash,
    required this.pixabay,
    required this.gemini,
    required this.upscayl,
    required this.firefly,
  });

  final TextEditingController pexels, unsplash, pixabay, gemini, upscayl, firefly;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      children: [
        _sectionLabel(context, 'Image Sources'),
        const SizedBox(height: 12),
        _ApiKeyField(ctrl: pexels,   label: 'Pexels',   hint: 'pexels_xxxxxxxxxx'),
        _ApiKeyField(ctrl: unsplash, label: 'Unsplash', hint: 'Access key from unsplash.com'),
        _ApiKeyField(ctrl: pixabay,  label: 'Pixabay',  hint: 'pixabay_xxxxxxxxxx'),
        const SizedBox(height: 20),
        _sectionLabel(context, 'AI Services'),
        const SizedBox(height: 12),
        _ApiKeyField(ctrl: gemini,   label: 'Gemini',   hint: 'AI naming & tagging'),
        _ApiKeyField(ctrl: upscayl,  label: 'Upscayl',  hint: 'AI upscaling'),
        _ApiKeyField(
          ctrl: firefly,
          label: 'Adobe Firefly',
          hint: 'Coming soon…',
          enabled: false,
        ),
        const SizedBox(height: 12),
        const _InfoCard(items: [
          'Crop with 6:13 ratio before download',
          'Saved as 1080×2340 JPG',
          'AI names up to 10 characters',
          'Tags saved per-wallpaper',
        ]),
      ],
    );
  }

  Widget _sectionLabel(BuildContext context, String text) => Text(
        text,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: AppTheme.accent,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.8,
            ),
      );
}

// ── File Paths tab ────────────────────────────────────────────────────────────

class _FilePathsTab extends StatelessWidget {
  const _FilePathsTab({
    required this.download,
    required this.tags,
    required this.copyright,
  });

  final TextEditingController download, tags, copyright;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      children: [
        Text(
          'Configure where files will be saved on disk.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 20),
        _PathField(
          ctrl: download,
          label: 'Wallpapers Download Path',
          hint: '/path/to/wallpapers',
        ),
        _PathField(
          ctrl: tags,
          label: 'Tags Directory',
          hint: '/path/to/tags',
          helper: 'Where .txt tag files are saved',
        ),
        _PathField(
          ctrl: copyright,
          label: 'Copyright Files Path',
          hint: '/path/to/copyright',
          helper: 'Where .zip copyright files are saved',
        ),
      ],
    );
  }
}

// ── Reusable field widgets ────────────────────────────────────────────────────

class _ApiKeyField extends StatefulWidget {
  const _ApiKeyField({
    required this.ctrl,
    required this.label,
    required this.hint,
    this.enabled = true,
  });

  final TextEditingController ctrl;
  final String label;
  final String hint;
  final bool enabled;

  @override
  State<_ApiKeyField> createState() => _ApiKeyFieldState();
}

class _ApiKeyFieldState extends State<_ApiKeyField> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: widget.ctrl,
        obscureText: _obscure && widget.enabled,
        enabled: widget.enabled,
        decoration: InputDecoration(
          labelText: widget.label,
          hintText: widget.hint,
          prefixIcon: const Icon(Icons.vpn_key_outlined, size: 16),
          suffixIcon: widget.enabled
              ? IconButton(
                  icon: Icon(
                    _obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                    size: 18,
                  ),
                  onPressed: () => setState(() => _obscure = !_obscure),
                )
              : null,
        ),
      ),
    );
  }
}

class _PathField extends StatelessWidget {
  const _PathField({
    required this.ctrl,
    required this.label,
    required this.hint,
    this.helper,
  });

  final TextEditingController ctrl;
  final String label;
  final String hint;
  final String? helper;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: ctrl,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          helperText: helper,
          prefixIcon: const Icon(Icons.folder_outlined, size: 16),
          suffixIcon: IconButton(
            icon: const Icon(Icons.edit_outlined, size: 16),
            onPressed: () => _editPath(context),
          ),
        ),
      ),
    );
  }

  Future<void> _editPath(BuildContext context) async {
    final result = await showDialog<String>(
      context: context,
      builder: (_) => _InlinePathDialog(title: label, initial: ctrl.text),
    );
    if (result != null) ctrl.text = result;
  }
}

class _InlinePathDialog extends StatefulWidget {
  const _InlinePathDialog({required this.title, required this.initial});
  final String title;
  final String initial;

  @override
  State<_InlinePathDialog> createState() => _InlinePathDialogState();
}

class _InlinePathDialogState extends State<_InlinePathDialog> {
  late final TextEditingController _c =
      TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _c,
        autofocus: true,
        decoration: const InputDecoration(
          hintText: '/path/to/directory',
          prefixIcon: Icon(Icons.folder_outlined, size: 16),
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(
            onPressed: () => Navigator.pop(context, _c.text),
            child: const Text('OK')),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.items});
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.primaryContainer.withAlpha(60),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.primary.withAlpha(50)),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.info_outline_rounded, color: cs.primary, size: 16),
            const SizedBox(width: 8),
            Text('Features',
                style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: cs.primary,
                    fontSize: 13)),
          ]),
          const SizedBox(height: 10),
          ...items.map((i) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text('• $i',
                    style: Theme.of(context).textTheme.bodySmall),
              )),
        ],
      ),
    );
  }
}
