import 'dart:io';

import 'package:flutter/material.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:provider/provider.dart';

import '../constants.dart';
import 'icon.dart';

class WallpaperProvider extends ChangeNotifier {
  bool? isLoading = true;
  String? folderNum = "1";

  set setIsLoading(val) {
    isLoading = val;
    notifyListeners();
  }

  int? index = 0;

  void setIndex(int n, context) {
    index = n;
    fetchColorPalette(context);
    notifyListeners();
  }

  List<String>? paths = [];
  List<Color>? colorPalette = [];

  set setColorPalette(List<Color> colors) {
    colorPalette = colors;
    notifyListeners();
  }

  void setTotalImage(String num, context) async {
    setIsLoading = true;
    final dir = Directory('${MIUIConstants.preLock}$num');
    folderNum = num;
    final entities = await dir.list().toList();
    entities.map((e) => paths!.add(e.path));
    for (FileSystemEntity file in entities) {
      paths!.add(file.path);
    }
    setIsLoading = false;
    fetchColorPalette(context);
    notifyListeners();
  }

  void fetchColorPalette(context) async {
    // ColorPalette.from(basicColors)
    final list = await PaletteGenerator.fromImageProvider(
        FileImage(File(paths![index!])));
    setColorPalette = list.colors.toList();
    Provider.of<IconProvider>(context, listen: false).setBgColor =
        list.dominantColor!.color;
  }
}
