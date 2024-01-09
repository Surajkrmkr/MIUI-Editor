import 'dart:io';

import 'package:provider/provider.dart';

import '../constants.dart';
import '../provider/wallpaper.dart';
import 'windows_utils.dart';

class CurrentTheme {
  static String? getPath(context) {
    final provider = Provider.of<WallpaperProvider>(context, listen: false);
    final weekNum = provider.weekNum;
    final themeName = provider.paths![provider.index!]
        .split(Platform.isWindows ? "\\" : "/")
        .last
        .split('.')
        .first;
    final themePath = platformBasedPath(
        "${MIUIConstants.basePath}THEMES\\Week$weekNum\\$themeName\\");
    return themePath;
  }

  static String getTagDirectory(context) {
    final provider = Provider.of<WallpaperProvider>(context, listen: false);
    final weekNum = provider.weekNum;
    final tagPath = platformBasedPath(
        "${MIUIConstants.basePath}THEMES\\Week$weekNum\\1tags\\");
    return tagPath;
  }

  static String? getCurrentThemeName(context) {
    final provider = Provider.of<WallpaperProvider>(context, listen: false);
    final themeName = provider.paths![provider.index!]
        .split(Platform.isWindows ? "\\" : "/")
        .last
        .split('.')
        .first;
    return themeName;
  }

  static Future createWallpaperDirectory({String? themePath}) async {
    await Directory(platformBasedPath("$themePath\\wallpaper\\"))
        .create(recursive: true);
  }

  static Future createLockscreenDirectory({String? themePath}) async {
    await Directory(platformBasedPath("$themePath\\lockscreen\\advance"))
        .create(recursive: true);
  }

  static String getCurrentCopyrightDirectory(context) {
    final provider = Provider.of<WallpaperProvider>(context, listen: false);
    final weekNum = provider.weekNum;
    final copyrightPath = platformBasedPath(
        "${MIUIConstants.basePath}THEMES\\Week$weekNum\\1copyright\\");
    return copyrightPath;
  }
}
