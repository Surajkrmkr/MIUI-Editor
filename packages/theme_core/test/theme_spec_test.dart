import 'dart:convert';

import 'package:test/test.dart';
import 'package:theme_core/theme_core.dart';

Map<String, Object?> _example() => {
  'specVersion': 1,
  'meta': {
    'title': 'Neon Dusk',
    'designer': 'Suraj',
    'authorTag': 'Sj',
    'uiVersion': 17,
    'profile': 'suraj',
  },
  'workspace': {'week': '12', 'folder': '3'},
  'wallpaper': {'home': 'wallpapers/neon.jpg'},
  'icons': {
    'pack': 'u7',
    'shape': 'cookie7',
    'radius': 14,
    'background': {
      'colors': ['#6A11CB', '#2575FC'],
      'gradient': {
        'start': [-1, -1],
        'end': [1, 1],
      },
    },
    'effect': {'type': 'liquidGlass', 'intensity': 0.5},
    'texture': {'type': 'grain'},
  },
  'systemUi': {'accent': '#3D7BFF', 'controlCenterTemplate': 'neonRing'},
  'lockscreen': {
    'bgAlpha': 0.2,
    'elements': [
      {'type': 'hourClock', 'color': '#FFFFFF', 'font': 'gf:Inter'},
      {
        'type': 'slideToUnlock',
        'align': 'Alignment.centerLeft',
        'animations': [
          {'type': 'alpha', 'ease': 'sineEaseIn'},
        ],
      },
    ],
  },
  'fonts': [
    {'ref': 'gf:Inter', 'path': 'fonts/Inter.ttf'},
  ],
  'output': {'name': 'NeonDusk'},
};

List<String> _paths(SpecParseResult r, [IssueSeverity? severity]) => [
  for (final i in r.issues)
    if (severity == null || i.severity == severity) i.path,
];

