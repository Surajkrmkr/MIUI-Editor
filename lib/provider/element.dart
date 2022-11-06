import 'package:flutter/material.dart';

import '../data/element_map_dart.dart';

class ElementProvider extends ChangeNotifier {
  List<ElementWidget> elementList = [];
  double? bgAlpha = 0;

  ElementType? activeType = ElementType.swipeUpUnlock;
  set setActiveType(ElementType? type) {
    activeType = type;
    notifyListeners();
  }

  set setBgAlpha(double? alpha) {
    bgAlpha = alpha;
    notifyListeners();
  }

  void addElementInList(ElementWidget ele) {
    elementList.add(ele);
    notifyListeners();
  }

  void removeElementFromList(ElementType type) {
    elementList.removeWhere(
      (element) => element.type == type,
    );
    if (elementList.isNotEmpty) setActiveType = elementList[0].type;
    notifyListeners();
  }

  ElementWidget getElementFromList(ElementType type) {
    return elementList.firstWhere((element) => element.type == type,
        orElse: (() =>
            ElementWidget(name: "default", type: null, child: Container())));
  }

  void updateElementPositionInList(ElementType type, double dx, double dy) {
    elementList.firstWhere((element) => element.type == type).dx = dx;
    elementList.firstWhere((element) => element.type == type).dy = dy;
    notifyListeners();
  }

  void updateElementColorInList(ElementType type, Color? color) {
    elementList.firstWhere((element) => element.type == type).color = color;
    notifyListeners();
  }

  void updateElementFontInList(ElementType type, String? font) {
    elementList.firstWhere((element) => element.type == type).font = font;
    notifyListeners();
  }

  void updateElementScaleInList(ElementType type, double? scale) {
    elementList.firstWhere((element) => element.type == type).scale = scale;
    notifyListeners();
  }

  void updateElementAlignInList(ElementType type, AlignmentGeometry? align) {
    elementList.firstWhere((element) => element.type == type).align = align;
    notifyListeners();
  }

  void updateElementAngleInList(ElementType type, double? angle) {
    elementList.firstWhere((element) => element.type == type).angle = angle;
    notifyListeners();
  }

  void updateElementTextInList(ElementType type, String? text) {
    elementList.firstWhere((element) => element.type == type).text = text;
    notifyListeners();
  }

  void updateElementFontSizeInList(ElementType type, double? fontSize) {
    elementList.firstWhere((element) => element.type == type).fontSize =
        fontSize;
    notifyListeners();
  }

  void updateElementFontWeightInList(ElementType type, FontWeight? fontWeight) {
    elementList.firstWhere((element) => element.type == type).fontWeight =
        fontWeight;
    notifyListeners();
  }

  void updateElementIsShortInList(ElementType type, bool? isShort) {
    elementList.firstWhere((element) => element.type == type).isShort = isShort;
    notifyListeners();
  }
}

class ElementWidget {
  String? name;
  double? dx;
  double? dy;
  double? scale;
  double? height;
  double? width;
  ElementType? type;
  Widget? child;
  Color? color;
  String? font;
  AlignmentGeometry? align;
  double? angle;
  String? path;
  String? text;
  double? fontSize;
  FontWeight? fontWeight;
  bool? isShort;
  ElementWidget(
      {required this.child,
      this.dx = 0,
      this.dy = 0,
      this.height = 200,
      required this.name,
      this.scale = 1,
      required this.type,
      this.width = 200,
      this.font = 'Roboto',
      this.color = Colors.white,
      this.align = Alignment.center,
      this.angle = 0,
      this.path = "",
      this.fontWeight = FontWeight.normal,
      this.text = "Text",
      this.fontSize = 20,
      this.isShort = false});
}
