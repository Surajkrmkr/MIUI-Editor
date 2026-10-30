import 'dart:convert';
import 'dart:io';

import 'package:image/image.dart' as img;
import 'package:test/test.dart';
import 'package:theme_core/theme_core.dart';

/// Decoded-JSON shaped maps, so tests can overwrite values with any type.
Map<String, dynamic> _loose(Map<String, Object?> m) =>
    jsonDecode(jsonEncode(m)) as Map<String, dynamic>;

void main() {
  late Directory tmp;
  const validator = SpecValidator();

  setUp(() => tmp = Directory.systemTemp.createTempSync('validator_test'));
  tearDown(() => tmp.deleteSync(recursive: true));

  String solid(String name, int r, int g, int b, {int w = 120, int h = 260}) {
    final image = img.Image(width: w, height: h)..clear(img.ColorRgb8(r, g, b));
    final f = File('${tmp.path}/$name')
      ..writeAsBytesSync(
        name.endsWith('.jpg') ? img.encodeJpg(image) : img.encodePng(image),
      );
    return f.path;
  }

  /// A lockscreen assets folder with the one file every theme needs.
  String assetsDir() {
    final d = Directory('${tmp.path}/ls')..createSync();
    solid('ls/bg.png', 0, 0, 0);
    return d.path;
  }

  Map<String, dynamic> good({String? wallpaper, String? assets}) => _loose({
    'specVersion': 1,
    'meta': {'title': 'Neon', 'designer': 'Suraj', 'authorTag': 'Sj'},
    'wallpaper': {'home': wallpaper ?? solid('w.jpg', 30, 30, 60)},
    'icons': {
      'pack': 'u7',
      'background': {
        'colors': ['#2575FC'],
      },
    },
    'lockscreen': {
      'assetsDir': assets ?? assetsDir(),
      'elements': [
        {'type': 'swipeUpUnlock'},
        {'type': 'hourClock', 'color': '#FFFFFF'},
      ],
    },
  });

  ValidationReport run(
    Object? json, {
    bool contrast = true,
    bool design = false,
    List<NamedDesign> similar = const [],
    String? assetsRoot,
    List<String> fontsDirs = const [],
  }) => validator.validate(
    json,
    ValidationOptions(
      baseDir: tmp.path,
      assetsRoot: assetsRoot,
      checkContrast: contrast,
      checkDesign: design,
      similarDesigns: similar,
      fontsDirs: fontsDirs,
    ),
  );

  Iterable<String> codes(ValidationReport r) => r.issues.map((i) => i.code);

  SpecIssue issue(ValidationReport r, String code) => r.issues.firstWhere(
    (i) => i.code == code,
    orElse: () => fail('no $code in ${r.issues}'),
  );

  test('a good spec has no issues', () {
    final r = run(good());
    expect(r.issues, isEmpty, reason: r.issues.join('\n'));
    expect(r.ok, isTrue);
    expect(r.spec, isNotNull);
  });

  test('invalid JSON text is a spec.json error', () {
    final r = validator.validateText(
      '{"a": ',
      ValidationOptions(baseDir: tmp.path),
    );
    expect(r.ok, isFalse);
    expect(codes(r), ['spec.json']);
  });

  test('parse errors stop semantic checks and keep their paths', () {
    final r = run({'specVersion': 1});
    expect(r.ok, isFalse);
    expect(r.spec, isNull);
    expect(
      r.issues.map((i) => i.path),
      containsAll(['/meta', '/wallpaper', '/icons']),
    );
  });

  group('meta and names', () {
    test('only HyperOS 3 can be built', () {
      final j = good();
      (j['meta'] as Map)['uiVersion'] = 15;
      expect(issue(run(j), 'meta.ui_version').path, '/meta/uiVersion');
    });

    test('unsafe titles and output names are rejected', () {
      for (final bad in ['a/b', 'CON', 'x.', 'a:b', 'q' * 101]) {
        final j = good();
        (j['meta'] as Map)['title'] = bad;
        expect(codes(run(j)), contains('name.unsafe'), reason: bad);
      }
      var j = good();
      (j['meta'] as Map)['title'] = '  ';
      expect(codes(run(j)), contains('spec.empty'));

      j = good();
      j['output'] = {'name': 'a|b'};
      expect(issue(run(j), 'name.unsafe').path, '/output/name');
    });

    test('blank designer and author are warnings', () {
      final j = good();
      (j['meta'] as Map)
        ..['designer'] = ''
        ..['authorTag'] = '';
      final r = run(j);
      expect(r.ok, isTrue);
      expect(
        codes(r),
        containsAll(['meta.designer_missing', 'meta.author_missing']),
      );
    });
  });

  group('icons', () {
    test('unknown packs list the available ones', () {
      final j = good();
      (j['icons'] as Map)['pack'] = 'u99';
      final i = issue(run(j), 'icons.pack_unknown');
      expect(i.hint, contains('u15'));
    });

    test('pack folders are checked when an assets root is given', () {
      final root = Directory('${tmp.path}/repo/assets/icons/u7')
        ..createSync(recursive: true);
      var r = run(good(), assetsRoot: '${tmp.path}/repo');
      expect(codes(r), contains('icons.pack_incomplete'));

      File('${root.path}/com.android.mms.svg').writeAsStringSync('<svg/>');
      r = run(good(), assetsRoot: '${tmp.path}/repo');
      expect(r.issues, isEmpty);

      final j = good();
      (j['icons'] as Map)['pack'] = 'u8';
      expect(
        codes(run(j, assetsRoot: '${tmp.path}/repo')),
        contains('asset.missing'),
      );
    });

    test('slider ranges match the editor', () {
      final j = good();
      (j['icons'] as Map)
        ..['radius'] = 25
        ..['margin'] = -1
        ..['effect'] = {'intensity': 1.5, 'blur': 101}
        ..['texture'] = {'scale': 0.05, 'opacity': 2};
      final paths = run(
        j,
      ).issues.where((i) => i.code == 'range').map((i) => i.path);
      expect(
        paths,
        containsAll([
          '/icons/radius',
          '/icons/margin',
          '/icons/effect/intensity',
          '/icons/effect/blur',
          '/icons/texture/scale',
          '/icons/texture/opacity',
        ]),
      );
    });

    test('background colors, palette and gradient points are checked', () {
      final j = good();
      (j['icons'] as Map)['background'] = {
        'colors': ['#111111', '#222222', '#333333'],
        'randomColors': true,
        'palette': [],
        'gradient': {
          'start': [-2, 0],
          'end': [1, 1],
        },
      };
      expect(
        codes(run(j)),
        containsAll([
          'icons.background_colors',
          'icons.palette_empty',
          'range',
        ]),
      );
    });

    test('low-contrast glyph colors warn', () {
      final j = good();
      (j['icons'] as Map)
        ..['iconColor'] = '#2575FD'
        ..['background'] = {
          'colors': ['#2575FC'],
        };
      final r = run(j);
      expect(r.ok, isTrue);
      expect(issue(r, 'contrast.icon').path, '/icons/background/colors/0');
    });
  });

  group('lockscreen', () {
    test('duplicate names and bad instance ids are errors', () {
      final j = good();
      (j['lockscreen'] as Map)['elements'] = [
        {'type': 'swipeUpUnlock'},
        {'type': 'hourClock'},
        {'type': 'hourClock'},
        {'type': 'normalText1', 'instanceId': 'a b'},
      ];
      final r = run(j);
      expect(
        issue(r, 'lockscreen.duplicate_element').path,
        '/lockscreen/elements/2',
      );
      expect(
        issue(r, 'lockscreen.bad_instance_id').path,
        '/lockscreen/elements/3/instanceId',
      );
    });

    test('the meet skin is rejected on a tap unlock only', () {
      List<Map<String, Object>> elements(String unlock) => [
        {'type': unlock, 'unlockSkin': 'meet'},
      ];
      final j = good();
      (j['lockscreen'] as Map)['elements'] = elements('tapToUnlock');
      final r = run(j);
      expect(
        issue(r, 'lockscreen.unsupported_skin').path,
        '/lockscreen/elements/0/unlockSkin',
      );
      expect(r.ok, isFalse);

      for (final ok in ['slideToUnlock', 'dragToUnlock']) {
        (j['lockscreen'] as Map)['elements'] = elements(ok);
        expect(codes(run(j)), isNot(contains('lockscreen.unsupported_skin')));
      }
    });

    test('a visible unlock element is required', () {
      final j = good();
      (j['lockscreen'] as Map)['elements'] = [
        {'type': 'swipeUpUnlock', 'isVisible': false},
      ];
      expect(codes(run(j)), contains('lockscreen.no_unlock'));
    });

    test('an empty lockscreen is fine and needs no assets', () {
      final j = good();
      j['lockscreen'] = {'elements': []};
      expect(run(j).issues, isEmpty);
    });

    test('elements need an assets folder with bg.png', () {
      var j = good();
      (j['lockscreen'] as Map).remove('assetsDir');
      expect(codes(run(j)), contains('lockscreen.assets_dir_missing'));

      j = good(assets: '${tmp.path}/nowhere');
      expect(codes(run(j)), contains('asset.missing'));

      final empty = Directory('${tmp.path}/empty')..createSync();
      j = good(assets: empty.path);
      expect(issue(run(j), 'asset.missing').message, contains('bg.png'));
    });

    test('custom unlock icons must exist', () {
      final j = good();
      (j['lockscreen'] as Map)['elements'] = [
        {
          'type': 'tapToUnlock',
          'unlockIcon': 'customPng',
          'unlockIconPath': 'unlock/x.png',
        },
      ];
      expect(
        issue(run(j), 'asset.missing').path,
        '/lockscreen/elements/0/unlockIconPath',
      );

      File('${tmp.path}/ls/unlock/x.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync([1]);
      expect(run(j).issues, isEmpty);

      (j['lockscreen'] as Map)['elements'] = [
        {'type': 'tapToUnlock', 'unlockIcon': 'customPng'},
      ];
      expect(codes(run(j)), contains('lockscreen.missing_path'));
    });

    test('sizes, scale and off-screen centres are flagged', () {
      final j = good();
      (j['lockscreen'] as Map)['elements'] = [
        {'type': 'swipeUpUnlock', 'width': 0},
        {'type': 'normalText1', 'scale': 0, 'fontSize': 0},
        {'type': 'hourClock', 'dx': 400},
      ];
      final r = run(j);
      expect(r.issues.where((i) => i.code == 'range').length, 3);
      expect(issue(r, 'lockscreen.off_screen').path, '/lockscreen/elements/2');
      expect(
        r.issues.firstWhere((i) => i.code == 'lockscreen.off_screen').severity,
        IssueSeverity.warning,
      );
    });

    test('bgAlpha must be 0 to 1', () {
      final j = good();
      (j['lockscreen'] as Map)['bgAlpha'] = 1.5;
      expect(issue(run(j), 'range').path, '/lockscreen/bgAlpha');
    });
  });

  group('wallpaper', () {
    test('missing and unreadable wallpapers are errors', () {
      var r = run(good(wallpaper: '${tmp.path}/none.jpg'));
      expect(issue(r, 'asset.missing').path, '/wallpaper/home');

      File('${tmp.path}/junk.jpg').writeAsStringSync('not an image');
      r = run(good(wallpaper: '${tmp.path}/junk.jpg'));
      expect(issue(r, 'asset.undecodable').path, '/wallpaper/home');
    });

    test('relative paths resolve against baseDir', () {
      solid('rel.png', 10, 10, 10);
      expect(run(good(wallpaper: 'rel.png')).issues, isEmpty);
    });

    test('lock wallpaper is checked too', () {
      final j = good();
      (j['wallpaper'] as Map)['lock'] = 'missing.jpg';
      expect(issue(run(j), 'asset.missing').path, '/wallpaper/lock');
    });
  });

  group('contrast', () {
    test(
      'white text on a bright wallpaper warns, and the overlay fixes it',
      () {
        final j = good(wallpaper: solid('bright.png', 240, 240, 240));
        var r = run(j);
        expect(issue(r, 'contrast.text').path, '/lockscreen/elements/1/color');
        expect(r.ok, isTrue);

        (j['lockscreen'] as Map)['bgAlpha'] = 0.8;
        r = run(j);
        expect(codes(r), isNot(contains('contrast.text')));
      },
    );

    test('a stroke exempts text, and the check can be turned off', () {
      final j = good(wallpaper: solid('bright.png', 240, 240, 240));
      ((j['lockscreen'] as Map)['elements'] as List)[1] = {
        'type': 'hourClock',
        'color': '#FFFFFF',
        'strokeWidth': 2,
        'strokeColor': '#000000',
      };
      expect(codes(run(j)), isNot(contains('contrast.text')));

      ((j['lockscreen'] as Map)['elements'] as List)[1] = {
        'type': 'hourClock',
        'color': '#FFFFFF',
      };
      expect(codes(run(j, contrast: false)), isNot(contains('contrast.text')));
    });

    test('hidden elements are not checked', () {
      final j = good(wallpaper: solid('bright.png', 240, 240, 240));
      ((j['lockscreen'] as Map)['elements'] as List)[1] = {
        'type': 'hourClock',
        'isVisible': false,
      };
      expect(codes(run(j)), isNot(contains('contrast.text')));
    });
  });

  group('fonts', () {
    Map<String, dynamic> withFont({Object? fonts}) {
      final j = good();
      ((j['lockscreen'] as Map)['elements'] as List)[1] = {
        'type': 'hourClock',
        'color': '#FFFFFF',
        'font': 'rf:Fira|https://x.test/fira.ttf',
      };
      if (fonts != null) j['fonts'] = fonts;
      return j;
    }

    test('fonts that need a file must be declared with one', () {
      final r = run(withFont());
      final i = issue(r, 'font.file_missing');
      expect(i.hint, contains('https://x.test/fira.ttf'));
      expect(r.ok, isFalse);
    });

    test('a fonts folder supplies files the spec does not name', () {
      final dir = Directory('${tmp.path}/fonts')..createSync();
      File('${dir.path}/Fira.ttf').writeAsBytesSync([0, 1, 0, 0, 9, 9]);

      final r = run(withFont(), fontsDirs: [dir.path]);
      expect(codes(r), isNot(contains('font.file_missing')));
      expect(r.ok, isTrue, reason: '${r.issues}');
    });

    test('a fonts folder without the family still reports it, with a hint', () {
      final dir = Directory('${tmp.path}/fonts')..createSync();
      File('${dir.path}/Other.ttf').writeAsBytesSync([0, 1, 0, 0, 9, 9]);

      final r = run(withFont(), fontsDirs: [dir.path]);
      expect(issue(r, 'font.file_missing').hint, contains('--fonts-dir'));
    });

    test('font files must exist and look like fonts', () {
      File('${tmp.path}/fira.ttf').writeAsBytesSync([0, 1, 0, 0, 9, 9]);
      File('${tmp.path}/fake.ttf').writeAsStringSync('hello');
      const ref = 'rf:Fira|https://x.test/fira.ttf';

      expect(
        run(
          withFont(
            fonts: [
              {'ref': ref, 'path': 'fira.ttf'},
            ],
          ),
        ).issues,
        isEmpty,
      );
      expect(
        codes(
          run(
            withFont(
              fonts: [
                {'ref': ref, 'path': 'fake.ttf'},
              ],
            ),
          ),
        ),
        contains('font.invalid'),
      );
      expect(
        codes(
          run(
            withFont(
              fonts: [
                {'ref': ref, 'path': 'nope.ttf'},
              ],
            ),
          ),
        ),
        contains('asset.missing'),
      );
    });

    test('unused and duplicate declarations are warnings', () {
      File('${tmp.path}/a.ttf').writeAsBytesSync([0, 1, 0, 0]);
      final j = good();
      j['fonts'] = [
        {'ref': 'gf:Unused', 'path': 'a.ttf'},
        {'ref': 'gf:Unused', 'path': 'a.ttf'},
      ];
      final r = run(j);
      expect(r.ok, isTrue);
      expect(codes(r), containsAll(['font.unused', 'font.duplicate']));
    });
  });

  test('reports serialise to JSON', () {
    final j = good();
    (j['meta'] as Map)['uiVersion'] = 15;
    final json = run(j).toJson();
    expect(json['ok'], isFalse);
    expect(json['errors'], 1);
    expect(() => jsonEncode(json), returnsNormally);
  });

  group('design checks', () {
    Map<String, dynamic> rich() {
      final j = good();
      (j['lockscreen'] as Map)['elements'] = <Map<String, dynamic>>[
        {'type': 'swipeUpUnlock'},
        {'type': 'hourClock', 'fontSize': 120},
        {'type': 'minClock', 'fontSize': 120},
        {'type': 'dateClock', 'fontSize': 28},
        {'type': 'weatherTemp', 'fontSize': 40},
        {'type': 'rectangleShape'},
        {'type': 'containerBG1'},
        {'type': 'normalText1', 'fontSize': 18},
      ];
      return j;
    }

    test('are off unless asked for', () {
      expect(run(good()).issues, isEmpty);
    });

    test('a bare lockscreen is warned about, and still builds', () {
      final r = run(good(), design: true);
      expect(r.ok, isTrue);
      expect(
        codes(r),
        containsAll([
          'lockscreen.sparse',
          'lockscreen.no_info',
          'lockscreen.no_decoration',
        ]),
      );
      expect(codes(r), isNot(contains('lockscreen.no_clock')));
      expect(issue(r, 'lockscreen.sparse').hint, contains('get_base_spec'));
    });

    test('a full lockscreen has no warnings', () {
      final r = run(rich(), design: true);
      expect(r.issues, isEmpty, reason: r.issues.join('\n'));
    });

    test('hidden elements do not count', () {
      final j = rich();
      for (final e in (j['lockscreen'] as Map)['elements'] as List) {
        if (const {
          'weatherTemp',
          'rectangleShape',
          'containerBG1',
        }.contains(e['type'])) {
          e['isVisible'] = false;
        }
      }
      final r = run(j, design: true);
      expect(
        codes(r),
        containsAll([
          'lockscreen.sparse',
          'lockscreen.no_info',
          'lockscreen.no_decoration',
        ]),
      );
    });

    test('one font size across several texts is warned about', () {
      final j = rich();
      for (final e in (j['lockscreen'] as Map)['elements'] as List) {
        e['fontSize'] = 30;
      }
      expect(codes(run(j, design: true)), ['lockscreen.one_font_size']);
    });

    test('a missing clock is warned about', () {
      final j = rich();
      ((j['lockscreen'] as Map)['elements'] as List).removeWhere(
        (e) => (e['type'] as String).endsWith('Clock'),
      );
      expect(codes(run(j, design: true)), contains('lockscreen.no_clock'));
    });

    List<dynamic> elementsOf(Map<String, dynamic> j) =>
        (j['lockscreen'] as Map)['elements'] as List;

    test('swipeUpUnlock is required and dragToUnlock is not used', () {
      final j = rich();
      elementsOf(j).removeWhere((e) => e['type'] == 'swipeUpUnlock');
      elementsOf(j).add({'type': 'dragToUnlock'});
      final r = run(j, design: true);
      expect(r.ok, isTrue);
      expect(
        codes(r),
        containsAll(['lockscreen.no_swipe_up', 'lockscreen.drag_unlock']),
      );
    });

    test('music alone is not the required widget', () {
      final j = rich();
      elementsOf(j).removeWhere((e) => e['type'] == 'weatherTemp');
      elementsOf(j).add({'type': 'musicPlay'});
      expect(codes(run(j, design: true)), contains('lockscreen.no_info'));
    });

    test('shortcuts must be system apps', () {
      final j = rich();
      elementsOf(j).add({
        'type': 'shortcutSet',
        'shortcutApps': 'camera, whatsapp,spotify,gallery',
      });
      elementsOf(j).add({'type': 'telegramIcon'});
      final r = run(j, design: true);
      final bad = r.issues.where((i) => i.code == 'shortcut.third_party');
      expect(bad, hasLength(2));
      expect(
        bad.first.message,
        allOf(contains('whatsapp'), contains('spotify')),
      );
      expect(bad.first.message, isNot(contains('camera')));

      final ok = rich();
      elementsOf(ok).add({
        'type': 'shortcutSet',
        'shortcutApps': 'camera,gallery,phone,messages',
      });
      expect(
        codes(run(ok, design: true)),
        isNot(contains('shortcut.third_party')),
      );
    });

    test('the hour and minute stay together', () {
      final j = rich();
      for (final e in elementsOf(j)) {
        if (e['type'] == 'hourClock') e['dx'] = -100;
        if (e['type'] == 'minClock') e['dx'] = 100;
      }
      expect(codes(run(j, design: true)), ['clock.spread']);

      for (final e in elementsOf(j)) {
        if (e['type'] == 'hourClock') e['dx'] = -40;
        if (e['type'] == 'minClock') e['dx'] = 40;
      }
      expect(run(j, design: true).issues, isEmpty);
    });

    test('the weekday, month and day stay together', () {
      final j = rich();
      elementsOf(j)
        ..add({'type': 'weekClock', 'dx': -120, 'fontSize': 18})
        ..add({'type': 'monthClock', 'dx': 120, 'fontSize': 18});
      expect(codes(run(j, design: true)), ['date.spread']);
    });

    test('content too close to the top or bottom edge is warned about', () {
      final j = rich();
      elementsOf(j)
        ..add({'type': 'normalText2', 'fontSize': 18, 'dy': -290})
        ..add({'type': 'normalText3', 'fontSize': 18, 'dy': 285})
        // Backgrounds may bleed to the edges.
        ..add({'type': 'containerBG2', 'dy': -290});
      final r = run(j, design: true);
      expect(codes(r), ['lockscreen.top_edge', 'lockscreen.bottom_edge']);
      expect(issue(r, 'lockscreen.top_edge').severity, IssueSeverity.warning);

      for (final e in elementsOf(j)) {
        if (e['type'] == 'normalText2') e['dy'] = -230;
        if (e['type'] == 'normalText3') e['dy'] = 230;
      }
      expect(run(j, design: true).issues, isEmpty);
    });

    NamedDesign earlier(String title, List<Map<String, dynamic>> elements) {
      final j = good();
      (j['lockscreen'] as Map)['elements'] = elements;
      return NamedDesign(
        title,
        DesignProfile(ThemeSpec.parse(j).spec!.lockscreen.elements),
      );
    }

    test('a design close to an earlier theme is named', () {
      final j = rich();
      final same = earlier('Old', [
        for (final e in elementsOf(j)) {...e},
      ]);
      final r = run(j, design: true, similar: [same]);
      expect(r.ok, isTrue);
      final i = issue(r, 'lockscreen.too_similar');
      expect(i.message, contains('"Old"'));
      expect(i.hint, contains('unlock control'));
    });

    test('a theme is not compared with itself, or with a different design', () {
      final j = rich();
      final mine = earlier('Neon', [
        for (final e in elementsOf(j)) {...e},
      ]);
      expect(
        codes(run(j, design: true, similar: [mine])),
        isNot(contains('lockscreen.too_similar')),
      );
      final other = earlier('Other', [
        {'type': 'analogClock', 'dx': 80, 'dy': 120, 'color': '#FF2200'},
        {'type': 'tapToUnlock'},
        {'type': 'calendarGrid'},
      ]);
      expect(
        codes(run(j, design: true, similar: [other])),
        isNot(contains('lockscreen.too_similar')),
      );
    });

    test('the starter layout is warned about, a changed one is not', () {
      final j = good();
      (j['lockscreen'] as Map)['elements'] = baseElements();
      final r = run(j, design: true);
      expect(codes(r), contains('lockscreen.base_layout'));
      expect(
        codes(run(rich(), design: true)),
        isNot(contains('lockscreen.base_layout')),
      );
    });
  });
}
