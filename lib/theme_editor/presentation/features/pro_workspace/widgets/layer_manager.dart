import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/theme/theme_extensions.dart';
import '../../../providers/element_provider.dart';
import '../../../../domain/entities/element_widget.dart';

class LayerManager extends ConsumerWidget {
  const LayerManager({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.appColors;
    final state = ref.watch(elementProvider);
    final notifier = ref.read(elementProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'LAYERS',
          style: TextStyle(
            color: colors.textDisabled,
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 12),
        if (state.elements.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Text(
                'No layers in this project',
                style: TextStyle(color: colors.textDisabled, fontSize: 12),
              ),
            ),
          )
        else
          ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: state.elements.length,
            onReorder: (oldIndex, newIndex) =>
                notifier.reorder(oldIndex, newIndex),
            itemBuilder: (context, index) {
              final element = state.elements[index];
              final isActive = state.activeType == element.type;

              return _LayerTile(
                key: ValueKey(element.type),
                element: element,
                isActive: isActive,
                onTap: () => notifier.setActive(element.type),
                onToggleVisibility: () =>
                    notifier.toggleVisibility(element.type),
                onToggleLock: () => notifier.toggleLock(element.type),
              );
            },
          ),
      ],
    );
  }
}

class _LayerTile extends StatelessWidget {
  const _LayerTile({
    super.key,
    required this.element,
    required this.isActive,
    required this.onTap,
    required this.onToggleVisibility,
    required this.onToggleLock,
  });

  final LockElement element;
  final bool isActive;
  final VoidCallback onTap;
  final VoidCallback onToggleVisibility;
  final VoidCallback onToggleLock;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Material(
      color: isActive
          ? colors.primary.withAlpha(20)
          : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(
                color: isActive ? colors.primary : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Row(
            children: [
              Icon(Icons.drag_indicator_rounded,
                  size: 14, color: colors.textDisabled),
              const SizedBox(width: 4),
              Icon(
                _getIcon(element.type),
                size: 14,
                color: isActive ? colors.primary : colors.textSecondary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  element.name,
                  style: TextStyle(
                    color: isActive
                        ? colors.textPrimary
                        : colors.textSecondary,
                    fontSize: 11,
                    fontWeight:
                        isActive ? FontWeight.bold : FontWeight.normal,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              _ActionButton(
                icon: element.isVisible
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                isActive: element.isVisible,
                onTap: onToggleVisibility,
              ),
              _ActionButton(
                icon: element.isLocked
                    ? Icons.lock_rounded
                    : Icons.lock_outline_rounded,
                isActive: element.isLocked,
                onTap: onToggleLock,
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getIcon(ElementType type) {
    if (type.isClock) return Icons.access_time_rounded;
    if (type.isIcon) return Icons.apps_rounded;
    if (type.isMusic) return Icons.music_note_rounded;
    if (type.isVideo) return Icons.videocam_rounded;
    if (type.isText) return Icons.text_fields_rounded;
    return Icons.layers_rounded;
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.onTap,
    this.isActive = false,
  });
  final IconData icon;
  final VoidCallback onTap;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return IconButton(
      icon: Icon(
        icon,
        size: 12,
        color: isActive ? colors.primary : colors.textDisabled,
      ),
      onPressed: onTap,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
    );
  }
}
