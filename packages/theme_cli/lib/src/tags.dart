import 'dart:convert';
import 'dart:io';

import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;

/// Most tags a theme may carry.
const maxTags = 6;

/// Folder next to the built themes that receives `<name>.txt`.
const tagsFolderName = '1tags';

/// Where the tag catalog lives inside the Flutter project.
String tagsCatalogPath(String project) =>
    p.join(project, 'assets', 'tags', 'tags.json');

/// The tags the store accepts (`assets/tags/tags.json`), by category.
class TagCatalog {
  TagCatalog(this.categories)
    : _byKey = {
        for (final e in categories.entries)
          for (final t in e.value) t.toLowerCase(): t,
      },
      _categoryOf = {
        for (final e in categories.entries)
          for (final t in e.value) t.toLowerCase(): e.key,
      };

  /// Category name → its tags, in file order.
  final Map<String, List<String>> categories;
  final Map<String, String> _byKey, _categoryOf;

  static TagCatalog load(String path) {
    final json = jsonDecode(File(path).readAsStringSync());
    final data = json is Map ? json['data'] : json;
    if (data is! List) {
      throw FormatException('$path has no "data" list of categories.');
    }
    return TagCatalog({
      for (final c in data)
        if (c is Map && c['name'] is String && c['subTags'] is List)
          c['name'] as String: [
            for (final t in c['subTags'] as List)
              if (t is String) t.trim(),
          ],
    });
  }

  /// The catalog of [project], or null when it has none.
  static TagCatalog? ofProject(String? project) {
    if (project == null) return null;
    final path = tagsCatalogPath(project);
    return File(path).existsSync() ? load(path) : null;
  }

  /// The catalog spelling of [tag], ignoring case; null when unknown.
  String? canonical(String tag) => _byKey[tag.trim().toLowerCase()];

  String? categoryOf(String tag) => _categoryOf[tag.trim().toLowerCase()];

  Iterable<String> get all => _byKey.values;
}

/// Turns tags the caller chose into catalog spellings, at most [maxTags],
/// without duplicates. Throws [FormatException] naming unknown tags.
List<String> normalizeTags(Iterable<String> tags, TagCatalog catalog) {
  final out = <String>[];
  final unknown = <String>[];
  for (final raw in tags) {
    if (raw.trim().isEmpty) continue;
    final t = catalog.canonical(raw);
    if (t == null) {
      unknown.add(raw.trim());
    } else if (!out.contains(t)) {
      out.add(t);
    }
  }
  if (unknown.isNotEmpty) {
    throw FormatException('Not in the tag catalog: ${unknown.join(', ')}.');
  }
  if (out.length > maxTags) {
    throw FormatException('At most $maxTags tags, got ${out.length}.');
  }
  return out;
}

/// What the tags of a theme are picked from.
class TagInput {
  TagInput({
    required this.title,
    this.elementTypes = const [],
    this.lockWallpaper,
  });

  /// Reads a built theme folder: its `theme.spec.json` and lock wallpaper.
  factory TagInput.ofWorkspace(String workspace) {
    final specFile = File(p.join(workspace, 'theme.spec.json'));
    if (!specFile.existsSync()) {
      throw FileSystemException('No theme.spec.json', workspace);
    }
    final spec = jsonDecode(specFile.readAsStringSync());
    return TagInput.ofSpec(
      spec is Map<String, dynamic> ? spec : const {},
      fallbackTitle: p.basename(workspace),
      lockWallpaper: _wallpaperIn(workspace),
    );
  }

  /// Reads a spec; [lockWallpaper] overrides the spec's own wallpaper paths.
  factory TagInput.ofSpec(
    Map<String, dynamic> spec, {
    String? fallbackTitle,
    String? lockWallpaper,
    String? baseDir,
  }) {
    final meta = spec['meta'];
    final output = spec['output'];
    final title =
        (output is Map ? output['name'] as String? : null) ??
        (meta is Map ? meta['title'] as String? : null) ??
        fallbackTitle ??
        '';
    final lock = spec['lockscreen'];
    final elements = lock is Map ? lock['elements'] : null;
    final types = <String>[
      if (elements is List)
        for (final e in elements)
          if (e is Map && e['type'] is String && e['isVisible'] != false)
            e['type'] as String,
    ];
    var wall = lockWallpaper;
    if (wall == null) {
      final w = spec['wallpaper'];
      for (final key in ['lock', 'home']) {
        final v = w is Map ? w[key] : null;
        if (v is! String || v.isEmpty) continue;
        final path = p.isAbsolute(v) || baseDir == null
            ? v
            : p.join(baseDir, v);
        if (File(path).existsSync()) {
          wall = path;
          break;
        }
      }
    }
    return TagInput(
      title: p.basename(title),
      elementTypes: types,
      lockWallpaper: wall,
    );
  }

