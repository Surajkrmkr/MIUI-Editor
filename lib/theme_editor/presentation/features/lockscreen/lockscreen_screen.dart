import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/entities/element_widget.dart';
import '../../providers/element_provider.dart';
import '../../providers/wallpaper_provider.dart';
import '../home/widgets/image_stack.dart';
import '../font_picker/font_list_panel.dart';
import 'widgets/element_info_panel.dart';
import 'widgets/element_list_panel.dart';
import 'widgets/lockscreen_functions_panel.dart';

class LockscreenScreen extends ConsumerWidget {
  const LockscreenScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final n = ref.read(elementProvider.notifier);
      if (!ref.read(elementProvider).contains(ElementType.swipeUpUnlock)) {
        n.add(const LockElement(type: ElementType.swipeUpUnlock));
        n.setActive(ElementType.swipeUpUnlock);
      }
    });

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
                'Lockscreen',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                  letterSpacing: -0.3,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Consumer(builder: (_, ref, __) {
              final ws = ref.watch(wallpaperProvider);
              if (ws.paths.isEmpty) return const SizedBox.shrink();
              return _CountBadge(
                current: ws.index + 1,
                total: ws.paths.length,
              );
            }),
          ],
        ),
        actions: [
          Consumer(builder: (_, ref, __) {
            final colors = ref.watch(wallpaperProvider).colorPalette;
            return _PaletteStrip(colors: colors, ref: ref);
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
      body: const Padding(
        padding: EdgeInsets.all(24),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ImageStack(isLockscreen: true),
            SizedBox(width: 16),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ElementInfoPanel(),
                  SizedBox(width: 12),
                  ElementListPanel(),
                  SizedBox(width: 12),
                  LockscreenFunctionsPanel(),
                  SizedBox(width: 12),
                  FontListPanel(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Count Badge ───────────────────────────────────────────────────────────────

class _CountBadge extends StatelessWidget {
  const _CountBadge({required this.current, required this.total});
  final int current;
  final int total;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '$current / $total',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: scheme.onPrimaryContainer,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

// ── Palette Strip ─────────────────────────────────────────────────────────────

class _PaletteStrip extends StatelessWidget {
  const _PaletteStrip({required this.colors, required this.ref});
  final List<Color> colors;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: colors
              .map((c) => GestureDetector(
                    onTap: () {
                      final elState = ref.read(elementProvider);
                      ref.read(elementProvider.notifier)
                        ..setColor(elState.activeType, c)
                        ..setColorSecondary(elState.activeType, c);
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
