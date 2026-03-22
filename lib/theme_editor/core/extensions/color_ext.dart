import 'package:flutter/material.dart';

extension ColorX on Color {
  String toHex({bool withAlpha = false}) {
    final rr = (r * 255).round().toRadixString(16).padLeft(2, '0');
    final gg = (g * 255).round().toRadixString(16).padLeft(2, '0');
    final bb = (b * 255).round().toRadixString(16).padLeft(2, '0');
    if (withAlpha) {
      final aa = (a * 255).round().toRadixString(16).padLeft(2, '0');
      return '#$aa$rr$gg$bb'.toUpperCase();
    }
    return '#$rr$gg$bb'.toUpperCase();
  }

  String toMamlHex() =>
      '#FF${(r * 255).round().toRadixString(16).padLeft(2, '0')}'
      '${(g * 255).round().toRadixString(16).padLeft(2, '0')}'
      '${(b * 255).round().toRadixString(16).padLeft(2, '0')}'.toUpperCase();

  static Color fromHex(String hex) {
    final clean = hex.replaceAll('#', '');
    return Color(int.parse(clean.length == 6 ? 'FF$clean' : clean, radix: 16));
  }
}