  final String title;

  /// Types of the visible lockscreen elements.
  final List<String> elementTypes;

  /// The picture behind the lockscreen, when it can be read.
  final String? lockWallpaper;

  static String? _wallpaperIn(String workspace) {
    for (final name in ['default_lock_wallpaper', 'default_wallpaper']) {
      for (final ext in ['jpg', 'jpeg', 'png', 'webp']) {
        final f = File(p.join(workspace, 'wallpaper', '$name.$ext'));
        if (f.existsSync()) return f.path;
      }
    }
    return null;
  }
}

/// Picks up to [maxTags] catalog tags for a theme from its lockscreen: the
/// clock and unlock control it shows, the wallpaper's main colour and tone,
/// and words of its name. Every tag returned is in [catalog].
List<String> suggestTags(TagInput input, TagCatalog catalog) {
  final picked = <String>[];
  void add(String tag) {
    if (picked.length >= maxTags) return;
    final t = catalog.canonical(tag);
    if (t != null && !picked.contains(t)) picked.add(t);
  }

  final types = input.elementTypes.toSet();
  final analog = types.any((t) => t.startsWith('analog'));
  final digital = types.any(
    (t) => const {'hourClock', 'minClock', 'secClock'}.contains(t),
  );
  final slide = types.any(
    (t) => const {'swipeUpUnlock', 'slideToUnlock', 'dragToUnlock'}.contains(t),
  );
  final widget = types.any(
    (t) =>
        t.startsWith('music') ||
        t.startsWith('steps') ||
        const {
          'shortcutSet',
          'calendarGrid',
          'dayStrip',
          'countdownTicker',
          'gaugeSet',
          'batteryLevel',
          'progressBar',
        }.contains(t),
  );

  final look = input.lockWallpaper == null
      ? null
      : _WallpaperLook.read(input.lockWallpaper!);

  // What the name is about matters most, then what the lockscreen shows.
  for (final t in _nameTags(input.title, catalog).take(2)) {
    add(t);
  }
  if (analog) add('Analog clock');
  if (digital || (!analog && types.isNotEmpty)) add('Clock');
  if (slide) add('Slide');
  if (look?.color != null) add(look!.color!);
  if (types.contains('videoWallpaper')) {
    add('Dynamic lock screen');
  } else if (widget) {
    add('Widget');
  }
  add(look?.dark == true ? 'Dark' : 'Simple');
  for (final t in const ['Regular', 'Abstract', 'Cool', 'Simple']) {
    add(t);
  }
  return picked;
}

/// Writes `<dir>/<title>.txt` with [tags] comma separated; returns its path.
String writeTagsFile(String dir, String title, List<String> tags) {
  Directory(dir).createSync(recursive: true);
  final file = File(p.join(dir, '$title.txt'))
    ..writeAsStringSync(tags.join(','));
  return file.path;
}

// ── Name words ───────────────────────────────────────────────────────────────

/// Words of theme names that mean a catalog tag without spelling it.
const _synonyms = <String, List<String>>{
  'crescent': ['Moon'],
  'lunar': ['Moon'],
  'moonlit': ['Moon', 'Night'],
  'celestial': ['Star'],
  'starlit': ['Star', 'Night'],
  'stargazer': ['Star'],
  'cosmic': ['Universe'],
  'galactic': ['Milky Way'],
  'galaxy': ['Milky Way'],
  'orbit': ['Planet'],
  'ocean': ['Sea'],
  'coastal': ['Beach'],
  'tide': ['Sea'],
  'sakura': ['Cherry blossom'],
  'petals': ['Flower'],
  'petal': ['Flower'],
  'bloom': ['Flower'],
  'blossom': ['Flower'],
  'lotus': ['Flower'],
  'ginkgo': ['Leaf'],
  'bonsai': ['Tree'],
  'arctic': ['Ice', 'Winter'],
  'frozen': ['Ice', 'Winter'],
  'crimson': ['Red'],
  'emerald': ['Green'],
  'matcha': ['Green'],
  'turquoise': ['Blue'],
  'ivory': ['White'],
  'golden': ['Gold'],
  'kintsugi': ['Gold'],
  'sunlit': ['Sun'],
  'sunlight': ['Sun'],
  'sunset': ['Sun'],
  'twilight': ['Night'],
  'midnight': ['Night'],
  'summit': ['Mountain'],
  'canyon': ['Valley'],
  'doorway': ['Door'],
  'gateway': ['Door'],
  'archway': ['Door'],
  'portal': ['Door'],
  'spooky': ['Halloween'],
  'vinyl': ['Music'],
  'express': ['Train'],
  'prism': ['Colorful'],
  'prismatic': ['Colorful'],
  'chromatic': ['Colorful'],
  'candle': ['Light'],
  'luminous': ['Light'],
  'cuddles': ['Cute'],
  'geometry': ['Geometric'],
  'rainy': ['Rain'],
  'rainforest': ['Forest', 'Rain'],
  'wishes': ['Star'],
  'dreamer': ['Dream'],
};

