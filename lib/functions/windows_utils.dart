import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

Future startUpWindowsUtils() async {
  await windowManager.ensureInitialized();
  windowManager.waitUntilReadyToShow().then((_) async {
    await windowManager.setSize(const Size(1500, 900));
    await windowManager.setMinimumSize(const Size(1500, 900));
    await windowManager.center();
    await windowManager.show();
  });
}

errorBuilder(){
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
