import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../constants.dart';
import '../../functions/theme_path.dart';
import '../../provider/element.dart';
import '../bg_stack.dart';
import '../element_map_dart.dart';

class ShortcutIcon extends StatelessWidget {
  const ShortcutIcon({super.key, required this.path, required this.type});

  final String? path;
  final ElementType? type;

  static Widget getChild(
      {ElementProvider? value,
      String? themePath,
      String? path,
      ElementType? type}) {
    final ele = value!.getElementFromList(type!);
    return commonWidget(
        child: Image.memory(
          File("${themePath}lockscreen\\advance\\$path.png").readAsBytesSync(),
          gaplessPlayback: true,
          height: ele.height! / MIUIConstants.ratio,
          width: ele.width! / MIUIConstants.ratio,
        ),
        type: type,
        value: value);
  }

  @override
  Widget build(BuildContext context) {
    final themePath = CurrentTheme.getPath(context);
    return Consumer<ElementProvider>(builder: (context, value, _) {
      return getChild(
          value: value, path: path, type: type, themePath: themePath);
    });
  }
}
