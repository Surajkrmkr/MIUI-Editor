import 'package:flutter/material.dart';

import '../api/pixabay_api.dart';
import '../model/pixabay_wall_model.dart';

class PickWallProvider extends ChangeNotifier {
  bool? isLoading = true;

  String search = "";
  PixabayImageType imageType = PixabayImageType.illustration;

  set setIsLoading(bool val) {
    isLoading = val;
    notifyListeners();
  }

  set setSearch(String val) {
    search = val;
    notifyListeners();
  }

  List<PixabayWall> walls = [];

  set setImageType(PixabayImageType newImageType) {
    imageType = newImageType;
    notifyListeners();
  }

  getWallsFromAPI(int page) async {
    setIsLoading = true;
    final PixabayWallModel model =
        await PixabayApi.fetchList(search, imageType.name, page);
    walls = model.walls ?? [];
    notifyListeners();
    setIsLoading = false;
  }
}
