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
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: 'Back',
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            ShaderMask(
              shaderCallback: (bounds) => LinearGradient(
                colors: [scheme.primary, scheme.tertiary],
              ).createShader(bounds),
              child: const Text(
                'Theme Generator',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                  letterSpacing: -0.3,
                ),
              ),
            ),
            const SizedBox(width: 16),
            if (!wallState.isLoading) _ProgressBar(state: wallState),
            if (dirState.isCreatingDirs)
              Padding(
                padding: const EdgeInsets.only(left: 10),
                child: SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: scheme.primary,
                  ),
                ),
              ),
          ],
        ),
        actions: [
          Consumer(builder: (_, ref, __) {
            final colors = ref.watch(wallpaperProvider).colorPalette;
            return _PaletteStrip(colors: colors, isLockscreen: false);
          }),
          const SizedBox(width: 12),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  scheme.primary.withAlpha(0),
                  scheme.primary.withAlpha(100),
                  scheme.tertiary.withAlpha(100),
                  scheme.primary.withAlpha(0),
                ],
              ),
            ),
          ),
        ),
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

// ── Progress Bar ──────────────────────────────────────────────────────────────

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.state});
  final WallpaperState state;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final progress = state.paths.isEmpty
        ? 0.0
        : state.index / (state.themeCount - 1);
    final remaining = state.themeCount - state.index - 1;

    return Row(
      children: [
        SizedBox(
          width: 190,
          height: 7,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Track
                Container(color: scheme.surfaceContainerHigh),
                // Filled gradient
                FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: progress,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [scheme.primary, scheme.tertiary],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        if (remaining > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: scheme.primaryContainer,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$remaining left',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: scheme.onPrimaryContainer,
              ),
            ),
          ),
      ],
    );
  }
}

// ── Palette Strip ─────────────────────────────────────────────────────────────

class _PaletteStrip extends ConsumerWidget {
  const _PaletteStrip({required this.colors, required this.isLockscreen});
  final List<Color> colors;
  final bool isLockscreen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox(
      height: 44,
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
                      margin: const EdgeInsets.only(right: 6),
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: c,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withAlpha(70),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: c.withAlpha(110),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  ))
              .toList(),
        ),
      ),
    );
  }
}
