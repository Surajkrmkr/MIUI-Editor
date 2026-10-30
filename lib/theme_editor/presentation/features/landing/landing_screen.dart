import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import '../../providers/directory_provider.dart';
import '../../providers/font_provider.dart';
import '../../providers/spec_loader.dart';
import '../../providers/tag_provider.dart';
import '../../providers/wallpaper_provider.dart';
import 'package:miui_icon_generator/widgets/app_icon_button.dart';
import '../home/home_screen.dart';
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
  }

  Future<void> _openSpec() async {
    final picked = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
      dialogTitle: 'Open theme spec',
    );
    final path = picked?.files.single.path;
    if (path == null) return;
    final (spec, readFailure) = await readThemeSpecFile(path);
    if (spec == null) return _showError(readFailure!.message);

    var week = spec.workspace?.week;
    if (week == null || week.isEmpty) {
      if (!mounted) return;
      week = await _askWeek();
      if (week == null) return;
    }
    final applyFailure = await ref.read(themeSpecLoaderProvider)(
      spec,
      baseDir: p.dirname(path),
      week: week,
    );
    if (applyFailure != null) return _showError(applyFailure.message);
    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => HomeScreen(
          folderNum: spec.workspace?.folder ?? '1',
          weekNum: week!,
          loadOnStart: false,
        ),
      ),
    );
  }

  Future<String?> _askWeek() {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Week number'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            helperText: 'The spec has no workspace week.',
          ),
          onSubmitted: (v) => Navigator.pop(dialogContext, v.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(dialogContext, controller.text.trim()),
            child: const Text('Open'),
          ),
        ],
      ),
    ).then((v) => v == null || v.isEmpty ? null : v);
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final dirState = ref.watch(directoryProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('MIUI Editor'),
        leading: AppBackButton(
          onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.file_open_rounded),
            tooltip: 'Open theme spec',
            onPressed: _openSpec,
          ),
          IconButton(
            icon: const Icon(Icons.settings_rounded),
            tooltip: 'Settings',
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
            child: Builder(
              builder: (_) {
                if (dirState.isLoadingFolders) {
                  return const CircularProgressIndicator();
                }
                if (dirState.preLockFolders.isEmpty) {
                  return Text(
                    'NO FOLDER AVAILABLE',
                    style: Theme.of(context).textTheme.bodyLarge,
                  );
                }
                return const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [FolderWeekOptions(), PreviewWallsPanel()],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
