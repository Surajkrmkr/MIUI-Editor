import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:miui_icon_generator/widgets/text_field.dart';
import 'package:provider/provider.dart';
import 'package:xml/xml.dart';

import '../constants.dart';
import '../data/element_map_dart.dart';
import '../data/miui_theme_data.dart';
import '../functions/theme_path.dart';
import '../data/xml data/lockscreen.dart';
import '../functions/windows_utils.dart';
import '../widgets/ui_widgets.dart';
import 'element.dart';
import 'mtz.dart';

class LockscreenProvider extends ChangeNotifier {
  bool? isExporting = false;
  bool isExported = false;
  bool? isDefaultPngsCopying = false;

  set setIsExporting(bool val) {
    isExporting = val;
    notifyListeners();
  }

  set setIsExported(bool val) {
    isExported = val;
    notifyListeners();
  }

  set setIsDefaultPngsCopying(bool val) {
    isDefaultPngsCopying = val;
    notifyListeners();
  }

  Future copyDefaultPngs({BuildContext? context}) async {
    setIsDefaultPngsCopying = true;
    await checkAlreadyExport(context: context!);
    Provider.of<MTZProvider>(context, listen: false)
        .checkAlreadyExport(context: context);
    if (!isExported) {
      final themePath = CurrentTheme.getPath(context);
      CurrentTheme.createLockscreenDirectory(themePath: themePath);
      for (var png in MIUIThemeData.lockscreenPngList) {
        await File(platformBasedPath(
                "${MIUIConstants.sample2Lockscreen!}$png.png"))
            .copy(platformBasedPath("${themePath}lockscreen\\advance$png.png"));
      }
    }
    setIsDefaultPngsCopying = false;
  }

  void export({BuildContext? context}) async {
    setIsExporting = true;
    final lockscreen = lockscreenXml.copy();
    final themePath = CurrentTheme.getPath(context);
    final eleProvider = Provider.of<ElementProvider>(context!, listen: false);
    eleProvider.setActiveType = ElementType.swipeUpUnlock;
    final elementList = eleProvider.elementList;
    await Future.delayed(const Duration(seconds: 2), () {});
    for (ElementWidget widget in elementList) {
      final elementFromMap = elementWidgetMap[widget.type];
      dynamic elementXmlFromMap;
      // if (widget.type == ElementType.textLineClock) {
      //   elementXmlFromMap = elementFromMap!["xml"]!(
      //       textName: "d/E", color: "#ffffff", size: "60");
      // } else {
      //   elementXmlFromMap = elementFromMap!["xml"]!;
      // }
      if (elementFromMap!["isIconType"] ?? false) {
        elementXmlFromMap = elementFromMap["xml"]!(ele: widget);
      } else if (elementFromMap["isMusic"] ?? false) {
        elementXmlFromMap = elementFromMap["xml"]!(ele: widget);
        final previousText = lockscreen
            .findAllElements("MusicControl")
            .toList()
            .firstWhere(
                (element) => element.getAttribute("name") == "music_control")
            .innerXml;
        lockscreen
            .findAllElements("MusicControl")
            .toList()
            .firstWhere(
                (element) => element.getAttribute("name") == "music_control")
            .innerXml = previousText + elementXmlFromMap;
      } else if ((elementFromMap["isTextType"] ?? false) ||
          (elementFromMap["isContainerType"] ?? false)) {
        elementXmlFromMap = elementFromMap["xml"]!(ele: widget);
      } else {
        elementXmlFromMap = elementFromMap["xml"]!;
      }
      if (!(elementFromMap["isMusic"] ?? false)) {
        lockscreen
            .findAllElements("Group")
            .toList()
            .firstWhere(
                (element) => element.getAttribute("name") == widget.type!.name)
            .innerXml = elementXmlFromMap;
      }

      if (elementFromMap["exportable"]) {
        await Directory(platformBasedPath(
                "$themePath\\lockscreen\\advance\\${elementFromMap["png"]["path"]}"))
            .create(recursive: true)
            .then((value) async {
          await elementFromMap["png"]["export"](context);
        });
      }
    }
    await Future.delayed(const Duration(seconds: 15), () {});
    lockscreen
        .findAllElements("Group")
        .toList()
        .firstWhere((element) => element.getAttribute("name") == "bgAlpha")
        .innerXml = getBgAlphaString(alpha: eleProvider.bgAlpha! * 255)!;
    await File(
            platformBasedPath("$themePath\\lockscreen\\advance\\manifest.xml"))
        .writeAsString(lockscreen.toXmlString(pretty: true, indent: '\t'));
    checkAlreadyExport(context: context);
    setIsExporting = false;
  }

