import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/theme/theme_extensions.dart';
import '../../../../domain/entities/lock_widget.dart';
import '../../../providers/element_provider.dart';

class WidgetCenterPanel extends ConsumerWidget {
  const WidgetCenterPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.appColors;
    final scheme = Theme.of(context).colorScheme;

    final grouped = <String, List<LockWidget>>{};
    for (final w in kPresetWidgets) {
      grouped.putIfAbsent(w.category, () => []).add(w);
    }

    return SizedBox(
      width: 250,
      child: SingleChildScrollView(
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
                      color: colors.primary,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Text(
                    'Widget Center',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: scheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),

            // Categories
            ...grouped.entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Theme(
                  data: Theme.of(context)
                      .copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    title: Text(
                      entry.key,
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    shape: RoundedRectangleBorder(
                      side: BorderSide(color: colors.border),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    collapsedShape: RoundedRectangleBorder(
                      side: BorderSide(color: colors.border),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    collapsedBackgroundColor: colors.surfaceOverlay,
                    backgroundColor: colors.surfaceOverlay,
                    children: entry.value.map((widget) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        child: Material(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          clipBehavior: Clip.antiAlias,
                          child: InkWell(
                            onTap: () => ref
                                .read(elementProvider.notifier)
                                .addAll(widget.elements),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                border: Border.all(color: colors.border),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        widget.name,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const Spacer(),
                                      Icon(
                                        Icons.add_circle_outline_rounded,
                                        size: 16,
                                        color: colors.primary,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    widget.description,
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: scheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
