import 'package:flutter/material.dart';
import 'package:miui_icon_generator/theme_editor/presentation/features/icon_editor/widgets/icon_set_selection_panel.dart';
import 'widgets/color_tab.dart';
import 'widgets/bg_drop_zones.dart';

class IconEditorPanel extends StatelessWidget {
  const IconEditorPanel({super.key});

  @override
  Widget build(BuildContext context) => const Column(
        children: [
          IconSetSelectionPanel(),
          SizedBox(height: 10),
          BgDropZones(),
          SizedBox(height: 10),
          ColorTab(),
        ],
      );
}
