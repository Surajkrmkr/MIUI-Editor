import 'package:miui_icon_generator/data/unlock/unlock.dart';

import 'container/container_bg.dart';
import 'music/music.dart';
import 'notification/notification.dart';
import 'text/text.dart';
import 'xml data/container/container_bg.dart';
import 'xml data/music/music.dart';
import 'xml data/notification/notification.dart';
import 'xml data/shortcuts/icons.dart';
import 'xml data/swipe_up_unlock.dart';
import 'xml data/clock/date_time_clock.dart';
import 'shortcuts/icons.dart';
import 'time/clock.dart';
import 'xml data/text/text.dart';

enum ElementType {
  containerBG1,
  containerBG2,
  containerBG3,
  containerBG4,
  containerBG5,
  hourClock,
  minClock,
  dotClock,
  amPmClock,
  weekClock,
  monthClock,
  dateClock,
  weatherIconClock,
  notification,
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
  musicPlay,
  musicPause,
  cameraIcon,
  themeIcon,
  musicIcon,
  dialerIcon,
  mmsIcon,
  contactIcon,
  whatsAppIcon,
  telegramIcon,
  instagramIcon,
  spotifyIcon,
  settingIcon,
  galleryIcon,
  swipeUpUnlock
}

final Map<ElementType, Map<String, dynamic>> elementWidgetMap = {
  ElementType.containerBG1: {
    "widget": const ContainerBG(type: ElementType.containerBG1),
    "xml": containerBGXml,
    "exportable": true,
    "isContainerType": true,
    "png": {"export": exportContainerBG1Png, "path": "container"},
  },
  ElementType.containerBG2: {
    "widget": const ContainerBG(type: ElementType.containerBG2),
    "xml": containerBGXml,
    "exportable": true,
    "isContainerType": true,
    "png": {"export": exportContainerBG2Png, "path": "container"},
  },
  ElementType.containerBG3: {
    "widget": const ContainerBG(type: ElementType.containerBG3),
    "xml": containerBGXml,
    "exportable": true,
    "isContainerType": true,
    "png": {"export": exportContainerBG3Png, "path": "container"},
  },
  ElementType.containerBG4: {
    "widget": const ContainerBG(type: ElementType.containerBG4),
    "xml": containerBGXml,
    "exportable": true,
    "isContainerType": true,
    "png": {"export": exportContainerBG4Png, "path": "container"},
  },
  ElementType.containerBG5: {
    "widget": const ContainerBG(type: ElementType.containerBG5),
    "xml": containerBGXml,
    "exportable": true,
    "isContainerType": true,
    "png": {"export": exportContainerBG5Png, "path": "container"},
  },
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
  ElementType.notification: {
    "widget": const Notification(),
    "exportable": false,
    "xml": notificationXml,
    "path": "notification\\close",
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
  ElementType.musicPlay: {
    "widget": const MusicPlay(),
    "exportable": false,
    "xml": musicPlayXml,
    "isMusic": true,
    "path": "music\\play"
  },
  ElementType.musicPause: {
    "widget": const MusicPause(),
    "exportable": false,
    "xml": musicPauseXml,
    "isMusic": true,
    "path": "music\\pause"
  },
  ElementType.cameraIcon: {
    "widget":
        const ShortcutIcon(path: "icon\\camera", type: ElementType.cameraIcon),
    "exportable": false,
    "xml": cameraIconXml,
    "isIconType": true,
    "path": "icon\\camera"
  },
  ElementType.themeIcon: {
    "widget": const ShortcutIcon(
      path: "icon\\theme",
      type: ElementType.themeIcon,
    ),
    "exportable": false,
    "xml": themeIconXml,
    "isIconType": true,
    "path": "icon\\theme"
  },
  ElementType.settingIcon: {
    "widget": const ShortcutIcon(
        path: "icon\\setting", type: ElementType.settingIcon),
    "exportable": false,
    "xml": settingIconXml,
    "isIconType": true,
    "path": "icon\\setting"
  },
  ElementType.galleryIcon: {
    "widget": const ShortcutIcon(
        path: "icon\\gallery", type: ElementType.galleryIcon),
    "exportable": false,
    "xml": galleryIconXml,
    "isIconType": true,
    "path": "icon\\gallery"
  },
  ElementType.musicIcon: {
    "widget":
        const ShortcutIcon(path: "icon\\music", type: ElementType.musicIcon),
    "exportable": false,
    "xml": musicIconXml,
    "isIconType": true,
    "path": "icon\\music"
  },
  ElementType.dialerIcon: {
    "widget":
        const ShortcutIcon(path: "icon\\dialer", type: ElementType.dialerIcon),
    "exportable": false,
    "xml": dialerIconXml,
    "isIconType": true,
    "path": "icon\\dialer"
  },
  ElementType.mmsIcon: {
    "widget": const ShortcutIcon(path: "icon\\mms", type: ElementType.mmsIcon),
    "exportable": false,
    "xml": mmsIconXml,
    "isIconType": true,
    "path": "icon\\mms"
  },
  ElementType.contactIcon: {
    "widget": const ShortcutIcon(
        path: "icon\\contact", type: ElementType.contactIcon),
    "exportable": false,
    "xml": cameraIconXml,
    "isIconType": true,
    "path": "icon\\contact"
  },
  ElementType.whatsAppIcon: {
    "widget": const ShortcutIcon(
        path: "icon\\whatsApp", type: ElementType.whatsAppIcon),
    "exportable": false,
    "xml": whatsAppIconXml,
    "isIconType": true,
    "path": "icon\\whatsApp"
  },
  ElementType.instagramIcon: {
    "widget": const ShortcutIcon(
        path: "icon\\instagram", type: ElementType.instagramIcon),
    "exportable": false,
    "xml": instagramIconXml,
    "isIconType": true,
    "path": "icon\\instagram"
  },
  ElementType.telegramIcon: {
    "widget": const ShortcutIcon(
        path: "icon\\telegram", type: ElementType.telegramIcon),
    "exportable": false,
    "xml": telegramIconXml,
    "isIconType": true,
    "path": "icon\\telegram"
  },
  ElementType.spotifyIcon: {
    "widget": const ShortcutIcon(
        path: "icon\\spotify", type: ElementType.spotifyIcon),
    "exportable": false,
    "xml": spotifyIconXml,
    "isIconType": true,
    "path": "icon\\spotify"
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

const Map<String, List<ElementType>> elementsByGroup = {
  "Container": [
    ElementType.containerBG1,
    ElementType.containerBG2,
    ElementType.containerBG3,
    ElementType.containerBG4,
    ElementType.containerBG5
  ],
  "Clock": [
    ElementType.hourClock,
    ElementType.minClock,
    ElementType.dotClock,
    ElementType.amPmClock,
    ElementType.weekClock,
  ],
  "Date": [
    ElementType.monthClock,
    ElementType.dateClock,
  ],
  "Weather": [
    ElementType.weatherIconClock,
  ],
  "Notification":[
    ElementType.notification
  ],
  "DateTime Text": [
    ElementType.dateTimeText1,
    ElementType.dateTimeText2,
    ElementType.dateTimeText3,
  ],
  "Text": [
    ElementType.normalText1,
    ElementType.normalText2,
    ElementType.normalText3,
    ElementType.normalText4,
    ElementType.normalText5,
  ],
  "Music": [
    ElementType.musicBg,
    ElementType.musicNext,
    ElementType.musicPrev,
    ElementType.musicPlay,
    ElementType.musicPause,
  ],
  "Icon": [
    ElementType.cameraIcon,
    ElementType.themeIcon,
    ElementType.musicIcon,
    ElementType.dialerIcon,
    ElementType.mmsIcon,
    ElementType.contactIcon,
    ElementType.whatsAppIcon,
    ElementType.telegramIcon,
    ElementType.instagramIcon,
    ElementType.spotifyIcon,
    ElementType.settingIcon,
    ElementType.galleryIcon,
  ],
  "Other": [
    ElementType.swipeUpUnlock,
  ],
};
