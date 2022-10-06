import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:screenshot/screenshot.dart';

import '../../constants.dart';
import '../../functions/theme_path.dart';
import '../../provider/element.dart';
import '../element_map_dart.dart';

class HourClock extends StatelessWidget {
  const HourClock({super.key, required this.num});
  final int? num;

  static Widget getChild(ele, num) {
    return Text(
      num.toString().padLeft(2, '0'),
      style: TextStyle(
          fontFamily: ele.font, fontSize: 60, height: 1, color: ele.color),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ElementProvider>(builder: (context, provider, _) {
      final ele = provider.getElementFromList(ElementType.hourClock);
      return getChild(ele, num);
    });
  }
}

class MinClock extends StatelessWidget {
  const MinClock({super.key, required this.num});
  final int? num;

  static Widget getChild(ele, num) {
    return Text(
      num.toString().padLeft(2, '0'),
      style: TextStyle(
          fontFamily: ele.font, fontSize: 60, height: 1, color: ele.color),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ElementProvider>(builder: (context, provider, _) {
      final ele = provider.getElementFromList(ElementType.minClock);
      return getChild(ele, num);
    });
  }
}

class DotClock extends StatelessWidget {
  const DotClock({super.key});

  static Widget getChild(ele) {
    return Text(
      ":",
      style: TextStyle(
          fontFamily: ele.font, fontSize: 60, height: 1, color: ele.color),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ElementProvider>(builder: (context, provider, _) {
      final ele = provider.getElementFromList(ElementType.dotClock);
      return getChild(ele);
    });
  }
}

void exportHourPng(BuildContext context) {
  final ele = Provider.of<ElementProvider>(context, listen: false)
      .getElementFromList(ElementType.hourClock);
  final themePath = CurrentTheme.getPath(context);
  for (int i = 0; i <= 12; i++) {
    ScreenshotController()
        .captureFromWidget(
            getBGStack(
                child: Positioned(
                    left: ele.dx!,
                    top: ele.dy!,
                    child: Transform.scale(
                        scale: ele.scale, child: HourClock.getChild(ele, i)))),
            pixelRatio: 4)
        .then((value) async {
      final imagePath =
          File('$themePath\\lockscreen\\advance\\hour\\hour_$i.png');
      await imagePath.writeAsBytes(value);
    });
  }
}

void exportMinPng(BuildContext context) {
  final ele = Provider.of<ElementProvider>(context, listen: false)
      .getElementFromList(ElementType.minClock);
  final themePath = CurrentTheme.getPath(context);
  for (int i = 0; i <= 59; i++) {
    ScreenshotController()
        .captureFromWidget(
            getBGStack(
                child: Positioned(
                    left: ele.dx!,
                    top: ele.dy!,
                    child: Transform.scale(
                        scale: ele.scale, child: MinClock.getChild(ele, i)))),
            pixelRatio: 4)
        .then((value) async {
      final imagePath =
          File('$themePath\\lockscreen\\advance\\min\\min_$i.png');
      await imagePath.writeAsBytes(value);
    });
  }
}

void exportDotPng(BuildContext context) {
  final ele = Provider.of<ElementProvider>(context, listen: false)
      .getElementFromList(ElementType.dotClock);
  final themePath = CurrentTheme.getPath(context);
  ScreenshotController()
      .captureFromWidget(
          getBGStack(
              child: Positioned(
                  left: ele.dx!,
                  top: ele.dy!,
                  child: Transform.scale(
                      scale: ele.scale, child: DotClock.getChild(ele)))),
          pixelRatio: 4)
      .then((value) async {
    final imagePath = File('$themePath\\lockscreen\\advance\\dot\\dot.png');
    await imagePath.writeAsBytes(value);
  });
}

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
