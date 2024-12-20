import 'dart:io';

import 'package:flutter/material.dart';
import 'package:miui_icon_generator/widgets/text.dart';
import 'package:provider/provider.dart';
import 'package:screenshot/screenshot.dart';

import '../../functions/theme_path.dart';
import '../../functions/windows_utils.dart';
import '../../provider/element.dart';
import '../bg_stack.dart';
import '../element_map_dart.dart';
import '../miui_theme_data.dart';

class HourClock extends StatelessWidget {
  const HourClock({super.key, required this.num});
  final int? num;

  static Widget getChild({int? num, ElementProvider? value}) {
    final ele = value!.getElementFromList(ElementType.hourClock);
    return commonWidget(
        child: GradientText(
          num.toString().padLeft(2, '0'),
          gradient: getGradient(colors: [
            ele.color!,
            ele.colorSecondary!,
          ], ele: ele),
          style: TextStyle(
              fontFamily: ele.font, fontSize: 60, height: 1, color: ele.color),
        ),
        type: ElementType.hourClock,
        value: value);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ElementProvider>(builder: (context, value, _) {
      return getChild(num: num, value: value);
    });
  }
}

class MinClock extends StatelessWidget {
  const MinClock({super.key, required this.num});
  final int? num;

  static Widget getChild({int? num, ElementProvider? value}) {
    final ele = value!.getElementFromList(ElementType.minClock);
    return commonWidget(
        child: GradientText(
          num.toString().padLeft(2, '0'),
          gradient: getGradient(colors: [
            ele.color!,
            ele.colorSecondary!,
          ], ele: ele),
          style: TextStyle(
              fontFamily: ele.font, fontSize: 60, height: 1, color: ele.color),
        ),
        type: ElementType.minClock,
        value: value);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ElementProvider>(builder: (context, value, _) {
      return getChild(num: num, value: value);
    });
  }
}

class DotClock extends StatelessWidget {
  const DotClock({super.key});

  static Widget getChild({ElementProvider? value}) {
    final ele = value!.getElementFromList(ElementType.dotClock);
    return commonWidget(
        child: GradientText(
          ":",
          gradient: getGradient(colors: [
            ele.color!,
            ele.colorSecondary!,
          ], ele: ele),
          style: TextStyle(
              fontFamily: ele.font, fontSize: 60, height: 1, color: ele.color),
        ),
        type: ElementType.dotClock,
        value: value);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ElementProvider>(builder: (context, value, _) {
      return getChild(value: value);
    });
  }
}

class WeekClock extends StatelessWidget {
  const WeekClock({super.key, required this.num});
  final int? num;

  static Widget getChild({int? num, ElementProvider? value}) {
    final ele = value!.getElementFromList(ElementType.weekClock);
    return commonWidget(
        child: GradientText(
          ele.isShort!
              ? MIUIThemeData.weekNames[num!]!.substring(0, 3)
              : ele.isWrap!
                  ? sliceAndJoin(MIUIThemeData.weekNames[num!]!)
                  : MIUIThemeData.weekNames[num!]!,
          gradient: getGradient(colors: [
            ele.color!,
            ele.colorSecondary!,
          ], ele: ele),
          style: TextStyle(
              fontFamily: ele.font, fontSize: 30, height: 1, color: ele.color),
        ),
        type: ElementType.weekClock,
        value: value);
  }

  static String sliceAndJoin(String input) {
    List<int> slicePattern = [3, 2];
    List<String> result = [];
    int startIndex = 0;

    for (int length in slicePattern) {
      if (startIndex + length <= input.length) {
        result.add(input.substring(startIndex, startIndex + length));
        startIndex += length;
      } else {
        result.add(input.substring(startIndex)); // add remaining characters
        break;
      }
    }

    // Add remaining part of the string after the last slice
    if (startIndex < input.length) {
      result.add(input.substring(startIndex));
    }

    // Join slices with '\n'
    return result.join('\n');
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ElementProvider>(builder: (context, value, _) {
      return getChild(num: num, value: value);
    });
  }
}

class MonthClock extends StatelessWidget {
  const MonthClock({super.key, required this.num});
  final int? num;

