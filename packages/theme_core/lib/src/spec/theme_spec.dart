import '../icons/control_center_template.dart';
import '../icons/icon_effect.dart';
import '../icons/icon_shape.dart';
import '../icons/icon_style.dart';
import '../icons/icon_texture.dart';
import '../lockscreen/element_enums.dart';
import '../lockscreen/lock_element_spec.dart';
import '../values/alignment2.dart';
import '../values/rgba.dart';
import 'font_ref.dart';
import 'json_reader.dart';
import 'spec_issue.dart';

String _hex(Rgba c) => c.toHex(withAlpha: c.a != 0xFF);

/// Thrown by [ThemeSpec.fromJson] when the JSON has errors.
class SpecFormatException implements Exception {
  SpecFormatException(this.issues);

  final List<SpecIssue> issues;

  @override
  String toString() =>
      'Invalid theme spec:\n${issues.where((i) => i.severity == IssueSeverity.error).join('\n')}';
}

class SpecParseResult {
  const SpecParseResult(this.spec, this.issues);

  /// Null when any error was found.
  final ThemeSpec? spec;
  final List<SpecIssue> issues;

  bool get ok => spec != null;
}

class MetaSpec {
  const MetaSpec({
    required this.title,
    this.designer = '',
    this.authorTag = '',
    this.version = '1.0',
    this.uiVersion = 17,
    this.profile,
  });

  final String title, designer, authorTag, version;

  /// Target OS build; HyperOS 3 is 17.
  final int uiVersion;

  /// Editor profile name (e.g. `suraj`) that supplies default designer/tag.
  final String? profile;

  static const _keys = {
    'title',
    'designer',
    'authorTag',
    'version',
    'uiVersion',
    'profile',
  };

  static MetaSpec? _read(JsonReader r) {
    if (r.object(required: true) == null) return null;
    r.warnUnknownKeys(_keys);
    final title = r.string('title', required: true);
    final ui = r.integer('uiVersion');
    final out = MetaSpec(
      title: title ?? '',
      designer: r.string('designer') ?? '',
      authorTag: r.string('authorTag') ?? '',
      version: r.string('version') ?? '1.0',
      uiVersion: ui ?? 17,
      profile: r.string('profile'),
    );
    return title == null ? null : out;
  }

  Map<String, Object?> toJson() => {
    'title': title,
    'designer': designer,
    'authorTag': authorTag,
    'version': version,
    'uiVersion': uiVersion,
    if (profile != null) 'profile': profile,
  };
}

/// Where the theme lives in the editor's Week/folder layout; informational.
class WorkspaceSpec {
  const WorkspaceSpec({this.week, this.folder});

  final String? week, folder;

  static WorkspaceSpec? _read(JsonReader r) {
    if (r.object() == null) return null;
    r.warnUnknownKeys(const {'week', 'folder'});
    return WorkspaceSpec(week: r.string('week'), folder: r.string('folder'));
  }

  Map<String, Object?> toJson() => {
    if (week != null) 'week': week,
    if (folder != null) 'folder': folder,
  };
}

class WallpaperSpec {
  const WallpaperSpec({required this.home, this.lock});

  /// Path to the wallpaper image, relative to the spec file or absolute.
  final String home;

  /// Lockscreen wallpaper; defaults to [home].
  final String? lock;

  String get lockOrHome => lock ?? home;

  static WallpaperSpec? _read(JsonReader r) {
    if (r.object(required: true) == null) return null;
    r.warnUnknownKeys(const {'home', 'lock'});
    final home = r.string('home', required: true);
    final lock = r.string('lock');
    return home == null ? null : WallpaperSpec(home: home, lock: lock);
  }

  Map<String, Object?> toJson() => {
    'home': home,
    if (lock != null) 'lock': lock,
  };
}

class EffectSpec {
  const EffectSpec({
    this.type = IconEffect.none,
    this.intensity = 0.6,
    this.blur = 20.0,
    this.elevation = 4.0,
  });

  final IconEffect type;
  final double intensity, blur, elevation;

  static EffectSpec _read(JsonReader r) {
    if (r.object() == null) return const EffectSpec();
    r.warnUnknownKeys(const {'type', 'intensity', 'blur', 'elevation'});
    const d = EffectSpec();
    return EffectSpec(
      type: r.enumValue('type', IconEffect.values) ?? d.type,
      intensity: r.number('intensity') ?? d.intensity,
      blur: r.number('blur') ?? d.blur,
      elevation: r.number('elevation') ?? d.elevation,
    );
  }

