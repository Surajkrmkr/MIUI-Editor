import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/theme/theme_extensions.dart';
import 'layer_manager.dart';

final layersPanelVisibleProvider = StateProvider<bool>((ref) => false);
final layersPanelOffsetProvider = StateProvider<Offset>(
  (ref) => const Offset(24, 64),
);

class LayersButton extends ConsumerWidget {
  const LayersButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => IconButton(
    tooltip: 'Layers',
    isSelected: ref.watch(layersPanelVisibleProvider),
    icon: const Icon(Icons.layers_outlined, size: 18),
    selectedIcon: Icon(
      Icons.layers_rounded,
      size: 18,
      color: context.appColors.primary,
    ),
    onPressed: () => ref.read(layersPanelVisibleProvider.notifier).state = !ref
        .read(layersPanelVisibleProvider),
  );
}

class FloatingLayersPanel extends ConsumerWidget {
  const FloatingLayersPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(layersPanelVisibleProvider)) return const SizedBox.shrink();
    final colors = context.appColors;
    final offset = ref.watch(layersPanelOffsetProvider);
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = math.min(320.0, math.max(0.0, constraints.maxWidth - 16));
        final height = math.min(
          420.0,
          math.max(0.0, constraints.maxHeight - 16),
        );
        Offset bound(Offset value) => Offset(
          value.dx.clamp(0, constraints.maxWidth - width),
          value.dy.clamp(0, constraints.maxHeight - height),
        );
        final position = bound(offset);
        return Stack(
          children: [
            Positioned(
              left: position.dx,
              top: position.dy,
              width: width,
              height: height,
              child: Material(
                key: const ValueKey('floating-layers'),
                elevation: 12,
                color: colors.surface,
                borderRadius: BorderRadius.circular(8),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    GestureDetector(
                      key: const ValueKey('layers-panel-handle'),
                      behavior: HitTestBehavior.opaque,
                      onPanUpdate: (details) =>
                          ref.read(layersPanelOffsetProvider.notifier).state =
                              bound(position + details.delta),
                      child: SizedBox(
                        height: 40,
                        child: Row(
                          children: [
                            const SizedBox(width: 12),
                            Icon(
                              Icons.drag_indicator_rounded,
                              size: 18,
                              color: colors.textSecondary,
                            ),
                            const SizedBox(width: 8),
                            const Expanded(child: Text('Layers')),
                            IconButton(
                              tooltip: 'Close layers',
                              icon: const Icon(Icons.close_rounded, size: 18),
                              onPressed: () =>
                                  ref
                                          .read(
                                            layersPanelVisibleProvider.notifier,
                                          )
                                          .state =
                                      false,
                            ),
                          ],
                        ),
                      ),
                    ),
                    Divider(height: 1, color: colors.border),
                    const Expanded(
                      child: Padding(
                        padding: EdgeInsets.all(8),
                        child: LayerManager(scrollable: true),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
