import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/directory_provider.dart';
import '../../providers/font_provider.dart';
import '../../providers/icon_editor_provider.dart';
import '../../providers/tag_provider.dart';
import '../../providers/wallpaper_provider.dart';
import 'widgets/folder_week_options.dart';
import 'widgets/preview_walls.dart';
import 'widgets/settings_dialog.dart';

class LandingScreen extends ConsumerStatefulWidget {
  const LandingScreen({super.key});

  @override
  ConsumerState<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends ConsumerState<LandingScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _init());
  }

  void _init() {
    // Ensure WallpaperNotifier.build() runs first so PathConstants.customBasePath
    // is populated from SharedPreferences before any directory operations.
    ref.read(wallpaperProvider);

    ref.read(directoryProvider.notifier)
      ..loadPreLockFolders()
      ..loadPreviewWalls('1');
    ref.read(tagProvider.notifier).load();
    ref.read(fontListProvider);
    ref.read(iconEditorProvider.notifier).loadIconAssets();
  }

  @override
  Widget build(BuildContext context) {
    final dirState = ref.watch(directoryProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Welcome to MIUI World'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: 'Back to Launcher',
          onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => showDialog(
              context: context,
              builder: (_) => const SettingsDialog(),
            ),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Builder(builder: (_) {
              if (dirState.isLoadingFolders) {
                return const CircularProgressIndicator();
              }
              if (dirState.preLockFolders.isEmpty) {
                return Text('NO FOLDER AVAILABLE',
                    style: Theme.of(context).textTheme.bodyLarge);
              }
              return const Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FolderWeekOptions(),
                  PreviewWallsPanel(),
                ],
              );
            }),
          ),
        ),
      ),
    );
  }
}