  Map<String, Object?> toJson() => {
    'type': type.name,
    'intensity': intensity,
    'blur': blur,
    'elevation': elevation,
  };
}

class TextureSpec {
  const TextureSpec({
    this.type = IconTexture.none,
    this.scale = 1.0,
    this.opacity = 0.3,
  });

  final IconTexture type;
  final double scale, opacity;

  static TextureSpec _read(JsonReader r) {
    if (r.object() == null) return const TextureSpec();
    r.warnUnknownKeys(const {'type', 'scale', 'opacity'});
    const d = TextureSpec();
    return TextureSpec(
      type: r.enumValue('type', IconTexture.values) ?? d.type,
      scale: r.number('scale') ?? d.scale,
      opacity: r.number('opacity') ?? d.opacity,
    );
  }

  Map<String, Object?> toJson() => {
    'type': type.name,
    'scale': scale,
    'opacity': opacity,
  };
}

/// Icon tile background: a one- or two-color gradient, or a random pick from
/// [palette] per icon.
class BackgroundSpec {
  const BackgroundSpec({
    this.colors = const [Rgba(0xFFFFC300)],
    this.randomColors = false,
    this.palette = const [Rgba(0xFFFFC300)],
    this.gradientStart = Alignment2.topLeft,
    this.gradientEnd = Alignment2.bottomRight,
  });

  /// One or two colors: gradient start and end.
  final List<Rgba> colors;
  final bool randomColors;
  final List<Rgba> palette;
  final Alignment2 gradientStart, gradientEnd;

  static BackgroundSpec _read(JsonReader r) {
    if (r.object() == null) return const BackgroundSpec();
    r.warnUnknownKeys(const {'colors', 'randomColors', 'palette', 'gradient'});
    const d = BackgroundSpec();
    final g = r.child('gradient');
    Alignment2? start, end;
    if (g.object() != null) {
      g.warnUnknownKeys(const {'start', 'end'});
      start = _align(g, 'start');
      end = _align(g, 'end');
    }
    return BackgroundSpec(
      colors: r.colors('colors') ?? d.colors,
      randomColors: r.boolean('randomColors') ?? d.randomColors,
      palette: r.colors('palette') ?? d.palette,
      gradientStart: start ?? d.gradientStart,
      gradientEnd: end ?? d.gradientEnd,
    );
  }

  static Alignment2? _align(JsonReader g, String key) {
    final v = g.node is Map ? (g.node as Map)[key] : null;
    if (v == null) return null;
    final a = Alignment2.tryParse(v);
    if (a == null) {
      g.issues.add(
        SpecIssue(
          code: 'spec.type',
          path: '${g.path}/$key',
          message: 'Expected [x, y] with each between -1 and 1.',
        ),
      );
    }
    return a;
  }

  Map<String, Object?> toJson() => {
    'colors': colors.map(_hex).toList(),
    'randomColors': randomColors,
    'palette': palette.map(_hex).toList(),
    'gradient': {'start': gradientStart.toJson(), 'end': gradientEnd.toJson()},
  };
}

class IconsSpec {
  const IconsSpec({
    required this.pack,
    this.margin = 4,
    this.padding = 9,
    this.radius = 10,
    this.borderWidth = 2,
    this.shape = IconShape.squircle,
    this.iconColor = const Rgba(0xFFFFFFFF),
    this.borderColor = const Rgba(0x4DFFFFFF),
    this.background = const BackgroundSpec(),
    this.effect = const EffectSpec(),
    this.texture = const TextureSpec(),
  });

  /// Icon pack folder under `assets/icons`, `u1`–`u15`.
  final String pack;
  final double margin, padding, radius, borderWidth;
  final IconShape shape;
  final Rgba iconColor, borderColor;
  final BackgroundSpec background;
  final EffectSpec effect;
  final TextureSpec texture;

  static const _keys = {
    'pack',
    'margin',
    'padding',
    'radius',
    'borderWidth',
    'shape',
    'iconColor',
    'borderColor',
    'background',
    'effect',
    'texture',
  };

