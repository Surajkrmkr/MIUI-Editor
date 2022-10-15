import 'package:miui_icon_generator/data/unlock/unlock.dart';

import '../xml data/swipe_up_unlock.dart';
import '../xml data/clock/date_time_clock.dart';
import 'time/clock.dart';

enum ElementType {
  hourClock,
  minClock,
  dotClock,
  amPmClock,
  textLineClock,
  weekClock,
  monthClock,
  dateClock,
  weatherIconClock,
  swipeUpUnlock
}

final Map<ElementType, Map<String, dynamic>> elementWidgetMap = {
  ElementType.hourClock: {
    "widget": const HourClock(num: 12),
    "xml": hourClockXml,
    "exportable": true,
    "png": {"export": exportHourPng, "path": "hour"}
  },
  ElementType.minClock: {
    "widget": const MinClock(num: 36),
    "xml": minClockXml,
    "exportable": true,
    "png": {"export": exportMinPng, "path": "min"}
  },
  ElementType.dotClock: {
    "widget": const DotClock(),
    "exportable": true,
    "xml": dotClockXml,
    "png": {"export": exportDotPng, "path": "dot"}
  },
  ElementType.textLineClock: {
    "widget": const TextLineClock(text: '8 feb, Tue'),
    "exportable": false,
    "xml": textLineClockXml,
  },
  ElementType.weekClock: {
    "widget": const WeekClock(
      num: 3,
    ),
    "exportable": true,
    "xml": weekClockXml,
    "png": {"export": exportWeekPng, "path": "week"}
  },
  ElementType.monthClock: {
    "widget": const MonthClock(
      num: 3,
    ),
    "exportable": true,
    "xml": monthClockXml,
    "png": {"export": exportMonthPng, "path": "month"}
  },
  ElementType.dateClock: {
    "widget": const DateClock(
      num: 3,
    ),
    "exportable": true,
    "xml": dateClockXml,
    "png": {"export": exportDatePng, "path": "date"}
  },
  ElementType.weatherIconClock: {
    "widget": const WeatherIconClock(
      num: 0,
    ),
    "exportable": true,
    "xml": weatherIconClockXml,
    "png": {"export": exportWeatherIconPng, "path": "weather"}
  },
  ElementType.amPmClock: {
    "widget": const AmPmClock(
      isAm: true,
    ),
    "exportable": true,
    "xml": amClockXml,
    "png": {"export": exportAmPmPng, "path": "ampm"}
  },
  ElementType.swipeUpUnlock: {
    "widget": const SwipeUpUnlock(),
    "xml": swipeUpUnlockXml,
    "exportable": false,
  }
};
