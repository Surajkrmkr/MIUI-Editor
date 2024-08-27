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
  final isActive = ele.type == value.activeType;
  final showGuidLines = ele.showGuideLines ?? false;

  return Stack(
    children: [
      Positioned(
        left: 0,
        top: ele.dy! + MIUIConstants.screenHeight / 2,
        child: Visibility(
          visible: showGuidLines,
          child: Container(
            width: MIUIConstants.screenWidth,
            height: 2,
            color: Colors.white12, // Color of the vertical line
          ),
        ),
      ),
      Positioned(
        left: ele.dx! + MIUIConstants.screenWidth / 2,
        top: 0,
        child: Visibility(
          visible: showGuidLines,
          child: Container(
            width: 2,
            height: MIUIConstants.screenHeight,
            color: Colors.white12, // Color of the vertical line
          ),
        ),
      ),
      Positioned(
          left: ele.dx!,
          top: ele.dy!,
          child: GestureDetector(
              onTap: () {
                value.setActiveType = ele.type!;
              },
              onPanUpdate: ((details) {
                value.setActiveType = ele.type!;
                value.updateElementShowGuideLinesInList(ele.type!, true);
                value.updateElementPositionInList(ele.type!,
                    ele.dx! + details.delta.dx, ele.dy! + details.delta.dy);
              }),
              onPanEnd: (details) {
                value.updateElementShowGuideLinesInList(ele.type!, false);
              },
              child: Transform.scale(
                  scale: ele.scale!,
                  child: Transform.rotate(
                      angle: -ele.angle! * pi / 180,
                      child: Container(
                          height: MIUIConstants.screenHeight,
                          width: MIUIConstants.screenWidth,
                          alignment: ele.align,
                          child: MouseRegion(
                              cursor: SystemMouseCursors.click,
                              child: Container(
                                  // decoration: BoxDecoration(
                                  //     border: Border.all(
                                  //         width: isActive ? 1 : 0,
                                  //         color: isActive
                                  //             ? Colors.white24
                                  //             : Colors.transparent)),
                                  padding: const EdgeInsets.all(2),
                                  child: child))))))),
      Positioned(
        left: ele.dx! + MIUIConstants.screenWidth / 2 + 30,
        top: ele.dy! + MIUIConstants.screenHeight / 2 - 60,
        child: Visibility(
            visible: showGuidLines,
            child: Text(
              "${ele.dx!.toStringAsFixed(0)},${ele.dy!.toStringAsFixed(0)}",
              style: const TextStyle(color: Colors.white70),
            )),
      ),
    ],
  );
}
