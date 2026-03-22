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
  final _downloadPathController = TextEditingController();

  @override
  void dispose() {
    _pexelsController.dispose();
    _unsplashController.dispose();
    _pixabayController.dispose();
    _fireflyController.dispose();
    _downloadPathController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings(AppConfig config) async {
    _pexelsController.text = config.pexelsApiKey ?? '';
    _unsplashController.text = config.unsplashApiKey ?? '';
    _pixabayController.text = config.pixabayApiKey ?? '';
    _fireflyController.text = config.fireflyApiKey ?? '';

    // Set default download path
    final appDir = await getApplicationDocumentsDirectory();
    final defaultPath = '${appDir.path}/wallpapers';
    _downloadPathController.text = config.downloadPath ?? defaultPath;
  }

  Future<void> _saveSettings(AppConfig config) async {
    await config.setPexelsApiKey(_pexelsController.text.trim());
    await config.setUnsplashApiKey(_unsplashController.text.trim());
    await config.setPixabayApiKey(_pixabayController.text.trim());
    await config.setFireflyApiKey(_fireflyController.text.trim());
    await config.setDownloadPath(_downloadPathController.text.trim());

    // Reinitialize providers
    ref.read(wallpaperNotifierProvider.notifier).initializeProviders();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Settings saved successfully')),
      );
    }
  }

  Future<void> _selectDownloadPath() async {
    // For now, just show a dialog. In production, use file_picker package
    final controller =
        TextEditingController(text: _downloadPathController.text);

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Download Path'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Path',
            hintText: '/path/to/wallpapers',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('OK'),
          ),
        ],
      ),
    );

    if (result != null) {
      _downloadPathController.text = result;
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
          // Load settings once
          if (_pexelsController.text.isEmpty && config.pexelsApiKey != null) {
            Future.microtask(() => _loadSettings(config));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'API Keys',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  'Configure your API keys for different image sources',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
                const SizedBox(height: 24),

                // Pexels API Key
                TextField(
                  controller: _pexelsController,
                  decoration: const InputDecoration(
                    labelText: 'Pexels API Key',
                    hintText: 'Enter your Pexels API key',
                    helperText: 'Get it from: https://www.pexels.com/api/',
                  ),
                  obscureText: true,
                ),
                const SizedBox(height: 16),

                // Unsplash API Key
                TextField(
                  controller: _unsplashController,
                  decoration: const InputDecoration(
                    labelText: 'Unsplash API Key',
                    hintText: 'Enter your Unsplash Access Key',
                    helperText: 'Get it from: https://unsplash.com/developers',
                  ),
                  obscureText: true,
                ),
                const SizedBox(height: 16),

                // Pixabay API Key
                TextField(
                  controller: _pixabayController,
                  decoration: const InputDecoration(
                    labelText: 'Pixabay API Key',
                    hintText: 'Enter your Pixabay API key',
                    helperText: 'Get it from: https://pixabay.com/api/docs/',
                  ),
                  obscureText: true,
                ),
                const SizedBox(height: 16),

                // Adobe Firefly API Key (Future)
                TextField(
                  controller: _fireflyController,
                  decoration: const InputDecoration(
                    labelText: 'Adobe Firefly API Key (Coming Soon)',
                    hintText: 'Enter your Adobe Firefly API key',
                    helperText: 'AI-generated images',
                  ),
                  obscureText: true,
                  enabled: false, // Disabled for now
                ),
                const SizedBox(height: 32),

                // Download Settings
                Text(
                  'Download Settings',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 16),

                TextField(
                  controller: _downloadPathController,
                  decoration: InputDecoration(
                    labelText: 'Download Path',
                    hintText: '/path/to/wallpapers',
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.folder_open),
                      onPressed: _selectDownloadPath,
                    ),
                  ),
                  readOnly: true,
                ),
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
}
