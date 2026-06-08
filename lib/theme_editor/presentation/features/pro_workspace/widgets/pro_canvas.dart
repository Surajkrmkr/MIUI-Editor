import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/theme/theme_extensions.dart';
import '../../../providers/workspace_provider.dart';
import '../../home/widgets/image_stack.dart';

class ProCanvas extends ConsumerWidget {
  const ProCanvas({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.appColors;
    final page = ref.watch(workspaceProvider).page;

    return Container(
      color: colors.bg,
      child: Stack(
        children: [
          Positioned.fill(
            child: InteractiveViewer(
              constrained: false,
              boundaryMargin: const EdgeInsets.all(1000),
              minScale: 0.01,
              maxScale: 10.0,
              child: Center(
                child: ImageStack(
                    isLockscreen: page == WorkspacePage.lockscreen),
              ),
            ),
          ),

          // Navigation hint overlay
          Positioned(
            bottom: 16,
            right: 16,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: colors.border),
              ),
              child: Row(
                children: [
                  Icon(Icons.mouse_outlined,
                      size: 12, color: colors.textDisabled),
                  const SizedBox(width: 8),
                  Text(
                    'PINCH TO ZOOM · SPACE TO PAN',
                    style: TextStyle(
                      color: colors.textDisabled,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
