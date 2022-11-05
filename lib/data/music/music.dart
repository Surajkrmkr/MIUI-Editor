import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../constants.dart';
import '../../functions/theme_path.dart';
import '../../provider/element.dart';
import '../bg_stack.dart';
import '../element_map_dart.dart';

class MusicBG extends StatelessWidget {
  const MusicBG({super.key, required this.id});
  final String? id;
  static Widget getChild(
      {String? id, ElementProvider? value, String? themePath}) {
    final ele = value!.getElementFromList(id!);
    return commonWidget(
        child: Image.memory(
          File("${themePath}lockscreen\\advance\\music\\bg.png")
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

class MusicNext extends StatelessWidget {
  const MusicNext({super.key, required this.id});
  final String? id;
  static Widget getChild(
      {String? id, ElementProvider? value, String? themePath}) {
    final ele = value!.getElementFromList(id!);
    return commonWidget(
        child: Image.memory(
          File("${themePath}lockscreen\\advance\\music\\next.png")
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

class MusicPrev extends StatelessWidget {
  const MusicPrev({super.key, required this.id});
  final String? id;
  static Widget getChild(
      {String? id, ElementProvider? value, String? themePath}) {
    final ele = value!.getElementFromList(id!);
    return commonWidget(
        child: Image.memory(
          File("${themePath}lockscreen\\advance\\music\\prev.png")
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
