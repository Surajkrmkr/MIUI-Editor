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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: 'Back',
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            const Text('Theme Generator'),
            const SizedBox(width: 16),
            if (!wallState.isLoading) _ProgressBar(state: wallState),
            if (dirState.isCreatingDirs)
              const Padding(
                padding: EdgeInsets.only(left: 10),
                child: SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2)),
              ),
          ],
        ),
        actions: [
          Consumer(builder: (_, ref, __) {
            final colors = ref.watch(wallpaperProvider).colorPalette;
            return _PaletteStrip(colors: colors, isLockscreen: false);
          }),
          const SizedBox(width: 8),
        ],
      ),
      body: wallState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : const Padding(
              padding: EdgeInsets.fromLTRB(24, 16, 24, 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ImageStack(isLockscreen: false),
                  SizedBox(width: 24),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        ModulePreview(),
                        SizedBox(height: 20),
                        ExportButtons(),
                      ],
                    ),
                  ),
                  SizedBox(width: 24),
                  SingleChildScrollView(
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
