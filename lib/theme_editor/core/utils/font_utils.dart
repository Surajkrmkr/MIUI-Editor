import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

const String gfPrefix = 'gf:';

bool isGoogleFont(String font) => font.startsWith(gfPrefix);

String googleFontName(String font) => font.substring(gfPrefix.length);

/// Resolves a stored font string into a [TextStyle].
///
/// API fonts are stored as their fontFamily name directly.
/// Google Fonts are stored with a `gf:` prefix (e.g. `gf:Lato`).
TextStyle fontTextStyle({
  required String font,
  double? fontSize,
  Color? color,
  FontWeight? fontWeight,
  double? height,
}) {
  if (isGoogleFont(font)) {
    try {
      return GoogleFonts.getFont(
        googleFontName(font),
        fontSize: fontSize,
        color: color,
        fontWeight: fontWeight,
        height: height,
      );
    } catch (_) {
      return TextStyle(fontSize: fontSize, color: color, fontWeight: fontWeight, height: height);
    }
  }
  return TextStyle(
    fontFamily: font,
    fontSize: fontSize,
    color: color,
    fontWeight: fontWeight,
    height: height,
  );
}
