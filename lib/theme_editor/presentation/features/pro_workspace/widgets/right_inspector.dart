import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../providers/workspace_provider.dart';
import '../../icon_editor/icon_editor_panel.dart';
import '../../lockscreen/widgets/element_info_panel.dart';
import '../../lockscreen/widgets/element_list_panel.dart';
import '../../lockscreen/widgets/lockscreen_functions_panel.dart';
import '../../font_picker/font_list_panel.dart';
import '../../home/widgets/module_preview.dart';
import '../../home/widgets/export_buttons.dart';
import 'layer_manager.dart';
import 'svg_inspector.dart';

class RightInspector extends ConsumerWidget {
  const RightInspector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final page = ref.watch(workspaceProvider).page;

    return Container(
      width: 450,
      decoration: const BoxDecoration(
        color: AppTheme.proInspector,
        border: Border(left: BorderSide(color: Colors.black, width: 1)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            height: 36,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            alignment: Alignment.centerLeft,
            decoration: const BoxDecoration(
              color: AppTheme.proSidebar,
              border: Border(bottom: BorderSide(color: Colors.black)),
            ),
            child: const Text(
              'INSPECTOR',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
          ),
          
          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: _buildInspectorContent(page),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInspectorContent(WorkspacePage page) {
    // Content (Context-Sensitive)
    switch (page) {
      case WorkspacePage.home:
      case WorkspacePage.dashboard:
        return const SizedBox.shrink();
      case WorkspacePage.icons:
      case WorkspacePage.svgEditor:
        return const Column(
          children: [
            ModulePreview(),
            SizedBox(height: 16),
            ExportButtons(),
            SizedBox(height: 24),
            IconEditorPanel(),
          ],
        );
      case WorkspacePage.lockscreen:
        return const Column(
          children: [
            ElementInfoPanel(),
            SizedBox(height: 12),
            LockscreenFunctionsPanel(),
          ],
        );
      default:
        return const SizedBox.shrink();
    }
  }
}
