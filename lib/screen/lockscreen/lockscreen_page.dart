import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/element_map_dart.dart';
import '../../provider/element.dart';
import '../../widgets/accent_color_list.dart';
import '../../widgets/element_info.dart';
import '../../widgets/font.dart';
import '../../widgets/image_stack.dart';
import '../../widgets/lockscreen_function.dart';
import '../../widgets/ui_widgets.dart';
import '../homescreen/home_page.dart';

class LockscreenPage extends StatelessWidget {
  const LockscreenPage({super.key});

  @override
  Widget build(BuildContext context) {
    Future.delayed(Duration.zero, () {
      addDefaultLock(context);
    });
    return Scaffold(
      appBar: AppBar(
        title: Platform.isWindows
            ? Row(
                children: [
                  const SizedBox(width: 220, child: Text("Lockscreen")),
                  const SizedBox(
                    width: 20,
                  ),
                  getProgress()
                ],
              )
            : Container(),
        actions: [
          if (Platform.isWindows) accentColorsList(isLockscreen: true),
          if (Platform.isAndroid)
            Row(
              children: [
                UIWidgets.getIconButton(
                  context: context,
                  icon: Icons.layers,
                  widget: const ElementList(),
                ),
                UIWidgets.getIconButton(
                  context: context,
                  icon: Icons.build,
                  widget: const ElementInfo(),
                ),
                UIWidgets.getIconButton(
                  context: context,
                  icon: Icons.lock,
                  widget: const LockscreenFunctions(),
                ),
                UIWidgets.getIconButton(
                  context: context,
                  icon: Icons.format_size,
                  widget: const FontListWidget(),
                )
              ],
            )
        ],
      ),
      body: Padding(
        padding:
            Platform.isAndroid ? EdgeInsets.zero : const EdgeInsets.all(30),
        child: Platform.isAndroid
            ? SingleChildScrollView(
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      ImageStack(isLockscreen: true),
                      accentColorsList(isLockscreen: true),
                    ]),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                    ImageStack(isLockscreen: true),
                    const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ElementInfo(),
                        ElementList(),
                        LockscreenFunctions(),
                        FontListWidget(),
                      ],
                    )
                  ]),
      ),
    );
  }

  void addDefaultLock(context) {
    ElementWidget ele = ElementWidget(
        type: ElementType.swipeUpUnlock,
        name: ElementType.swipeUpUnlock.name,
        child: elementWidgetMap[ElementType.swipeUpUnlock]!["widget"]);
    final provider = Provider.of<ElementProvider>(context, listen: false);
    provider.addElementInList(ele);
    provider.setActiveType = ElementType.swipeUpUnlock;
  }
}

class BgAlpha extends StatelessWidget {
  const BgAlpha({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<ElementProvider>(builder: (context, provider, _) {
      return Slider(
        value: provider.bgAlpha!,
        onChanged: (val) {
          provider.setBgAlpha = val;
        },
        min: 0,
        max: 1,
        divisions: 1 ~/ 0.05,
      );
    });
  }
}
