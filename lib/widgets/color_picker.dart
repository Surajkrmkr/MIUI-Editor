import 'package:flex_color_picker/flex_color_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../provider/icon.dart';

class ColorsTab extends StatelessWidget {
  const ColorsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 550,
      width: 500,
      child: DefaultTabController(
        length: 4,
        child: Scaffold(
          appBar: AppBar(
              automaticallyImplyLeading: false,
              title: const Text("Color"),
              centerTitle: true,
              bottom: const TabBar(
                  labelColor: Colors.black,
                  indicatorColor: Colors.pinkAccent,
                  tabs: [
                    Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text("BG"),
                    ),
                    Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text("Icon"),
                    ),
                    Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text("Border"),
                    ),
                    Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text("Accent"),
                    )
                  ])),
          body: Builder(builder: (context) {
            final provider = Provider.of<IconProvider>(context, listen: false);
            return TabBarView(children: [
              ColorPicker(
                color: provider.bgColor!,
                showRecentColors: true,
                onColorChanged: (value) {
                  provider.setBgColor = value;
                },
                enableOpacity: true,
                pickersEnabled: const {ColorPickerType.wheel: true},
              ),
              ColorPicker(
                color: provider.iconColor!,
                onColorChanged: (value) {
                  provider.setIconColor = value;
                },
                enableOpacity: true,
                pickersEnabled: const {ColorPickerType.wheel: true},
              ),
              ColorPicker(
                color: provider.borderColor!,
                onColorChanged: (value) {
                  provider.setBorderColor = value;
                },
                enableOpacity: true,
                pickersEnabled: const {ColorPickerType.wheel: true},
              ),
              ColorPicker(
                color: provider.accentColor!,
                onColorChanged: (value) {
                  provider.setAccentColor = value;
                },
                enableOpacity: true,
                pickersEnabled: const {ColorPickerType.wheel: true},
              )
            ]);
          }),
        ),
      ),
    );
  }
}
