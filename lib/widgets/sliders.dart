import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../provider/icon.dart';

class Sliders extends StatelessWidget {
  const Sliders({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<IconProvider>(builder: (context, provider, _) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Row(
            children: [
              Slider(
                label: "Radius",
                value: provider.radius!,
                onChanged: (val) {
                  provider.setRadius = val;
                },
                min: 0,
                max: 20,
              ),
              Slider(
                label: "Border",
                value: provider.borderWidth!,
                onChanged: (val) {
                  provider.setBorderWidth = val;
                },
                min: 0,
                max: 20,
              ),
            ],
          ),
          Row(
            children: [
              Slider(
                label: "Margin",
                value: provider.margin!,
                onChanged: (val) {
                  provider.setMargin = val;
                },
                min: 0,
                max: 20,
              ),
              Slider(
                label: "Padding",
                value: provider.padding!,
                onChanged: (val) {
                  provider.setPadding = val;
                },
                min: 0,
                max: 20,
              ),
            ],
          ),
        ],
      );
    });
  }
}
