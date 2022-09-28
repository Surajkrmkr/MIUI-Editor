import 'package:flutter/material.dart';
import 'package:miui_icon_generator/provider/export.dart';
import 'package:miui_icon_generator/provider/font.dart';
import 'package:miui_icon_generator/provider/icon.dart';
import 'package:miui_icon_generator/provider/module.dart';
import 'package:miui_icon_generator/provider/wallpaper.dart';
import 'package:provider/provider.dart';

import 'screen/Landing_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (context) => IconProvider(),
        ),
        ChangeNotifierProvider(
          create: (context) => WallpaperProvider(),
        ),
        ChangeNotifierProvider(
          create: (context) => ExportIconProvider(),
        ),
        ChangeNotifierProvider(
          create: (context) => ModuleProvider(),
        ),
        ChangeNotifierProvider(
          create: (context) => FontProvider(),
        ),
      ],
      child: MaterialApp(
        title: 'Icon Generator',
        theme: ThemeData(
            useMaterial3: true,
            sliderTheme: const SliderThemeData(
              showValueIndicator: ShowValueIndicator.always,
            ),
            colorScheme: const ColorScheme.light(primary: Colors.pinkAccent)),
        home: LandingPage(),
      ),
    );
  }
}