/// Tag categories a name word never picks from: features are read from the
/// lockscreen, and the rest are licensed or too easy to hit by accident.
const _nameSkips = {'Features', 'Characters', 'Horoscope', 'Holiday'};

List<String> _nameTags(String title, TagCatalog catalog) {
  final found = <String>[];
  void add(String? t) {
    if (t != null && !found.contains(t)) found.add(t);
  }

  final words = title
      .toLowerCase()
      .replaceAll(RegExp(r"['’]"), '')
      .split(RegExp(r'[^a-z]+'))
      .where((w) => w.length >= 3);
  for (final word in words) {
    final syn = _synonyms[word];
    if (syn != null) {
      for (final s in syn) {
        add(catalog.canonical(s));
      }
      continue;
    }
    String? hit = catalog.canonical(word);
    if (hit == null && word.endsWith('s')) {
      hit = catalog.canonical(word.substring(0, word.length - 1));
    }
    if (hit == null && word.endsWith('es')) {
      hit = catalog.canonical(word.substring(0, word.length - 2));
    }
    if (hit != null && _nameSkips.contains(catalog.categoryOf(hit))) {
      hit = null;
    }
    add(hit);
  }
  return found;
}

// ── Wallpaper ────────────────────────────────────────────────────────────────

class _WallpaperLook {
  _WallpaperLook(this.color, this.dark);

  /// The catalog colour most of the picture is, if one stands out.
  final String? color;
  final bool dark;

  static _WallpaperLook? read(String path) {
    final img.Image? source;
    try {
      source = img.decodeImage(File(path).readAsBytesSync());
    } on Object {
      return null;
    }
    if (source == null) return null;
    final small = source.width > 64
        ? img.copyResize(
            source,
            width: 64,
            interpolation: img.Interpolation.average,
          )
        : source;
    // Pixels count by how vivid they are, so a bright subject outweighs a
    // larger dull or shadowed background.
    final weights = <String, double>{};
    final counts = <String, int>{};
    var luma = 0.0;
    var total = 0;
    var vivid = 0.0;
    for (final px in small) {
      final r = px.r / 255, g = px.g / 255, b = px.b / 255;
      luma += .2126 * r + .7152 * g + .0722 * b;
      total++;
      final name = _colorName(r.toDouble(), g.toDouble(), b.toDouble());
      counts[name] = (counts[name] ?? 0) + 1;
      final mx = [r, g, b].reduce((a, c) => a > c ? a : c).toDouble();
      final mn = [r, g, b].reduce((a, c) => a < c ? a : c).toDouble();
      final sat = mx == 0 ? 0.0 : (mx - mn) / mx;
      final w = sat * sat * mx;
      if (!_neutral.contains(name)) {
        weights[name] = (weights[name] ?? 0) + w;
        vivid += w;
      }
    }
    if (total == 0) return null;
    String? color;
    if (vivid / total >= .04) {
      final top = weights.entries.reduce((a, b) => a.value >= b.value ? a : b);
      if (top.value / vivid >= .3) color = top.key;
    }
    if (color == null) {
      // Hardly any colour: a mostly black, grey or white picture says so.
      final top = counts.entries.reduce((a, b) => a.value >= b.value ? a : b);
      if (_neutral.contains(top.key) && top.value / total >= .5) {
        color = top.key;
      }
    }
    return _WallpaperLook(color, luma / total < .3);
  }

  static const _neutral = {'Black', 'Grey', 'White'};

  static String _colorName(double r, double g, double b) {
    final max = [r, g, b].reduce((a, c) => a > c ? a : c);
    final min = [r, g, b].reduce((a, c) => a < c ? a : c);
    final v = max, d = max - min;
    final s = max == 0 ? 0.0 : d / max;
    if (v < .16) return 'Black';
    if (s < .15) return v > .85 ? 'White' : 'Grey';
    double h;
    if (max == r) {
      h = 60 * (((g - b) / d) % 6);
    } else if (max == g) {
      h = 60 * ((b - r) / d + 2);
    } else {
      h = 60 * ((r - g) / d + 4);
    }
    if (h < 0) h += 360;
    if (h < 12 || h >= 345) return v < .45 ? 'Brown' : 'Red';
    if (h < 40) return v < .55 ? 'Brown' : 'Orange';
    if (h < 50) return v < .55 ? 'Brown' : 'Gold';
    if (h < 68) return 'Yellow';
    if (h < 165) return 'Green';
    if (h < 255) return 'Blue';
    if (h < 295) return 'Purple';
    return 'Pink';
  }
}
