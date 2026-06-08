import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:miui_icon_generator/core/theme/app_radius.dart';
import '../../../../../core/theme/theme_extensions.dart';
import '../../../../domain/entities/element_widget.dart';
import '../../../providers/element_provider.dart';

class ElementListPanel extends ConsumerWidget {
  const ElementListPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.appColors;
    final scheme = Theme.of(context).colorScheme;
    final state = ref.watch(elementProvider);
    final notifier = ref.read(elementProvider.notifier);
    final addedCount = state.elements.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              Container(
                width: 3,
                height: 16,
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: colors.primary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Text(
                'Widgets',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurface,
                ),
              ),
              const Spacer(),
              if (addedCount > 0)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: scheme.primaryContainer,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Text(
                    '$addedCount',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: scheme.onPrimaryContainer,
                    ),
                  ),
                ),
            ],
          ),
        ),

        // List
        Column(
          mainAxisSize: MainAxisSize.min,
          children: kElementGroups.entries.map((entry) {
            final groupAdded =
                entry.value.where((t) => state.contains(t)).length;
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Theme(
                data: Theme.of(context)
                    .copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  title: Row(
                    children: [
                      Expanded(
                        child: Text(
                          entry.key,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (groupAdded > 0)
                        Container(
                          width: 18,
                          height: 18,
                          decoration: BoxDecoration(
                            color: colors.primary,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              '$groupAdded',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: colors.onPrimary,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  shape: RoundedRectangleBorder(
                    side: BorderSide(color: colors.border),
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                  ),
                  collapsedShape: RoundedRectangleBorder(
                    side: BorderSide(color: colors.border),
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                  ),
                  collapsedBackgroundColor: colors.surfaceOverlay,
                  backgroundColor: colors.surfaceOverlay,
                  children: entry.value.map((type) {
                    final added = state.contains(type);
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      child: Material(
                        color: added ? colors.primary : Colors.transparent,
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                        clipBehavior: Clip.antiAlias,
                        child: ListTile(
                          dense: true,
                          selected: added,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                          ),
                          contentPadding:
                              const EdgeInsets.symmetric(horizontal: 12),
                          leading: Icon(
                            added
                                ? Icons.check_circle_rounded
                                : Icons.radio_button_unchecked_rounded,
                            size: 16,
                            color: added
                                ? colors.onPrimary
                                : scheme.onSurfaceVariant,
                          ),
                          title: Text(
                            type.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: added
                                  ? FontWeight.w700
                                  : FontWeight.normal,
                              color: added
                                  ? colors.onPrimary
                                  : scheme.onSurface,
                            ),
                          ),
                          onTap: () {
                            if (!added) {
                              notifier.add(LockElement(
                                type: type,
                                colorSecondary: type ==
                                        ElementType.notification
                                    ? colors.primary.withAlpha(60)
                                    : colors.textPrimary,
                              ));
                            } else {
                              notifier.remove(type);
                            }
                          },
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
