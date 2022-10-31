import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:xml/xml.dart';

import '../constants.dart';
import '../data/element_map_dart.dart';
import '../data/miui_theme_data.dart';
import '../functions/theme_path.dart';
import '../data/xml data/lockscreen.dart';
import 'element.dart';

class LockscreenProvider extends ChangeNotifier {
  bool? isExporting = true;
  bool? isDefaultPngsCopying = false;

  set setIsExporting(bool val) {
    isExporting = val;
    notifyListeners();
  }

  set setIsDefaultPngsCopying(bool val) {
    isDefaultPngsCopying = val;
    notifyListeners();
  }

  Future copyDefaultPngs({BuildContext? context}) async {
    setIsDefaultPngsCopying = true;
    final themePath = CurrentTheme.getPath(context);
    CurrentTheme.createLockscreenDirectory(themePath: themePath);
    for (var png in MIUIThemeData.lockscreenPngList) {
      await File("${MIUIConstants.sample2Lockscreen!}$png.png")
          .copy("${themePath}lockscreen\\advance$png.png");
    }
    setIsDefaultPngsCopying = false;
  }

  void export({BuildContext? context}) async {
    setIsExporting = true;
    final lockscreen = lockscreenXml.copy();
    final themePath = CurrentTheme.getPath(context);
    final eleProvider = Provider.of<ElementProvider>(context!, listen: false);
    final elementList = eleProvider.elementList;
    for (ElementWidget widget in elementList) {
      final elementFromMap = elementWidgetMap[widget.type];
      dynamic elementXmlFromMap;
      // if (widget.type == ElementType.textLineClock) {
      //   elementXmlFromMap = elementFromMap!["xml"]!(
      //       textName: "d/E", color: "#ffffff", size: "60");
      // } else {
      //   elementXmlFromMap = elementFromMap!["xml"]!;
      // }
      if (elementFromMap!["isIconType"]) {
        elementXmlFromMap = elementFromMap["xml"]!(ele: widget);
      } else {
        elementXmlFromMap = elementFromMap["xml"]!;
      }
      lockscreen
          .findAllElements("Group")
          .toList()
          .firstWhere(
              (element) => element.getAttribute("name") == widget.type!.name)
          .innerXml = elementXmlFromMap;
      await Future.delayed(const Duration(seconds: 5), () {});
      if (elementFromMap["exportable"]) {
        await Directory(
                "$themePath\\lockscreen\\advance\\${elementFromMap["png"]["path"]}")
            .create(recursive: true)
            .then((value) async {
          await elementFromMap["png"]["export"](context);
        });
      }
    }
    await Future.delayed(const Duration(seconds: 5), () {});
    lockscreen
          .findAllElements("Group")
          .toList()
          .firstWhere(
              (element) => element.getAttribute("name") == "bgAlpha")
          .innerXml = getBgAlphaString(alpha: eleProvider.bgAlpha! * 255)!;
    await File("$themePath\\lockscreen\\advance\\manifest.xml")
        .writeAsString(lockscreen.toXmlString(pretty: true, indent: '\t'));
    setIsExporting = false;
  }
}

class ExportLockscreenBtn extends StatelessWidget {
  const ExportLockscreenBtn({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 190,
      child: ElevatedButton(
          style: ElevatedButton.styleFrom(
              backgroundColor: Colors.pinkAccent,
              foregroundColor: Colors.white,
              padding:
                  const EdgeInsets.symmetric(vertical: 23, horizontal: 35)),
          onPressed: () {
            Provider.of<LockscreenProvider>(context, listen: false)
                .export(context: context);
            showDialog(
                barrierDismissible: false,
                context: context,
                builder: (context) {
                  return Consumer<LockscreenProvider>(
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
                                if (provider.isExporting!)
                                  const Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                if (!provider.isExporting!)
                                  const Padding(
                                      padding:
                                          EdgeInsets.symmetric(vertical: 20.0),
                                      child: Text("Lockscreen Exported...")),
                                if (!provider.isExporting!)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 20.0),
                                    child: ElevatedButton(
                                        onPressed: () {
                                          Navigator.pop(context);
                                        },
                                        child: const Text("OK")),
                                  )
                              ],
                            ),
                          ))
                        ],
                      );
                    },
                  );
                });
          },
          child: const Text("Export")),
    );
  }
}
