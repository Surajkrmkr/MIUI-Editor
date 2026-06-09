import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/theme/theme_extensions.dart';
import '../../../providers/workspace_provider.dart';
import '../../lockscreen/widgets/element_list_panel.dart';
import '../../lockscreen/widgets/lockscreen_functions_panel.dart';
import '../../font_picker/font_list_panel.dart';
import '../../icon_editor/icon_editor_panel.dart';
import '../../home/widgets/icon_export_card.dart';

class SidebarContent extends ConsumerWidget {
  const SidebarContent({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.appColors;
    final workspaceState = ref.watch(workspaceProvider);
    if (!workspaceState.isSidebarExpanded) return const SizedBox.shrink();

    final isLockscreen = workspaceState.page == WorkspacePage.lockscreen;
    final isIcons = workspaceState.page == WorkspacePage.svgEditor ||
        workspaceState.page == WorkspacePage.icons;

    return Container(
      width: isLockscreen ? 560 : (isIcons ? 400 : 280),
      height: double.infinity,
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(right: BorderSide(color: colors.border)),
      ),
      child: _buildContent(workspaceState.page, colors),
    );
  }

  Widget _buildContent(WorkspacePage page, AppColorScheme colors) {
    switch (page) {
      case WorkspacePage.dashboard:
      case WorkspacePage.home:
        return const SizedBox.shrink();
      case WorkspacePage.svgEditor:
      case WorkspacePage.icons:
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Export Options',
                style: TextStyle(
                  color: colors.textDisabled,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 20),
              const IconExportCard(),
              const SizedBox(height: 16),
              const IconEditorPanel(),
            ],
          ),
        );
      case WorkspacePage.lockscreen:
        return const Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: SingleChildScrollView(child: ElementListPanel()),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  children: [
                    Expanded(child: FontListPanel()),
                    SizedBox(height: 12),
                    SingleChildScrollView(
                      child: LockscreenFunctionsPanel(toolsOnly: true),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      default:
        return const SizedBox.shrink();
    }
  }
}
