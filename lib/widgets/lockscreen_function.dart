import 'dart:io';

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
    return SingleChildScrollView(
      child: Column(
        children: [
          if (Platform.isWindows) const Text("BG"),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20.0),
            child: BGDropZone(
              path: "bg",
            ),
          ),
          const BgAlpha(),
          const GlobalVarDetailsDialog(),
          const SizedBox(
            height: 10,
          ),
          const Text("Lockscreen"),
          const SizedBox(
            height: 20,
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
