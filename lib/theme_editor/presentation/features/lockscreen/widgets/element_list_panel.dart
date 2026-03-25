import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:miui_icon_generator/core/theme/app_theme.dart';
import '../../../../domain/entities/element_widget.dart';
import '../../../providers/element_provider.dart';

class ElementListPanel extends ConsumerWidget {
  const ElementListPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(elementProvider);
    final notifier = ref.read(elementProvider.notifier);
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final addedCount = state.elements.length;

    return SizedBox(
      width: 210,
      child: Column(
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
                    color: AppTheme.accent,
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
                      borderRadius: BorderRadius.circular(10),
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
          Expanded(
            child: ListView(
              children: kElementGroups.entries.map((entry) {
                final groupAdded =
                    entry.value.where((t) => state.contains(t)).length;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Theme(
                    data: Theme.of(context).copyWith(
                      dividerColor: Colors.transparent,
                    ),
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
                              decoration: const BoxDecoration(
                                color: AppTheme.accent,
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  '$groupAdded',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: scheme.onPrimary,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      shape: RoundedRectangleBorder(
                        side: BorderSide(
                            color: isDark
                                ? Colors.white.withAlpha(18)
                                : Colors.black.withAlpha(15),
                            width: 1.5),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      collapsedShape: RoundedRectangleBorder(
                        side: BorderSide(
                            color: isDark
                                ? Colors.white.withAlpha(18)
                                : Colors.black.withAlpha(15),
                            width: 1.5),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      collapsedBackgroundColor:
                          isDark ? AppTheme.cardDark : Colors.white,
                      backgroundColor:
                          isDark ? AppTheme.cardDark : Colors.white,
                      children: entry.value.map((type) {
                        final added = state.contains(type);
                        return ListTile(
                          dense: true,
                          selected: added,
                          selectedTileColor:
                              scheme.primaryContainer.withAlpha(120),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          contentPadding:
                              const EdgeInsets.symmetric(horizontal: 16),
                          leading: Icon(
                            added
                                ? Icons.check_circle_rounded
                                : Icons.radio_button_unchecked_rounded,
                            size: 16,
                            color: added
                                ? scheme.primary
                                : scheme.onSurfaceVariant,
                          ),
                          title: Text(
                            type.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight:
                                  added ? FontWeight.w600 : FontWeight.normal,
                              color: added ? scheme.primary : scheme.onSurface,
                            ),
                          ),
                          onTap: () {
                            if (!added) {
                              notifier.add(LockElement(
                                type: type,
                                colorSecondary: type == ElementType.notification
                                    ? Colors.white24
                                    : Colors.white,
                              ));
                            } else {
                              notifier.remove(type);
                            }
                          },
                        );
                      }).toList(),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
