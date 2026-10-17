import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:miui_icon_generator/theme_editor/core/extensions/alignment_ext.dart';
import 'package:miui_icon_generator/theme_editor/core/extensions/color_ext.dart';
import 'package:miui_icon_generator/theme_editor/core/extensions/core_value_adapters.dart';

/// The hex formatting these extensions had before delegating to theme_core.
String _legacyHex(Color c, {bool withAlpha = false}) {
  String h(double v) => (v * 255).round().toRadixString(16).padLeft(2, '0');
  final rgb = '${h(c.r)}${h(c.g)}${h(c.b)}';
  return '#${withAlpha ? h(c.a) : ''}$rgb'.toUpperCase();
}

void main() {
  test('ColorX hex output is unchanged for every channel value', () {
    for (var v = 0; v < 256; v += 5) {
      for (final argb in [
        0xFF000000 | v << 16 | (255 - v) << 8 | v,
        v << 24 | 0x336699,
      ]) {
        final c = Color(argb);
        expect(c.toHex(), _legacyHex(c), reason: '$argb');
        expect(c.toHex(withAlpha: true), _legacyHex(c, withAlpha: true));
        expect(c.toMamlHex(), '#FF${_legacyHex(c).substring(1)}');
      }
    }
  });

  test('Color <-> Rgba round-trips and luminance agrees with Flutter', () {
    for (final c in const [
      Color(0xFF3D7BFF),
      Color(0x80FFC300),
      Colors.black,
      Colors.white,
    ]) {
      final rgba = c.toRgba();
      expect(rgba.toColor(), c);
      expect(rgba.luminance, closeTo(c.computeLuminance(), 1e-3));
    }
  });

  test('alignment adapters and legacy parsing match Flutter', () {
    for (final a in const [
      Alignment.topLeft,
      Alignment.center,
      Alignment.bottomRight,
      Alignment.centerLeft,
    ]) {
      expect(a.toAlignment2().toAlignment(), a);
      expect(AlignmentX.fromString(a.toString()), a);
      expect(a.toAlignment2().toLegacyString(), a.toString());
    }
    expect(AlignmentX.fromString('garbage'), Alignment.center);
    expect(const Alignment(0.3, 0.3).toAlignment2().x, 0.3);
  });
}
