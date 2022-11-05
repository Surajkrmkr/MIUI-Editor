import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../constants.dart';
import '../../functions/theme_path.dart';
import '../../provider/element.dart';
import '../bg_stack.dart';
import '../element_map_dart.dart';

class CameraIcon extends StatelessWidget {
  const CameraIcon({super.key, required this.id});
  final String? id;

  static Widget getChild(
      {String? id, ElementProvider? value, String? themePath}) {
    final ele = value!.getElementFromList(id!);
    return commonWidget(
        child: Image.memory(
          File("${themePath}lockscreen\\advance\\icon\\camera.png")
              .readAsBytesSync(),
          gaplessPlayback: true,
          height: ele.height! / MIUIConstants.ratio,
          width: ele.width! / MIUIConstants.ratio,
        ),
        id: id,
        value: value);
  }

  @override
  Widget build(BuildContext context) {
    final themePath = CurrentTheme.getPath(context);
    return Consumer<ElementProvider>(builder: (context, value, _) {
      return getChild(id:id,value: value, themePath: themePath);
    });
  }
}

class ThemeIcon extends StatelessWidget {
  const ThemeIcon({super.key, required this.id});
  final String? id;
  static Widget getChild(
      {String? id, ElementProvider? value, String? themePath}) {
    final ele = value!.getElementFromList(id!);
    return commonWidget(
        child: Image.memory(
          File("${themePath}lockscreen\\advance\\icon\\theme.png")
              .readAsBytesSync(),
          gaplessPlayback: true,
          height: ele.height! / MIUIConstants.ratio,
          width: ele.width! / MIUIConstants.ratio,
        ),
        id: id,
        value: value);
  }

  @override
  Widget build(BuildContext context) {
    final themePath = CurrentTheme.getPath(context);
    return Consumer<ElementProvider>(builder: (context, value, _) {
      return getChild(id:id,value: value, themePath: themePath);
    });
  }
}

class SettingIcon extends StatelessWidget {
  const SettingIcon({super.key, required this.id});
  final String? id;
  static Widget getChild(
      {String? id, ElementProvider? value, String? themePath}) {
    final ele = value!.getElementFromList(id!);
    return commonWidget(
        child: Image.memory(
          File("${themePath}lockscreen\\advance\\icon\\setting.png")
              .readAsBytesSync(),
          gaplessPlayback: true,
          height: ele.height! / MIUIConstants.ratio,
          width: ele.width! / MIUIConstants.ratio,
        ),
        id: id,
        value: value);
  }

  @override
  Widget build(BuildContext context) {
    final themePath = CurrentTheme.getPath(context);
    return Consumer<ElementProvider>(builder: (context, value, _) {
      return getChild(id:id,value: value, themePath: themePath);
    });
  }
}

class GalleryIcon extends StatelessWidget {
  const GalleryIcon({super.key, required this.id});
  final String? id;
  static Widget getChild(
      {String? id, ElementProvider? value, String? themePath}) {
    final ele = value!.getElementFromList(id!);
    return commonWidget(
        child: Image.memory(
          File("${themePath}lockscreen\\advance\\icon\\gallery.png")
              .readAsBytesSync(),
          gaplessPlayback: true,
          height: ele.height! / MIUIConstants.ratio,
          width: ele.width! / MIUIConstants.ratio,
        ),
        id: id,
        value: value);
  }

  @override
  Widget build(BuildContext context) {
    final themePath = CurrentTheme.getPath(context);
    return Consumer<ElementProvider>(builder: (context, value, _) {
      return getChild(id:id,value: value, themePath: themePath);
    });
  }
}
