import 'package:flutter/material.dart';

class IconProvider extends ChangeNotifier {
  double? margin = 4;

  set setMargin(double m) {
    margin = m;
    notifyListeners();
  }

  double? padding = 9;

  set setPadding(double p) {
    padding = p;
    notifyListeners();
  }

  double? radius = 10;

  set setRadius(double r) {
    radius = r;
    notifyListeners();
  }

  Color? bgColor = Colors.pinkAccent;

  set setBgColor(Color c) {
    bgColor = c;
    notifyListeners();
  }

  Color? iconColor = Colors.white;

  set setIconColor(Color c) {
    iconColor = c;
    notifyListeners();
  }

  Color? borderColor = Colors.white.withOpacity(0.3);

  set setBorderColor(Color c) {
    borderColor = c;
    notifyListeners();
  }

  double? borderWidth = 2;

  set setBorderWidth(double r) {
    borderWidth = r;
    notifyListeners();
  }
}
