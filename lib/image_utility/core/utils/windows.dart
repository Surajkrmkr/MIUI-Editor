import 'dart:io';
import 'dart:ui';

import 'package:window_manager/window_manager.dart';

Future startUpWindowsUtils() async {
  await windowManager.ensureInitialized();
  windowManager.waitUntilReadyToShow().then((_) async {
    await windowManager.setTitle("Miui Tools");
    await windowManager.setSize(getWindowSize);
    await windowManager.setMinimumSize(getWindowSize);
    await windowManager.center();
    await windowManager.show();
  });
}

Size get getWindowSize {
  if (Platform.isWindows) {
    return const Size(1300, 750);
  } else if (Platform.isMacOS) {
    return const Size(1300, 800);
  } else if (Platform.isLinux) {
    return const Size(1400, 800);
  }
  return Size.zero;
}
