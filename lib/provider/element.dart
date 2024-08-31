// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

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

  void addAllElements(List<ElementWidget> elements) {
    elementList = elements;
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

  @override
  String toString() {
    return 'ElementWidget(name: $name, dx: $dx, dy: $dy, scale: $scale, height: $height, width: $width, radius: $radius, borderWidth: $borderWidth, borderColor: $borderColor, type: $type, child: $child, color: $color, colorSecondary: $colorSecondary, gradientType: $gradientType, gradStartAlign: $gradStartAlign, gradEndAlign: $gradEndAlign, font: $font, align: $align, angle: $angle, path: $path, text: $text, fontSize: $fontSize, fontWeight: $fontWeight, isShort: $isShort, showGuideLines: $showGuideLines)';
  }

  // JSON serialization method
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'dx': dx,
      'dy': dy,
      'scale': scale,
      'height': height,
      'width': width,
      'radius': radius,
      'borderWidth': borderWidth,
      'borderColor': (borderColor ?? Colors.white).value,
      'type': type!.name,
      'child': child.toString(),
      'color': (color ?? Colors.white).value,
      'colorSecondary': (colorSecondary ?? Colors.white).value,
      'gradientType': gradientType.toString().split('.').last,
      'gradStartAlign': (gradStartAlign ?? Alignment.center).toString(),
      'gradEndAlign': (gradEndAlign ?? Alignment.center).toString(),
      'font': font,
      'align': (align ?? Alignment.center).toString(),
      'angle': angle,
      'path': path ?? "",
      'text': text,
      'fontSize': fontSize,
      'fontWeight': fontWeight.toString(),
      'isShort': isShort,
      'showGuideLines': showGuideLines,
    };
  }

  // JSON deserialization method
  factory ElementWidget.fromJson(Map<String, dynamic> json) {
    return ElementWidget(
      name: json['name'],
      dx: json['dx'],
      dy: json['dy'],
      scale: json['scale'],
      height: json['height'],
      width: json['width'],
      radius: json['radius'],
      borderWidth: json['borderWidth'],
      borderColor: Color(json['borderColor']),
      type: _stringToElementType(json['type']),
      child: buildElementWidget(json["child"]),
      color: Color(json['color']),
      colorSecondary: Color(json['colorSecondary']),
      gradientType: _stringToGradientType(json['gradientType']),
      gradStartAlign: _stringToAlignment(json['gradStartAlign']),
      gradEndAlign: _stringToAlignment(json['gradEndAlign']),
      font: json['font'],
      align: _stringToAlignment(json['align']),
      angle: json['angle'],
      path: json['path'],
      text: json['text'],
      fontSize: json['fontSize'],
      fontWeight: _stringToFontWeight(json['fontWeight']),
      isShort: json['isShort'],
      showGuideLines: json['showGuideLines'],
    );
  }

  // Helper method to convert a string to ElementType
  static ElementType _stringToElementType(String type) {
    return ElementType.values
        .firstWhere((e) => e.toString().split('.').last == type);
  }

  // Helper method to convert a string to GradientType
  static GradientType _stringToGradientType(String gradientType) {
    return GradientType.values
        .firstWhere((e) => e.toString().split('.').last == gradientType);
  }

  // Helper method to convert a string to Alignment
  static Alignment _stringToAlignment(String alignment) {
    switch (alignment) {
      case 'Alignment.centerLeft':
        return Alignment.centerLeft;
      case 'Alignment.centerRight':
        return Alignment.centerRight;
      case 'Alignment.center':
        return Alignment.center;
      case 'Alignment.topLeft':
        return Alignment.topLeft;
      case 'Alignment.topRight':
        return Alignment.topRight;
      case 'Alignment.topCenter':
        return Alignment.topCenter;
      case 'Alignment.bottomLeft':
        return Alignment.bottomLeft;
      case 'Alignment.bottomRight':
        return Alignment.bottomRight;
      case 'Alignment.bottomCenter':
        return Alignment.bottomCenter;
      default:
        return Alignment.center; // Fallback alignment
    }
  }

  // Helper method to convert a string to FontWeight
  static FontWeight _stringToFontWeight(String fontWeight) {
    switch (fontWeight) {
      case 'FontWeight.w100':
        return FontWeight.w100;
      case 'FontWeight.w200':
        return FontWeight.w200;
      case 'FontWeight.w300':
        return FontWeight.w300;
      case 'FontWeight.w400':
        return FontWeight.w400;
      case 'FontWeight.w500':
        return FontWeight.w500;
      case 'FontWeight.w600':
        return FontWeight.w600;
      case 'FontWeight.w700':
        return FontWeight.w700;
      case 'FontWeight.w800':
        return FontWeight.w800;
      case 'FontWeight.w900':
        return FontWeight.w900;
      default:
        return FontWeight.normal; // Fallback weight
    }
  }

  static Widget buildElementWidget(String elementName) {
    return elementWidgetMap[ElementType.values.firstWhere(
      (element) => element.name.toLowerCase() == elementName.toLowerCase(),
      orElse: () => ElementType.swipeUpUnlock,
    )]!["widget"];
  }
}

List<Map<String, dynamic>> elementWidgetToMap(List<ElementWidget> elements) {
  List<Map<String, dynamic>> jsonElements =
      elements.map((element) => element.toJson()).toList();
  return jsonElements;
}

enum GradientType {
  linear,
  radial,
  sweep,
}
