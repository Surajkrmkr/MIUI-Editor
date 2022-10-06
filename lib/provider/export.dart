import 'dart:io';

import 'package:flutter/material.dart';
import 'package:miui_icon_generator/provider/wallpaper.dart';
import 'package:provider/provider.dart';
import 'package:screenshot/screenshot.dart';

import '../data/miui_theme_data.dart';
import '../functions/theme_path.dart';
import '../widgets/icon.dart';
import 'icon.dart';

class ExportIconProvider extends ChangeNotifier {
  bool? isIconsExporting = true;
  int? progress = 0;

  set setProgress(int? p) {
    progress = p;
    notifyListeners();
  }

  set setIsExporting(bool val) {
    isIconsExporting = val;
    notifyListeners();
  }

  void export({BuildContext? context}) async {
    final provider = Provider.of<IconProvider>(context!, listen: false);
    final themePath = CurrentTheme.getPath(context);

    setIsExporting = true;
    CurrentTheme.createIconDirectory(themePath: themePath);
    try {
      for (String? element in MIUIThemeData.vectorList) {
        ScreenshotController()
            .captureFromWidget(
                IconWidget(
                  name: element,
                  bgColor: provider.bgColor,
                  iconColor: provider.iconColor,
                  margin: provider.margin,
                  padding: provider.padding,
                  radius: provider.radius,
                  borderColor: provider.borderColor,
                  borderWidth: provider.borderWidth,
                ),
                pixelRatio: 4)
            .then((value) async {
          final imagePath = File(
              '$themePath\\icons\\res\\drawable-xhdpi\\$element.png');
          await imagePath.writeAsBytes(value);
          final imagePath2 = File(
              '$themePath\\icons\\res\\drawable-xxhdpi\\$element.png');
          await imagePath2.writeAsBytes(value);
          setProgress = progress! + 1;
          if (progress == MIUIThemeData.vectorList.length) {
            setIsExporting = false;
            setProgress = 0;
          }
        });
      }
    } on Exception catch (e) {
      debugPrint(e.toString());
    }
  }
}

class ExportIconsBtn extends StatelessWidget {
  const ExportIconsBtn({super.key});

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
            Provider.of<ExportIconProvider>(context, listen: false)
                .export(context: context);
            showDialog(
                barrierDismissible: false,
                context: context,
                builder: (context) {
                  return Consumer<ExportIconProvider>(
                    builder: (context, provider, _) {
                      final progress = provider.progress;
                      final total = MIUIThemeData.vectorList.length;
                      return SimpleDialog(
                        contentPadding: const EdgeInsets.all(20),
                        title: const Center(child: Text("Get Set Go")),
                        children: [
                          Center(
                              child: Column(
                            children: [
                              if (provider.isIconsExporting!)
                                LinearProgressIndicator(
                                  value: progress!.toDouble() / total,
                                ),
                              if (provider.isIconsExporting!)
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Text(
                                      "${provider.progress.toString()}/$total"),
                                ),
                              if (!provider.isIconsExporting!)
                                const Padding(
                                    padding:
                                        EdgeInsets.symmetric(vertical: 20.0),
                                    child: Text("Icons Export Completed...")),
                              if (!provider.isIconsExporting!)
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
          child: const Text("Icon Export")),
    );
  }
}