  static Widget getChild({int? num, ElementProvider? value}) {
    final ele = value!.getElementFromList(ElementType.monthClock);
    return commonWidget(
        child: GradientText(
          ele.isShort!
              ? MIUIThemeData.monthNames[num! - 1]!.substring(0, 3)
              : MIUIThemeData.monthNames[num! - 1]!,
          gradient: getGradient(colors: [
            ele.color!,
            ele.colorSecondary!,
          ], ele: ele),
          style: TextStyle(
              fontFamily: ele.font, fontSize: 30, height: 1, color: ele.color),
        ),
        type: ElementType.monthClock,
        value: value);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ElementProvider>(builder: (context, value, _) {
      return getChild(num: num, value: value);
    });
  }
}

class DateClock extends StatelessWidget {
  const DateClock({super.key, required this.num});
  final int? num;

  static Widget getChild({int? num, ElementProvider? value}) {
    final ele = value!.getElementFromList(ElementType.dateClock);
    return commonWidget(
        child: GradientText(
          num.toString().padLeft(2, '0'),
          gradient: getGradient(colors: [
            ele.color!,
            ele.colorSecondary!,
          ], ele: ele),
          style: TextStyle(
              fontFamily: ele.font, fontSize: 30, height: 1, color: ele.color),
        ),
        type: ElementType.dateClock,
        value: value);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ElementProvider>(builder: (context, value, _) {
      return getChild(num: num, value: value);
    });
  }
}

class AmPmClock extends StatelessWidget {
  const AmPmClock({super.key, required this.isAm});
  final bool? isAm;

  static Widget getChild({bool? isAm, ElementProvider? value}) {
    final ele = value!.getElementFromList(ElementType.amPmClock);
    return commonWidget(
        child: GradientText(
          isAm! ? 'AM' : 'PM',
          gradient: getGradient(colors: [
            ele.color!,
            ele.colorSecondary!,
          ], ele: ele),
          style: TextStyle(
              fontFamily: ele.font, fontSize: 30, height: 1, color: ele.color),
        ),
        type: ElementType.amPmClock,
        value: value);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ElementProvider>(builder: (context, value, _) {
      return getChild(isAm: isAm, value: value);
    });
  }
}

class WeatherIconClock extends StatelessWidget {
  const WeatherIconClock({super.key, required this.num});
  final int? num;

  static Widget getChild({int? num, ElementProvider? value}) {
    return commonWidget(
        child: Image.asset(
          "assets/lockscreen/weatherIcon/weather_$num.png",
          height: 40,
        ),
        type: ElementType.weatherIconClock,
        value: value);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ElementProvider>(builder: (context, value, _) {
      return getChild(num: num, value: value);
    });
  }
}

Future exportHourPng(BuildContext context) async {
  final value = Provider.of<ElementProvider>(context, listen: false);
  final themePath = CurrentTheme.getPath(context);
  for (int i = 0; i <= 12; i++) {
    ScreenshotController()
        .captureFromWidget(
            getBGStack(child: HourClock.getChild(num: i, value: value)),
            context: context,
            pixelRatio: 3)
        .then((value) async {
      final imagePath = File(platformBasedPath(
          '$themePath\\lockscreen\\advance\\hour\\hour_$i.png'));
      await imagePath.writeAsBytes(value);
    });
  }
}

Future exportMinPng(BuildContext context) async {
  final value = Provider.of<ElementProvider>(context, listen: false);
  final themePath = CurrentTheme.getPath(context);
  for (int i = 0; i <= 59; i++) {
    ScreenshotController()
        .captureFromWidget(
            getBGStack(child: MinClock.getChild(num: i, value: value)),
            context: context,
            pixelRatio: 3)
        .then((value) async {
      final imagePath = File(platformBasedPath(
          '$themePath\\lockscreen\\advance\\min\\min_$i.png'));
      await imagePath.writeAsBytes(value);
    });
  }
}

