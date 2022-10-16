import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../provider/directory.dart';
import '../../provider/icon.dart';
import '../../provider/lockscreen.dart';
import '../../provider/module.dart';
import '../../provider/wallpaper.dart';
import '../../widgets/accent_color_list.dart';
import '../../widgets/color_picker.dart';
import '../../widgets/image_stack.dart';
import '../../widgets/module.dart';
import '../../widgets/sliders.dart';
import '../Landing_page.dart';
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
        title: Row(
          children: [
            const Text("Theme Generator"),
            const SizedBox(
              width: 20,
            ),
            getProgress(),const SizedBox(
              width: 20,
            ),
            directoryCreatingLoading()
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.home_rounded),
          onPressed: () {
            Navigator.pushReplacement(context,
                MaterialPageRoute(builder: (context) => LandingPage()));
          },
        ),
        actions: [accentColorsList(isLockscreen: false)],
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
                      buildLockscreenBtn(context: context)
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

Widget buildLockscreenBtn({BuildContext? context}) {
  return Consumer<LockscreenProvider>(builder: (context, provider, _) {
    return ElevatedButton(
        style: ElevatedButton.styleFrom(
            backgroundColor: Colors.pinkAccent,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 23, horizontal: 50)),
        onPressed: () {
          provider.copyDefaultPngs(context: context).then((value) =>
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const LockscreenPage())));
        },
        child: provider.isDefaultPngsCopying!
            ? const Center(
                child: CircularProgressIndicator(
                  color: Colors.white,
                ),
              )
            : const Text("Lockscreen"));
  });
}

Widget getProgress() {
  return Consumer<WallpaperProvider>(builder: (context, provider, _) {
    return Row(
      children: [
        SizedBox(
          width: 200,
          height: 10,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: provider.index! / 25,
              backgroundColor: Colors.black12,
            ),
          ),
        ),
        const SizedBox(
          width: 20,
        ),
        Text(
          "${25 - provider.index!} left",
          style: Theme.of(context).textTheme.bodyMedium,
        )
      ],
    );
  });
}

Widget directoryCreatingLoading() {
  return Consumer<DirectoryProvider>(builder: (context, provider, _) {
    if (provider.isCreating!) {
      return Row(
        children: [
          const SizedBox(
              width: 30, height: 30, child: CircularProgressIndicator()),
          const SizedBox(
            width: 20,
          ),
          Text(
            "Creating Directory",
            style: Theme.of(context).textTheme.bodyMedium,
          )
        ],
      );
    }
    return Container();
  });
}
