import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:download_task/download_task.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:miui_icon_generator/functions/theme_path.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:provider/provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:image/image.dart' as img;

import '../constants.dart';
import '../functions/shared_prefs.dart';
import '../functions/windows_utils.dart';
import '../widgets/ui_widgets.dart';
import 'directory.dart';
import 'icon.dart';
import 'module.dart';
import 'tag.dart';

class WallpaperProvider extends ChangeNotifier {
  bool? isLoading = true;
  String? folderNum = "1";
  String? weekNum;
  int totalThemeCount = 25;
  DownloadTask? task;

  bool isDownloading = false;

  set setIsLoading(val) {
    isLoading = val;
    notifyListeners();
  }

  set setIsDownloading(val) {
    isDownloading = val;
    notifyListeners();
  }

  int? index = 0;

  void setIndex(int n, context) {
    index = n;
    fetchColorPalette(context);
    Provider.of<DirectoryProvider>(context, listen: false)
        .createThemeDirectory(context: context);
    Provider.of<TagProvider>(context, listen: false).getTagsFromFile(context);
    checkExported(context);
    notifyListeners();
  }

  List<String>? paths = [];
  List<Color>? colorPalette = [];

  set setColorPalette(List<Color> colors) {
    colorPalette = colors;
    notifyListeners();
  }

  void setWeekWallNum(String num, String week) {
    folderNum = num;
    weekNum = week;
    notifyListeners();
  }

  void setTotalImage(String num, String week, context) async {
    setIsLoading = true;
    paths!.clear();
    final dir = Directory('${MIUIConstants.preLock}$num');
    setWeekWallNum(num, week);
    totalThemeCount = SharedPrefs.getDataFromSF().themeCount;
    final entities = await dir.list().toList();
    entities.map((e) => paths!.add(e.path));
    for (FileSystemEntity file in entities) {
      if (file.path.endsWith(".jpg")) paths!.add(file.path);
    }
    setIsLoading = false;
    fetchColorPalette(context);
    Provider.of<DirectoryProvider>(context, listen: false)
        .createThemeDirectory(context: context);
    checkExported(context);
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

  void checkExported(context) async {
    Provider.of<IconProvider>(context, listen: false)
        .checkAlreadyExport(context: context);
    Provider.of<ModuleProvider>(context, listen: false)
        .checkAlreadyExport(context: context);
  }

  void exportScreenShot(context, ScreenshotController screenshotController) {
    final themeName = CurrentTheme.getCurrentThemeName(context);
    screenshotController.capture().then((Uint8List? image) async {
      final imagePath = File(platformBasedPath(
          '${MIUIConstants.basePath}THEMES\\Week$weekNum\\$themeName.png'));
      await imagePath.writeAsBytes(image!);
      UIWidgets.getBanner(
          content: "Screenshot Generated", context: context, hasError: false);
    });
  }

  Future<DownloadTask> downloadWallpaper(String url, String name) async {
    final path = '${MIUIConstants.preLock}$folderNum/$name.jpg';
    task = await DownloadTask.download(Uri.parse(url), file: File(path));
    setIsDownloading = true;
    if (url.endsWith(".png")) {
      final image = img.decodeImage(await task!.file.readAsBytes())!;
      await File(path).writeAsBytes(img.encodePng(image));
    }
    return task!;
  }

  Future<void> makeCopyrightZip(
      String pageUrl, String name, BuildContext context) async {
    final path = CurrentTheme.getCurrentCopyrightDirectory(context);
    await Directory(platformBasedPath(path)).create(recursive: true);
    final file = await File("$path$name.txt").writeAsString(pageUrl);
    var encoder = ZipFileEncoder();
    encoder.create(platformBasedPath("$path\\$name.zip"));
    await encoder.addFile(file);
    encoder.close();
    await file.delete();
  }
}
