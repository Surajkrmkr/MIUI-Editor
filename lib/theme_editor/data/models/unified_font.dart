import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/utils/font_utils.dart';
import '../../core/utils/remote_fonts.dart';

enum FontSource {
  api,
  google,
  fontsource,
  fontshare;

  String get label => switch (this) {
        api => 'Custom',
        google => 'Google Fonts',
        fontsource => 'Fontsource',
        fontshare => 'Fontshare',
      };

  bool get isRemoteCatalog => this == fontsource || this == fontshare;
}

class UnifiedFont {
  const UnifiedFont({
    required this.name,
    required this.fontFamily,
    required this.source,
    this.url,
  });

  final String name;
  final String fontFamily;
  final FontSource source;

  /// TTF download URL for catalog sources.
  final String? url;

  /// Key stored in [LockElement.font]. Google fonts are prefixed with `gf:`,
  /// catalog fonts with `rf:` (family + URL).
  String get storageKey => switch (source) {
        FontSource.google => 'gf:$name',
        FontSource.fontsource ||
        FontSource.fontshare =>
          remoteFontKey(fontFamily, url ?? ''),
        FontSource.api => fontFamily,
      };

  TextStyle previewStyle({
    double? fontSize,
    Color? color,
    FontWeight? fontWeight,
  }) {
    if (source.isRemoteCatalog) {
      return fontTextStyle(
        font: storageKey,
        fontSize: fontSize,
        color: color,
        fontWeight: fontWeight,
      );
    }
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