  static IconsSpec? _read(JsonReader r) {
    if (r.object(required: true) == null) return null;
    r.warnUnknownKeys(_keys);
    final pack = r.string('pack', required: true);
    const d = IconsSpec(pack: '');
    final out = IconsSpec(
      pack: pack ?? '',
      margin: r.number('margin') ?? d.margin,
      padding: r.number('padding') ?? d.padding,
      radius: r.number('radius') ?? d.radius,
      borderWidth: r.number('borderWidth') ?? d.borderWidth,
      shape: r.enumValue('shape', IconShape.values) ?? d.shape,
      iconColor: r.color('iconColor') ?? d.iconColor,
      borderColor: r.color('borderColor') ?? d.borderColor,
      background: BackgroundSpec._read(r.child('background')),
      effect: EffectSpec._read(r.child('effect')),
      texture: TextureSpec._read(r.child('texture')),
    );
    return pack == null ? null : out;
  }

  Map<String, Object?> toJson() => {
    'pack': pack,
    'margin': margin,
    'padding': padding,
    'radius': radius,
    'borderWidth': borderWidth,
    'shape': shape.name,
    'iconColor': _hex(iconColor),
    'borderColor': _hex(borderColor),
    'background': background.toJson(),
    'effect': effect.toJson(),
    'texture': texture.toJson(),
  };

  factory IconsSpec.fromStyle(IconStyle s, {required String pack}) => IconsSpec(
    pack: pack,
    margin: s.margin,
    padding: s.padding,
    radius: s.radius,
    borderWidth: s.borderWidth,
    shape: s.shape,
    iconColor: s.iconColor,
    borderColor: s.borderColor,
    background: BackgroundSpec(
      colors: s.bgColor == s.bgColor2 ? [s.bgColor] : [s.bgColor, s.bgColor2],
      randomColors: s.randomColors,
      palette: s.bgColors,
      gradientStart: s.bgGradStart,
      gradientEnd: s.bgGradEnd,
    ),
    effect: EffectSpec(
      type: s.effect,
      intensity: s.effectIntensity,
      blur: s.effectBlur,
      elevation: s.effectElevation,
    ),
    texture: TextureSpec(
      type: s.texture,
      scale: s.textureScale,
      opacity: s.textureOpacity,
    ),
  );

  /// The style the renderers consume, with the system-UI half filled in.
  IconStyle toStyle(SystemUiSpec ui) {
    final first = background.colors.isEmpty
        ? const Rgba(0xFFFFC300)
        : background.colors.first;
    return IconStyle(
      margin: margin,
      padding: padding,
      radius: radius,
      borderWidth: borderWidth,
      bgColor: first,
      bgColor2: background.colors.length > 1 ? background.colors[1] : first,
      bgGradStart: background.gradientStart,
      bgGradEnd: background.gradientEnd,
      bgColors: background.palette,
      randomColors: background.randomColors,
      iconColor: iconColor,
      borderColor: borderColor,
      accent: ui.accent,
      shape: shape,
      effect: effect.type,
      effectIntensity: effect.intensity,
      effectBlur: effect.blur,
      effectElevation: effect.elevation,
      texture: texture.type,
      textureScale: texture.scale,
      textureOpacity: texture.opacity,
      ccTemplate: ui.controlCenterTemplate,
    );
  }
}

class SystemUiSpec {
  const SystemUiSpec({
    this.accent = const Rgba(0xFFFFC300),
    this.controlCenterTemplate = ControlCenterTemplate.frostedGlass,
  });

  final Rgba accent;
  final ControlCenterTemplate controlCenterTemplate;

  static SystemUiSpec _read(JsonReader r) {
    if (r.object() == null) return const SystemUiSpec();
    r.warnUnknownKeys(const {'accent', 'controlCenterTemplate'});
    const d = SystemUiSpec();
    return SystemUiSpec(
      accent: r.color('accent') ?? d.accent,
      controlCenterTemplate:
          r.enumValue('controlCenterTemplate', ControlCenterTemplate.values) ??
          d.controlCenterTemplate,
    );
  }

  Map<String, Object?> toJson() => {
    'accent': _hex(accent),
    'controlCenterTemplate': controlCenterTemplate.name,
  };
}

class LockscreenSpec {
  const LockscreenSpec({
    this.bgAlpha = 0.0,
    this.assetsDir,
    this.elements = const [],
  });

  /// Black overlay over the lock wallpaper, 0–1.
  final double bgAlpha;

  /// Folder in the editor's `lockscreen/advance` layout (default PNGs,
  /// `bg.png`, `video.mp4` and any custom images elements point at).
  final String? assetsDir;
  final List<LockElementSpec> elements;

