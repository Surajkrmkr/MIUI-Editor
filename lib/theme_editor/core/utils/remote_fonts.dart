import 'package:dynamic_cached_fonts/dynamic_cached_fonts.dart';
import 'package:flutter/foundation.dart';

/// Fonts downloaded from a catalog (Fontsource, Fontshare) are stored as
/// `rf:<family>|<ttf url>` so a saved design can reload them anywhere.
const String rfPrefix = 'rf:';

String remoteFontKey(String family, String url) => '$rfPrefix$family|$url';

bool isRemoteFont(String font) => font.startsWith(rfPrefix);

({String family, String url})? parseRemoteFont(String font) {
  if (!isRemoteFont(font)) return null;
  final body = font.substring(rfPrefix.length);
  final split = body.indexOf('|');
  if (split <= 0 || split == body.length - 1) return null;
  return (family: body.substring(0, split), url: body.substring(split + 1));
}

/// Downloads, disk-caches and registers remote TTF/OTF fonts once per family.
abstract final class RemoteFonts {
  static final Map<String, Future<void>> _loads = {};

  static Future<void> ensure(String family, String url) =>
      _loads.putIfAbsent(family, () async {
        try {
          await DynamicCachedFonts(fontFamily: family, url: url).load();
        } catch (e) {
          // Allow a retry on the next request instead of caching the failure.
          _loads.remove(family);
          debugPrint('Remote font load failed for $family ($url): $e');
        }
      });

  static Future<void> ensureKey(String font) {
    final parsed = parseRemoteFont(font);
    return parsed == null ? Future.value() : ensure(parsed.family, parsed.url);
  }
}
