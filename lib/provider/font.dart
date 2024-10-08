import 'package:flutter/material.dart';

import '../api/font_api.dart';
import '../model/font_model.dart';

class FontProvider extends ChangeNotifier {
  bool? isLoading = true;
  String? fontFamily = 'Roboto';
  set setIsLoading(bool val) {
    isLoading = val;
    notifyListeners();
  }

  List<Fonts> fonts = [];

  set setFontFamily(String? newFont) {
    fontFamily = newFont;
    notifyListeners();
  }

  getFontsFromAPI(context) async {
    setIsLoading = true;
    final FontModel model = await FontApi.fetchFontList(context);
    fonts = model.fonts!;
    notifyListeners();
    setIsLoading = false;
  }
}
