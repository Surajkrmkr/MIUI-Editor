import 'dart:io';

class MIUIConstants {
  static String? basePath = Platform.isWindows ? "E:\\Xiaomi Contract\\" :"/storage/emulated/0/Xiaomi Contract/";
  static String? preLock = Platform.isWindows
      ? "E:\\Xiaomi Contract\\PreLock\\"
      : "/storage/emulated/0/Xiaomi Contract/PreLock/";
  static String? prePare = "E:\\Xiaomi Contract\\Prepare\\";
  static String? sample2Lockscreen = Platform.isWindows
      ? "E:\\Xiaomi Contract\\Sample2\\lockscreen\\advance"
      : "/storage/emulated/0/Xiaomi Contract/Sample2/lockscreen/advance";
  static String? sample2 = Platform.isWindows
      ? "E:\\Xiaomi Contract\\Sample2\\"
      : "/storage/emulated/0/Xiaomi Contract/Sample2/";

  static double screenHeight = 600;
  static double screenWidth = 276.92;
  static double ratio = 2340 / 600;
}
