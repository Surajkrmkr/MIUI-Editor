import 'dart:io';

import 'package:flutter/material.dart';
import 'package:miui_icon_generator/provider/wallpaper.dart';
import 'package:provider/provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:xml/xml.dart';

import '../constants.dart';
import '../data/miui_theme_data.dart';
import '../functions/theme_path.dart';
import '../functions/windows_utils.dart';
import '../resources/color_values.dart';
import '../resources/description.dart';
import '../resources/nine_svg.dart';
import '../widgets/ui_widgets.dart';
import 'icon.dart';

class ModuleProvider extends ChangeNotifier {
  bool? isCopying = true;
  ScreenshotController? contactPngController = ScreenshotController();
  ScreenshotController? dialerPngController = ScreenshotController();
  ScreenshotController? qsBigTileController = ScreenshotController();

  set setIsCopying(val) {
    isCopying = val;
    notifyListeners();
  }

  void copyModule({context}) async {
    setIsCopying = true;
    final themePath = CurrentTheme.getPath(context);
    for (var module in MIUIThemeData.moduleList) {
      for (var subDir in MIUIThemeData.subDirectoryList) {
        final files = await getFiles(module, subDir);
        for (var entity in files) {
          await File(entity.path).copy(platformBasedPath(
              "$themePath$module\\$subDir\\${entity.path.split(Platform.isWindows ? "\\" : "/").last}"));
        }
        await File(platformBasedPath(
                "${MIUIConstants.sample2}$module\\theme_fallback.xml"))
            .copy(platformBasedPath("$themePath$module\\theme_fallback.xml"));
        final accentColor =
            Provider.of<IconProvider>(context, listen: false).accentColor;
        final document = XmlDocument.parse(ColorValues.getXmlString![module]!
            .replaceAll("#ffff8cee", colorToHexString(accentColor)));
        await File(platformBasedPath("$themePath$module\\theme_values.xml"))
            .writeAsString(document.toXmlString(pretty: true, indent: '\t'));
      }
    }

    for (var patch in NineSvg.patches) {
      ScreenshotController()
          .captureFromWidget(patch(context)["widget"],
              pixelRatio: 1, targetSize: patch(context)["size"])
          .then((value) async {
        for (var png in patch(context)["list"]) {
          for (var dir in png["path"]) {
            final imagePath =
                File(platformBasedPath('$themePath$dir${png["name"]}.png'));
            await imagePath.writeAsBytes(value);
          }
        }
      });
    }

    await contactPngController!.captureAndSave(
        platformBasedPath(
            "$themePath${MIUIThemeData.moduleList[0]}\\res\\drawable-xxhdpi"),
        fileName: "${MIUIThemeData.contactsPngs[0]}.png",
        pixelRatio: 2);
    await dialerPngController!.captureAndSave(
        platformBasedPath(
            "$themePath${MIUIThemeData.moduleList[0]}\\res\\drawable-xxhdpi"),
        fileName: "${MIUIThemeData.contactsPngs[1]}.png",
        pixelRatio: 2);
    final wallpaperProvider =
        Provider.of<WallpaperProvider>(context, listen: false);
    await File(wallpaperProvider.paths![wallpaperProvider.index!]).copy(
        platformBasedPath("$themePath\\wallpaper\\default_lock_wallpaper.jpg"));
    await File(wallpaperProvider.paths![wallpaperProvider.index!]).copy(
        platformBasedPath("$themePath\\wallpaper\\default_wallpaper.jpg"));
    await File(platformBasedPath("$themePath\\clock_2x4\\manifest.xml"))
        .writeAsString(XmlDocument.parse(ThemeDesc.clockManifest()!)
            .toXmlString(pretty: true, indent: '\t'));
    final desc = XmlDocument.parse(ThemeDesc.getXmlString()!.replaceAll("Test",
        themePath!.split(platformBasedPath("\\")).reversed.toList()[1]));
    await File(platformBasedPath("$themePath\\description.xml"))
        .writeAsString(desc.toXmlString(pretty: true, indent: '\t'));
    final pluginInfo = XmlDocument.parse(ThemeDesc.pluginInfo()!);
    await File(platformBasedPath("$themePath\\plugin_config.xml"))
        .writeAsString(pluginInfo.toXmlString(pretty: true, indent: '\t'));
    setIsCopying = false;
  }

  colorToHexString(Color? color) {
    return '#FF${color!.value.toRadixString(16).substring(2, 8)}';
  }

  Future<List<FileSystemEntity>> getFiles(String module, String subDir) async {
    return await Directory(
            platformBasedPath("${MIUIConstants.sample2}$module\\$subDir"))
        .list()
        .toList();
  }
}

class ExportModuleBtn extends StatelessWidget {
  const ExportModuleBtn({super.key});

  void onTap(context) {
    Provider.of<ModuleProvider>(context, listen: false)
        .copyModule(context: context);
    showDialog(
        barrierDismissible: false,
        context: context,
        builder: (context) {
          return Consumer<ModuleProvider>(
            builder: (context, provider, _) {
              return SimpleDialog(
                contentPadding: const EdgeInsets.all(20),
                title: const Center(child: Text("Get Set Go")),
                children: [
                  Center(
                      child: SizedBox(
                    height: 150,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        if (provider.isCopying!)
                          const CircularProgressIndicator(),
                        if (!provider.isCopying!)
                          Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 20.0),
                              child: Column(
                                children: [
                                  const Text("Module Export Completed..."),
                                  const SizedBox(
                                    height: 30,
                                  ),
                                  ElevatedButton(
                                      onPressed: () {
                                        Navigator.pop(context);
                                      },
                                      child: const Text("OK")),
                                ],
                              )),
                      ],
                    ),
                  ))
                ],
              );
            },
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    return UIWidgets.getElevatedButton(
        text: "Module Export",
        icon: const Icon(Icons.smart_toy),
        onTap: () => onTap(context));
  }
}
