import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../constants.dart';
import '../data/miui_theme_data.dart';
import '../functions/shared_prefs.dart';
import '../functions/theme_path.dart';
import '../functions/windows_utils.dart';
import 'tag.dart';

class DirectoryProvider extends ChangeNotifier {
  bool? isCreating = false;
  bool? isLoadingPrelockCount = false;
  bool? isLoadingPreviewWallPath = false;
  bool? isLoadingPresetLockPath = false;
  String? preLockFolderNum = "1";
  String? status = "";

  List<String?> preLockPaths = [];
  List<String?> previewWallsPath = [];
  List<String?> presetLockPaths = [];

  set setIsCreating(bool val) {
    isCreating = val;
    notifyListeners();
  }

  set setIsLoadingPrelockCount(bool val) {
    isLoadingPrelockCount = val;
    notifyListeners();
  }

  set setIsLoadingPresetLockPath(bool val) {
    isLoadingPresetLockPath = val;
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

  void addPresetPathsToList({String? path}) {
    presetLockPaths.add(path);
    notifyListeners();
  }

  void setStatus({String? newStatus}) {
    status = newStatus;
    notifyListeners();
  }

  Future createThemeDirectory(
      {BuildContext? context, String? themeName}) async {
    setIsCreating = true;
    final themePath = CurrentTheme.getPath(context);
    for (String? path in MIUIThemeData.directoryList) {
      await Directory(platformBasedPath("$themePath$path"))
          .create(recursive: true);
    }
    await createTagDirectory(context: context, themeName: themeName);
    setIsCreating = false;
  }

  Future createTagDirectory(
      {BuildContext? context, bool saveFile = false, String? themeName}) async {
    final tagPath = CurrentTheme.getTagDirectory(context);
    final tagDir =
        await Directory(platformBasedPath(tagPath)).create(recursive: true);
    final String tagFilePath =
        "${tagDir.path}${themeName ?? CurrentTheme.getCurrentThemeName(context)!}.txt";
    if (!await File(tagFilePath).exists() || saveFile) {
      final File tagFile = await File(tagFilePath).create();
      await tagFile.writeAsString(
          Provider.of<TagProvider>(context!, listen: false)
              .appliedTags
              .join(","));
    }
  }

  Future getPreLockCount() async {
    setIsLoadingPrelockCount = true;
    if (Platform.isAndroid) {
      await Directory(MIUIConstants.preLock!).create(recursive: true);
    }
    final folders = await Directory("${MIUIConstants.preLock}").list().toList();
    preLockPaths.clear();
    for (var fileEntity in folders) {
      if (fileEntity is! File) {
        final path = fileEntity.path.split(platformBasedPath("\\")).last;
        addPrelockFolderToList(path: path);
      }
    }
    setIsLoadingPrelockCount = false;
  }

  Future getPresetLockPath() async {
    setIsLoadingPresetLockPath = true;
    if (Platform.isAndroid) {
      await Directory(MIUIConstants.preset!).create(recursive: true);
    }
    final folders = await Directory("${MIUIConstants.preset}").list().toList();
    presetLockPaths.clear();
    for (var folderEntity in folders) {
      if (folderEntity is Directory) {
        // final presetName =
        //     folderEntity.path.split(platformBasedPath("\\")).last;
        addPresetPathsToList(path: platformBasedPath(folderEntity.path));
      }
    }
    presetLockPaths.sort((a, b) => a!.compareTo(b!));
    setIsLoadingPresetLockPath = false;
  }

  Future setPreviewWallsPath({String? folderNum}) async {
    isLoadingPreviewWallPath = true;
    setStatus(newStatus: "Analyzing...🤨🤨🤨");
    previewWallsPath.clear();
    final folders = await Directory(
            platformBasedPath("${MIUIConstants.preLock}\\$folderNum"))
        .list()
        .toList();
    bool isAllInJPGFormat = true;
    for (var fileEntity in folders) {
      if (fileEntity is File) {
        if (fileEntity.path.endsWith(".jpg") ||
            fileEntity.path.endsWith(".png")) {
          addPreviewWallPathsToList(path: fileEntity.path);
          if (!fileEntity.path.endsWith(".jpg")) {
            isAllInJPGFormat = false;
          }
        }
      }
    }
    setStatus(
        newStatus: isAllInJPGFormat
            ? "Superb All Looks Fine...😍😍😍"
            : "Nahh All Walls are not in JPG...😥😰🥴");
    final settings = SharedPrefs.getDataFromSF();
    if (previewWallsPath.length != settings.themeCount) {
      setStatus(newStatus: "Walls are missing in counts...😶‍🌫️😕🤕");
    }
    isLoadingPreviewWallPath = false;
  }
}
