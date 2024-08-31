import 'package:flutter/material.dart';
import 'package:miui_icon_generator/constants.dart';
import 'package:miui_icon_generator/widgets/bg_drop_zone.dart';

import '../provider/lockscreen.dart';
import '../provider/mtz.dart';
import '../resources/strings.dart';
import '../screen/lockscreen/lockscreen_page.dart';
import '../screen/lockscreen/preset.dart';

class LockscreenFunctions extends StatelessWidget {
  const LockscreenFunctions({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          if (MIUIConstants.isDesktop) const Text("BG"),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20.0),
            child: BGDropZone(
              path: "bg",
            ),
          ),
          const BgAlpha(),
          const GlobalVarDetailsDialog(),
          const SizedBox(height: 10),
          const PresetLockscreenDialog(),
          const SizedBox(height: 10),
          const Text("Lockscreen"),
          const SizedBox(height: 20),
          const AILockscreenBtn(),
          const SizedBox(height: 10),
          const PresetLockscreenBtn(),
          Container(
            height: 5,
            width: 60,
            margin: const EdgeInsets.symmetric(vertical: 20),
            decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.5),
                borderRadius: const BorderRadius.all(Radius.circular(10))),
          ),
          const ExportLockscreenBtn(),
          const SizedBox(
            height: 10,
          ),
          const ExportMTZBtn()
        ],
      ),
    );
  }
}
