import 'package:flex_color_picker/flex_color_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../provider/icon.dart';
import '../provider/wallpaper.dart';

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
          SizedBox(
            width: 300,
            child: Column(
              children: [
                SwitchListTile(
                    value: provider.randomColors!,
                    activeColor: Theme.of(context).colorScheme.primary,
                    title: Text(
                      "Random Colors",
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    onChanged: (value) {
                      final wallProvider = Provider.of<WallpaperProvider>(
                          context,
                          listen: false);
                      provider.setRandomColors = value;
                      if (provider.randomColors ?? false) {
                        final colors = wallProvider.colorPalette!
                            .where((e) =>
                                ThemeData.estimateBrightnessForColor(e) ==
                                Brightness.dark)
                            .toList();
                        provider.setBgColors = colors;
                      } else {
                        provider.setBgColor =
                            (wallProvider.colorPalette!.first);
                        provider.setBgColor2 =
                            (wallProvider.colorPalette!.first);
                      }
                    }),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  child: Visibility(
                    visible: provider.randomColors ?? false,
                    child: Wrap(runSpacing: 10, spacing: 10, children: [
                      ...provider.bgColors!
                          .map(
                            (color) => randomColorContainer(provider, color),
                          )
                          .toList(),
                      ColorPicker(
                        color: provider.accentColor!,
                        onColorChangeEnd: (value) {
                          provider.setBgColors = [...provider.bgColors!, value];
                        },
                        onColorChanged: (value) {},
                        enableOpacity: true,
                        pickersEnabled: const {
                          ColorPickerType.wheel: true,
                          ColorPickerType.primary: false,
                          ColorPickerType.accent: false
                        },
                      ),
                    ]),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    });
  }

  MouseRegion randomColorContainer(IconProvider provider, Color color) {
    return MouseRegion(
      cursor: SystemMouseCursors.precise,
      child: InkWell(
        onTap: () {
          if (provider.bgColors!.length > 1) {
            provider.setBgColors = provider.bgColors!
                .where((e) => e.value != color.value)
                .toList();
          }
        },
        child: Container(
          height: 40,
          width: 40,
          decoration: BoxDecoration(
              color: color, borderRadius: BorderRadius.circular(10)),
          child: const Icon(
            Icons.close,
            color: Colors.white10,
          ),
        ),
      ),
    );
  }
}
