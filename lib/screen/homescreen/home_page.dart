import 'dart:io';

import 'package:flutter/material.dart';
import 'package:miui_icon_generator/constants.dart';
import 'package:miui_icon_generator/screen/landing/export.dart';
import 'package:provider/provider.dart';
import '../../provider/directory.dart';
import '../../provider/icon.dart';
import '../../provider/lockscreen.dart';
import '../../provider/module.dart';
import '../../provider/tag.dart';
import '../../provider/wallpaper.dart';
import '../../widgets/accent_color_list.dart';
import '../../widgets/color_picker.dart';
import '../../widgets/image_stack.dart';
import '../../widgets/module.dart';
import '../../widgets/sliders.dart';
import '../../widgets/tags.dart';
import '../../widgets/ui_widgets.dart';
import '../lockscreen/lockscreen_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key, required this.folderNum, required this.weekNum});
  final String folderNum;
  final String weekNum;

  @override
  Widget build(BuildContext context) {
    Future.delayed(Duration.zero, () {
      Provider.of<WallpaperProvider>(context, listen: false)
          .setTotalImage(folderNum, weekNum, context);
    });
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            if (MIUIConstants.isDesktop)
              const SizedBox(width: 220, child: Text("Theme Generator")),
            Padding(
              padding: EdgeInsets.symmetric(
                  horizontal: MIUIConstants.isDesktop ? 20.0 : 5),
              child: getProgress(),
            ),
            directoryCreatingLoading()
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.home_rounded),
          onPressed: () {
            Navigator.pushReplacement(context,
                MaterialPageRoute(builder: (context) => const LandingPage()));
          },
        ),
        actions: [
          if (MIUIConstants.isDesktop) accentColorsList(isLockscreen: false)
        ],
      ),
      body: Padding(
          padding:
              Platform.isAndroid ? EdgeInsets.zero : const EdgeInsets.all(30),
          child: Platform.isAndroid
              ? SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      ImageStack(isLockscreen: false),
                      const SizedBox(
                        height: 20,
                      ),
                      if (Platform.isAndroid)
                        accentColorsList(isLockscreen: false),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          const ModuleWidget(),
                          Column(
                            children: [
                              const ExportIconsBtn(),
                              const SizedBox(
                                height: 5,
                              ),
                              const ExportModuleBtn(),
                              const SizedBox(
                                height: 5,
                              ),
                              buildLockscreenBtn(context: context)
                            ],
                          )
                        ],
                      ),
                      Column(
                        children: [
                          const Sliders(),
                          const ColorsTab(),
                          Tags(themeName: null)
                        ],
                      ),
                    ],
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    ImageStack(isLockscreen: false),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        const ModuleWidget(),
                        Column(
                          children: [
                            Consumer<TagProvider>(
                                builder: (context, provider, _) => Visibility(
                                    visible: provider.appliedTags.length != 6,
                                    child: Text(
                                      "Please Select 6 Tags",
                                      style: TextStyle(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .error),
                                    ))),
                            const SizedBox(height: 20),
                            const ExportIconsBtn(),
                            const SizedBox(height: 20),
                            const ExportModuleBtn(),
                            const SizedBox(height: 20),
                            buildLockscreenBtn(context: context)
                          ],
                        )
                      ],
                    ),
                    const SingleChildScrollView(
                      child: Column(
                        children: [
                          Sliders(),
                          IconBgDropZones(),
                          ColorsTab(),
                        ],
                      ),
                    ),
                    Tags(themeName: null)
                  ],
                )),
    );
  }
}

Widget buildLockscreenBtn({BuildContext? context}) {
  return Consumer<LockscreenProvider>(builder: (context, provider, _) {
    if (provider.isDefaultPngsCopying!) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }
    return UIWidgets.getElevatedButton(
        text: "Lockscreen",
        icon: const Icon(Icons.lock),
        onTap: () => provider.copyDefaultPngs(context: context).then((value) =>
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const LockscreenPage()))));
  });
}

Widget getProgress() {
  return Consumer<WallpaperProvider>(builder: (context, provider, _) {
    return Row(
      children: [
        SizedBox(
          width: MIUIConstants.isDesktop ? 200 : 100,
          height: 10,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: (provider.index!) / 24,
              backgroundColor: Colors.black12,
            ),
          ),
        ),
        const SizedBox(
          width: 20,
        ),
        Text(
          provider.index == (provider.totalThemeCount - 1)
              ? ""
              : "${provider.totalThemeCount - provider.index! - 1} left",
          style: Theme.of(context).textTheme.bodyMedium,
        )
      ],
    );
  });
}

Widget directoryCreatingLoading() {
  return Consumer<DirectoryProvider>(builder: (context, provider, _) {
    if (provider.isCreating!) {
      return const SizedBox(
          width: 30, height: 30, child: CircularProgressIndicator());
    }
    return Container();
  });
}
