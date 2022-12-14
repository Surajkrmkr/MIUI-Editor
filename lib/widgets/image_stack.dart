import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants.dart';
import '../provider/wallpaper.dart';
import '../screen/homescreen/icon_preview.dart';
import '../screen/lockscreen/element_widget_preview.dart';

class ImageStack extends StatelessWidget {
  const ImageStack({super.key, required this.isLockscreen});
  final bool? isLockscreen;
  @override
  Widget build(BuildContext context) {
    return Consumer<WallpaperProvider>(builder: (context, provider, _) {
      if (provider.isLoading!) {
        return const CircularProgressIndicator();
      }
      return Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              if (!(provider.index != 0) && Platform.isWindows)
                const SizedBox(
                  width: 40,
                ),
              if (!isLockscreen! && provider.index != 0)
                IconButton(
                    onPressed: () {
                      final provider = Provider.of<WallpaperProvider>(context,
                          listen: false);
                      provider.setIndex(provider.index! - 1, context);
                    },
                    icon: const Icon(Icons.navigate_before)),
              Padding(
                padding: Platform.isAndroid
                    ? EdgeInsets.zero
                    : const EdgeInsets.symmetric(horizontal: 20.0),
                child: Container(
                  height: MIUIConstants.screenHeight,
                  width: MIUIConstants.screenWidth,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(40),
                    image: DecorationImage(
                      image: FileImage(
                        File(provider.paths![provider.index!]),
                      ),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        spreadRadius: 2,
                        blurRadius: 9,
                        offset:
                            const Offset(5, 5), // changes position of shadow
                      ),
                    ],
                  ),
                  child: !isLockscreen!
                      ? const PreviewIcons()
                      : const ElementWidgetPreview(),
                ),
              ),
              if (!isLockscreen! && (provider.index != 24))
                IconButton(
                    onPressed: () {
                      final provider = Provider.of<WallpaperProvider>(context,
                          listen: false);
                      provider.setIndex(provider.index! + 1, context);
                    },
                    icon: const Icon(Icons.navigate_next)),
              if (!(provider.index != 24) && Platform.isWindows)
                const SizedBox(
                  width: 40,
                )
            ],
          ),
          if (Platform.isAndroid)
            const SizedBox(
              height: 20,
            ),
          if (isLockscreen! && Platform.isWindows)
            Text(
              provider.paths![provider.index!]
                  .split(Platform.isWindows ? "\\" : "/")
                  .last,
              style: const TextStyle(fontWeight: FontWeight.bold),
            )
        ],
      );
    });
  }
}
