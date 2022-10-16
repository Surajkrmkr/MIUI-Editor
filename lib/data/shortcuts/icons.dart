import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../constants.dart';
import '../../functions/theme_path.dart';
import '../../provider/element.dart';
import '../bg_stack.dart';
import '../element_map_dart.dart';

class CameraIcon extends StatelessWidget {
  const CameraIcon({super.key});

  static Widget getChild({ElementProvider? value, String? themePath}) {
    final ele = value!.getElementFromList(ElementType.cameraIcon);
    return commonWidget(
        child: Image.memory(
          File("${themePath}lockscreen\\advance\\icon\\camera.png")
              .readAsBytesSync(),
          gaplessPlayback: true,
          height: ele.height! / MIUIConstants.ratio,
          width: ele.width! / MIUIConstants.ratio,
        ),
        type: ElementType.cameraIcon,
        value: value);
  }

  @override
  Widget build(BuildContext context) {
    final themePath = CurrentTheme.getPath(context);
    return Consumer<ElementProvider>(builder: (context, value, _) {
      return getChild(value: value, themePath: themePath);
    });
  }
}
class ThemeIcon extends StatelessWidget {
  const ThemeIcon({super.key});

  static Widget getChild({ElementProvider? value, String? themePath}) {
    final ele = value!.getElementFromList(ElementType.themeIcon);
    return commonWidget(
        child: Image.memory(
          File("${themePath}lockscreen\\advance\\icon\\theme.png")
              .readAsBytesSync(),
          gaplessPlayback: true,
          height: ele.height! / MIUIConstants.ratio,
          width: ele.width! / MIUIConstants.ratio,
        ),
        type: ElementType.themeIcon,
        value: value);
  }

  @override
  Widget build(BuildContext context) {
    final themePath = CurrentTheme.getPath(context);
    return Consumer<ElementProvider>(builder: (context, value, _) {
      return getChild(value: value, themePath: themePath);
    });
  }
}
class SettingIcon extends StatelessWidget {
  const SettingIcon({super.key});

  static Widget getChild({ElementProvider? value, String? themePath}) {
    final ele = value!.getElementFromList(ElementType.settingIcon);
    return commonWidget(
        child: Image.memory(
          File("${themePath}lockscreen\\advance\\icon\\setting.png")
              .readAsBytesSync(),
          gaplessPlayback: true,
          height: ele.height! / MIUIConstants.ratio,
          width: ele.width! / MIUIConstants.ratio,
        ),
        type: ElementType.settingIcon,
        value: value);
  }

  @override
  Widget build(BuildContext context) {
    final themePath = CurrentTheme.getPath(context);
    return Consumer<ElementProvider>(builder: (context, value, _) {
      return getChild(value: value, themePath: themePath);
    });
  }
}
class GalleryIcon extends StatelessWidget {
  const GalleryIcon({super.key});

  static Widget getChild({ElementProvider? value, String? themePath}) {
    final ele = value!.getElementFromList(ElementType.galleryIcon);
    return commonWidget(
        child: Image.memory(
          File("${themePath}lockscreen\\advance\\icon\\gallery.png")
              .readAsBytesSync(),
          gaplessPlayback: true,
          height: ele.height! / MIUIConstants.ratio,
          width: ele.width! / MIUIConstants.ratio,
        ),
        type: ElementType.galleryIcon,
        value: value);
  }

  @override
  Widget build(BuildContext context) {
    final themePath = CurrentTheme.getPath(context);
    return Consumer<ElementProvider>(builder: (context, value, _) {
      return getChild(value: value, themePath: themePath);
    });
  }
}
