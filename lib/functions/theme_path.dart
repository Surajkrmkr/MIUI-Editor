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

  static String? getCurrentThemeName(context) {
    final provider = Provider.of<WallpaperProvider>(context, listen: false);
    final themeName =
        provider.paths![provider.index!].split("\\").last.split('.').first;
    return themeName;
  }

  static Future createWallpaperDirectory({String? themePath}) async {
    await Directory("$themePath\\wallpaper\\").create(recursive: true);
  }

  static Future createLockscreenDirectory({String? themePath}) async {
    await Directory("$themePath\\lockscreen\\advance").create(recursive: true);
  }
}
