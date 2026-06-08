import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/theme/theme_extensions.dart';
import '../../../providers/workspace_provider.dart';
import '../../../providers/wallpaper_provider.dart';

class TopCommandBar extends ConsumerWidget {
  const TopCommandBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.appColors;
    final n = ref.read(workspaceProvider.notifier);

    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(bottom: BorderSide(color: colors.border)),
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back_rounded,
                color: colors.textSecondary, size: 18),
            tooltip: 'Back to Project Selection',
            visualDensity: VisualDensity.compact,
            onPressed: () => Navigator.of(context).pop(),
          ),
          const SizedBox(width: 4),
          IconButton(
            icon:
                Icon(Icons.menu_rounded, color: colors.textSecondary, size: 18),
            tooltip: 'Toggle Sidebar',
            visualDensity: VisualDensity.compact,
            onPressed: () => n.toggleSidebar(),
          ),
          const SizedBox(width: 8),

          // Project breadcrumb
          Consumer(
            builder: (context, ref, _) {
              final wallState = ref.watch(wallpaperProvider);
              final name = wallState.currentThemeName ?? 'Default Theme';
              return Text(
                name,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              );
            },
          ),
          const Spacer(),
        ],
      ),
    );
  }
}
