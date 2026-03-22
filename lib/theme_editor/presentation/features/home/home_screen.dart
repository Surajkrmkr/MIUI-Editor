import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/directory_provider.dart';
import '../../providers/icon_editor_provider.dart';
import '../../providers/wallpaper_provider.dart';
import '../icon_editor/icon_editor_panel.dart';
import 'widgets/image_stack.dart';
import 'widgets/module_preview.dart';
import 'widgets/export_buttons.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key, required this.folderNum, required this.weekNum});
  final String folderNum;
  final String weekNum;

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(wallpaperProvider.notifier)
          .loadFolder(widget.folderNum, widget.weekNum);
    });
  }

  @override
  Widget build(BuildContext context) {
    final wallState = ref.watch(wallpaperProvider);
    final dirState = ref.watch(directoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const SizedBox(width: 220, child: Text('Theme Generator')),
            const SizedBox(width: 20),
            _ProgressBar(state: wallState),
            if (dirState.isCreatingDirs)
              const Padding(
                padding: EdgeInsets.only(left: 12),
                child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2)),
              ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.home_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Consumer(builder: (_, ref, __) {
            final colors = ref.watch(wallpaperProvider).colorPalette;
            return _PaletteStrip(colors: colors, isLockscreen: false);
          }),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(30),
        child: wallState.isLoading
            ? const Center(child: CircularProgressIndicator())
            : Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const ImageStack(isLockscreen: false),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      const ModulePreview(),
                      const ExportButtons(),
                    ],
                  ),
                  const SingleChildScrollView(
                    child: IconEditorPanel(),
                  ),
                ],
              ),
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.state});
  final WallpaperState state;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          SizedBox(
            width: 200,
            height: 10,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: state.paths.isEmpty
                    ? 0
                    : state.index / (state.themeCount - 1),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Text(
            state.index == state.themeCount - 1
                ? ''
                : '${state.themeCount - state.index - 1} left',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      );
}

class _PaletteStrip extends ConsumerWidget {
  const _PaletteStrip({required this.colors, required this.isLockscreen});
  final List<Color> colors;
  final bool isLockscreen;

  @override
  Widget build(BuildContext context, WidgetRef ref) => SizedBox(
        height: 40,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: colors
                .map((c) => GestureDetector(
                      onTap: () {
                        if (!isLockscreen) {
                          ref.read(iconEditorProvider.notifier)
                            ..setBgColor(c)
                            ..setBgColor2(c)
                            ..setAccentColor(c);
                        }
                      },
                      child: Container(
                        margin: const EdgeInsets.only(right: 4),
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: c,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ))
                .toList(),
          ),
        ),
      );
}
