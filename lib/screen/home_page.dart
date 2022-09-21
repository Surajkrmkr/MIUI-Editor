import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../provider/icon.dart';
import '../provider/wallpaper.dart';
import '../widgets/color_picker.dart';
import '../widgets/image_stack.dart';
import '../widgets/textfield.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key, required this.folderNum});
  final String? folderNum;

  @override
  Widget build(BuildContext context) {
    Future.delayed(Duration.zero, () {
      Provider.of<WallpaperProvider>(context, listen: false)
          .setTotalImage(folderNum!,context);
    });
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Icon Generator"),
        actions: [
          Consumer<WallpaperProvider>(builder: (context, provider, child) {
            if (provider.isLoading!) {
              return const CircularProgressIndicator();
            }
            return Row(
              children: provider.colorPalette!
                  .map((e) => Padding(
                        padding: const EdgeInsets.only(right: 3),
                        child: MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: InkWell(
                            onTap: () => Provider.of<IconProvider>(context,
                                    listen: false)
                                .setBgColor = e,
                            child: Container(
                              height: 40,
                              width: 40,
                              decoration: BoxDecoration(
                                  color: e,
                                  borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ),
                      ))
                  .toList(),
            );
          })
        ],
      ),
      body: Padding(
          padding: const EdgeInsets.all(30),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: const [
              ImageStack(),
              TextFields(),
              ColorsTab(),
            ],
          )),
    );
  }
}
