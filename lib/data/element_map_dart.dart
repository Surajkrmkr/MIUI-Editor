import 'package:miui_icon_generator/data/unlock/unlock.dart';

import '../xml data/swipe_up_unlock.dart';
import '../xml data/clock/dateTime_clock.dart';
import 'time/clock.dart';

enum ElementType {
  hourClock,
  minClock,
  dotClock,
  weekClock,
  monthClock,
  dateClock,
  swipeUpUnlock
}

final Map<ElementType, Map<String, dynamic>> elementWidgetMap = {
  ElementType.hourClock: {
    "widget": const HourClock(num: 2),
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
  ElementType.weekClock: {
    "widget": const WeekClock(
      num: 5,
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
  ElementType.swipeUpUnlock: {
    "widget": const SwipeUpUnlock(),
    "xml": swipeUpUnlockXml,
    "exportable": false,
  }
};
