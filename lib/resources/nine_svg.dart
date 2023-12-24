import 'dart:ui';

import '../data/module/module.dart';

class NineSvg {
  static List<Function> patches = [
    // dialogNinePngs,
    // baseNinePngs,
    // dialerNinePngs,
    // bgNinePngs
  ];

  static Map dialogNinePngs(context) => {
        "widget":
            ninePatchSvg(context: context, svgPath: NineSvg.getDialogSvg()),
        "size": const Size(155, 155),
        "list": [
          {
            "name": "dialog_bg_light.9",
            "path": [
              directoryList[2],
              directoryList[3],
              directoryList[6],
              directoryList[7],
              directoryList[11],
              directoryList[12],
            ]
          },
          {
            "name": "list_menu_bg_light.9",
            "path": [
              directoryList[2],
              directoryList[3],
              directoryList[6],
              directoryList[7],
              directoryList[11],
              directoryList[12],
            ],
          }
        ]
      };

  static Map baseNinePngs(context) => {
        "widget": ninePatchSvg(context: context, svgPath: NineSvg.getBaseSvg()),
        "size": const Size(30, 30),
        "list": [
          {
            "name": "search_mode_input_bg_light.9",
            "path": [
              directoryList[2],
              directoryList[3],
              directoryList[6],
              directoryList[7],
              directoryList[11],
              directoryList[12],
            ]
          },
          // {
          //   "name": "action_bar_bg_light.9",
          //   "path": [
          //     directoryList[3],
          //     directoryList[7],
          //     directoryList[12],
          //   ]
          // },
          // {
          //   "name": "action_bar_split_bg_light.9",
          //   "path": [
          //     directoryList[3],
          //     directoryList[7],
          //     directoryList[12],
          //   ]
          // },
          {
            "name": "action_mode_bg_light.9",
            "path": [
              directoryList[3],
              directoryList[7],
              directoryList[12],
            ]
          },
          {
            "name": "contact_detail_default_photo.9",
            "path": [
              directoryList[0],
            ]
          },
          {
            "name": "dialer_title_bg.9",
            "path": [
              directoryList[0],
            ]
          },
        ]
      };

  static Map dialerNinePngs(context) => {
        "widget":
            ninePatchSvg(context: context, svgPath: NineSvg.getDialerSvg()),
        "size": const Size(254, 265),
        "list": [
          {
            "name": "dialerpad_background.9",
            "path": [
              directoryList[0],
            ]
          },
        ]
      };

  static Map bgNinePngs(context) => {
        "widget":
            ninePatchPng(context: context, pngPath: "assets/9pngs/wall.png"),
        "size": const Size(1080, 2340),
        "list": [
          {
            "name": "window_bg_light.9",
            "path": [
              directoryList[2],
              directoryList[3],
              directoryList[6],
              directoryList[7],
              directoryList[11],
              directoryList[12],
            ]
          },
          {
            "name": "attachment_screen_bg.9",
            "path": [
              directoryList[4],
            ]
          },
          {
            "name": "conversation_bg.9",
            "path": [
              directoryList[4],
            ]
          },
          {
            "name": "search_bg.9",
            "path": [
              directoryList[4],
            ]
          },
          {
            "name": "window_bg_verification_list.9",
            "path": [
              directoryList[4],
            ]
          },
        ]
      };

  static List<String> directoryList = [
    "\\com.android.contacts\\${subDirectoryList[0]}",
    "\\com.android.contacts\\${subDirectoryList[1]}",
    "\\com.android.contacts\\${subDirectoryList[2]}",
    "\\com.android.contacts\\${subDirectoryList[3]}",
    "\\com.android.mms\\${subDirectoryList[0]}",
    "\\com.android.mms\\${subDirectoryList[1]}",
    "\\com.android.mms\\${subDirectoryList[2]}",
    "\\com.android.mms\\${subDirectoryList[3]}",
    "\\com.android.systemui\\${subDirectoryList[0]}",
    "\\com.android.settings\\${subDirectoryList[0]}",
    "\\com.android.settings\\${subDirectoryList[1]}",
    "\\com.android.settings\\${subDirectoryList[2]}",
    "\\com.android.settings\\${subDirectoryList[3]}",
  ];

  static List<String> subDirectoryList = [
    "res\\drawable-xxhdpi\\",
    "res\\drawable-nxhdpi\\",
    "framework-miui-res\\res\\drawable-nxhdpi\\",
    "framework-miui-res\\res\\drawable-xxhdpi\\"
  ];
  static String getDialogSvg() => '''
      <svg width="155" height="155" viewBox="0 0 155 155" fill="none" xmlns="http://www.w3.org/2000/svg">
        <path d="M1 69C1 31.4446 31.4446 1 69 1H86C123.555 1 154 31.4446 154 69V154H1V69Z" fill="#FF8CEE"/>
        <rect x="154" y="3" width="1" height="151" fill="black"/>
        <rect x="3" y="154" width="150" height="1" fill="black"/>
        <rect x="75" width="1" height="1" fill="black"/>
        <rect y="148" width="1" height="1" fill="black"/>
      </svg>
''';

  static String getDialerSvg() => '''
      <svg width="254" height="265" viewBox="0 0 254 265" fill="none" xmlns="http://www.w3.org/2000/svg">
        <rect x="1" y="1" width="252" height="263" rx="15" fill="#FF8CEE"/>
        <rect x="1" y="264" width="252" height="1" fill="black"/>
        <rect x="27" width="200" height="1" fill="black"/>
        <rect x="253" y="1" width="1" height="263" fill="black"/>
        <rect y="25" width="1" height="215" fill="black"/>
      </svg>
''';

  static String getBaseSvg() => '''
      <svg width="30" height="30" viewBox="0 0 30 30" fill="none" xmlns="http://www.w3.org/2000/svg">
        <rect x="1" y="1" width="28" height="28" fill="#FF8CEE"/>
        <rect x="1" width="28" height="1" fill="black"/>
        <rect x="1" y="29" width="28" height="1" fill="black"/>
        <rect y="1" width="1" height="28" fill="black"/>
        <rect x="29" y="1" width="1" height="28" fill="black"/>
      </svg>
''';
}
