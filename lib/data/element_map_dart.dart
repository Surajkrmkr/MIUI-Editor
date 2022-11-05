import 'package:miui_icon_generator/data/unlock/unlock.dart';

import 'music/music.dart';
import 'xml data/music/music.dart';
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
    "widget": (String? id) => HourClock(
          num: 02,
          id: id,
        ),
    "xml": hourClockXml,
    "exportable": true,
    "png": {"export": exportHourPng, "path": "hour"},
  },
  ElementType.minClock: {
    "widget": (String? id) => MinClock(
          num: 36,
          id: id,
        ),
    "xml": minClockXml,
    "exportable": true,
    "png": {"export": exportMinPng, "path": "min"},
  },
  ElementType.dotClock: {
    "widget": (String? id) => DotClock(id: id),
    "exportable": true,
    "xml": dotClockXml,
    "png": {"export": exportDotPng, "path": "dot"},
  },
  ElementType.textLineClock: {
    "widget": (String? id) => TextLineClock(
          text: '8 feb, Tue',
          id: id,
        ),
    "exportable": false,
    "xml": textLineClockXml,
  },
  ElementType.weekClock: {
    "widget": (String? id) => WeekClock(
          num: 3,
          id: id,
        ),
    "exportable": true,
    "xml": weekClockXml,
    "png": {"export": exportWeekPng, "path": "week"},
  },
  ElementType.monthClock: {
    "widget": (String? id) => MonthClock(
          num: 3,
          id: id,
        ),
    "exportable": true,
    "xml": monthClockXml,
    "png": {"export": exportMonthPng, "path": "month"},
  },
  ElementType.dateClock: {
    "widget": (String? id) => DateClock(
          num: 3,
          id: id,
        ),
    "exportable": true,
    "xml": dateClockXml,
    "png": {"export": exportDatePng, "path": "date"},
  },
  ElementType.weatherIconClock: {
    "widget": (String? id) => WeatherIconClock(num: 0, id: id),
    "exportable": true,
    "xml": weatherIconClockXml,
    "png": {"export": exportWeatherIconPng, "path": "weather"},
  },
  ElementType.amPmClock: {
    "widget": (String? id) => AmPmClock(
          isAm: true,
          id: id,
        ),
    "exportable": true,
    "xml": amClockXml,
    "png": {"export": exportAmPmPng, "path": "ampm"},
  },
  ElementType.musicBg: {
    "widget": (String? id) => MusicBG(id: id,),
    "exportable": false,
    "xml": musicBgXml,
    "isMusic": true,
    "path": "music\\bg"
  },
  ElementType.musicNext: {
    "widget": (String? id) => MusicNext(id: id),
    "exportable": false,
    "xml": musicNextXml,
    "isMusic": true,
    "path": "music\\next"
  },
  ElementType.musicPrev: {
    "widget": (String? id) => MusicPrev(id: id),
    "exportable": false,
    "xml": musicPrevXml,
    "isMusic": true,
    "path": "music\\prev"
  },
  ElementType.cameraIcon: {
    "widget": (String? id) => CameraIcon(id: id),
    "exportable": false,
    "xml": cameraIconXml,
    "isIconType": true,
    "path": "icon\\camera"
  },
  ElementType.themeIcon: {
    "widget": (String? id) => ThemeIcon(id: id),
    "exportable": false,
    "xml": themeIconXml,
    "isIconType": true,
    "path": "icon\\theme"
  },
  ElementType.settingIcon: {
    "widget": (String? id) => SettingIcon(id: id),
    "exportable": false,
    "xml": settingIconXml,
    "isIconType": true,
    "path": "icon\\setting"
  },
  ElementType.galleryIcon: {
    "widget": (String? id) => GalleryIcon(id: id),
    "exportable": false,
    "xml": galleryIconXml,
    "isIconType": true,
    "path": "icon\\gallery"
  },
  ElementType.swipeUpUnlock: {
    "widget": (String? id) => const SwipeUpUnlock(),
    "xml": swipeUpUnlockXml,
    "exportable": false,
  },
};
