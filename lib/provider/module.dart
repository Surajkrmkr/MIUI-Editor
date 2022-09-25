import 'dart:io';

import 'package:flutter/material.dart';
import 'package:miui_icon_generator/provider/wallpaper.dart';
import 'package:provider/provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:xml/xml.dart';

import '../data.dart';
import '../resources/color_values.dart';
import '../resources/description.dart';
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
    final provider = Provider.of<WallpaperProvider>(context, listen: false);
    final weekNum = provider.weekNum;
    final themeName =
        provider.paths![provider.index!].split("\\").last.split('.').first;
    final themePath =
        "${MIUIThemeData.rootPath}THEMES\\Week$weekNum\\$themeName\\";
    for (var module in MIUIThemeData.moduleList) {
      await Directory("$themePath$module\\res\\drawable-xxhdpi\\")
          .create(recursive: true);
      final files = await getFiles(module!);
      for (var entity in files) {
        await File(entity.path).copy(
            "$themePath$module\\res\\drawable-xxhdpi\\${entity.path.split("\\").last}");
      }

      final accentColor =
          Provider.of<IconProvider>(context, listen: false).accentColor;
      final document = XmlDocument.parse(ColorValues.getXmlString![module]!
          .replaceAll("#ffff8cee", colorToHexString(accentColor)));
      await File("$themePath$module\\theme_values.xml")
          .writeAsString(document.toXmlString(pretty: true, indent: '\t'));
    }

    await contactPngController!.captureAndSave(
        "$themePath${MIUIThemeData.moduleList[0]}\\res\\drawable-xxhdpi",
        fileName: "${MIUIThemeData.contactsPngs[0]}.png",
        pixelRatio: 2);
    await dialerPngController!.captureAndSave(
        "$themePath${MIUIThemeData.moduleList[0]}\\res\\drawable-xxhdpi",
        fileName: "${MIUIThemeData.contactsPngs[1]}.png",
        pixelRatio: 2);
    final document = XmlDocument.parse(
        ThemeDesc.getXmlString()!.replaceAll("Test", themeName));
    await File("$themePath\\theme_values.xml")
        .writeAsString(document.toXmlString(pretty: true, indent: '\t'));
    setIsCopying = false;
  }

  colorToHexString(Color? color) {
    return '#FF${color!.value.toRadixString(16).substring(2, 8)}';
  }

  Future<List<FileSystemEntity>> getFiles(String module) async {
    return await Directory(
            "E:\\Xiaomi Contract\\Sample2\\$module\\res\\drawable-xxhdpi")
        .list()
        .toList();
  }
}

class ExportModuleBtn extends StatelessWidget {
  const ExportModuleBtn({super.key});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
        style: ElevatedButton.styleFrom(
            backgroundColor: Colors.pinkAccent,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 23, horizontal: 35)),
        onPressed: () {
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
                            child: Column(
                          children: [
                            if (provider.isCopying!)
                              const CircularProgressIndicator(),
                            if (!provider.isCopying!)
                              Padding(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 20.0),
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
                        ))
                      ],
                    );
                  },
                );
              });
        },
        child: const Text("Module Export"));
  }
}
