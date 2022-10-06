import 'dart:io';

import 'package:provider/provider.dart';

import '../data/miui_theme_data.dart';
import '../provider/wallpaper.dart';

class CurrentTheme {
  static String? getPath(context) {
    final provider = Provider.of<WallpaperProvider>(context, listen: false);
    final weekNum = provider.weekNum;
    final themeName =
        provider.paths![provider.index!].split("\\").last.split('.').first;
    final themePath =
        "${MIUIThemeData.rootPath}THEMES\\Week$weekNum\\$themeName\\";
    return themePath;
  }

  static Future createIconDirectory({String? themePath}) async {
    await Directory("$themePath\\icons\\res\\drawable-xhdpi\\")
        .create(recursive: true);
    await Directory("$themePath\\icons\\res\\drawable-xxhdpi\\")
        .create(recursive: true);
  }

  static Future createWallpaperDirectory({String? themePath}) async {
    await Directory("$themePath\\wallpaper\\").create(recursive: true);
  }
}
