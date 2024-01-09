import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../functions/theme_path.dart';
import '../functions/windows_utils.dart';
import '../model/tag_model.dart';
import 'directory.dart';

class TagProvider extends ChangeNotifier {
  bool isLoading = true;
  set setIsLoading(bool val) {
    isLoading = val;
    notifyListeners();
  }

  List<Tag>? tags = [];
  List<String> flatTagList = [];
  List<String>? searchedTags = [];
  List<String> appliedTags = [
    "Simple",
    "Abstract",
    "Clock",
    "cool",
    "Regular",
    "Slide"
  ];

  void setTags(List<String> tags) {
    appliedTags = tags;
    notifyListeners();
  }

  void searchTags(String query) {
    if (query.isNotEmpty) {
      searchedTags = flatTagList
          .where((e) =>
              e.toLowerCase().contains(query.toLowerCase()) &&
              e.toLowerCase().startsWith(query.toLowerCase()))
          .toList();
    } else {
      searchedTags!.clear();
    }
    notifyListeners();
  }

  bool isTagSelected(String tag) {
    return appliedTags.contains(tag);
  }

  void addTag(BuildContext context, String tag, String? themeName) {
    if (!appliedTags.contains(tag) && appliedTags.length != 6) {
      appliedTags.add(tag);
      updateTagFile(context, themeName);
      notifyListeners();
    }
  }

  void removeTag(BuildContext context, String tag, String? themeName) {
    appliedTags.remove(tag);
    updateTagFile(context, themeName);
    notifyListeners();
  }

  void updateTagFile(BuildContext context, String? themeName) {
    Provider.of<DirectoryProvider>(context, listen: false).createTagDirectory(
        context: context, saveFile: true, themeName: themeName);
  }

  void getTagsFromFile(BuildContext context) async {
    final tagPath = CurrentTheme.getTagDirectory(context);
    final tagDir =
        await Directory(platformBasedPath(tagPath)).create(recursive: true);
    final String tagFilePath =
        "${tagDir.path}${CurrentTheme.getCurrentThemeName(context)!}.txt";
    if (await File(tagFilePath).exists()) {
      final String tagsFromFile = await File(tagFilePath).readAsString();
      appliedTags = tagsFromFile.split(",");
      notifyListeners();
    }
  }

  Future<void> getTagsFromJson() async {
    setIsLoading = true;
    final String data = await rootBundle.loadString('assets/tags/tags.json');
    final jsonData = await json.decode(data);
    final MIUITags miuiTags = MIUITags.fromJson(jsonData);
    tags = miuiTags.tag;
    for (var e in tags!) {
      flatTagList.addAll(e.subTags!);
    }
    notifyListeners();
    setIsLoading = false;
  }
}
