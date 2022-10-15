import 'package:flutter/material.dart';

import '../data/element_map_dart.dart';

class ElementProvider extends ChangeNotifier {
  List<ElementWidget> elementList = [];

  ElementType? activeType;
  set setActiveType(ElementType? type) {
    activeType = type;
    notifyListeners();
  }

  void addElementInList(ElementWidget ele) {
    if (getElementFromList(ele.type!).type == null) {
      elementList.add(ele);
    } else {
      elementList.remove(ele);
      if (elementList.isEmpty) {
        setActiveType = null;
      }
    }
    notifyListeners();
  }

  void removeElementFromList(ElementType type) {
    elementList.removeWhere(
      (element) => element.type == type,
    );
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
      this.angle = 0});
}
