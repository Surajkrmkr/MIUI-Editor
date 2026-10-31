import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/theme/theme_extensions.dart';
import '../../../providers/element_provider.dart';
import '../../../../domain/entities/element_widget.dart';
import '../../../../domain/entities/builtin_widget_styles.dart';

class LayerManager extends ConsumerWidget {
  const LayerManager({super.key, this.scrollable = false});
  final bool scrollable;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.appColors;
    final state = ref.watch(elementProvider);
    final notifier = ref.read(elementProvider.notifier);
    final layers = state.editableElements.reversed.toList();
    Widget constrain(Widget child) =>
        scrollable ? Expanded(child: child) : child;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'LAYERS',
                style: TextStyle(
                  color: colors.textDisabled,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            if (state.isGroupMode) ...[
              Text(
                '${state.elements.where(state.isSelected).length} selected',
                style: TextStyle(color: colors.primary, fontSize: 10),
              ),
              TextButton(
                onPressed: notifier.exitGroupMode,
                style: TextButton.styleFrom(
                  minimumSize: const Size(0, 20),
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text('Clear', style: TextStyle(fontSize: 10)),
              ),
            ],
          ],
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
          constrain(
            ReorderableListView.builder(
              buildDefaultDragHandles: false,
              shrinkWrap: !scrollable,
              physics: scrollable ? null : const NeverScrollableScrollPhysics(),
              itemCount: layers.length,
              onReorderItem: (oldIndex, newIndex) {
                if (oldIndex == newIndex) return;
                final target = layers[newIndex];
                final members = state.infoSetMembers(target);
                final names = (members.isEmpty ? [target] : members)
                    .map((element) => element.name)
                    .toSet();
                final boundary = newIndex > oldIndex
                    ? state.elements.indexWhere(
                        (element) => names.contains(element.name),
                      )
                    : state.elements.lastIndexWhere(
                            (element) => names.contains(element.name),
                          ) +
                          1;
                notifier.reorder(
                  state.elements.indexOf(layers[oldIndex]),
                  boundary,
                );
              },
              itemBuilder: (context, index) {
                final element = layers[index];
                final members = state.infoSetMembers(element);
                final isActive =
                    state.active?.name == element.name ||
                    members.any((member) => member.name == state.active?.name);
                final isChecked =
                    state.isGroupMode && state.isSelected(element);

                void toggleChecked() => state.isGroupMode
                    ? notifier.toggleGroupSelect(element.type, id: element.name)
                    : notifier.enterGroupMode(element.type, id: element.name);

                return _LayerTile(
                  key: ValueKey(element.name),
                  index: index,
                  element: members.isEmpty
                      ? element
                      : element.copyWith(
                          isLocked: members.any((member) => member.isLocked),
                          isVisible: members.any((member) => member.isVisible),
                        ),
                  label: members.isEmpty
                      ? element.label
                      : isWeatherSetElement(element)
                      ? 'Weather Sets'
                      : 'Battery Sets',
                  isActive: isActive,
                  isChecked: isChecked,
                  onToggleChecked: toggleChecked,
                  onTap: () => state.isGroupMode
                      ? toggleChecked()
                      : notifier.setActive(element.type, id: element.name),
                  onToggleVisibility: () =>
                      notifier.toggleVisibility(element.type, id: element.name),
                  onToggleLock: () =>
                      notifier.toggleLock(element.type, id: element.name),
                  onDelete: () =>
                      notifier.remove(element.type, id: element.name),
                );
              },
            ),
          ),
      ],
    );
  }
}

class _LayerTile extends StatelessWidget {
  const _LayerTile({
    super.key,
    required this.element,
    required this.label,
    required this.index,
    required this.isActive,
    required this.isChecked,
    required this.onToggleChecked,
    required this.onTap,
    required this.onToggleVisibility,
    required this.onToggleLock,
    required this.onDelete,
  });

  final LockElement element;
  final String label;
  final int index;
  final bool isActive;
  final bool isChecked;
  final VoidCallback onToggleChecked;
  final VoidCallback onTap;
  final VoidCallback onToggleVisibility;
  final VoidCallback onToggleLock;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Material(
      color: isActive || isChecked
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
              SizedBox(
                width: 24,
                height: 24,
                child: Checkbox(
                  key: ValueKey('select-${element.name}'),
                  value: isChecked,
                  onChanged: (_) => onToggleChecked(),
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
              ReorderableDragStartListener(
                index: index,
                key: ValueKey('reorder-${element.name}'),
                child: Icon(
                  Icons.drag_indicator_rounded,
                  size: 14,
                  color: colors.textDisabled,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                _getIcon(element.type),
                size: 14,
                color: isActive ? colors.primary : colors.textSecondary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: isActive ? colors.textPrimary : colors.textSecondary,
                    fontSize: 11,
                    fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              _ActionButton(
                tooltip: element.isVisible ? 'Hide $label' : 'Show $label',
                icon: element.isVisible
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                isActive: element.isVisible,
                onTap: onToggleVisibility,
              ),
              _ActionButton(
                tooltip: element.isLocked ? 'Unlock $label' : 'Lock $label',
                icon: element.isLocked
                    ? Icons.lock_rounded
                    : Icons.lock_outline_rounded,
                isActive: element.isLocked,
                onTap: onToggleLock,
              ),
              _ActionButton(
                icon: Icons.delete_outline_rounded,
                tooltip: 'Delete $label',
                onTap: onDelete,
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
    required this.tooltip,
    required this.onTap,
    this.isActive = false,
  });
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return IconButton(
      tooltip: tooltip,
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
