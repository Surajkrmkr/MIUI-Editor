import 'dart:io';

import 'package:flex_color_picker/flex_color_picker.dart';
import 'package:flutter/material.dart';
import 'package:miui_icon_generator/constants.dart';
import 'package:provider/provider.dart';

import '../provider/icon.dart';

class ColorsTab extends StatelessWidget {
  const ColorsTab({super.key});

  Widget child(context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
            automaticallyImplyLeading: false,
            title: const Text("Color"),
            centerTitle: true,
            backgroundColor: Colors.transparent,
            bottom: TabBar(
                indicatorColor: Theme.of(context).colorScheme.primary,
                dividerColor: Colors.transparent,
                splashBorderRadius: BorderRadius.circular(25),
                tabs: [
                  Padding(
                    padding: EdgeInsets.all(MIUIConstants.isDesktop ? 8.0 : 6.0),
                    child: const Text("BG"),
                  ),
                  Padding(
                    padding: EdgeInsets.all(MIUIConstants.isDesktop ? 8.0 : 6.0),
                    child: const Text("Icon"),
                  ),
                  Padding(
                    padding: EdgeInsets.all(MIUIConstants.isDesktop ? 8.0 : 6.0),
                    child: const Text("Border"),
                  ),
                  Padding(
                    padding: EdgeInsets.all(MIUIConstants.isDesktop ? 8.0 : 6.0),
                    child: const Text("Accent"),
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return MIUIConstants.isDesktop
        ? SizedBox(height: 550, width: 500, child: child(context))
        : SizedBox(height: 650, child: child(context));
  }
}
