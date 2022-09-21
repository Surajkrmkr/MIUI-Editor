import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import '../data.dart';
import '../provider/icon.dart';
import '../provider/wallpaper.dart';
import '../widgets/color_picker.dart';
import '../widgets/textfield.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key, required this.folderNum});
  final String? folderNum;

  @override
  Widget build(BuildContext context) {
    Future.delayed(Duration.zero, () {
      Provider.of<WallpaperProvider>(context, listen: false)
          .setTotalImage(folderNum!);
    });
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        centerTitle: true,
        title: const Text("Icon Generator"),
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

class IconContainer extends StatelessWidget {
  final String? name;
  const IconContainer({
    Key? key,
    required this.name,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<IconProvider>(
      builder: (context, provider, _) {
        return SizedBox(
          height: 45,
          width: 45,
          child: Container(
            margin: EdgeInsets.all(provider.margin!),
            child: Container(
              padding: EdgeInsets.all(provider.padding!),
              height: 130,
              width: 130,
              decoration: BoxDecoration(
                  border: Border.all(
                      width: provider.borderWidth!,
                      color: provider.borderColor!),
                  borderRadius: BorderRadius.circular(provider.radius!),
                  color: provider.bgColor),
              child: Center(
                  child: SvgPicture.asset(
                "assets/icons/$name.svg",
                color: provider.iconColor,
              )),
            ),
          ),
        );
      },
    );
  }
}

class ImageStack extends StatelessWidget {
  const ImageStack({super.key});

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
            children: [
              IconButton(
                  onPressed: () {
                    final provider =
                        Provider.of<WallpaperProvider>(context, listen: false);
                    if (provider.index != 0) {
                      provider.setIndex = provider.index! - 1;
                    }
                  },
                  icon: const Icon(Icons.navigate_before)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(40),
                  child: SizedBox(
                    height: 600,
                    width: 276.92,
                    child: Stack(
                      children: [
                        Image.file(
                          File(provider.paths![provider.index!]),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(
                              bottom: 50.0, left: 10, right: 10),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: List.generate(
                                          4,
                                          (index) => IconContainer(
                                              name: IconVectorData
                                                  .vectorList[index + 5]))
                                      .toList()),
                              const SizedBox(
                                height: 10,
                              ),
                              Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: List.generate(
                                          4,
                                          (index) => IconContainer(
                                              name: IconVectorData
                                                  .vectorList[index + 9]))
                                      .toList()),
                            ],
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              ),
              IconButton(
                  onPressed: () {
                    final provider =
                        Provider.of<WallpaperProvider>(context, listen: false);
                    if (provider.index != 25) {
                      provider.setIndex = provider.index! + 1;
                    }
                  },
                  icon: const Icon(Icons.navigate_next)),
            ],
          ),
          Text(
            provider.paths![provider.index!].split("\\").last,
            style: const TextStyle(fontWeight: FontWeight.bold),
          )
        ],
      );
    });
  }
}
