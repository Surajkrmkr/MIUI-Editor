import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants.dart';
import '../../functions/theme_path.dart';
import '../../provider/export.dart';
import '../../provider/module.dart';
import '../../provider/wallpaper.dart';
import '../../widgets/accent_color_list.dart';
import '../../widgets/color_picker.dart';
import '../../widgets/image_stack.dart';
import '../../widgets/module.dart';
import '../../widgets/sliders.dart';
import '../lockscreen/lockscreen_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key, required this.folderNum, required this.weekNum});
  final String? folderNum;
  final String? weekNum;

  @override
  Widget build(BuildContext context) {
    Future.delayed(Duration.zero, () {
      Provider.of<WallpaperProvider>(context, listen: false)
          .setTotalImage(folderNum!, weekNum!, context);
    });
    return Scaffold(
      appBar: AppBar(
        title: const Text("Icon Generator"),
        actions: [accentColorsList()],
      ),
      body: Padding(
          padding: const EdgeInsets.all(30),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const ImageStack(isLockscreen: false),
              Column(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  const ModuleWidget(),
                  Column(
                    children: [
                      const ExportIconsBtn(),
                      const SizedBox(
                        height: 20,
                      ),
                      const ExportModuleBtn(),
                      const SizedBox(
                        height: 20,
                      ),
                      ElevatedButton(
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.pinkAccent,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                  vertical: 23, horizontal: 50)),
                          onPressed: () {
                            final themePath = CurrentTheme.getPath(context);
                            CurrentTheme.createLockscreenDirectory(
                                    themePath: themePath)
                                .then((value) async {
                              await File("${MIUIConstants.preLock!}\\bg.png")
                                  .copy(
                                      "$themePath\\lockscreen\\advance\\bg.png")
                                  .then((value) {
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) =>
                                            const LockscreenPage()));
                              });
                            });
                          },
                          child: const Text("Lockscreen")),
                    ],
                  )
                ],
              ),
              Column(
                children: const [
                  Sliders(),
                  ColorsTab(),
                ],
              ),
            ],
          )),
    );
  }
}
