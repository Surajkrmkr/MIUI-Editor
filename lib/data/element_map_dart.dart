import 'package:miui_icon_generator/data/unlock/unlock.dart';

import 'music/music.dart';
import 'text/text.dart';
import 'xml data/music/music.dart';
import 'xml data/shortcuts/icons.dart';
import 'xml data/swipe_up_unlock.dart';
import 'xml data/clock/date_time_clock.dart';
import 'shortcuts/icons.dart';
import 'time/clock.dart';
import 'xml data/text/text.dart';

enum ElementType {
  hourClock,
  minClock,
  dotClock,
  amPmClock,
  weekClock,
  monthClock,
  dateClock,
  weatherIconClock,
  dateTimeText1,
  dateTimeText2,
  dateTimeText3,
  normalText1,
  normalText2,
  normalText3,
  normalText4,
  normalText5,
  musicBg,
  musicNext,
  musicPrev,
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
  },
  ElementType.minClock: {
    "widget": const MinClock(num: 36),
    "xml": minClockXml,
    "exportable": true,
    "png": {"export": exportMinPng, "path": "min"},
  },
  ElementType.dotClock: {
    "widget": const DotClock(),
    "exportable": true,
    "xml": dotClockXml,
    "png": {"export": exportDotPng, "path": "dot"},
  },
  ElementType.weekClock: {
    "widget": const WeekClock(
      num: 3,
    ),
    "exportable": true,
    "xml": weekClockXml,
    "png": {"export": exportWeekPng, "path": "week"},
  },
  ElementType.monthClock: {
    "widget": const MonthClock(
      num: 3,
    ),
    "exportable": true,
    "xml": monthClockXml,
    "png": {"export": exportMonthPng, "path": "month"},
  },
  ElementType.dateClock: {
    "widget": const DateClock(
      num: 3,
    ),
    "exportable": true,
    "xml": dateClockXml,
    "png": {"export": exportDatePng, "path": "date"},
  },
  ElementType.weatherIconClock: {
    "widget": const WeatherIconClock(
      num: 0,
    ),
    "exportable": true,
    "xml": weatherIconClockXml,
    "png": {"export": exportWeatherIconPng, "path": "weather"},
  },
  ElementType.amPmClock: {
    "widget": const AmPmClock(
      isAm: true,
    ),
    "exportable": true,
    "xml": amClockXml,
    "png": {"export": exportAmPmPng, "path": "ampm"},
  },
  ElementType.musicBg: {
    "widget": const MusicBG(),
    "exportable": false,
    "xml": musicBgXml,
    "isMusic": true,
    "path": "music\\bg"
  },
  ElementType.musicNext: {
    "widget": const MusicNext(),
    "exportable": false,
    "xml": musicNextXml,
    "isMusic": true,
    "path": "music\\next"
  },
  ElementType.musicPrev: {
    "widget": const MusicPrev(),
    "exportable": false,
    "xml": musicPrevXml,
    "isMusic": true,
    "path": "music\\prev"
  },
  ElementType.cameraIcon: {
    "widget": const CameraIcon(),
    "exportable": false,
    "xml": cameraIconXml,
    "isIconType": true,
    "path": "icon\\camera"
  },
  ElementType.themeIcon: {
    "widget": const ThemeIcon(),
    "exportable": false,
    "xml": themeIconXml,
    "isIconType": true,
    "path": "icon\\theme"
  },
  ElementType.settingIcon: {
    "widget": const SettingIcon(),
    "exportable": false,
    "xml": settingIconXml,
    "isIconType": true,
    "path": "icon\\setting"
  },
  ElementType.galleryIcon: {
    "widget": const GalleryIcon(),
    "exportable": false,
    "xml": galleryIconXml,
    "isIconType": true,
    "path": "icon\\gallery"
  },
  ElementType.swipeUpUnlock: {
    "widget": const SwipeUpUnlock(),
    "xml": swipeUpUnlockXml,
    "exportable": false,
  },
  ElementType.dateTimeText1: {
    "widget": const DateTimeText(type: ElementType.dateTimeText1),
    "xml": dateTimeTextXml,
    "isTextType": true,
    "exportable": false,
  },
  ElementType.dateTimeText2: {
    "widget": const DateTimeText(type: ElementType.dateTimeText2),
    "xml": dateTimeTextXml,
    "isTextType": true,
    "exportable": false,
  },
  ElementType.dateTimeText3: {
    "widget": const DateTimeText(type: ElementType.dateTimeText3),
    "xml": dateTimeTextXml,
    "isTextType": true,
    "exportable": false,
  },
  ElementType.normalText1: {
    "widget": const NormalText(type: ElementType.normalText1),
    "xml": normalTextXml,
    "isTextType": true,
    "exportable": false,
  },
  ElementType.normalText2: {
    "widget": const NormalText(type: ElementType.normalText2),
    "xml": normalTextXml,
    "isTextType": true,
    "exportable": false,
  },
  ElementType.normalText3: {
    "widget": const NormalText(type: ElementType.normalText3),
    "xml": normalTextXml,
    "isTextType": true,
    "exportable": false,
  },
  ElementType.normalText4: {
    "widget": const NormalText(type: ElementType.normalText4),
    "xml": normalTextXml,
    "isTextType": true,
    "exportable": false,
  },
  ElementType.normalText5: {
    "widget": const NormalText(type: ElementType.normalText5),
    "xml": normalTextXml,
    "isTextType": true,
    "exportable": false,
  },
};
