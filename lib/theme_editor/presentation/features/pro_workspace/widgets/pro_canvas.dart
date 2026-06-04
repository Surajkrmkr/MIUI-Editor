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
          const Positioned(
            top: 20,
            left: 20,
            child: _CanvasToolBar(),
          ),
          
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

class _CanvasToolBar extends ConsumerWidget {
  const _CanvasToolBar();

  void _addNewElement(WidgetRef ref, String groupKey) {
    final state = ref.read(elementProvider);
    final notifier = ref.read(elementProvider.notifier);
    
    final group = kElementGroups[groupKey];
    if (group == null) return;

    // Find first unused element type in group
    for (final type in group) {
      if (!state.contains(type)) {
        notifier.add(LockElement(
          type: type,
          colorSecondary: type == ElementType.notification
              ? Colors.white24
              : Colors.white,
        ));
        
        // Also ensure we are in lockscreen mode to see the elements
        final workspacePage = ref.read(workspaceProvider).page;
        if (workspacePage != WorkspacePage.lockscreen) {
          ref.read(workspaceProvider.notifier).setPage(WorkspacePage.lockscreen);
        }
        return;
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppTheme.proInspector,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.black),
        boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 10)],
      ),
      child: Column(
        children: [
          _ToolBtn(
            icon: Icons.near_me_rounded, 
            isActive: true,
            onPressed: () {},
          ),
          _ToolBtn(
            icon: Icons.crop_free_rounded,
            onPressed: () => _addNewElement(ref, 'Container'),
          ),
          _ToolBtn(
            icon: Icons.text_fields_rounded,
            onPressed: () => _addNewElement(ref, 'Text'),
          ),
          _ToolBtn(
            icon: Icons.image_outlined,
            onPressed: () => _addNewElement(ref, 'PNG'),
          ),
        ],
      ),
    );
  }
}

class _ToolBtn extends StatelessWidget {
  const _ToolBtn({
    required this.icon, 
    this.isActive = false,
    required this.onPressed,
  });

  final IconData icon;
  final bool isActive;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon, size: 18, color: isActive ? Colors.blue : Colors.white54),
      onPressed: onPressed,
      splashRadius: 20,
    );
  }
}
