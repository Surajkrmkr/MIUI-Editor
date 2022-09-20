import 'dart:io';

import 'package:flutter/material.dart';

import '../constants.dart';

class WallpaperProvider extends ChangeNotifier {
  bool? isLoading = true;
  String? folderNum = "1";

  set setIsLoading(val) {
    isLoading = val;
    notifyListeners();
  }

  int? index = 0;

  set setIndex(int n) {
    index = n;
    notifyListeners();
  }

  List<String>? paths = [];

  void setTotalImage(String num) async {
    setIsLoading = true;
    final dir = Directory('${MIUIConstants.preLock}$num');
    folderNum = num;
    final entities = await dir.list().toList();
    entities.map((e) => paths!.add(e.path));
    for (FileSystemEntity file in entities) {
      paths!.add(file.path);
    }
    setIsLoading = false;
    notifyListeners();
  }
}
