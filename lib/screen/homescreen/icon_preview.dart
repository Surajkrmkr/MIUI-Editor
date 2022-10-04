
import 'package:flutter/material.dart';

import '../../data/miui_theme_data.dart';
import '../../widgets/icon.dart';

class PreviewIcons extends StatelessWidget {
  const PreviewIcons({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 50.0, left: 10, right: 10),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(
                  4,
                  (index) => IconContainer(
                      name: MIUIThemeData.vectorList[index + 5])).toList()),
          const SizedBox(
            height: 10,
          ),
          Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(
                  4,
                  (index) => IconContainer(
                      name: MIUIThemeData.vectorList[index + 9])).toList()),
        ],
      ),
    );
  }
}
