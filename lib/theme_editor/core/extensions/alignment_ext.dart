import 'package:flutter/material.dart';

extension AlignmentX on AlignmentGeometry {
  String get label {
    const map = {
      'Alignment.topLeft':      'Top Left',
      'Alignment.topCenter':    'Top Center',
      'Alignment.topRight':     'Top Right',
      'Alignment.centerLeft':   'Center Left',
      'Alignment.center':       'Center',
      'Alignment.centerRight':  'Center Right',
      'Alignment.bottomLeft':   'Bottom Left',
      'Alignment.bottomCenter': 'Bottom Center',
      'Alignment.bottomRight':  'Bottom Right',
    };
    return map[toString()] ?? 'Center';
  }

  static AlignmentGeometry fromString(String s) {
    const map = {
      'Alignment.topLeft':      Alignment.topLeft,
      'Alignment.topCenter':    Alignment.topCenter,
      'Alignment.topRight':     Alignment.topRight,
      'Alignment.centerLeft':   Alignment.centerLeft,
      'Alignment.center':       Alignment.center,
      'Alignment.centerRight':  Alignment.centerRight,
      'Alignment.bottomLeft':   Alignment.bottomLeft,
      'Alignment.bottomCenter': Alignment.bottomCenter,
      'Alignment.bottomRight':  Alignment.bottomRight,
    };
    return map[s] ?? Alignment.center;
  }
}
