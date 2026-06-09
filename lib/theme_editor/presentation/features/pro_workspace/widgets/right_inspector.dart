import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/theme/theme_extensions.dart';
import '../../../providers/workspace_provider.dart';
import '../../lockscreen/widgets/element_info_panel.dart';
import '../../lockscreen/widgets/lockscreen_functions_panel.dart';
import '../../home/widgets/module_preview.dart';
import '../../icon_editor/widgets/sliders_panel.dart';

class RightInspector extends ConsumerWidget {
  const RightInspector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.appColors;
    final page = ref.watch(workspaceProvider).page;

    return Container(
      width: 400,
      decoration: BoxDecoration(
        color: colors.surfaceElevated,
        border: Border(left: BorderSide(color: colors.border)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            height: 36,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            alignment: Alignment.centerLeft,
            decoration: BoxDecoration(
              color: colors.surface,
              border: Border(bottom: BorderSide(color: colors.border)),
            ),
            child: Text(
              'INSPECTOR',
              style: TextStyle(
                color: colors.textDisabled,
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
    switch (page) {
      case WorkspacePage.home:
      case WorkspacePage.dashboard:
        return const SizedBox.shrink();
      case WorkspacePage.icons:
      case WorkspacePage.svgEditor:
        return const Column(
          children: [
            ModulePreview(),
            SizedBox(height: 24),
            SlidersPanel(),
          ],
        );
      case WorkspacePage.lockscreen:
        return const Column(
          children: [
            ElementInfoPanel(),
            SizedBox(height: 12),
            LockscreenFunctionsPanel(hideTools: true),
          ],
        );
      default:
        return const SizedBox.shrink();
    }
  }
}
