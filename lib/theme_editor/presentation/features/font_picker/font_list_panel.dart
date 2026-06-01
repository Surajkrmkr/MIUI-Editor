import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:miui_icon_generator/core/theme/app_theme.dart';
import '../../../domain/entities/user_profile.dart';
import '../../../presentation/providers/font_provider.dart';
import '../../../presentation/providers/element_provider.dart';

class FontListPanel extends ConsumerWidget {
  const FontListPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fontsAsync = ref.watch(fontListProvider);
    final elState = ref.watch(elementProvider);
    final selectedUser = ref.watch(fontUserSelectionProvider);
    final scheme = Theme.of(context).colorScheme;
    final activeFont = elState.active?.font;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
          // Header
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
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

          // User selection grid
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              children: kUserProfiles.entries.map((e) {
                final isSelected = selectedUser == e.key;
                return GestureDetector(
                  onTap: () => ref.read(fontUserSelectionProvider.notifier).select(e.key),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected ? AppTheme.accent : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: CircleAvatar(
                          radius: 16,
                          backgroundImage: AssetImage(e.value.avatarAsset),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        e.value.displayName,
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected ? AppTheme.accent : scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),

          // Font list
          fontsAsync.when(
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
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: fonts.length,
              itemBuilder: (_, i) {
                  final font = fonts[i];
                  final sel = activeFont == font.fontFamily;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 4),
                    decoration: BoxDecoration(
                      color: sel
                          ? AppTheme.accent.withAlpha(30)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: sel ? AppTheme.accent.withAlpha(80) : Colors.black,
                        width: 1.0,
                      ),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      clipBehavior: Clip.antiAlias,
                      borderRadius: BorderRadius.circular(12),
                      child: ListTile(
                        dense: true,
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 12),
                        leading: sel
                            ? const Icon(Icons.check_rounded,
                                size: 16, color: AppTheme.accent)
                            : null,
                        title: Text(
                          font.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: font.name,
                            fontSize: 20,
                            color: sel ? AppTheme.accent : scheme.onSurface,
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
                    ),
                  );
                },
              ),
            ),
        ],
      );
  }
}
