import 'dart:math';

import 'package:flutter/material.dart';

import '../constants.dart';
import '../provider/element.dart';
import 'element_map_dart.dart';

Widget getBGStack({required Widget child}) {
  return SizedBox(
    height: MIUIConstants.screenHeight,
    width: MIUIConstants.screenWidth,
    child: Stack(
      children: [
        child,
      ],
    ),
  );
}

Widget commonWidget(
    {ElementType? type, ElementProvider? value, Widget? child}) {
  final ele = value!.getElementFromList(type!);

  bool? isIconType = elementWidgetMap[type]!["isIconType"];
  return Positioned(
      left: ele.dx!,
      top: ele.dy!,
      child: GestureDetector(
          onTap: () {
            value.setActiveType = ele.type!;
          },
          onPanUpdate: ((details) {
            value.setActiveType = ele.type!;
            value.updateElementPositionInList(ele.type!,
                ele.dx! + details.delta.dx, ele.dy! + details.delta.dy);
          }),
          child: Transform.scale(
              scale: ele.scale!,
              child: Transform.rotate(
                  angle: -ele.angle! * pi / 180,
                  child: Container(
                      height: MIUIConstants.screenHeight,
                      width: MIUIConstants.screenWidth,
                      alignment: ele.align,
                      child: MouseRegion(
                          cursor: SystemMouseCursors.click, child: child))))));
}
