import 'package:flutter/material.dart';
import 'widgets/color_tab.dart';
import 'widgets/bg_drop_zones.dart';

class IconEditorPanel extends StatelessWidget {
  const IconEditorPanel({super.key});

  @override
  Widget build(BuildContext context) => const Column(
        spacing: 10,
        children: [
          BgDropZones(),
          ColorTab(),
        ],
      );
}
