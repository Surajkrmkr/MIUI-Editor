import 'package:flutter/material.dart';
import 'package:miui_icon_generator/provider/font.dart';
import 'package:miui_icon_generator/provider/icon.dart';
import 'package:miui_icon_generator/provider/module.dart';
import 'package:miui_icon_generator/provider/wallpaper.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';

import 'provider/directory.dart';
import 'provider/element.dart';
import 'provider/lockscreen.dart';
import 'screen/Landing_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();
  windowManager.waitUntilReadyToShow().then((_) async {
    await windowManager.setSize(const Size(1500, 900));
    await windowManager.setMinimumSize(const Size(1500, 900));
    await windowManager.center();
    await windowManager.show();
  });
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
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (context) => DirectoryProvider(),
        ),
        ChangeNotifierProvider(
          create: (context) => IconProvider(),
        ),
        ChangeNotifierProvider(
          create: (context) => WallpaperProvider(),
        ),
        ChangeNotifierProvider(
          create: (context) => ModuleProvider(),
        ),
        ChangeNotifierProvider(
          create: (context) => FontProvider(),
        ),
        ChangeNotifierProvider(
          create: (context) => ElementProvider(),
        ),
        ChangeNotifierProvider(
          create: (context) => LockscreenProvider(),
        ),
      ],
      child: MaterialApp(
        title: 'Icon Generator',
        theme: ThemeData(
            useMaterial3: true,
            scaffoldBackgroundColor: Colors.white,
            sliderTheme: const SliderThemeData(
              showValueIndicator: ShowValueIndicator.always,
            ),
            listTileTheme: ListTileThemeData(
              selectedColor: Colors.white,
              selectedTileColor: Colors.pinkAccent,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15)),
            ),
            chipTheme: ChipThemeData(
                checkmarkColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                side: BorderSide.none,
                secondaryLabelStyle: const TextStyle(color: Colors.white),
                selectedColor: Colors.pinkAccent),
            colorScheme: const ColorScheme.light(primary: Colors.pinkAccent)),
        home: LandingPage(),
      ),
    );
  }
}
