import 'dart:io';

import 'package:flutter/material.dart';

import '../constants.dart';
import '../data/miui_theme_data.dart';
import '../functions/theme_path.dart';

class DirectoryProvider extends ChangeNotifier {
  bool? isCreating = false;
  bool? isLoadingPrelockCount = false;
  bool? isLoadingPreviewWallPath = false;
  String? preLockFolderNum = "1";
  String? status = "";

  List<String?> preLockPaths = [];
  List<String?> previewWallsPath = [];

  set setIsCreating(bool val) {
    isCreating = val;
    notifyListeners();
  }

  set setIsLoadingPrelockCount(bool val) {
    isLoadingPrelockCount = val;
    notifyListeners();
  }

  set setPreLockFolderNum(String? val) {
    preLockFolderNum = val;
    notifyListeners();
  }

  set setIsLoadingPreviewWallPath(bool? val) {
    isLoadingPreviewWallPath = val;
    notifyListeners();
  }

  void addPrelockFolderToList({String? path}) {
    preLockPaths.add(path);
    notifyListeners();
  }

  void addPreviewWallPathsToList({String? path}) {
    previewWallsPath.add(path);
    notifyListeners();
  }

  void setStatus({String? newStatus}) {
    status = newStatus;
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

  Future getPreLockCount() async {
    setIsLoadingPrelockCount = true;
    final folders = await Directory("${MIUIConstants.preLock}").list().toList();
    preLockPaths.clear();
    for (var fileEntity in folders) {
      if (fileEntity is! File) {
        addPrelockFolderToList(path: fileEntity.path.split("\\").last);
      }
    }
    setIsLoadingPrelockCount = false;
  }

  Future setPreviewWallsPath({String? folderNum}) async {
    isLoadingPreviewWallPath = true;
    setStatus(newStatus: "Analyzing...🤨🤨🤨");
    previewWallsPath.clear();
    final folders =
        await Directory("${MIUIConstants.preLock}\\$folderNum").list().toList();
    bool isAllInJPGFormat = true;
    for (var fileEntity in folders) {
      if (fileEntity is File) {
        addPreviewWallPathsToList(path: fileEntity.path);
        if (!fileEntity.path.endsWith(".jpg")) {
          isAllInJPGFormat = false;
        }
      }
    }
    setStatus(
        newStatus: isAllInJPGFormat
            ? "Superb All Looks Fine...😍😍😍"
            : "Nahh All Walls are not in JPG...😥😰🥴");
    if (previewWallsPath.length != 25) {
      setStatus(newStatus: "Walls are missing in counts...😶‍🌫️😕🤕");
    }
    isLoadingPreviewWallPath = false;
  }
}
