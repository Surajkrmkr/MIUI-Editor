import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:screenshot/screenshot.dart';

import '../../functions/theme_path.dart';
import '../../functions/windows_utils.dart';
import '../../provider/element.dart';
import '../bg_stack.dart';
import '../element_map_dart.dart';

class ContainerBG extends StatelessWidget {
  final ElementType type;
  const ContainerBG({super.key, required this.type});

  static Widget getChild({ElementProvider? value, ElementType? type}) {
    final ele = value!.getElementFromList(type!);
    return commonWidget(
      type: type,
      value: value,
      child: Container(
        height: ele.height,
        width: ele.width,
        decoration: BoxDecoration(
          border: ele.borderWidth == 0
              ? const Border.fromBorderSide(BorderSide.none)
              : Border.all(width: ele.borderWidth!, color: ele.borderColor!),
          borderRadius: BorderRadius.circular(ele.radius!),
          gradient: getGradient(ele: ele, colors: [
            ele.color!,
            ele.colorSecondary!,
          ]),
        ),
      ),
    );
  }

  static Gradient getGradient({List<Color>? colors, ElementWidget? ele}) {
    switch (ele!.gradientType) {
      case GradientType.linear:
        return LinearGradient(
            begin: ele.gradStartAlign!,
            end: ele.gradEndAlign!,
            colors: colors!);

      case GradientType.radial:
        return RadialGradient(
            center: Alignment.center, radius: 0.5, colors: colors!);

      case GradientType.sweep:
        return SweepGradient(center: Alignment.center, colors: colors!);
      case null:
        return LinearGradient(
            begin: ele.gradStartAlign!,
            end: ele.gradEndAlign!,
            colors: colors!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ElementProvider>(builder: (context, value, _) {
      return getChild(value: value, type: type);
    });
  }
}

class ContainerWidget extends StatelessWidget {
  const ContainerWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}

Future exportContainerBG1Png(BuildContext context) async {
  final value = Provider.of<ElementProvider>(context, listen: false);
  final themePath = CurrentTheme.getPath(context);
  ScreenshotController()
      .captureFromWidget(
          getBGStack(
              child: ContainerBG.getChild(
                  value: value, type: ElementType.containerBG1)),
          context: context,
          pixelRatio: 3)
      .then((value) async {
    final imagePath = File(platformBasedPath(
        '$themePath\\lockscreen\\advance\\container\\containerBG1.png'));
    await imagePath.writeAsBytes(value);
  });
}

Future exportContainerBG2Png(BuildContext context) async {
  final value = Provider.of<ElementProvider>(context, listen: false);
  final themePath = CurrentTheme.getPath(context);
  ScreenshotController()
      .captureFromWidget(
          getBGStack(
              child: ContainerBG.getChild(
                  value: value, type: ElementType.containerBG2)),
          context: context,
          pixelRatio: 3)
      .then((value) async {
    final imagePath = File(platformBasedPath(
        '$themePath\\lockscreen\\advance\\container\\containerBG2.png'));
    await imagePath.writeAsBytes(value);
  });
}

Future exportContainerBG3Png(BuildContext context) async {
  final value = Provider.of<ElementProvider>(context, listen: false);
  final themePath = CurrentTheme.getPath(context);
  ScreenshotController()
      .captureFromWidget(
          getBGStack(
              child: ContainerBG.getChild(
                  value: value, type: ElementType.containerBG3)),
          context: context,
          pixelRatio: 3)
      .then((value) async {
    final imagePath = File(platformBasedPath(
        '$themePath\\lockscreen\\advance\\container\\containerBG3.png'));
    await imagePath.writeAsBytes(value);
  });
}

Future exportContainerBG4Png(BuildContext context) async {
  final value = Provider.of<ElementProvider>(context, listen: false);
  final themePath = CurrentTheme.getPath(context);
  ScreenshotController()
      .captureFromWidget(
          getBGStack(
              child: ContainerBG.getChild(
                  value: value, type: ElementType.containerBG4)),
          context: context,
          pixelRatio: 3)
      .then((value) async {
    final imagePath = File(platformBasedPath(
        '$themePath\\lockscreen\\advance\\container\\containerBG4.png'));
    await imagePath.writeAsBytes(value);
  });
}

Future exportContainerBG5Png(BuildContext context) async {
  final value = Provider.of<ElementProvider>(context, listen: false);
  final themePath = CurrentTheme.getPath(context);
  ScreenshotController()
      .captureFromWidget(
          getBGStack(
              child: ContainerBG.getChild(
                  value: value, type: ElementType.containerBG5)),
          context: context,
          pixelRatio: 3)
      .then((value) async {
    final imagePath = File(platformBasedPath(
        '$themePath\\lockscreen\\advance\\container\\containerBG5.png'));
    await imagePath.writeAsBytes(value);
  });
}