  /// Element keys holding an enum, with the allowed values.
  static final enumKeys = <String, List<Enum>>{
    'type': ElementType.values,
    'progressSource': ArcProgressSource.values,
    'unlockIcon': UnlockIcon.values,
    'unlockSkin': UnlockSkin.values,
    'analogStyle': AnalogStyle.values,
    'shortcutStyle': ShortcutStyle.values,
    'shortcutEdge': ShortcutEdge.values,
    'calendarStyle': CalendarStyle.values,
    'dayStripStyle': DayStripStyle.values,
    'tickerStyle': TickerStyle.values,
    'tickerSource': TickerSource.values,
    'gaugeStyle': GaugeStyle.values,
    'surfaceTexture': IconTexture.values,
    'gradientType': GradientType.values,
    'animation': ElementAnimation.values,
  };

  /// Element keys holding a color.
  static const colorKeys = [
    'unlockAccent',
    'borderColor',
    'color',
    'colorSecondary',
    'colorDigit1',
    'colorDigit2',
    'strokeColor',
    'strokeColorDigit1',
    'strokeColorDigit2',
  ];

  /// Element keys holding an alignment.
  static const alignKeys = ['gradStartAlign', 'gradEndAlign', 'align'];

  static final Set<String> _knownElementKeys = const LockElementSpec(
    type: ElementType.hourClock,
  ).toJson().keys.toSet();

  static LockscreenSpec _read(JsonReader r) {
    if (r.object() == null) return const LockscreenSpec();
    r.warnUnknownKeys(const {'bgAlpha', 'assetsDir', 'elements'});
    final elements = <LockElementSpec>[];
    final raw = r.list('elements') ?? const [];
    for (var i = 0; i < raw.length; i++) {
      final e = JsonReader(raw[i], '${r.path}/elements/$i', r.issues);
      final before = r.issues.length;
      final m = e.object();
      if (m == null) continue;
      _checkElement(e, m);
      if (r.issues.skip(before).any((x) => x.severity == IssueSeverity.error)) {
        continue;
      }
      try {
        elements.add(LockElementSpec.fromJson(m));
      } catch (err) {
        r.issues.add(
          SpecIssue(
            code: 'spec.element',
            path: e.path,
            message: 'Element could not be read: $err',
          ),
        );
      }
    }
    return LockscreenSpec(
      bgAlpha: r.number('bgAlpha') ?? 0.0,
      assetsDir: r.string('assetsDir'),
      elements: elements,
    );
  }

  static void _checkElement(JsonReader e, Map<String, dynamic> m) {
    e.warnUnknownKeys(_knownElementKeys);
    e.enumValue('type', ElementType.values, required: true);
    for (final entry in enumKeys.entries) {
      if (entry.key != 'type') e.enumValue(entry.key, entry.value);
    }
    for (final k in colorKeys) {
      e.color(k);
    }
    for (final k in alignKeys) {
      final v = m[k];
      if (v != null && Alignment2.tryParse(v) == null) {
        e.issues.add(
          SpecIssue(
            code: 'spec.type',
            path: '${e.path}/$k',
            message: 'Not a valid alignment: $v',
            hint: 'Use a name like "Alignment.center" or [x, y].',
          ),
        );
      }
    }
    final tracks = e.list('animations') ?? const [];
    for (var i = 0; i < tracks.length; i++) {
      final t = JsonReader(tracks[i], '${e.path}/animations/$i', e.issues);
      if (t.object() == null) continue;
      t.enumValue('type', ElementAnimation.values, required: true);
      t.enumValue('ease', MamlEase.values);
    }
  }

  Map<String, Object?> toJson() => {
    'bgAlpha': bgAlpha,
    if (assetsDir != null) 'assetsDir': assetsDir,
    'elements': [for (final e in elements) e.toJson()],
  };
}

/// A local font file standing in for a font reference used by elements.
class FontSpec {
  const FontSpec({required this.ref, this.path});

  /// The exact `font` string elements use, e.g. `gf:Inter`.
  final String ref;

  /// Font file to render with; required before building headless.
  final String? path;

  FontRef get parsed => FontRef.parse(ref);

  static FontSpec? _read(JsonReader r) {
    if (r.object() == null) return null;
    r.warnUnknownKeys(const {'ref', 'path'});
    final ref = r.string('ref', required: true);
    final path = r.string('path');
    return ref == null ? null : FontSpec(ref: ref, path: path);
  }

  Map<String, Object?> toJson() => {'ref': ref, if (path != null) 'path': path};
}

class OutputSpec {
  const OutputSpec({this.name, this.dir});

  /// `.mtz` file name without extension; defaults to the title.
  final String? name;

  /// Folder the workspace and `.mtz` are written to.
  final String? dir;

