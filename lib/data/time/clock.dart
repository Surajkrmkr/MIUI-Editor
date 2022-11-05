import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:screenshot/screenshot.dart';

import '../../functions/theme_path.dart';
import '../../provider/element.dart';
import '../bg_stack.dart';
import '../element_map_dart.dart';
import '../miui_theme_data.dart';

class HourClock extends StatelessWidget {
  const HourClock({super.key, required this.num, required this.id});
  final int? num;
  final String? id;

  static Widget getChild({String? id, int? num, ElementProvider? value}) {
    final ele = value!.getElementFromList(id!);
    return commonWidget(
        child: Text(
          num.toString().padLeft(2, '0'),
          style: TextStyle(
              fontFamily: ele.font, fontSize: 60, height: 1, color: ele.color),
        ),
        id: id,
        value: value);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ElementProvider>(builder: (context, value, _) {
      return getChild(id: id, num: num, value: value);
    });
  }
}

class MinClock extends StatelessWidget {
  const MinClock({super.key, required this.num, required this.id});
  final int? num;
  final String? id;

  static Widget getChild({String? id, int? num, ElementProvider? value}) {
    final ele = value!.getElementFromList(id!);
    return commonWidget(
        child: Text(
          num.toString().padLeft(2, '0'),
          style: TextStyle(
              fontFamily: ele.font, fontSize: 60, height: 1, color: ele.color),
        ),
        id: id,
        value: value);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ElementProvider>(builder: (context, value, _) {
      return getChild(id: id, num: num, value: value);
    });
  }
}

class DotClock extends StatelessWidget {
  const DotClock({super.key, required this.id});
  final String? id;
  static Widget getChild({String? id, ElementProvider? value}) {
    final ele = value!.getElementFromList(id!);
    return commonWidget(
        child: Text(
          ":",
          style: TextStyle(
              fontFamily: ele.font, fontSize: 60, height: 1, color: ele.color),
        ),
        id: id,
        value: value);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ElementProvider>(builder: (context, value, _) {
      return getChild(id: id, value: value);
    });
  }
}

class TextLineClock extends StatelessWidget {
  const TextLineClock({super.key, this.text, required this.id});
  final String? text;
  final String? id;
  static Widget getChild({String? id, ElementProvider? value, String? text}) {
    final ele = value!.getElementFromList(id!);
    return commonWidget(
        child: Text(
          text!,
          style: TextStyle(
              fontFamily: ele.font, fontSize: 60, height: 1, color: ele.color),
        ),
        id: id,
        value: value);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ElementProvider>(builder: (context, value, _) {
      return getChild(id: id, value: value, text: text);
    });
  }
}

class WeekClock extends StatelessWidget {
  const WeekClock({super.key, required this.num, required this.id});
  final int? num;
  final String? id;
  static Widget getChild({String? id, int? num, ElementProvider? value}) {
    final ele = value!.getElementFromList(id!);
    return commonWidget(
        child: Text(
          ele.isShort!
              ? MIUIThemeData.weekNames[num!]!.substring(0, 3)
              : MIUIThemeData.weekNames[num!]!,
          style: TextStyle(
              fontFamily: ele.font, fontSize: 30, height: 1, color: ele.color),
        ),
        id: id,
        value: value);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ElementProvider>(builder: (context, value, _) {
      return getChild(id: id, num: num, value: value);
    });
  }
}

class MonthClock extends StatelessWidget {
  const MonthClock({super.key, required this.num, required this.id});
  final int? num;
  final String? id;

  static Widget getChild({String? id, int? num, ElementProvider? value}) {
    final ele = value!.getElementFromList(id!);
    return commonWidget(
        child: Text(
          ele.isShort!
              ? MIUIThemeData.monthNames[num! - 1]!.substring(0, 3)
              : MIUIThemeData.monthNames[num! - 1]!,
          style: TextStyle(
              fontFamily: ele.font, fontSize: 30, height: 1, color: ele.color),
        ),
        id: id,
        value: value);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ElementProvider>(builder: (context, value, _) {
      return getChild(id: id, num: num, value: value);
    });
  }
}

class DateClock extends StatelessWidget {
  const DateClock({super.key, required this.num, required this.id});
  final int? num;
  final String? id;
  static Widget getChild({String? id, int? num, ElementProvider? value}) {
    final ele = value!.getElementFromList(id!);
    return commonWidget(
        child: Text(
          num.toString().padLeft(2, '0'),
          style: TextStyle(
              fontFamily: ele.font, fontSize: 30, height: 1, color: ele.color),
        ),
        id: id,
        value: value);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ElementProvider>(builder: (context, value, _) {
      return getChild(id: id, num: num, value: value);
    });
  }
}

class AmPmClock extends StatelessWidget {
  const AmPmClock({super.key, required this.isAm, required this.id});
  final bool? isAm;
  final String? id;

  static Widget getChild({String? id, bool? isAm, ElementProvider? value}) {
    final ele = value!.getElementFromList(id!);
    return commonWidget(
        child: Text(
          isAm! ? 'AM' : 'PM',
          style: TextStyle(
              fontFamily: ele.font, fontSize: 30, height: 1, color: ele.color),
        ),
        id: id,
        value: value);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ElementProvider>(builder: (context, value, _) {
      return getChild(id: id, isAm: isAm, value: value);
    });
  }
}

