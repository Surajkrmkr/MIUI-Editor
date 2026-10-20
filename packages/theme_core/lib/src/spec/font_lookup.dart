import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

String _key(String s) => s.toLowerCase().replaceAll(RegExp('[^a-z0-9]'), '');

/// A font a fonts folder offers: the family name to put in an element's
/// `font`, and its file.
typedef FontFamilyFile = ({String family, String path});

/// The fonts in [dirs], one per family, in folder order.
///
/// A `fonts.json` catalog (`{"fonts": [{"name", "url"}]}`, as the editor's
/// font API serves) in a folder or its parent names the files; other files
/// are named after their file name.
List<FontFamilyFile> listFontFamilies(Iterable<String> dirs) {
  final seen = <String>{};
  final out = <FontFamilyFile>[];
  for (final dir in dirs) {
    final d = Directory(dir);
    if (!d.existsSync()) continue;
    final named = {for (final e in _catalog(dir).entries) e.value: e.key};
    final files = d.listSync().whereType<File>().where(_isFont).toList()
      ..sort((a, b) => a.path.compareTo(b.path));
    for (final f in files) {
      final family = named[p.normalize(f.path)] ?? _stemFamily(f.path);
      if (seen.add(_key(family))) out.add((family: family, path: f.path));
    }
  }
  return out;
}

/// A `.ttf` or `.otf` in one of [dirs] named after [family], or null.
///
/// Names match ignoring case, spaces and punctuation, and a `Regular` suffix:
/// "Fira Sans" finds `FiraSans-Regular.ttf`. A `fonts.json` catalog maps
/// names that differ from the file ("GoBold" -> `Gobold High Bold.otf`).
/// Directories are searched in order.
String? findFontFile(String family, Iterable<String> dirs) {
  final wanted = _key(family);
  if (wanted.isEmpty) return null;
  for (final dir in dirs) {
    final d = Directory(dir);
    if (!d.existsSync()) continue;
    final files = d.listSync().whereType<File>().where(_isFont).toList()
      ..sort((a, b) => a.path.compareTo(b.path));
    for (final f in files) {
      if (_key(_stemFamily(f.path)) == wanted) return f.path;
    }
    for (final e in _catalog(dir).entries) {
      if (_key(e.key) == wanted && File(e.value).existsSync()) return e.value;
    }
  }
  return null;
}

bool _isFont(File f) {
  final ext = p.extension(f.path).toLowerCase();
  return ext == '.ttf' || ext == '.otf';
}

String _stemFamily(String path) {
  final stem = p.basenameWithoutExtension(path);
  final m = RegExp(
    r'^(.+?)[-_ ]?regular$',
    caseSensitive: false,
  ).firstMatch(stem);
  return m == null ? stem : m.group(1)!;
}

/// Catalog family name -> font file path in [dir], from `fonts.json`.
Map<String, String> _catalog(String dir) {
  for (final candidate in [
    p.join(dir, 'fonts.json'),
    p.join(p.dirname(dir), 'fonts.json'),
  ]) {
    final file = File(candidate);
    if (!file.existsSync()) continue;
    try {
      final fonts = (jsonDecode(file.readAsStringSync()) as Map)['fonts'];
      if (fonts is! List) continue;
      return {
        for (final f in fonts)
          if (f is Map && f['name'] is String && f['url'] is String)
            f['name'] as String: p.normalize(
              p.join(
                dir,
                Uri.decodeComponent(
                  Uri.parse(f['url'] as String).pathSegments.last,
                ),
              ),
            ),
      };
    } on FormatException {
      continue;
    }
  }
  return const {};
}
