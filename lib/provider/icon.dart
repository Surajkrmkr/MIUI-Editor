import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:xml/xml.dart';

import '../data/miui_theme_data.dart';
import '../data/xml data/lockscreen.dart';
import '../functions/theme_path.dart';
import '../functions/windows_utils.dart';
import '../widgets/icon.dart';
import '../widgets/ui_widgets.dart';
import 'userprofile.dart';

class IconProvider extends ChangeNotifier {
  double? margin = 4;
  bool? isIconsExporting = false;
  bool isExported = false;
  int? progress = 0;
  List<dynamic> iconAssetsPath = [];

  set setMargin(double m) {
    margin = m;
    notifyListeners();
  }

  double? padding = 9;

  set setPadding(double p) {
    padding = p;
    notifyListeners();
  }

  double? radius = 10;

  set setRadius(double r) {
    radius = r;
    notifyListeners();
  }

  Color? bgColor = Colors.pinkAccent;

  set setBgColor(Color c) {
    bgColor = c;
    notifyListeners();
  }

  Color? bgColor2 = Colors.pinkAccent;

  set setBgColor2(Color c) {
    bgColor2 = c;
    notifyListeners();
  }

  AlignmentGeometry? bgGradAlign = Alignment.topLeft;

  set setbgGradAlign(AlignmentGeometry c) {
    bgGradAlign = c;
    notifyListeners();
  }

  AlignmentGeometry? bgGradAlign2 = Alignment.bottomRight;

  set setbgGradAlign2(AlignmentGeometry c) {
    bgGradAlign2 = c;
    notifyListeners();
  }

  Color? iconColor = Colors.white;

  set setIconColor(Color c) {
    iconColor = c;
    notifyListeners();
  }

  List<Color>? bgColors = [Colors.pinkAccent];

  set setBgColors(List<Color> c) {
    bgColors = c;
    notifyListeners();
  }

  bool?  randomColors= false;

  set setRandomColors(bool c) {
    randomColors = c;
    notifyListeners();
  }

  Color? borderColor = Colors.white.withOpacity(0.3);

  set setBorderColor(Color c) {
    borderColor = c;
    notifyListeners();
  }

  double? borderWidth = 2;

  set setBorderWidth(double r) {
    borderWidth = r;
    notifyListeners();
  }

  Color? accentColor = Colors.pinkAccent;

  set setAccentColor(Color c) {
    accentColor = c;
    notifyListeners();
  }

  set setProgress(int? p) {
    progress = p;
    notifyListeners();
  }

  set setIsExporting(bool val) {
    isIconsExporting = val;
    notifyListeners();
  }

  set setIsExported(bool val) {
    isExported = val;
    notifyListeners();
  }

  void getIconAssetsPath(context) async {
    final provider = Provider.of<UserProfileProvider>(context, listen: false);
    var assets = await rootBundle.loadString('AssetManifest.json');
    var json = jsonDecode(assets);
    final List<String> paths = json.keys
        .where((String element) => element
            .startsWith("assets/icons/${users[provider.activeUser]!['user']}/"))
        .toList();

    iconAssetsPath = paths
        .map(
          (e) => e
              .replaceAll(
                  "assets/icons/${users[provider.activeUser]!['user']}/", '')
              .replaceAll(".svg", ''),
        )
        .toList();
    iconAssetsPath = [...MIUIThemeData.vectorList, ...iconAssetsPath];
    notifyListeners();
  }

  void checkAlreadyExport({required BuildContext context}) async {
    final themePath = CurrentTheme.getPath(context);
    final isExist = await File(platformBasedPath(
            '$themePath\\icons\\res\\drawable-xhdpi\\${iconAssetsPath[1]}.png'))
        .exists();
    setIsExported = isExist;
  }

  void export({BuildContext? context}) async {
    final provider = Provider.of<IconProvider>(context!, listen: false);
    final userType =
        Provider.of<UserProfileProvider>(context, listen: false).activeUser;
    final themePath = CurrentTheme.getPath(context);
    setIsExporting = true;
    try {
      for (String? element in iconAssetsPath) {
        ScreenshotController()
            .captureFromWidget(
                IconWidget(
                    name: element,
                    bgColor: provider.bgColor,
                    bgColor2: provider.bgColor2,
                    bgGradAlign2: provider.bgGradAlign,
                    bgGradAlign: provider.bgGradAlign2,
                    iconColor: provider.iconColor,
                    margin: provider.margin,
                    padding: provider.padding,
                    radius: provider.radius,
                    bgColors: provider.bgColors,
                    randomColors: provider.randomColors,
                    borderColor: provider.borderColor,
                    borderWidth: provider.borderWidth,
                    userType: userType),
                pixelRatio: 4)
            .then((value) async {
          final imagePath = File(platformBasedPath(
              '$themePath\\icons\\res\\drawable-xhdpi\\$element.png'));
          await imagePath.writeAsBytes(value);
          final imagePath2 = File(platformBasedPath(
              '$themePath\\icons\\res\\drawable-xxhdpi\\$element.png'));
          await imagePath2.writeAsBytes(value);
          setProgress = progress! + 1;
          if (progress == iconAssetsPath.length) {
            checkAlreadyExport(context: context);
            setIsExporting = false;
            setProgress = 0;
          }
        });
      }
      await File(platformBasedPath("$themePath\\icons\\transform_config.xml"))
          .writeAsString(
              transformConfig.toXmlString(pretty: true, indent: '\t'));
    } on Exception catch (e) {
      debugPrint(e.toString());
    }
  }
}

final transformConfig = XmlDocument.parse(iconTransformConfig);

class ExportIconsBtn extends StatelessWidget {
  const ExportIconsBtn({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<IconProvider>(builder: (context, provider, _) {
      return UIWidgets.getElevatedButton(
          text: "Icon Export",
          icon: Icon(provider.isExported ? Icons.check : Icons.android),
          isLoading: provider.isIconsExporting!,
          onTap: () => provider.export(context: context));
    });
  }
}
