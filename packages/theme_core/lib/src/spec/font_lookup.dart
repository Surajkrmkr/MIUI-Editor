import 'dart:io';

import 'package:path/path.dart' as p;

String _key(String s) => s.toLowerCase().replaceAll(RegExp('[^a-z0-9]'), '');

/// A `.ttf` or `.otf` in one of [dirs] named after [family], or null.
///
/// Names match ignoring case, spaces and punctuation, and a `Regular` suffix:
/// "Fira Sans" finds `FiraSans-Regular.ttf`. Directories are searched in order.
String? findFontFile(String family, Iterable<String> dirs) {
  final wanted = _key(family);
  if (wanted.isEmpty) return null;
  for (final dir in dirs) {
    final d = Directory(dir);
    if (!d.existsSync()) continue;
    final files = d.listSync().whereType<File>().toList()
      ..sort((a, b) => a.path.compareTo(b.path));
    for (final f in files) {
      final ext = p.extension(f.path).toLowerCase();
      if (ext != '.ttf' && ext != '.otf') continue;
      var stem = _key(p.basenameWithoutExtension(f.path));
      if (stem != 'regular' && stem.endsWith('regular')) {
        stem = stem.substring(0, stem.length - 'regular'.length);
      }
      if (stem == wanted) return f.path;
    }
  }
  return null;
}
