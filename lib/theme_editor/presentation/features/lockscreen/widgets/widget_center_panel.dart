import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:miui_icon_generator/core/theme/app_theme.dart';
import '../../../../domain/entities/lock_widget.dart';
import '../../../providers/element_provider.dart';

class WidgetCenterPanel extends ConsumerWidget {
  const WidgetCenterPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;

    // Group widgets by category
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
                    color: AppTheme.accent,
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
                data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  title: Text(
                    entry.key,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  shape: RoundedRectangleBorder(
                    side: const BorderSide(color: Colors.black, width: 1.0),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  collapsedShape: RoundedRectangleBorder(
                    side: const BorderSide(color: Colors.black, width: 1.0),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  collapsedBackgroundColor: AppTheme.proCard,
                  backgroundColor: AppTheme.proCard,
                  children: entry.value.map((widget) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: Material(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          onTap: () {
                            ref.read(elementProvider.notifier).addAll(widget.elements);
                          },
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.white10),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
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
                                    const Icon(Icons.add_circle_outline_rounded,
                                        size: 16, color: AppTheme.accent),
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
          }).toList(),
        ],
      ),
    ),
   );
  }
}
