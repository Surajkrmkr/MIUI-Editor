import 'package:flutter/material.dart';
import 'package:theme_core/theme_core.dart';
import 'core_value_adapters.dart';

extension ColorX on Color {
  String toHex({bool withAlpha = false}) =>
      toRgba().toHex(withAlpha: withAlpha);

  String toMamlHex() => toRgba().toMamlHex();

  static Color fromHex(String hex) => Rgba.fromHex(hex).toColor();
}
