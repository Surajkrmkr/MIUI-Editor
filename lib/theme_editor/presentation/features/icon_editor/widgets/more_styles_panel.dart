import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:miui_icon_generator/core/theme/app_radius.dart';
import 'package:miui_icon_generator/core/theme/theme_extensions.dart';
import '../../../../core/constants/asset_paths.dart';
import '../../../../domain/entities/user_profile.dart';
import '../../../providers/user_profile_provider.dart';

/// Extra icon sets not owned by any profile; applied on top of the active profile.
class MoreStylesPanel extends ConsumerWidget {
  const MoreStylesPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.appColors;
    final scheme = Theme.of(context).colorScheme;
    final hasProfile = ref.watch(activeUserProfileProvider) != null;
    final override = ref.watch(iconStyleOverrideProvider);
    final profileFolders = kUserProfiles.values
        .map((p) => p.iconFolder)
        .toSet();
    final styles = IconVariant.values.where(
      (v) => !profileFolders.contains(v.folder),
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surfaceOverlay,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Container(
                  width: 3,
                  height: 12,
                  margin: const EdgeInsets.only(right: 6),
                  decoration: BoxDecoration(
                    color: colors.primary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Text(
                  'MORE STYLES',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: scheme.onSurfaceVariant,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ),
          if (!hasProfile)
            Text(
              'Select a profile to use these styles',
              style: TextStyle(fontSize: 10, color: scheme.onSurfaceVariant),
            )
          else
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: styles.map((v) {
                final selected = override == v.folder;
                return InkWell(
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  // Tapping the active style again returns to the profile's own set.
                  onTap: () => ref
                      .read(iconStyleOverrideProvider.notifier)
                      .select(selected ? null : v.folder),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: selected ? colors.primary : Colors.transparent,
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      border: Border.all(
                        color: selected ? colors.primary : colors.border,
                      ),
                    ),
                    child: Text(
                      v.displayName,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: selected
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: selected
                            ? scheme.onPrimary
                            : scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
}