  Future<void> checkAlreadyExport({required BuildContext context}) async {
    final themePath = CurrentTheme.getPath(context);
    final isExist = await File(
            platformBasedPath("$themePath\\lockscreen\\advance\\manifest.xml"))
        .exists();
    setIsExported = isExist;
  }

  void aiGeneratedLockscreen({required BuildContext context}) async {
    final eleProvider = Provider.of<ElementProvider>(context, listen: false);
    final elementList = eleProvider.elementList;
    final eleJSON = json.encode(elementWidgetToMap(elementList));

    // print(elementList);
    print("${eleJSON}raw");
    // final list = (json.decode(eleJSON) as List<dynamic>)
    //     .map((element) => ElementWidget.fromJson(element))
    //     .toList();
    // print(list);
    final schema = Schema.array(
      description: 'List of lock screen elements',
      items: Schema.object(properties: {
        'name': Schema.string(description: 'Unique name for the element'),
        'dx': Schema.number(description: 'X-coordinate of the element'),
        'dy': Schema.number(description: 'Y-coordinate of the element'),
        'scale': Schema.number(description: 'Scale factor of the element'),
        'height': Schema.number(description: 'Height of the element'),
        'width': Schema.number(description: 'Width of the element'),
        'radius': Schema.number(description: 'Corner radius of the element'),
        'borderWidth':
            Schema.number(description: 'Border width of the element'),
        'borderColor': Schema.string(description: 'Color of the border'),
        'type': Schema.enumString(
          description: 'Type of the lock screen element',
          enumValues: ElementType.values.map((e) => e.name).toList(),
        ),
        'child': Schema.enumString(
          enumValues:
              ElementType.values.map((e) => e.name.capitalize()).toList(),
          description: 'Child element within this element',
        ),
        'color': Schema.string(description: 'Primary color of the element'),
        'colorSecondary':
            Schema.string(description: 'Secondary color of the element'),
        'gradientType': Schema.enumString(
            enumValues: ['GradientType.linear'],
            description: 'Type of gradient applied to the element'),
        'gradStartAlign': Schema.object(
            description: 'Alignment of the gradient start point',
            properties: {
              'x': Schema.number(description: 'X-coordinate alignment'),
              'y': Schema.number(description: 'Y-coordinate alignment'),
            }),
        'gradEndAlign': Schema.object(
            description: 'Alignment of the gradient end point',
            properties: {
              'x': Schema.number(description: 'X-coordinate alignment'),
              'y': Schema.number(description: 'Y-coordinate alignment'),
            }),
        'font': Schema.string(description: 'Font family of the text'),
        'align': Schema.enumString(enumValues: [
          "Alignment.bottomCenter",
          "Alignment.bottomLeft",
          "Alignment.bottomRight",
          "Alignment.center",
          "Alignment.centerLeft",
          "Alignment.centerRight",
          "Alignment.topCenter",
          "Alignment.topLeft",
          "Alignment.topRight"
        ], description: 'Text alignment within the element'),
        'angle': Schema.number(description: 'Rotation angle of the element'),
        'path': Schema.string(description: 'Path data for custom shapes'),
        'text': Schema.string(
            description: 'Text content displayed within the element'),
        'fontSize': Schema.number(description: 'Font size of the text'),
        'fontWeight': Schema.enumString(enumValues: [
          'FontWeight.w100',
          'FontWeight.w200', /* more weights */
        ], description: 'Font weight of the text'),
        'isShort': Schema.boolean(
            description: 'Whether the clock display is short (optional)'),
        'showGuideLines': Schema.boolean(
            description: 'Whether to display guidelines (optional)')
      }),
    );

    final model = GenerativeModel(
        model: 'gemini-1.5-flash-latest',
        apiKey: apiKey,
        systemInstruction:
            Content.system("Example of sample json aray : $eleJSON"),
        generationConfig: GenerationConfig(
            responseMimeType: 'application/json', responseSchema: schema));

    const prompt = 'Suggest me a lock screen';
    final response = await model.generateContent([Content.text(prompt)]);
    print(response.text);
    final jsonString = response.text;
    List<ElementWidget> elementList1 =
        (json.decode(jsonString!) as List<dynamic>)
            .map((element) => ElementWidget.fromJson(element))
            .toList();

    eleProvider.addAllElements(elementList1);
    eleProvider.setActiveType = elementList1.last.type;
    Navigator.pop(context);
    UIWidgets.getBanner(
        content: "Preset Imported", context: context, hasError: false);
  }

