import 'package:miui_icon_generator/provider/font.dart';
import 'package:miui_icon_generator/provider/icon.dart';
import 'package:miui_icon_generator/provider/module.dart';
import 'package:miui_icon_generator/provider/wallpaper.dart';
import 'package:provider/provider.dart';

import 'provider/directory.dart';
import 'provider/element.dart';
import 'provider/lockscreen.dart';
import 'provider/mtz.dart';
import 'provider/tag.dart';

class MIUIProvider {
  static getProviders(context) => [
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
          create: (context) => TagProvider(),
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
      ];
}
