import 'package:flutter/material.dart';
import 'package:theme_core/theme_core.dart' show FontRef;

typedef FontTextStyleBuilder =
    TextStyle Function({
      required String font,
      double? fontSize,
      Color? color,
      FontWeight? fontWeight,
      double? height,
    });

/// Turns an element's `font` string into a [TextStyle]; every lockscreen
/// painter calls this.
///
/// The default uses the font's family name and expects that family to be
/// registered with the engine already (a headless build loads the spec's font
/// files). The app replaces it with a resolver that downloads Google and
/// catalog fonts on demand.
FontTextStyleBuilder fontTextStyle = defaultFontTextStyle;

TextStyle defaultFontTextStyle({
  required String font,
  double? fontSize,
  Color? color,
  FontWeight? fontWeight,
  double? height,
}) => TextStyle(
  fontFamily: FontRef.parse(font).family,
  fontSize: fontSize,
  color: color,
  fontWeight: fontWeight,
  height: height,
);
