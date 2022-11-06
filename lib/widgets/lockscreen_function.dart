import 'package:flutter/material.dart';
import 'package:miui_icon_generator/widgets/bg_drop_zone.dart';

import '../provider/lockscreen.dart';
import '../provider/mtz.dart';
import '../resources/strings.dart';
import '../screen/lockscreen/lockscreen_page.dart';

class LockscreenFunctions extends StatelessWidget {
  const LockscreenFunctions({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: const [
        Text("BG"),
        Padding(
          padding: EdgeInsets.symmetric(vertical: 20.0),
          child: BGDropZone(
            path: "bg",
          ),
        ),
        BgAlpha(),
        GlobalVarDetailsDialog(),
        SizedBox(
          height: 10,
        ),
        Text("Lockscreen"),
        SizedBox(
          height: 20,
        ),
        ExportLockscreenBtn(),
        SizedBox(
          height: 10,
        ),
        ExportMTZBtn()
      ],
    );
  }
}
