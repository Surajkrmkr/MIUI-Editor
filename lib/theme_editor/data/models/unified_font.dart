import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/utils/font_utils.dart';
import '../../core/utils/remote_fonts.dart';

enum FontSource {
  frequent,
  api,
  google,
  fontsource,
  fontshare;

  String get label => switch (this) {
    frequent => 'Frequent',
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
    FontSource.fontshare => remoteFontKey(fontFamily, url ?? ''),
    FontSource.api || FontSource.frequent => fontFamily,
  };

  factory UnifiedFont.fromStorageKey(String key) {
    final remote = parseRemoteFont(key);
    if (remote != null) {
      return UnifiedFont(
        name: remote.family,
        fontFamily: remote.family,
        source: Uri.tryParse(remote.url)?.host.endsWith('fontshare.com') == true
            ? FontSource.fontshare
            : FontSource.fontsource,
        url: remote.url,
      );
    }
    if (key.startsWith('gf:')) {
      final name = key.substring(3);
      return UnifiedFont(
        name: name,
        fontFamily: name,
        source: FontSource.google,
      );
    }
    return UnifiedFont(name: key, fontFamily: key, source: FontSource.api);
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'fontFamily': fontFamily,
    'source': source.name,
    'url': url,
  };

  factory UnifiedFont.fromJson(Map<String, dynamic> json) => UnifiedFont(
    name: json['name'] as String,
    fontFamily: json['fontFamily'] as String,
    source: FontSource.values.byName(json['source'] as String),
    url: json['url'] as String?,
  );

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
        return TextStyle(
          fontSize: fontSize,
          color: color,
          fontWeight: fontWeight,
        );
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
