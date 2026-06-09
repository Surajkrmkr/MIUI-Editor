import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

enum FontSource { api, google }

class UnifiedFont {
  const UnifiedFont({
    required this.name,
    required this.fontFamily,
    required this.source,
  });

  final String name;
  final String fontFamily;
  final FontSource source;

  /// Key stored in [LockElement.font]. Google fonts are prefixed with `gf:`.
  String get storageKey => source == FontSource.google ? 'gf:$name' : fontFamily;

  TextStyle previewStyle({
    double? fontSize,
    Color? color,
    FontWeight? fontWeight,
  }) {
    if (source == FontSource.google) {
      try {
        return GoogleFonts.getFont(
          name,
          fontSize: fontSize,
          color: color,
          fontWeight: fontWeight,
        );
      } catch (_) {
        return TextStyle(fontSize: fontSize, color: color, fontWeight: fontWeight);
      }
    }
    return TextStyle(
      fontFamily: fontFamily,
      fontSize: fontSize,
      color: color,
      fontWeight: fontWeight,
    );
  }
}
