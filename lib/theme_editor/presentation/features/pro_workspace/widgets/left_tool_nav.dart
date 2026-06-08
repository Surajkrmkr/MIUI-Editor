import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/theme/theme_extensions.dart';
import '../../../providers/workspace_provider.dart';
import '../../landing/widgets/settings_dialog.dart';

class LeftToolNav extends ConsumerWidget {
  const LeftToolNav({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.appColors;
    final page = ref.watch(workspaceProvider).page;
    final n = ref.read(workspaceProvider.notifier);

    return Container(
      width: 48,
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(right: BorderSide(color: colors.border)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          _NavIcon(
            icon: Icons.grid_view_outlined,
            activeIcon: Icons.grid_view,
            label: 'SVG Editor',
            isActive: page == WorkspacePage.svgEditor ||
                page == WorkspacePage.icons,
            onTap: () => n.setPage(WorkspacePage.svgEditor),
          ),
          _NavIcon(
            icon: Icons.lock_outline_rounded,
            activeIcon: Icons.lock_rounded,
            label: 'Lockscreen',
            isActive: page == WorkspacePage.lockscreen,
            onTap: () => n.setPage(WorkspacePage.lockscreen),
          ),
          const Spacer(),
          _NavIcon(
            icon: Icons.settings_outlined,
            label: 'Settings',
            isActive: false,
            onTap: () => showDialog(
              context: context,
              builder: (_) => const SettingsDialog(),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

class _NavIcon extends StatelessWidget {
  const _NavIcon({
    required this.icon,
    this.activeIcon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  final IconData icon;
  final IconData? activeIcon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Tooltip(
        message: label,
        preferBelow: false,
        child: InkWell(
          onTap: onTap,
          child: Container(
            width: 48,
            height: 40,
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(
                  color: isActive ? colors.primary : Colors.transparent,
                  width: 2,
                ),
              ),
            ),
            child: Icon(
              isActive ? (activeIcon ?? icon) : icon,
              color: isActive ? colors.primary : colors.textDisabled,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }
}
