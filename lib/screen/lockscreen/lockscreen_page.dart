import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/element_map_dart.dart';
import '../../provider/element.dart';
import '../../provider/lockscreen.dart';
import '../../widgets/accent_color_list.dart';
import '../../widgets/bg_drop_zone.dart';
import '../../widgets/element_info.dart';
import '../../widgets/font.dart';
import '../../widgets/image_stack.dart';
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
        title: Row(
          children: [
            const Text("Lockscreen"),
            const SizedBox(
              width: 20,
            ),
            getProgress()
          ],
        ),
        actions: [accentColorsList(isLockscreen: true)],
      ),
      body: Padding(
        padding: const EdgeInsets.all(30),
        child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const ImageStack(isLockscreen: true),
              Row(
                children: [
                  const ElementInfo(),
                  Column(
                    children: const [
                      FontPreview(),
                      SizedBox(
                        height: 20,
                      ),
                      BGDropZone(),
                      SizedBox(
                        height: 20,
                      ),
                      ExportLockscreenBtn()
                    ],
                  ),
                  const FontListWidget(),
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
