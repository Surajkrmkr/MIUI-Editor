import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:miui_icon_generator/functions/theme_path.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:provider/provider.dart';

import '../constants.dart';
import '../functions/windows_utils.dart';
import '../widgets/ui_widgets.dart';
import 'directory.dart';
import 'icon.dart';

class WallpaperProvider extends ChangeNotifier {
  bool? isLoading = true;
  String? folderNum = "1";
  String? weekNum;

  set setIsLoading(val) {
    isLoading = val;
    notifyListeners();
  }

  int? index = 0;

  void setIndex(int n, context) {
    index = n;
    fetchColorPalette(context);
    Provider.of<DirectoryProvider>(context, listen: false)
        .createThemeDirectory(context: context);
    notifyListeners();
  }

  List<String>? paths = [];
  List<Color>? colorPalette = [];

  set setColorPalette(List<Color> colors) {
    colorPalette = colors;
    notifyListeners();
  }

  void setTotalImage(String num, String week, context) async {
    setIsLoading = true;
    paths!.clear();
    final dir = Directory('${MIUIConstants.preLock}$num');
    folderNum = num;
    weekNum = week;
    final entities = await dir.list().toList();
    entities.map((e) => paths!.add(e.path));
    for (FileSystemEntity file in entities) {
      paths!.add(file.path);
    }
    setIsLoading = false;
    fetchColorPalette(context);
    Provider.of<DirectoryProvider>(context, listen: false)
        .createThemeDirectory(context: context);
    notifyListeners();
  }

  void fetchColorPalette(context) async {
    // ColorPalette.from(basicColors)
    final list = await PaletteGenerator.fromImageProvider(
        FileImage(File(paths![index!])));
    setColorPalette = list.colors.toList();
    Provider.of<IconProvider>(context, listen: false).setBgColor =
        list.dominantColor!.color;
    Provider.of<IconProvider>(context, listen: false).setAccentColor =
        list.dominantColor!.color;
  }

  void exportScreenShot(context, screenshotController) {
    final themeName = CurrentTheme.getCurrentThemeName(context);
    screenshotController.capture().then((Uint8List? image) async {
      final imagePath = File(platformBasedPath(
          '${MIUIConstants.basePath}THEMES\\Week$weekNum\\$themeName.png'));
      await imagePath.writeAsBytes(image!);
      UIWidgets.getBanner(
          content: "Screenshot Generated", context: context, hasError: false);
    });
  }
}