class WeatherIconClock extends StatelessWidget {
  const WeatherIconClock({super.key, required this.num, required this.id});
  final int? num;
  final String? id;

  static Widget getChild({String? id, int? num, ElementProvider? value}) {
    return commonWidget(
        child: Image.asset(
          "assets/lockscreen/weatherIcon/weather_$num.png",
          height: 40,
        ),
        id: id,
        value: value);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ElementProvider>(builder: (context, value, _) {
      return getChild(id: id, num: num, value: value);
    });
  }
}

Future exportHourPng(BuildContext context, String id) async {
  final value = Provider.of<ElementProvider>(context, listen: false);
  final themePath = CurrentTheme.getPath(context);
  for (int i = 0; i <= 12; i++) {
    ScreenshotController()
        .captureFromWidget(
            getBGStack(child: HourClock.getChild(id: id, num: i, value: value)),
            context: context,
            pixelRatio: 3)
        .then((value) async {
      final imagePath =
          File('$themePath\\lockscreen\\advance\\hour\\hour_$i.png');
      await imagePath.writeAsBytes(value);
    });
  }
}

Future exportMinPng(BuildContext context, String id) async {
  final value = Provider.of<ElementProvider>(context, listen: false);
  final themePath = CurrentTheme.getPath(context);
  for (int i = 0; i <= 59; i++) {
    ScreenshotController()
        .captureFromWidget(
            getBGStack(child: MinClock.getChild(id: id, num: i, value: value)),
            context: context,
            pixelRatio: 3)
        .then((value) async {
      final imagePath =
          File('$themePath\\lockscreen\\advance\\min\\min_$i.png');
      await imagePath.writeAsBytes(value);
    });
  }
}

Future exportDotPng(BuildContext context, String id) async {
  final value = Provider.of<ElementProvider>(context, listen: false);
  final themePath = CurrentTheme.getPath(context);

  ScreenshotController()
      .captureFromWidget(
          getBGStack(child: DotClock.getChild(value: value, id: id)),
          context: context,
          pixelRatio: 3)
      .then((value) async {
    final imagePath = File('$themePath\\lockscreen\\advance\\dot\\dot.png');
    await imagePath.writeAsBytes(value);
  });
}

Future exportWeekPng(BuildContext context, String id) async {
  final value = Provider.of<ElementProvider>(context, listen: false);
  final themePath = CurrentTheme.getPath(context);
  for (int i = 0; i <= 6; i++) {
    ScreenshotController()
        .captureFromWidget(
            getBGStack(child: WeekClock.getChild(num: i, value: value, id: id)),
            context: context,
            pixelRatio: 3)
        .then((value) async {
      final imagePath =
          File('$themePath\\lockscreen\\advance\\week\\week_$i.png');
      await imagePath.writeAsBytes(value);
    });
  }
}

Future exportMonthPng(BuildContext context, String id) async {
  final value = Provider.of<ElementProvider>(context, listen: false);
  final themePath = CurrentTheme.getPath(context);
  for (int i = 1; i <= 12; i++) {
    ScreenshotController()
        .captureFromWidget(
            getBGStack(
                child: MonthClock.getChild(num: i, value: value, id: id)),
            context: context,
            pixelRatio: 3)
        .then((value) async {
      final imagePath =
          File('$themePath\\lockscreen\\advance\\month\\month_$i.png');
      await imagePath.writeAsBytes(value);
    });
  }
}

Future exportDatePng(BuildContext context, String id) async {
  final value = Provider.of<ElementProvider>(context, listen: false);
  final themePath = CurrentTheme.getPath(context);
  for (int i = 1; i <= 31; i++) {
    ScreenshotController()
        .captureFromWidget(
            getBGStack(child: DateClock.getChild(num: i, value: value, id: id)),
            context: context,
            pixelRatio: 3)
        .then((value) async {
      final imagePath =
          File('$themePath\\lockscreen\\advance\\date\\date_$i.png');
      await imagePath.writeAsBytes(value);
    });
  }
}

Future exportWeatherIconPng(BuildContext context, String id) async {
  final value = Provider.of<ElementProvider>(context, listen: false);
  final themePath = CurrentTheme.getPath(context);
  for (int i = 0; i < MIUIThemeData.weatherPngs.length; i++) {
    ScreenshotController()
        .captureFromWidget(
            getBGStack(
                child: WeatherIconClock.getChild(
                    num: MIUIThemeData.weatherPngs[i], value: value, id: id)),
            context: context,
            pixelRatio: 3)
        .then((value) async {
      final imagePath = File(
          '$themePath\\lockscreen\\advance\\weather\\weather_${MIUIThemeData.weatherPngs[i]}.png');
      await imagePath.writeAsBytes(value);
    });
  }
}

Future exportAmPmPng(BuildContext context, String id) async {
  final value = Provider.of<ElementProvider>(context, listen: false);
  final themePath = CurrentTheme.getPath(context);
  for (int i = 0; i <= 1; i++) {
    ScreenshotController()
        .captureFromWidget(
            getBGStack(
                child: AmPmClock.getChild(
                    isAm: i == 1 ? true : false, value: value, id: id)),
            context: context,
            pixelRatio: 3)
        .then((value) async {
      final imagePath =
          File('$themePath\\lockscreen\\advance\\ampm\\ampm_$i.png');
      await imagePath.writeAsBytes(value);
    });
  }
}
