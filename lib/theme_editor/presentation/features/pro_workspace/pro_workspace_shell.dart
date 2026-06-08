import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/theme/theme_extensions.dart';
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
    final colors = context.appColors;
    return Shortcuts(
      shortcuts: <LogicalKeySet, Intent>{
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyK):
            const _CommandPaletteIntent(),
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
            backgroundColor: colors.bg,
            body: const Column(
              children: [
                TopCommandBar(),
                Expanded(
                  child: Row(
                    children: [
                      LeftToolNav(),
                      SidebarContent(),
                      Expanded(child: ProCanvas()),
                      RightInspector(),
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
