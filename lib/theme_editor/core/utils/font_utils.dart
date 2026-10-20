import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:theme_raster_flutter/theme_raster_flutter.dart' as raster;
import 'remote_fonts.dart';

export 'package:theme_raster_flutter/theme_raster_flutter.dart'
    show fontTextStyle;

const String gfPrefix = 'gf:';

bool isGoogleFont(String font) => font.startsWith(gfPrefix);

String googleFontName(String font) => font.substring(gfPrefix.length);

// The CLI renderer ships these; the app isn't bundled with them, so it
// would otherwise fall back to the system font and measure text differently.
const _bundledFamilies = {
  'Roboto': 'Roboto',
  'RobotoCondensed': 'Roboto Condensed',
};

/// Makes every lockscreen painter resolve fonts through [appFontTextStyle],
/// which downloads Google and catalog fonts on demand.
void installAppFontResolver() => raster.fontTextStyle = appFontTextStyle;

/// Resolves a stored font string into a [TextStyle].
///
/// API fonts are stored as their fontFamily name directly.
/// Google Fonts are stored with a `gf:` prefix (e.g. `gf:Lato`).
TextStyle appFontTextStyle({
  required String font,
  double? fontSize,
  Color? color,
  FontWeight? fontWeight,
  double? height,
}) {
  final remote = parseRemoteFont(font);
  if (remote != null) {
    // Text relayouts automatically once the engine registers the font.
    RemoteFonts.ensure(remote.family, remote.url);
    return TextStyle(
      fontFamily: remote.family,
      fontSize: fontSize,
      color: color,
      fontWeight: fontWeight,
      height: height,
    );
  }
  if (isGoogleFont(font) || _bundledFamilies.containsKey(font)) {
    try {
      return GoogleFonts.getFont(
        _bundledFamilies[font] ?? googleFontName(font),
        fontSize: fontSize,
        color: color,
        fontWeight: fontWeight,
        height: height,
      );
    } catch (_) {
      return TextStyle(
        fontSize: fontSize,
        color: color,
        fontWeight: fontWeight,
        height: height,
      );
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
