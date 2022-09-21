import 'dart:io';

import 'package:flutter/material.dart';
import 'package:screenshot/screenshot.dart';

import '../constants.dart';
import '../data.dart';
import '../widgets/icon.dart';
import 'icon.dart';

class ExportIconProvider extends ChangeNotifier {
  bool? isExporting = true;
  int? progress = 0;

  set setProgress(int? p) {
    progress = p;
    notifyListeners();
  }

  bool get getIsExporting => isExporting!;

  set setIsExporting(bool val) {
    isExporting = val;
    notifyListeners();
  }

  void export(
      {IconProvider? provider, String? folderNum, String? wallNum}) async {
    setIsExporting = true;
    try {
      for (String? element in IconVectorData.vectorList) {
        final ScreenshotController screenshotController =
            ScreenshotController();
        screenshotController
            .captureFromWidget(
                IconWidget(
                  name: element,
                  bgColor: provider!.bgColor,
                  iconColor: provider.iconColor,
                  margin: provider.margin,
                  padding: provider.padding,
                  radius: provider.radius,
                  borderColor: provider.borderColor,
                  borderWidth: provider.borderWidth,
                ),
                pixelRatio: 4)
            .then((value) async {
          final imagePath = await File(
                  '${MIUIConstants.prePare}$folderNum\\$wallNum\\$element.png')
              .create(recursive: true);
          await imagePath.writeAsBytes(value);
          setProgress = progress! + 1;
          if (progress == IconVectorData.vectorList.length) {
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
