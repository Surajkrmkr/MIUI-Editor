import 'package:miui_icon_generator/data/unlock/unlock.dart';

import '../xml data/dot_clock.dart';
import '../xml data/min_clock.dart';
import '../xml data/swipe_up_unlock.dart';
import '../xml data/hour_clock.dart';
import 'time/clock.dart';

enum ElementType { hourClock, minClock, dotClock, swipeUpUnlock }

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
  ElementType.swipeUpUnlock: {
    "widget": const SwipeUpUnlock(),
    "xml": swipeUpUnlockXml,
    "exportable": false,
  }
};
