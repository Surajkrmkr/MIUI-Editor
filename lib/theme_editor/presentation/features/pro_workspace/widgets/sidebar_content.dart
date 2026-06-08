import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:miui_icon_generator/core/theme/app_theme.dart';
import '../../../providers/workspace_provider.dart';
import '../../lockscreen/widgets/element_list_panel.dart';
import '../../font_picker/font_list_panel.dart';
import '../../icon_editor/icon_editor_panel.dart';
import '../../home/widgets/icon_export_card.dart';

class SidebarContent extends ConsumerWidget {
  const SidebarContent({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workspaceState = ref.watch(workspaceProvider);
    if (!workspaceState.isSidebarExpanded) return const SizedBox.shrink();

    final isLockscreen = workspaceState.page == WorkspacePage.lockscreen;
    final isIcons = workspaceState.page == WorkspacePage.svgEditor ||
        workspaceState.page == WorkspacePage.icons;

    return Container(
      width: isLockscreen ? 560 : (isIcons ? 400 : 280),
      decoration: const BoxDecoration(
        color: AppTheme.proSidebar,
        border: Border(right: BorderSide(color: Colors.black, width: 1)),
      ),
      child: _buildContent(workspaceState.page, ref),
    );
  }

  Widget _buildContent(WorkspacePage page, WidgetRef ref) {
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
              const IconExportCard(),
              const SizedBox(height: 16),
              const Text(
                'SVG EDITOR',
                style: TextStyle(
                  color: Colors.white38,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 20),
              const IconEditorPanel(),
            ],
          ),
        );
      case WorkspacePage.lockscreen:
        return const Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: SingleChildScrollView(child: ElementListPanel())),
              SizedBox(width: 20),
              Expanded(child: SingleChildScrollView(child: FontListPanel())),
            ],
          ),
        );
      default:
        return const SizedBox.shrink();
    }
  }
}

class _SidebarPlaceholder extends StatelessWidget {
  const _SidebarPlaceholder({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: const TextStyle(
              color: Colors.white38,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 20),
          const Center(
            child: Text(
              'Content coming soon',
              style: TextStyle(color: Colors.white24, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
