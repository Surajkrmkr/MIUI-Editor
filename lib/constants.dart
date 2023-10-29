import 'dart:io';

import 'package:flutter/material.dart';

class MIUIConstants {
  static String? basePath = getBasePath;
  static String? preLock = getPrelock;
  static String? sample2Lockscreen = getSampleLockscreen;
  static String? sample2 = getSample;

  static double screenHeight = 600;
  static double screenWidth = 276.92;
  static double ratio = 2340 / 600;
  static Size windowSize = getWindowSize;

  static bool isDesktop = Platform.isWindows || Platform.isMacOS;

  static String get getBasePath {
    if (Platform.isWindows) {
      return "E:\\Xiaomi Contract\\";
    } else if (Platform.isAndroid) {
      return "/storage/emulated/0/Xiaomi Contract/";
    } else if (Platform.isMacOS) {
      return "/Users/surajkrmkr/Storage/Xiaomi Contract/";
    } else if (Platform.isIOS) {
      return "On My iPad/Xiaomi Contract/";
    }
    return "";
  }

  static String get getPrelock {
    if (Platform.isWindows) {
      return "${getBasePath}Wall\\";
    } else if (Platform.isAndroid || Platform.isIOS || Platform.isMacOS) {
      return "${getBasePath}Wall/";
    }
    return "";
  }

  static String get getSample {
    if (Platform.isWindows) {
      return "${getBasePath}Sample2\\";
    } else if (Platform.isAndroid || Platform.isIOS || Platform.isMacOS) {
      return "${getBasePath}Sample2/";
    }
    return "";
  }

  static String get getSampleLockscreen {
    if (Platform.isWindows) {
      return "${getSample}lockscreen\\advance\\";
    } else if (Platform.isAndroid || Platform.isIOS || Platform.isMacOS) {
      return "${getSample}lockscreen/advance/";
    }
    return "";
  }

  static Size get getWindowSize {
    if (Platform.isWindows) {
      return const Size(1500, 900);
    } else if (Platform.isMacOS) {
      return const Size(1400, 900);
    }
    return Size.zero;
  }
}
