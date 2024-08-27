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

  void updateElementSecondaryColorInList(ElementType type, Color? color) {
    elementList.firstWhere((element) => element.type == type).colorSecondary =
        color;
    notifyListeners();
  }

  void updateElementGradStartAlignInList(
      ElementType type, AlignmentGeometry? align) {
    elementList.firstWhere((element) => element.type == type).gradStartAlign =
        align;
    notifyListeners();
  }

  void updateElementGradEndAlignInList(
      ElementType type, AlignmentGeometry? align) {
    elementList.firstWhere((element) => element.type == type).gradEndAlign =
        align;
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

  void updateElementHeightInList(ElementType type, double? height) {
    elementList.firstWhere((element) => element.type == type).height = height;
    notifyListeners();
  }

  void updateElementWidthInList(ElementType type, double? width) {
    elementList.firstWhere((element) => element.type == type).width = width;
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

  void updateElementRadiusInList(ElementType type, double? radius) {
    elementList.firstWhere((element) => element.type == type).radius = radius;
    notifyListeners();
  }

  void updateElementBorderWidthInList(ElementType type, double? width) {
    elementList.firstWhere((element) => element.type == type).borderWidth =
        width;
    notifyListeners();
  }

  void updateElementBorderColorInList(ElementType type, Color? color) {
    elementList.firstWhere((element) => element.type == type).borderColor =
        color;
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

  void updateElementShowGuideLinesInList(
      ElementType type, bool? showGuideLines) {
    elementList.firstWhere((element) => element.type == type).showGuideLines =
        showGuideLines;
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
  double? radius;
  double? borderWidth;
  Color? borderColor;
  ElementType? type;
  Widget? child;
  Color? color;
  Color? colorSecondary;
  GradientType? gradientType;
  AlignmentGeometry? gradStartAlign;
  AlignmentGeometry? gradEndAlign;
  String? font;
  AlignmentGeometry? align;
  double? angle;
  String? path;
  String? text;
  double? fontSize;
  FontWeight? fontWeight;
  bool? isShort;
  bool? showGuideLines;
  ElementWidget(
      {required this.child,
      this.dx = 0,
      this.dy = 0,
      this.height = 200,
      required this.name,
      this.scale = 1,
      this.radius = 10,
      this.borderWidth = 0,
      this.borderColor = Colors.white,
      required this.type,
      this.width = 200,
      this.font = 'Roboto',
      this.color = Colors.white,
      this.colorSecondary = Colors.white,
      this.gradientType = GradientType.linear,
      this.gradStartAlign = Alignment.centerLeft,
      this.gradEndAlign = Alignment.centerRight,
      this.align = Alignment.center,
      this.angle = 0,
      this.path = "",
      this.fontWeight = FontWeight.normal,
      this.text = "Text",
      this.fontSize = 20,
      this.isShort = false,
      this.showGuideLines = false});
}

enum GradientType {
  linear,
  radial,
  sweep,
}
