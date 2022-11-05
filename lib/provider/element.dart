import 'package:flutter/material.dart';

import '../data/element_map_dart.dart';
import '../utils/get_uid.dart';

class ElementProvider extends ChangeNotifier {
  List<ElementWidget> elementList = [];
  double? bgAlpha = 0;

  String? activeId = "0";
  set setActiveWidget(String? id) {
    activeId = id;
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

  void removeElementFromList(String id) {
    elementList.removeWhere(
      (element) => element.id== id,
    );
    if (elementList.isNotEmpty) setActiveWidget = elementList[0].id;
    notifyListeners();
  }

  ElementWidget getElementFromList(String id) {
    return elementList.firstWhere((element) => element.id== id,
        orElse: (() => ElementWidget(
            id: idGenerator(),
            name: "default",
            type: null,
            child: Container())));
  }

  void updateElementPositionInList(String id, double dx, double dy) {
    elementList.firstWhere((element) => element.id== id).dx = dx;
    elementList.firstWhere((element) => element.id== id).dy = dy;
    notifyListeners();
  }

  void updateElementColorInList(String id, Color? color) {
    elementList.firstWhere((element) => element.id== id).color = color;
    notifyListeners();
  }

  void updateElementFontInList(String id, String? font) {
    elementList.firstWhere((element) => element.id== id).font = font;
    notifyListeners();
  }

  void updateElementScaleInList(String id, double? scale) {
    elementList.firstWhere((element) => element.id== id).scale = scale;
    notifyListeners();
  }

  void updateElementAlignInList(String id, AlignmentGeometry? align) {
    elementList.firstWhere((element) => element.id== id).align = align;
    notifyListeners();
  }

  void updateElementAngleInList(String id, double? angle) {
    elementList.firstWhere((element) => element.id== id).angle = angle;
    notifyListeners();
  }

  void updateElementIsShortInList(String id, bool? isShort) {
    elementList.firstWhere((element) => element.id== id).isShort = isShort;
    notifyListeners();
  }
}

class ElementWidget {
  String? id;
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
  bool? isShort;
  ElementWidget(
      {required this.child,
      required this.id,
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
      this.isShort = false});
}
