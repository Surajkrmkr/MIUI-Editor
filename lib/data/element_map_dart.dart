import 'package:miui_icon_generator/data/unlock/unlock.dart';

import 'xml data/shortcuts/icons.dart';
import 'xml data/swipe_up_unlock.dart';
import 'xml data/clock/date_time_clock.dart';
import 'shortcuts/icons.dart';
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
  cameraIcon,
  themeIcon,
  settingIcon,
  galleryIcon,
  swipeUpUnlock
}

final Map<ElementType, Map<String, dynamic>> elementWidgetMap = {
  ElementType.hourClock: {
    "widget": const HourClock(num: 02),
    "xml": hourClockXml,
    "exportable": true,
    "png": {"export": exportHourPng, "path": "hour"},
    "isIconType" : false,
  },
  ElementType.minClock: {
    "widget": const MinClock(num: 36),
    "xml": minClockXml,
    "exportable": true,
    "png": {"export": exportMinPng, "path": "min"},
    "isIconType" : false,
  },
  ElementType.dotClock: {
    "widget": const DotClock(),
    "exportable": true,
    "xml": dotClockXml,
    "png": {"export": exportDotPng, "path": "dot"},
    "isIconType" : false,
  },
  ElementType.textLineClock: {
    "widget": const TextLineClock(text: '8 feb, Tue'),
    "exportable": false,
    "xml": textLineClockXml,
    "isIconType" : false,
  },
  ElementType.weekClock: {
    "widget": const WeekClock(
      num: 3,
    ),
    "exportable": true,
    "xml": weekClockXml,
    "png": {"export": exportWeekPng, "path": "week"},
    "isIconType" : false,
  },
  ElementType.monthClock: {
    "widget": const MonthClock(
      num: 3,
    ),
    "exportable": true,
    "xml": monthClockXml,
    "png": {"export": exportMonthPng, "path": "month"},
    "isIconType" : false,
  },
  ElementType.dateClock: {
    "widget": const DateClock(
      num: 3,
    ),
    "exportable": true,
    "xml": dateClockXml,
    "png": {"export": exportDatePng, "path": "date"},
    "isIconType" : false,
  },
  ElementType.weatherIconClock: {
    "widget": const WeatherIconClock(
      num: 0,
    ),
    "exportable": true,
    "xml": weatherIconClockXml,
    "png": {"export": exportWeatherIconPng, "path": "weather"},
    "isIconType" : false,
  },
  ElementType.amPmClock: {
    "widget": const AmPmClock(
      isAm: true,
    ),
    "exportable": true,
    "xml": amClockXml,
    "png": {"export": exportAmPmPng, "path": "ampm"},
    "isIconType" : false,
  },
  ElementType.cameraIcon: {
    "widget": const CameraIcon(
    ),
    "exportable": false,
    "xml": cameraIconXml,
    "isIconType" : true,
    "path" : "icon\\camera"
  },
  ElementType.themeIcon: {
    "widget": const ThemeIcon(
    ),
    "exportable": false,
    "xml": themeIconXml,
    "isIconType" : true,
    "path" : "icon\\theme"
  },
  ElementType.settingIcon: {
    "widget": const SettingIcon(
    ),
    "exportable": false,
    "xml": settingIconXml,
    "isIconType" : true,
    "path" : "icon\\setting"
  },
  ElementType.galleryIcon: {
    "widget": const GalleryIcon(
    ),
    "exportable": false,
    "xml": galleryIconXml,
    "isIconType" : true,
    "path" : "icon\\gallery"
  },
  ElementType.swipeUpUnlock: {
    "widget": const SwipeUpUnlock(),
    "xml": swipeUpUnlockXml,
    "exportable": false,
    "isIconType" : false,
  }
};
