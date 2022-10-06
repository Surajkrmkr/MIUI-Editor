import 'package:flutter/material.dart';

import '../../provider/lockscreen.dart';
import '../../widgets/accent_color_list.dart';
import '../../widgets/element_info.dart';
import '../../widgets/font.dart';
import '../../widgets/image_stack.dart';

class LockscreenPage extends StatelessWidget {
  const LockscreenPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Lockscreen"),
        actions: [accentColorsList()],
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
                        height: 50,
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
}