Future exportDotPng(BuildContext context) async {
  final value = Provider.of<ElementProvider>(context, listen: false);
  final themePath = CurrentTheme.getPath(context);

  ScreenshotController()
      .captureFromWidget(getBGStack(child: DotClock.getChild(value: value)),
          context: context, pixelRatio: 3)
      .then((value) async {
    final imagePath = File(
        platformBasedPath('$themePath\\lockscreen\\advance\\dot\\dot.png'));
    await imagePath.writeAsBytes(value);
  });
}

Future exportWeekPng(BuildContext context) async {
  final value = Provider.of<ElementProvider>(context, listen: false);
  final themePath = CurrentTheme.getPath(context);
  for (int i = 0; i <= 6; i++) {
    ScreenshotController()
        .captureFromWidget(
            getBGStack(child: WeekClock.getChild(num: i, value: value)),
            context: context,
            pixelRatio: 3)
        .then((value) async {
      final imagePath = File(platformBasedPath(
          '$themePath\\lockscreen\\advance\\week\\week_$i.png'));
      await imagePath.writeAsBytes(value);
    });
  }
}

Future exportMonthPng(BuildContext context) async {
  final value = Provider.of<ElementProvider>(context, listen: false);
  final themePath = CurrentTheme.getPath(context);
  for (int i = 1; i <= 12; i++) {
    ScreenshotController()
        .captureFromWidget(
            getBGStack(child: MonthClock.getChild(num: i, value: value)),
            context: context,
            pixelRatio: 3)
        .then((value) async {
      final imagePath = File(platformBasedPath(
          '$themePath\\lockscreen\\advance\\month\\month_$i.png'));
      await imagePath.writeAsBytes(value);
    });
  }
}

Future exportDatePng(BuildContext context) async {
  final value = Provider.of<ElementProvider>(context, listen: false);
  final themePath = CurrentTheme.getPath(context);
  for (int i = 1; i <= 31; i++) {
    ScreenshotController()
        .captureFromWidget(
            getBGStack(child: DateClock.getChild(num: i, value: value)),
            context: context,
            pixelRatio: 3)
        .then((value) async {
      final imagePath = File(platformBasedPath(
          '$themePath\\lockscreen\\advance\\date\\date_$i.png'));
      await imagePath.writeAsBytes(value);
    });
  }
}

Future exportWeatherIconPng(BuildContext context) async {
  final value = Provider.of<ElementProvider>(context, listen: false);
  final themePath = CurrentTheme.getPath(context);
  for (int i = 0; i < MIUIThemeData.weatherPngs.length; i++) {
    ScreenshotController()
        .captureFromWidget(
            getBGStack(
                child: WeatherIconClock.getChild(
                    num: MIUIThemeData.weatherPngs[i], value: value)),
            context: context,
            pixelRatio: 3)
        .then((value) async {
      final imagePath = File(platformBasedPath(
          '$themePath\\lockscreen\\advance\\weather\\weather_${MIUIThemeData.weatherPngs[i]}.png'));
      await imagePath.writeAsBytes(value);
    });
  }
}

Future exportAmPmPng(BuildContext context) async {
  final value = Provider.of<ElementProvider>(context, listen: false);
  final themePath = CurrentTheme.getPath(context);
  for (int i = 0; i <= 1; i++) {
    ScreenshotController()
        .captureFromWidget(
            getBGStack(
                child: AmPmClock.getChild(
                    isAm: i == 0 ? true : false, value: value)),
            context: context,
            pixelRatio: 3)
        .then((value) async {
      final imagePath = File(platformBasedPath(
          '$themePath\\lockscreen\\advance\\ampm\\ampm_$i.png'));
      await imagePath.writeAsBytes(value);
    });
  }
}

Gradient getGradient({List<Color>? colors, ElementWidget? ele}) {
  switch (ele!.gradientType) {
    case GradientType.linear:
      return LinearGradient(
          begin: ele.gradStartAlign!, end: ele.gradEndAlign!, colors: colors!);

    case GradientType.radial:
      return RadialGradient(
          center: Alignment.center, radius: 0.5, colors: colors!);

    case GradientType.sweep:
      return SweepGradient(center: Alignment.center, colors: colors!);
    case null:
      return LinearGradient(
          begin: ele.gradStartAlign!, end: ele.gradEndAlign!, colors: colors!);
  }
}
