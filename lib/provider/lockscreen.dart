import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:xml/xml.dart';

import '../data/element_map_dart.dart';
import '../functions/theme_path.dart';
import '../xml data/lockscreen.dart';
import 'element.dart';

class LockscreenProvider extends ChangeNotifier {
  bool? isExporting = true;

  set setIsExporting(bool val) {
    isExporting = val;
    notifyListeners();
  }

  void export({BuildContext? context}) async {
    isExporting = true;
    final lockscreen = lockscreenXml.copy();
    final themePath = CurrentTheme.getPath(context);
    await Directory("$themePath\\lockscreen\\advance").create(recursive: true);
    final elementList =
        Provider.of<ElementProvider>(context!, listen: false).elementList;
    for (ElementWidget widget in elementList) {
      final elementFromMap = elementWidgetMap[widget.type]!;
      lockscreen
          .findAllElements("Group")
          .toList()
          .firstWhere(
              (element) => element.getAttribute("name") == widget.type!.name)
          .innerXml = elementFromMap["xml"];
      if (elementFromMap["exportable"]) {
        await Directory(
                "$themePath\\lockscreen\\advance\\${elementFromMap["png"]["path"]}")
            .create(recursive: true)
            .then((value) async {
          await elementFromMap["png"]["export"](context);
        });
      }
    }
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
                              child: Column(
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
                          ))
                        ],
                      );
                    },
                  );
                });
          },
          child: const Text("Lockscreen")),
    );
  }
}
