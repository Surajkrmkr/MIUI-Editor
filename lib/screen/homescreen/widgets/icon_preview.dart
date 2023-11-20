import 'package:flutter/material.dart';

import '../../../data/miui_theme_data.dart';
import '../../../widgets/home_clock.dart';
import '../../../widgets/icon.dart';

class PreviewIcons extends StatelessWidget {
  const PreviewIcons({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          const EdgeInsets.only(bottom: 50.0, top: 50, left: 10, right: 10),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const HomeClockWidget(),
          Column(
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
        ],
      ),
    );
  }
}
