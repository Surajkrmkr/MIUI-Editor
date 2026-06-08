import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../providers/workspace_provider.dart';
import '../../../providers/element_provider.dart';
import '../../../../domain/entities/element_widget.dart';
import '../../home/widgets/image_stack.dart';

class ProCanvas extends ConsumerWidget {
  const ProCanvas({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final page = ref.watch(workspaceProvider).page;

    return Container(
      color: AppTheme.proBackground, // Pure black canvas for pro feel
      child: Stack(
        children: [
          // Infinite Canvas with Mouse Interactivity
          Positioned.fill(
            child: InteractiveViewer(
              constrained: false, // Essential for infinite canvas / large children
              boundaryMargin: const EdgeInsets.all(1000),
              minScale: 0.01,
              maxScale: 10.0,
              child: Center(
                child: ImageStack(isLockscreen: page == WorkspacePage.lockscreen),
              ),
            ),
          ),
          
          // Selection / Canvas Tools Overlay
          // Removed as per request
          
          // Navigation Info
          Positioned(
            bottom: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.white10),
              ),
              child: const Row(
                children: [
                  Icon(Icons.mouse_outlined, size: 12, color: Colors.white24),
                  SizedBox(width: 8),
                  Text(
                    'PITCH TO ZOOM · SPACE TO PAN',
                    style: TextStyle(color: Colors.white24, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.5),
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

