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
import 'provider/mtz.dart';
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
        ChangeNotifierProvider(
          create: (context) => MTZProvider(),
        ),
      ],
      child: MaterialApp(
        title: 'Icon Generator',
        themeMode: ThemeMode.light,
        darkTheme: ThemeData.dark().copyWith(
            useMaterial3: true,
            appBarTheme: const AppBarTheme(
                backgroundColor: Color.fromARGB(255, 30, 30, 30),
                foregroundColor: Colors.white),
            backgroundColor: const Color.fromARGB(255, 30, 30, 30),
            scaffoldBackgroundColor: const Color.fromARGB(255, 30, 30, 30),
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
        theme: ThemeData(
            useMaterial3: true,
            backgroundColor: Colors.white,
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
