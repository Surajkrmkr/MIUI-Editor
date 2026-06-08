import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:miui_icon_generator/core/theme/app_theme.dart';
import '../../providers/workspace_provider.dart';
import 'widgets/top_command_bar.dart';
import 'widgets/left_tool_nav.dart';
import 'widgets/right_inspector.dart';
import 'widgets/pro_canvas.dart';
import 'widgets/sidebar_content.dart';
import 'widgets/command_palette.dart';

class ProfessionalWorkspaceShell extends ConsumerWidget {
  const ProfessionalWorkspaceShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Shortcuts(
      shortcuts: <LogicalKeySet, Intent>{
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyK): const _CommandPaletteIntent(),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          _CommandPaletteIntent: CallbackAction<_CommandPaletteIntent>(
            onInvoke: (intent) => showCommandPalette(context),
          ),
        },
        child: FocusScope(
          autofocus: true,
          child: Scaffold(
            backgroundColor: const Color(0xFF1E1E1E), 
            body: Column(
              children: [
                const TopCommandBar(),
                Expanded(
                  child: Row(
                    children: [
                      const LeftToolNav(),
                      const SidebarContent(),
                      const Expanded(
                        child: ProCanvas(),
                      ),
                      const RightInspector(),
                    ],
                  ),
                ),

              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CommandPaletteIntent extends Intent {
  const _CommandPaletteIntent();
}
