import 'dart:io';

import 'package:flutter/material.dart';
import 'package:miui_icon_generator/constants.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:window_manager/window_manager.dart';

Future startUpWindowsUtils() async {
  await windowManager.ensureInitialized();
  windowManager.waitUntilReadyToShow().then((_) async {
    await windowManager.setTitle("MIUI Theme Editor");
    await windowManager.setSize(MIUIConstants.windowSize);
    await windowManager.setMinimumSize(MIUIConstants.windowSize);
    await windowManager.center();
    await windowManager.show();
  });
}

errorBuilder() {
  ErrorWidget.builder = (FlutterErrorDetails details) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25),
        color: Colors.white,
      ),
      alignment: Alignment.center,
      child: Text(details.exceptionAsString()),
    );
  };
}

Future requestPermission() async {
  const permission = Permission.storage;
  final isGranted = await permission.isGranted;
  if (!isGranted) {
    await permission.request();
  }
  const managePermission = Permission.manageExternalStorage;
  final grant = await managePermission.isGranted;
  if (!grant) {
    await managePermission.request();
  }
}

String platformBasedPath(String path) {
  String newPath = path;
  if (Platform.isAndroid || Platform.isMacOS || Platform.isLinux) {
    newPath = path.replaceAll("\\", "/");
  }
  return newPath;
}
