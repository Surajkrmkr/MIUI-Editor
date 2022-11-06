import 'package:flutter/material.dart';

import '../../../constants.dart';
import '../../../provider/element.dart';

String dateTimeTextXml({required ElementWidget ele}) {
  final String text = (ele.text!);
  String? isBold;

  switch (ele.fontWeight) {
    case FontWeight.bold:
      isBold = "true";
      break;
    default:
      isBold = "false";
  }

  final String color = ele.color.toString().split("x").last.replaceAll(")", '');

  String dx = (ele.dx! * MIUIConstants.ratio).toStringAsFixed(2);
  final String dy = (ele.dy! * MIUIConstants.ratio).toStringAsFixed(2);
  final String angle = (360 - ele.angle!).toStringAsFixed(2);
  final String fontSize =
      (ele.fontSize! * MIUIConstants.ratio).toStringAsFixed(2);
  String? align;
  if (ele.align == Alignment.centerLeft) {
    align = "left";
    dx = "$dx-#sw/2";
  } else if (ele.align == Alignment.centerRight) {
    align = "right";
    dx = "$dx+#sw/2";
  } else {
    align = "center";
  }
  return '''
  <DateTime angle="$angle" x="#sw/2+$dx" y="#sh/2+$dy" align="$align" alignV="center" size="$fontSize" color="#$color" formatExp="'$text'" bold="$isBold"/>
''';
}



String normalTextXml({required ElementWidget ele}) {
  final String text = (ele.text!);
  String? isBold;

  switch (ele.fontWeight) {
    case FontWeight.bold:
      isBold = "true";
      break;
    default:
      isBold = "false";
  }

  final String color = ele.color.toString().split("x").last.replaceAll(")", '');

  String dx = (ele.dx! * MIUIConstants.ratio).toStringAsFixed(2);
  final String dy = (ele.dy! * MIUIConstants.ratio).toStringAsFixed(2);
  final String angle = (360 - ele.angle!).toStringAsFixed(2);
  final String fontSize =
      (ele.fontSize! * MIUIConstants.ratio).toStringAsFixed(2);
  String? align;
  if (ele.align == Alignment.centerLeft) {
    align = "left";
    dx = "$dx-#sw/2";
  } else if (ele.align == Alignment.centerRight) {
    align = "right";
    dx = "$dx+#sw/2";
  } else {
    align = "center";
  }
  return '''
  <Text angle="$angle" x="#sw/2+$dx" y="#sh/2+$dy" align="$align" alignV="center" size="$fontSize" color="#$color" textExp="$text" bold="$isBold"/>
''';
}