void main() {
  test('a complete spec parses and round-trips through JSON', () {
    final spec = ThemeSpec.fromJson(_example());
    expect(spec.meta.title, 'Neon Dusk');
    expect(spec.icons.shape, IconShape.cookie7);
    expect(spec.lockscreen.elements, hasLength(2));
    expect(spec.systemUi.controlCenterTemplate, ControlCenterTemplate.neonRing);
    expect(spec.outputName, 'NeonDusk');

    final json = jsonDecode(jsonEncode(spec.toJson()));
    expect(ThemeSpec.fromJson(json).toJson(), json);
  });

  test('defaults fill in everything optional', () {
    final spec = ThemeSpec.fromJson({
      'specVersion': 1,
      'meta': {'title': 'T'},
      'wallpaper': {'home': 'w.jpg'},
      'icons': {'pack': 'u1'},
    });
    expect(spec.meta.uiVersion, 17);
    expect(spec.lockscreen.elements, isEmpty);
    expect(spec.outputName, 'T');
    expect(spec.wallpaper.lockOrHome, 'w.jpg');
    expect(spec.iconStyle.shape, IconShape.squircle);
  });

  test('missing required fields are reported with their path', () {
    final r = ThemeSpec.parse({
      'specVersion': 1,
      'meta': {},
      'wallpaper': {},
      'icons': {},
    });
    expect(r.ok, isFalse);
    expect(
      _paths(r, IssueSeverity.error),
      containsAll(['/meta/title', '/wallpaper/home', '/icons/pack']),
    );
    expect(r.issues.every((i) => i.code.startsWith('spec.')), isTrue);
  });

  test('bad enum values list the allowed ones', () {
    final json = _example();
    (json['icons'] as Map)['shape'] = 'hexagonal';
    final r = ThemeSpec.parse(json);
    final issue = r.issues.singleWhere((i) => i.path == '/icons/shape');
    expect(issue.code, 'spec.enum');
    expect(issue.hint, contains('squircle'));
  });

  test('bad colors and element types point at the exact node', () {
    final json = _example();
    (json['icons'] as Map)['background'] = {
      'colors': ['#6A11CB', 'blue'],
    };
    ((json['lockscreen'] as Map)['elements'] as List)[1] = {
      'type': 'slideUnlock',
    };
    final r = ThemeSpec.parse(json);
    expect(
      _paths(r, IssueSeverity.error),
      containsAll([
        '/icons/background/colors/1',
        '/lockscreen/elements/1/type',
      ]),
    );
    expect(r.spec, isNull);
  });

  test('unknown keys are warnings and do not block parsing', () {
    final json = _example()..['extra'] = 1;
    ((json['lockscreen'] as Map)['elements'] as List)[0] = {
      'type': 'hourClock',
      'colour': '#FFF',
    };
    final r = ThemeSpec.parse(json);
    expect(r.ok, isTrue);
    expect(
      _paths(r, IssueSeverity.warning),
      containsAll(['/extra', '/lockscreen/elements/0/colour']),
    );
  });

  test('wrong types and unsupported versions are errors', () {
    expect(ThemeSpec.parse('nope').ok, isFalse);
    expect(
      ThemeSpec.parse({'specVersion': 2}).issues.map((i) => i.code),
      contains('spec.version'),
    );

    final json = _example();
    (json['meta'] as Map)['title'] = 5;
    expect(
      ThemeSpec.parse(json).issues.map((i) => i.code),
      contains('spec.type'),
    );
    expect(() => ThemeSpec.fromJson(json), throwsA(isA<SpecFormatException>()));
  });

  test('issues serialise for machine-readable output', () {
    final r = ThemeSpec.parse({'specVersion': 1});
    final json = r.issues.first.toJson();
    expect(json.keys, containsAll(['code', 'severity', 'path', 'message']));
    expect(() => jsonEncode(json), returnsNormally);
  });

  group('fonts', () {
    test('FontRef splits the editor font strings', () {
      expect(FontRef.parse('gf:Inter').source, FontSource.google);
      expect(FontRef.parse('gf:Inter').family, 'Inter');
      final rf = FontRef.parse('rf:Fira Sans|https://x.test/fira.ttf');
      expect(rf.source, FontSource.remote);
      expect(rf.family, 'Fira Sans');
      expect(rf.url, 'https://x.test/fira.ttf');
      expect(FontRef.parse('Roboto').needsFile, isFalse);
      expect(FontRef.parse('RobotoCondensed').needsFile, isFalse);
      expect(FontRef.parse('').needsFile, isFalse);
      // Plain names outside the built-ins are API or installed fonts.
      expect(FontRef.parse('Ground').needsFile, isTrue);
      expect(FontRef.parse('rf:broken').source, FontSource.system);
    });

    test('requiredFontRefs lists only fonts that need a file', () {
      final spec = ThemeSpec.fromJson(_example());
      expect(spec.requiredFontRefs, ['gf:Inter']);
      expect(spec.fontFor('gf:Inter')!.path, 'fonts/Inter.ttf');
      expect(spec.fontFor('gf:Other'), isNull);
    });
  });

  group('icon style mapping', () {
    test('IconStyle survives a trip through IconsSpec', () {
      const style = IconStyle(
        margin: 6,
        padding: 7,
        radius: 12,
        borderWidth: 1,
        bgColor: Rgba(0xFF112233),
        bgColor2: Rgba(0xFF445566),
        bgGradStart: Alignment2.topCenter,
        bgGradEnd: Alignment2.bottomCenter,
        bgColors: [Rgba(0xFF010203), Rgba(0xFF040506)],
        randomColors: true,
        iconColor: Rgba(0xFFEEEEEE),
        borderColor: Rgba(0x80FFFFFF),
        accent: Rgba(0xFF3D7BFF),
        shape: IconShape.heart,
        effect: IconEffect.neon,
        effectIntensity: .3,
        effectBlur: 11,
        effectElevation: 2,
        texture: IconTexture.paper,
        textureScale: 2,
        textureOpacity: .5,
        ccTemplate: ControlCenterTemplate.miniDots,
      );
      final icons = IconsSpec.fromStyle(style, pack: 'u3');
      final ui = SystemUiSpec(
        accent: style.accent,
        controlCenterTemplate: style.ccTemplate,
      );
      final back = IconsSpec.fromStyle(
        ThemeSpec(
          meta: const MetaSpec(title: 't'),
          wallpaper: const WallpaperSpec(home: 'w'),
          icons: icons,
          systemUi: ui,
        ).iconStyle,
        pack: 'u3',
      );
      expect(back.toJson(), icons.toJson());
      final s2 = icons.toStyle(ui);
      expect(
        [s2.bgColor, s2.bgColor2, s2.accent, s2.iconColor],
        [style.bgColor, style.bgColor2, style.accent, style.iconColor],
      );
      expect(s2.bgColors, style.bgColors);
      expect(s2.ccTemplate, style.ccTemplate);
    });

    test('a single gradient color serialises as one entry', () {
      const style = IconStyle(
        bgColor: Rgba(0xFF112233),
        bgColor2: Rgba(0xFF112233),
      );
      final icons = IconsSpec.fromStyle(style, pack: 'u1');
      expect(icons.background.colors, hasLength(1));
      expect(icons.toStyle(const SystemUiSpec()).bgColor2, style.bgColor2);
    });
  });
}
