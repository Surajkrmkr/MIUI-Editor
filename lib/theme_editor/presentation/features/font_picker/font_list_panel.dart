import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:miui_icon_generator/core/theme/app_theme.dart';
import '../../../presentation/providers/font_provider.dart';
import '../../../presentation/providers/element_provider.dart';

class FontListPanel extends ConsumerWidget {
  const FontListPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fontsAsync = ref.watch(fontListProvider);
    final elState = ref.watch(elementProvider);
    final scheme = Theme.of(context).colorScheme;
    final activeFont = elState.active?.font;

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
                  'Fonts',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: scheme.onSurface,
                  ),
                ),
                if (activeFont != null) ...[
                  const Spacer(),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: scheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Active',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: scheme.onSecondaryContainer,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Font list
          Expanded(
            child: fontsAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Text(
                  '$e',
                  style: TextStyle(
                    fontSize: 12,
                    color: scheme.error,
                  ),
                ),
              ),
              data: (fonts) => ListView.builder(
                itemCount: fonts.length,
                itemBuilder: (_, i) {
                  final font = fonts[i];
                  final sel = activeFont == font.fontFamily;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 4),
                    decoration: BoxDecoration(
                      color: sel
                          ? scheme.primaryContainer.withAlpha(120)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      border: sel
                          ? Border.all(
                              color: scheme.primary.withAlpha(80), width: 1.5)
                          : null,
                    ),
                    child: ListTile(
                      dense: true,
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 12),
                      leading: sel
                          ? Icon(Icons.check_rounded,
                              size: 16, color: scheme.primary)
                          : null,
                      title: Text(
                        font.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: font.name,
                          fontSize: 20,
                          color: sel ? scheme.primary : scheme.onSurface,
                          fontWeight: sel ? FontWeight.w700 : FontWeight.normal,
                        ),
                      ),
                      subtitle: Text(
                        font.name,
                        style: TextStyle(
                          fontSize: 10,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      onTap: () {
                        final type = ref.read(elementProvider).activeType;
                        ref
                            .read(elementProvider.notifier)
                            .setFont(type, font.fontFamily);
                      },
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