  final apiKey = () {
    const apiKey = 'AIzaSyBJaQrAWTCa6EXNG1ajqfwSyznU96rVYu0';
    return apiKey;
  }();

  void importPresetToLockscreen(
      {required BuildContext context, required String jsonPath}) async {
    final jsonString =
        await File(platformBasedPath("$jsonPath\\preset.json")).readAsString();
    List<ElementWidget> elementList = (json.decode(jsonString) as List<dynamic>)
        .map((element) => ElementWidget.fromJson(element))
        .toList();

    final eleProvider = Provider.of<ElementProvider>(context, listen: false);
    eleProvider.addAllElements(elementList);
    eleProvider.setActiveType = elementList.last.type;
    Navigator.pop(context);
    UIWidgets.getBanner(
        content: "Preset Imported", context: context, hasError: false);
  }

  void addLockscreenToPreset(
      {required BuildContext context, required String presetName}) async {
    final eleProvider = Provider.of<ElementProvider>(context, listen: false);
    final elementList = eleProvider.elementList;
    final eleJSON = json.encode(elementWidgetToMap(elementList));
    // final folders = await Directory("${MIUIConstants.preset}").list().toList();
    // for (var folderEntity in folders) {
    //   if (folderEntity is! Directory) {
    //     final presetName =
    //         folderEntity.path.split(platformBasedPath("\\")).last;
    final jsonPath =
        platformBasedPath("${MIUIConstants.preset}$presetName\\preset.json");
    if (await File(jsonPath).exists()) {
      await File(jsonPath).delete();
    } else {
      await Directory(platformBasedPath("${MIUIConstants.preset}$presetName"))
          .create(recursive: true);
    }
    await File(platformBasedPath(jsonPath)).writeAsString(eleJSON);
    // }
    // }

    UIWidgets.getBanner(
        content: "Preset Generated", context: context, hasError: false);
  }
}

class ExportLockscreenBtn extends StatelessWidget {
  const ExportLockscreenBtn({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<LockscreenProvider>(builder: (context, provider, _) {
      return UIWidgets.getElevatedButton(
          text: "Export",
          icon: Icon(provider.isExported ? Icons.check : Icons.lock),
          isLoading: provider.isExporting!,
          onTap: () => provider.export(context: context));
    });
  }
}

class AILockscreenBtn extends StatelessWidget {
  const AILockscreenBtn({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<LockscreenProvider>(builder: (context, provider, _) {
      return UIWidgets.getElevatedButton(
          text: "SURAJ AI",
          icon: const Icon(Icons.gesture_rounded),
          isLoading: provider.isExporting!,
          onTap: () => provider.aiGeneratedLockscreen(context: context));
    });
  }
}

class PresetLockscreenBtn extends StatelessWidget {
  const PresetLockscreenBtn({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<LockscreenProvider>(builder: (context, provider, _) {
      return UIWidgets.getElevatedButton(
          text: "Add Preset",
          icon: const Icon(Icons.save_rounded),
          isLoading: provider.isExporting!,
          onTap: () => provider.addLockscreenToPreset(
              context: context,
              presetName: DateTime.now().millisecondsSinceEpoch.toString()));
    });
  }
}
