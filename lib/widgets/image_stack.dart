import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data.dart';
import '../provider/wallpaper.dart';
import 'icon.dart';

class ImageStack extends StatelessWidget {
  const ImageStack({super.key, required this.isLockscreen});

  final bool isLockscreen;

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
                      provider.setIndex(provider.index! - 1, context);
                    }
                  },
                  icon: const Icon(Icons.navigate_before)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Container(
                  height: 600,
                  width: 276.92,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(40),
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
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(40),
                    child: Stack(
                      children: [
                        Image.file(
                          File(provider.paths![provider.index!]),
                        ),
                        if (!isLockscreen)
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
                                                name: MIUIThemeData
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
                                                name: MIUIThemeData
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
                    if (provider.index != 24) {
                      provider.setIndex(provider.index! + 1, context);
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
