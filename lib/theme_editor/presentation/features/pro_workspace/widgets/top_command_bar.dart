import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../providers/workspace_provider.dart';
import '../../../providers/export_provider.dart';
import '../../../providers/lockscreen_provider.dart';
import '../../../providers/wallpaper_provider.dart';
import '../../landing/widgets/settings_dialog.dart';
import 'command_palette.dart';

class TopCommandBar extends ConsumerWidget {
  const TopCommandBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final n = ref.read(workspaceProvider.notifier);
    
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        color: AppTheme.proInspector,
        border: Border(bottom: BorderSide(color: Colors.black, width: 1)),
      ),
      child: Row(
        children: [
          // Logo/Home
          IconButton(
            icon: const Icon(Icons.menu_rounded, color: Colors.white70, size: 20),
            onPressed: () => n.toggleSidebar(),
          ),
          const SizedBox(width: 8),
          const Text(
            'MIUI Editor Pro',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
          const SizedBox(width: 24),
          
          // Project Dropdown
          Consumer(builder: (context, ref, _) {
            final wallState = ref.watch(wallpaperProvider);
            final name = wallState.currentThemeName ?? 'Default Theme';
            return Text(
              'Project / $name',
              style: const TextStyle(color: Colors.white54, fontSize: 11),
            );
          }),
          const Icon(Icons.expand_more_rounded, color: Colors.white54, size: 14),
          
          const Spacer(),
          
          const SizedBox(width: 12),
        ],
      ),
    );
  }
}

