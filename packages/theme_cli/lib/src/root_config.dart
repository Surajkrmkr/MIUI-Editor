import 'dart:io';

import 'package:path/path.dart' as p;

final _segment = RegExp(r'^[A-Za-z0-9_-]+$');

/// A week or wallpaper-folder name that is safe to use as a path segment.
bool isSafeSegment(String s) => _segment.hasMatch(s);

/// The folder holding a designer's work, laid out like the desktop editor
/// expects: `Wall/<folder>/` wallpapers, `THEMES/Week<n>/` results,
/// `Sample2/lockscreen/advance/` default lockscreen images and `Preset/`.
class ThemeRoot {
  ThemeRoot(String path) : path = p.normalize(path);

  final String path;

  String get wallDir => p.join(path, 'Wall');
  String get themesDir => p.join(path, 'THEMES');
  String get assetsDir => p.join(path, 'Sample2', 'lockscreen', 'advance');
  String get presetsDir => p.join(path, 'Preset');

  /// Where the desktop editor saves the designer's own widget style sets.
  String get widgetStylesDir => p.join(path, 'WidgetStyles');

  /// Where the themes of [week] go, e.g. `THEMES/Week3`.
  String weekDir(String week) {
    if (!isSafeSegment(week)) {
      throw ArgumentError.value(week, 'week', 'Use letters, digits, _ or -.');
    }
    return p.join(themesDir, 'Week$week');
  }

  /// The wallpapers of [folder], e.g. `Wall/2`.
  String wallFolder(String folder) {
    if (!isSafeSegment(folder)) {
      throw ArgumentError.value(
        folder,
        'folder',
        'Use letters, digits, _ or -.',
      );
    }
    return p.join(wallDir, folder);
  }

  /// Fills in what a decoded spec leaves out, changing [spec] in place:
  ///
  /// - a lockscreen with elements but no `assetsDir` gets [assetsDir];
  /// - a relative wallpaper that isn't next to the spec is looked up in
  ///   `Wall/<workspace.folder>/`, then in `Wall/`.
  Map<String, dynamic> prepare(Map<String, dynamic> spec, String baseDir) {
    final workspace = spec['workspace'];
    final folder = workspace is Map ? '${workspace['folder'] ?? ''}' : '';

    final wallpaper = spec['wallpaper'];
    if (wallpaper is Map) {
      for (final key in ['home', 'lock']) {
        final v = wallpaper[key];
        if (v is! String || v.isEmpty || p.isAbsolute(v)) continue;
        if (File(p.join(baseDir, v)).existsSync()) continue;
        final found = [
          if (isSafeSegment(folder)) p.join(wallFolder(folder), v),
          p.join(wallDir, v),
        ].where((f) => File(f).existsSync()).firstOrNull;
        if (found != null) wallpaper[key] = found;
      }
    }

    final lockscreen = spec['lockscreen'];
    if (lockscreen is Map) {
      final dir = lockscreen['assetsDir'];
      final elements = lockscreen['elements'];
      if ((dir == null || dir == '') &&
          elements is List &&
          elements.isNotEmpty &&
          Directory(assetsDir).existsSync()) {
        lockscreen['assetsDir'] = assetsDir;
      }
    }
    return spec;
  }
}

/// What to apply to every spec before it is checked and built: [week] and
/// [folder] as its workspace, then [root]'s defaults. Null when there is
/// nothing to apply.
void Function(Map<String, dynamic> spec, String baseDir)? specPreparer({
  ThemeRoot? root,
  String? week,
  String? folder,
}) {
  if (root == null && week == null && folder == null) return null;
  return (spec, baseDir) {
    if (week != null || folder != null) {
      final workspace = spec['workspace'];
      final merged = workspace is Map
          ? Map<String, dynamic>.from(workspace)
          : <String, dynamic>{};
      if (week != null) merged['week'] = week;
      if (folder != null) merged['folder'] = folder;
      spec['workspace'] = merged;
    }
    root?.prepare(spec, baseDir);
  };
}
