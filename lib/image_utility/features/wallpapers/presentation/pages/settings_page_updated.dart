import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:miui_icon_generator/image_utility/core/config/app_config.dart';
import 'package:miui_icon_generator/image_utility/features/wallpapers/presentation/providers/wallpaper_providers.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

final appConfigProvider = FutureProvider<AppConfig>((ref) async {
  return await AppConfig.initialize();
});

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  final _pexelsController = TextEditingController();
  final _unsplashController = TextEditingController();
  final _pixabayController = TextEditingController();
  final _fireflyController = TextEditingController();
  final _geminiController = TextEditingController();
  final _upscaylController = TextEditingController();
  final _downloadPathController = TextEditingController();
  final _tagsPathController = TextEditingController();
  final _copyrightPathController = TextEditingController();

  @override
  void dispose() {
    _pexelsController.dispose();
    _unsplashController.dispose();
    _pixabayController.dispose();
    _fireflyController.dispose();
    _geminiController.dispose();
    _upscaylController.dispose();
    _downloadPathController.dispose();
    _tagsPathController.dispose();
    _copyrightPathController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings(AppConfig config) async {
    _pexelsController.text = config.pexelsApiKey ?? '';
    _unsplashController.text = config.unsplashApiKey ?? '';
    _pixabayController.text = config.pixabayApiKey ?? '';
    _fireflyController.text = config.fireflyApiKey ?? '';
    _geminiController.text = config.geminiApiKey ?? '';
    _upscaylController.text = config.upscaylApiKey ?? '';

    // Set default paths
    final appDir = await getApplicationDocumentsDirectory();
    _downloadPathController.text =
        config.downloadPath ?? '${appDir.path}/wallpapers';
    _tagsPathController.text =
        config.tagsPath ?? '${appDir.path}/tags'; // Changed from tagsJsonPath
    _copyrightPathController.text =
        config.copyrightPath ?? '${appDir.path}/copyright';
  }

  Future<void> _saveSettings(AppConfig config) async {
    await config.setPexelsApiKey(_pexelsController.text.trim());
    await config.setUnsplashApiKey(_unsplashController.text.trim());
    await config.setPixabayApiKey(_pixabayController.text.trim());
    await config.setFireflyApiKey(_fireflyController.text.trim());
    await config.setGeminiApiKey(_geminiController.text.trim());
    await config.setUpscaylApiKey(_upscaylController.text.trim());
    await config.setDownloadPath(_downloadPathController.text.trim());
    await config.setTagsPath(_tagsPathController.text.trim()); // Changed
    await config.setCopyrightPath(_copyrightPathController.text.trim());

    // Create directories if they don't exist
    await _createDirectories();

    // Reinitialize providers
    ref.read(wallpaperNotifierProvider.notifier).initializeProviders();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Settings saved successfully')),
      );
    }
  }

  Future<void> _createDirectories() async {
    final dirs = [
      _downloadPathController.text.trim(),
      _tagsPathController.text.trim(), // Added tags directory
      _copyrightPathController.text.trim(),
    ];

    for (final dirPath in dirs) {
      if (dirPath.isNotEmpty) {
        final dir = Directory(dirPath);
        if (!await dir.exists()) {
          await dir.create(recursive: true);
        }
      }
    }
  }

  Future<void> _selectPath(
      TextEditingController controller, String title) async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) => _PathDialog(
        title: title,
        initialPath: controller.text,
      ),
    );

    if (result != null) {
      controller.text = result;
    }
  }

  @override
  Widget build(BuildContext context) {
    final configAsync = ref.watch(appConfigProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: configAsync.when(
        data: (config) {
          if (_pexelsController.text.isEmpty && config.pexelsApiKey != null) {
            Future.microtask(() => _loadSettings(config));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // API Keys Section
                _buildSectionHeader(context, 'API Keys'),
                const Text(
                  'Configure your API keys for different image sources',
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 16),

                _buildTextField(
                  controller: _pexelsController,
                  label: 'Pexels API Key',
                  hint: 'Enter your Pexels API key',
                  helper: 'Get it from: https://www.pexels.com/api/',
                  obscure: true,
                ),
                const SizedBox(height: 12),

                _buildTextField(
                  controller: _unsplashController,
                  label: 'Unsplash API Key',
                  hint: 'Enter your Unsplash Access Key',
                  helper: 'Get it from: https://unsplash.com/developers',
                  obscure: true,
                ),
                const SizedBox(height: 12),

                _buildTextField(
                  controller: _pixabayController,
                  label: 'Pixabay API Key',
                  hint: 'Enter your Pixabay API key',
                  helper: 'Get it from: https://pixabay.com/api/docs/',
                  obscure: true,
                ),
                const SizedBox(height: 12),

                _buildTextField(
                  controller: _geminiController,
                  label: 'Gemini API Key',
                  hint: 'Enter your Gemini API key',
                  helper: 'Required for AI naming and tagging',
                  obscure: true,
                ),
                const SizedBox(height: 12),

                _buildTextField(
                  controller: _upscaylController,
                  label: 'Upscayl API Key',
                  hint: 'Enter your Upscayl API key',
                  helper: 'Required for AI upscaling in image generation',
                  obscure: true,
                ),
                const SizedBox(height: 12),

                _buildTextField(
                  controller: _fireflyController,
                  label: 'Adobe Firefly API Key (Coming Soon)',
                  hint: 'Enter your Adobe Firefly API key',
                  helper: 'AI-generated images',
                  obscure: true,
                  enabled: false,
                ),
                const SizedBox(height: 32),

                // Paths Section
                _buildSectionHeader(context, 'File Paths'),
                const Text(
                  'Configure where files will be saved',
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 16),

                _buildPathField(
                  controller: _downloadPathController,
                  label: 'Wallpapers Download Path',
                  hint: '/path/to/wallpapers',
                  onTap: () => _selectPath(
                      _downloadPathController, 'Select Download Path'),
                ),
                const SizedBox(height: 12),

                _buildPathField(
                  controller: _tagsPathController,
                  label: 'Tags Directory Path', // Changed label
                  hint: '/path/to/tags',
                  helper:
                      'Directory where tag files will be saved', // Changed helper
                  onTap: () =>
                      _selectPath(_tagsPathController, 'Select Tags Directory'),
                ),
                const SizedBox(height: 12),

                _buildPathField(
                  controller: _copyrightPathController,
                  label: 'Copyright Files Path',
                  hint: '/path/to/copyright',
                  helper: 'Where copyright zip files will be saved',
                  onTap: () => _selectPath(
                      _copyrightPathController, 'Select Copyright Path'),
                ),
                const SizedBox(height: 32),

                // Info Section
                _buildInfoCard(),
                const SizedBox(height: 32),

                // Save Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _saveSettings(config),
                    child: const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text('Save Settings'),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Clear Button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Clear All API Keys?'),
                          content: const Text(
                            'This will remove all configured API keys.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text('Clear'),
                            ),
                          ],
                        ),
                      );

                      if (confirm == true) {
                        await config.clearAllKeys();
                        _pexelsController.clear();
                        _unsplashController.clear();
                        _pixabayController.clear();
                        _fireflyController.clear();
                        _geminiController.clear();
                        _upscaylController.clear();

                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('All API keys cleared'),
                            ),
                          );
                        }
                      }
                    },
                    child: const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text('Clear All API Keys'),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('Error loading settings: $error'),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.headlineSmall,
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    String? helper,
    bool obscure = false,
    bool enabled = true,
  }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        helperText: helper,
        helperMaxLines: 2,
      ),
      obscureText: obscure,
      enabled: enabled,
    );
  }

  Widget _buildPathField({
    required TextEditingController controller,
    required String label,
    required String hint,
    String? helper,
    required VoidCallback onTap,
  }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        helperText: helper,
        helperMaxLines: 2,
        suffixIcon: IconButton(
          icon: const Icon(Icons.folder_open),
          onPressed: onTap,
        ),
      ),
      readOnly: true,
      onTap: onTap,
    );
  }

  Widget _buildInfoCard() {
    return const Card(
      color: Colors.blueGrey,
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: Colors.white),
                SizedBox(width: 8),
                Text(
                  'Feature Information',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Text('• Manual crop with 6:13 ratio before download'),
            Text('• Downloaded images saved as 1080×2340 JPG'),
            Text('• AI generates creative names (max 10 chars)'),
            Text('• Tags saved in separate tags directory'),
            Text('• Copyright info saved as .zip files'),
          ],
        ),
      ),
    );
  }
}

class _PathDialog extends StatefulWidget {
  final String title;
  final String initialPath;

  const _PathDialog({
    required this.title,
    required this.initialPath,
  });

  @override
  State<_PathDialog> createState() => _PathDialogState();
}

class _PathDialogState extends State<_PathDialog> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialPath);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _controller,
        decoration: const InputDecoration(
          labelText: 'Path',
          hintText: '/path/to/directory',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, _controller.text),
          child: const Text('OK'),
        ),
      ],
    );
  }
}
