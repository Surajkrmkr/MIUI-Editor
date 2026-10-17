import 'package:flutter/material.dart';
import 'package:theme_core/theme_core.dart';
import '../adapters.dart';

extension AlignmentX on AlignmentGeometry {
  String get label {
    const map = {
      'Alignment.topLeft': 'Top Left',
      'Alignment.topCenter': 'Top Center',
      'Alignment.topRight': 'Top Right',
      'Alignment.centerLeft': 'Center Left',
      'Alignment.center': 'Center',
      'Alignment.centerRight': 'Center Right',
      'Alignment.bottomLeft': 'Bottom Left',
      'Alignment.bottomCenter': 'Bottom Center',
      'Alignment.bottomRight': 'Bottom Right',
    };
    return map[toString()] ?? 'Center';
  }

  static AlignmentGeometry fromString(String s) =>
      (Alignment2.tryParse(s) ?? Alignment2.center).toAlignment();
}