  static OutputSpec _read(JsonReader r) {
    if (r.object() == null) return const OutputSpec();
    r.warnUnknownKeys(const {'name', 'dir'});
    return OutputSpec(name: r.string('name'), dir: r.string('dir'));
  }

  Map<String, Object?> toJson() => {
    if (name != null) 'name': name,
    if (dir != null) 'dir': dir,
  };
}

/// Declarative description of a whole theme; the input to validate, build and
/// preview.
class ThemeSpec {
  const ThemeSpec({
    required this.meta,
    required this.wallpaper,
    required this.icons,
    this.workspace,
    this.systemUi = const SystemUiSpec(),
    this.lockscreen = const LockscreenSpec(),
    this.fonts = const [],
    this.output = const OutputSpec(),
  });

  static const currentVersion = 1;

  final MetaSpec meta;
  final WorkspaceSpec? workspace;
  final WallpaperSpec wallpaper;
  final IconsSpec icons;
  final SystemUiSpec systemUi;
  final LockscreenSpec lockscreen;
  final List<FontSpec> fonts;
  final OutputSpec output;

  /// The `.mtz` base name.
  String get outputName => output.name ?? meta.title;

  /// Style consumed by the icon and system-UI renderers.
  IconStyle get iconStyle => icons.toStyle(systemUi);

  /// Font references elements use that can't come from the OS.
  List<String> get requiredFontRefs => {
    for (final e in lockscreen.elements)
      if (FontRef.parse(e.font).needsFile) e.font,
  }.toList();

  /// Fonts declared in the spec, by reference.
  FontSpec? fontFor(String ref) {
    for (final f in fonts) {
      if (f.ref == ref) return f;
    }
    return null;
  }

  static const _keys = {
    r'$schema',
    'specVersion',
    'meta',
    'workspace',
    'wallpaper',
    'icons',
    'systemUi',
    'lockscreen',
    'fonts',
    'output',
  };

  /// Reads a decoded JSON value, reporting every problem found.
  static SpecParseResult parse(Object? json) {
    final issues = <SpecIssue>[];
    final root = JsonReader(json, '', issues);
    if (root.object(required: true) == null) {
      return SpecParseResult(null, issues);
    }
    root.warnUnknownKeys(_keys);

    final version = root.integer('specVersion', required: true);
    if (version != null && version != currentVersion) {
      issues.add(
        SpecIssue(
          code: 'spec.version',
          path: '/specVersion',
          message: 'Unsupported specVersion $version.',
          hint: 'This tool reads specVersion $currentVersion.',
        ),
      );
    }

    final meta = MetaSpec._read(root.child('meta'));
    final wallpaper = WallpaperSpec._read(root.child('wallpaper'));
    final icons = IconsSpec._read(root.child('icons'));
    final workspace = WorkspaceSpec._read(root.child('workspace'));
    final systemUi = SystemUiSpec._read(root.child('systemUi'));
    final lockscreen = LockscreenSpec._read(root.child('lockscreen'));
    final output = OutputSpec._read(root.child('output'));

    final fonts = <FontSpec>[];
    final rawFonts = root.list('fonts') ?? const [];
    for (var i = 0; i < rawFonts.length; i++) {
      final f = FontSpec._read(JsonReader(rawFonts[i], '/fonts/$i', issues));
      if (f != null) fonts.add(f);
    }

    final hasError = issues.any((i) => i.severity == IssueSeverity.error);
    if (hasError || meta == null || wallpaper == null || icons == null) {
      return SpecParseResult(null, issues);
    }
    return SpecParseResult(
      ThemeSpec(
        meta: meta,
        workspace: workspace,
        wallpaper: wallpaper,
        icons: icons,
        systemUi: systemUi,
        lockscreen: lockscreen,
        fonts: fonts,
        output: output,
      ),
      issues,
    );
  }

  /// Like [parse] but throws [SpecFormatException] on errors.
  factory ThemeSpec.fromJson(Object? json) {
    final r = parse(json);
    if (r.spec == null) throw SpecFormatException(r.issues);
    return r.spec!;
  }

  Map<String, Object?> toJson() => {
    'specVersion': currentVersion,
    'meta': meta.toJson(),
    if (workspace != null) 'workspace': workspace!.toJson(),
    'wallpaper': wallpaper.toJson(),
    'icons': icons.toJson(),
    'systemUi': systemUi.toJson(),
    'lockscreen': lockscreen.toJson(),
    'fonts': [for (final f in fonts) f.toJson()],
    'output': output.toJson(),
  };
}
