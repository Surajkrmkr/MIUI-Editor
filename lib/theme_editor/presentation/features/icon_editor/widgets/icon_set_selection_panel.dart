import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:miui_icon_generator/core/theme/theme_extensions.dart';
import '../../../../domain/entities/user_profile.dart';
import '../../../providers/user_profile_provider.dart';

class IconSetSelectionPanel extends ConsumerWidget {
  const IconSetSelectionPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedUser = ref.watch(userProfileProvider);
    final colors = context.appColors;
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: kUserProfiles.entries.map((e) {
          final isSelected = selectedUser == e.key;
          return GestureDetector(
            onTap: () => ref.read(userProfileProvider.notifier).select(e.key),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? colors.primary : Colors.transparent,
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
                    color: isSelected ? colors.primary : scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
