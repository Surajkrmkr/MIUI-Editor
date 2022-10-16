import 'dart:io';

import 'package:flutter/material.dart';

import '../data/miui_theme_data.dart';
import '../functions/theme_path.dart';

class DirectoryProvider extends ChangeNotifier {
  bool? isCreating = false;
  
  set setIsCreating(bool val) {
    isCreating = val;
    notifyListeners();
  }

  Future createThemeDirectory({BuildContext? context}) async {
    setIsCreating = true;
    final themePath = CurrentTheme.getPath(context);
    for (String? path in MIUIThemeData.directoryList) {
      await Directory("$themePath$path").create(recursive: true);
    }
    setIsCreating = false;
  }
}
