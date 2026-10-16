import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../models/unified_font.dart';

/// Lists free, commercially usable fonts from public catalogs as TTF URLs.
class FontCatalogDataSource {
  static const _timeout = Duration(seconds: 20);

  Future<dynamic> _getJson(String url) async {
    final res = await http.get(Uri.parse(url)).timeout(_timeout);
    if (res.statusCode != 200) {
      throw Exception('Font catalog error ${res.statusCode} ($url)');
    }
    return jsonDecode(res.body);
  }

  /// https://fontsource.org — ~2,100 open-source families (OFL etc.).
  /// Fontsource-only families are listed first; the rest mirror Google Fonts.
  Future<List<UnifiedFont>> fetchFontsource() async {
    final list = await _getJson('https://api.fontsource.org/v1/fonts') as List;
    final fonts = <(bool, UnifiedFont)>[];
    for (final f in list.cast<Map<String, dynamic>>()) {
      if (f['category'] == 'icons') continue;
      final id = f['id'] as String?;
      final family = f['family'] as String?;
      final subsets = (f['subsets'] as List?)?.cast<String>() ?? const [];
      final weights = (f['weights'] as List?)?.cast<num>() ?? const [];
      final styles = (f['styles'] as List?)?.cast<String>() ?? const [];
      if (id == null || family == null || weights.isEmpty || styles.isEmpty) {
        continue;
      }
      final subset = subsets.contains('latin')
          ? 'latin'
          : (f['defSubset'] as String? ??
                (subsets.isEmpty ? 'latin' : subsets.first));
      final weight = weights.contains(400) ? 400 : weights.first.toInt();
      final style = styles.contains('normal') ? 'normal' : styles.first;
      fonts.add((
        f['type'] != 'google',
        UnifiedFont(
          name: family,
          fontFamily: 'fontsource_$id',
          source: FontSource.fontsource,
          url:
              'https://cdn.jsdelivr.net/fontsource/fonts/$id@latest/'
              '$subset-$weight-$style.ttf',
        ),
      ));
    }
    fonts.sort((a, b) {
      if (a.$1 != b.$1) return a.$1 ? -1 : 1;
      return a.$2.name.toLowerCase().compareTo(b.$2.name.toLowerCase());
    });
    return [for (final f in fonts) f.$2];
  }

  /// https://www.fontshare.com — Indian Type Foundry's free-for-commercial-use
  /// families (Satoshi, Clash Display, General Sans, ...).
  Future<List<UnifiedFont>> fetchFontshare() async {
    final body =
        await _getJson('https://api.fontshare.com/v2/fonts')
            as Map<String, dynamic>;
    final fonts = <UnifiedFont>[];
    for (final f
        in (body['fonts'] as List? ?? const []).cast<Map<String, dynamic>>()) {
      final name = f['name'] as String?;
      final slug = f['slug'] as String?;
      final styles = (f['styles'] as List? ?? const [])
          .cast<Map<String, dynamic>>();
      if (name == null || slug == null || styles.isEmpty) continue;
      final upright = styles.where((s) => s['is_italic'] != true).toList();
      final pool = upright.isEmpty ? styles : upright;
      final style = pool.firstWhere(
        (s) => s['default'] == true,
        orElse: () => pool.firstWhere(
          (s) => (s['weight'] as Map?)?['weight'] == 400,
          orElse: () => pool.first,
        ),
      );
      final file = style['file'] as String?;
      if (file == null || file.isEmpty) continue;
      // The CDN serves the raw TTF when `.ttf` is appended to the style path.
      final url = '${file.startsWith('//') ? 'https:$file' : file}.ttf';
      fonts.add(
        UnifiedFont(
          name: name,
          fontFamily: 'fontshare_$slug',
          source: FontSource.fontshare,
          url: url,
        ),
      );
    }
    fonts.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return fonts;
  }
}
