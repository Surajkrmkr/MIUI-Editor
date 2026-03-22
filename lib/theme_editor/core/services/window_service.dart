import 'dart:io';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import '../constants/app_constants.dart';

class WindowService {
  static Future<void> init() async {
    await windowManager.ensureInitialized();
    final size = Size(
      AppConstants.winWidth,
      Platform.isMacOS ? AppConstants.winHeightMac : AppConstants.winHeight,
    );
    await windowManager.waitUntilReadyToShow(
      WindowOptions(title: AppConstants.appName, size: size, minimumSize: size, center: true),
      () async {
        await windowManager.show();
        await windowManager.focus();
      },
    );
  }
}
