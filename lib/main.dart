import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'functions/windows_utils.dart';
import 'providers.dart';
import 'screen/Landing_page.dart';
import 'theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await startUpWindowsUtils();
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
        title: 'Icon Generator',
        themeMode: ThemeMode.light,
        darkTheme: AppThemeData.getDarkTheme(),
        theme: AppThemeData.getLightTheme(),
        home: LandingPage(),
      ),
    );
  }
}
