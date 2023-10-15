import 'dart:io';

import 'package:flutter/material.dart';
import 'package:miui_icon_generator/constants.dart';
import 'package:provider/provider.dart';

import 'functions/windows_utils.dart';
import 'providers.dart';
import 'screen/Landing_page.dart';
import 'theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (MIUIConstants.isDesktop) await startUpWindowsUtils();
  if (Platform.isAndroid) await requestPermission();
  errorBuilder();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: MIUIProvider.getProviders(context),
      child: MaterialApp(
        title: 'MIUI Theme Creator By Suraj',
        themeMode: ThemeMode.dark,
        darkTheme: AppThemeData.getDarkTheme(),
        theme: AppThemeData.getLightTheme(),
        home: LandingPage(),
      ),
    );
  }
}
