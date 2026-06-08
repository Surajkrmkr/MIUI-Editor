import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:miui_icon_generator/core/theme/theme_extensions.dart';
import '../../../../domain/entities/lock_widget.dart';
import '../../../providers/element_provider.dart';

class WidgetCenterDialog extends ConsumerWidget {
  const WidgetCenterDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final colors = context.appColors;

    // Group widgets by category
    final grouped = <String, List<LockWidget>>{};
    for (final w in kPresetWidgets) {
      grouped.putIfAbsent(w.category, () => []).add(w);
    }

    return Dialog(
      backgroundColor: context.appColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        width: 800,
        height: 600,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  width: 4,
                  height: 24,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    color: colors.primary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const Text(
                  'WIDGET CENTER',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Select a pre-designed widget to add to your lockscreen. These widgets are adaptive and work on any wallpaper.',
              style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13),
            ),
            const SizedBox(height: 24),

            // Content
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: grouped.entries.map((entry) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Text(
                            entry.key.toUpperCase(),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: colors.primary.withAlpha(200),
                              letterSpacing: 1.5,
                            ),
                          ),
                        ),
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            childAspectRatio: 1.4,
                          ),
                          itemCount: entry.value.length,
                          itemBuilder: (context, index) {
                            final widget = entry.value[index];
                            return _WidgetCard(widget: widget);
                          },
                        ),
                        const SizedBox(height: 24),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WidgetCard extends ConsumerWidget {
  const _WidgetCard({required this.widget});
  final LockWidget widget;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final colors = context.appColors;

    return Material(
      color: colors.surfaceOverlay,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          ref.read(elementProvider.notifier).addAll(widget.elements);
          Navigator.pop(context);
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: colors.border),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: colors.primary.withAlpha(30),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _getIconForCategory(widget.category),
                      size: 18,
                      color: colors.primary,
                    ),
                  ),
                  const Spacer(),
                  Icon(Icons.add_circle_outline_rounded,
                      size: 20, color: scheme.onSurface.withAlpha(60)),
                ],
              ),
              const Spacer(),
              Text(
                widget.name,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getIconForCategory(String category) {
    switch (category.toLowerCase()) {
      case 'date': return Icons.calendar_today_rounded;
      case 'music': return Icons.music_note_rounded;
      case 'weather': return Icons.cloud_rounded;
      case 'shortcuts': return Icons.apps_rounded;
      default: return Icons.widgets_rounded;
    }
  }
}
