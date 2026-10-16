import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/theme/theme_extensions.dart';
import '../../../providers/workspace_provider.dart';
import '../../home/widgets/image_stack.dart';

class ProCanvas extends ConsumerStatefulWidget {
  const ProCanvas({super.key});

  @override
  ConsumerState<ProCanvas> createState() => _ProCanvasState();
}

class _ProCanvasState extends ConsumerState<ProCanvas> {
  late final TransformationController _transformationController;

  @override
  void initState() {
    super.initState();
    _transformationController = TransformationController();
  }

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  void _resetView() {
    _transformationController.value = Matrix4.identity();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final page = ref.watch(workspaceProvider).page;
    final isLocked = ref.watch(canvasLockProvider);

    return Container(
      color: colors.bg,
      child: Stack(
        children: [
          Positioned.fill(
            child: InteractiveViewer(
              transformationController: _transformationController,
              panEnabled: !isLocked,
              scaleEnabled: !isLocked,
              constrained: false,
              boundaryMargin: const EdgeInsets.all(1000),
              minScale: 0.01,
              maxScale: 10.0,
              child: Center(
                child: ImageStack(
                  isLockscreen: page == WorkspacePage.lockscreen ||
                      page == WorkspacePage.lockscreenPresets,
                ),
              ),
            ),
          ),

          // Navigation hint & lock control overlay
          Positioned(
            bottom: 16,
            right: 16,
            child: _CanvasControlOverlay(
              isLocked: isLocked,
              onToggleLock: () => ref.read(canvasLockProvider.notifier).toggle(),
              onResetView: _resetView,
              colors: colors,
            ),
          ),
        ],
      ),
    );
  }
}

class _CanvasControlOverlay extends StatelessWidget {
  const _CanvasControlOverlay({
    required this.isLocked,
    required this.onToggleLock,
    required this.onResetView,
    required this.colors,
  });

  final bool isLocked;
  final VoidCallback onToggleLock;
  final VoidCallback onResetView;
  final AppColorScheme colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isLocked ? colors.primary.withAlpha(120) : colors.border,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(30),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Reset view button
          Tooltip(
            message: 'Reset zoom & position (100%)',
            child: InkWell(
              borderRadius: BorderRadius.circular(4),
              onTap: onResetView,
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Icon(
                  Icons.center_focus_strong_outlined,
                  size: 14,
                  color: colors.textSecondary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          Container(
            width: 1,
            height: 14,
            color: colors.border,
          ),
          const SizedBox(width: 4),

          // Lock toggle button + status label
          Tooltip(
            message: isLocked
                ? 'Canvas Locked (Drag & Zoom disabled) · Click to unlock'
                : 'Click to lock canvas (Prevent drag & zoom)',
            child: InkWell(
              borderRadius: BorderRadius.circular(6),
              onTap: onToggleLock,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isLocked ? Icons.lock_rounded : Icons.lock_open_rounded,
                      size: 13,
                      color: isLocked ? colors.primary : colors.textDisabled,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isLocked
                          ? 'CANVAS LOCKED'
                          : 'PINCH TO ZOOM · SPACE TO PAN',
                      style: TextStyle(
                        color: isLocked ? colors.primary : colors.textDisabled,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
