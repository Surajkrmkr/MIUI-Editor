import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:theme_core/theme_core.dart';

/// Writes just enough files for the builder and packager to be satisfied.
class FakeRenderer implements ThemeRenderer {
  final calls = <String>[];
  List<FontFile> fonts = [];
  List<LockElementSpec> frameElements = [];
  Failure? failIcons;
  List<String> pack = ['com.android.camera', 'com.android.mms'];

  void _write(String path, [List<int> bytes = const [1]]) => File(path)
    ..createSync(recursive: true)
    ..writeAsBytesSync(bytes);

  @override
  Future<void> loadFonts(List<FontFile> fonts) async {
    calls.add('fonts');
    this.fonts = fonts;
  }

  @override
  Future<List<String>> iconNames(String pack) async => this.pack;

  @override
  Future<Failure?> renderIcons({
    required ThemeLayout layout,
    required IconStyle style,
    required String pack,
    required List<String> iconNames,
    ProgressCallback? onProgress,
  }) async {
    calls.add('icons');
    if (failIcons != null) return failIcons;
    for (final n in iconNames) {
      _write(p.join(layout.iconsXxhdpi, '$n.png'), [7, 7]);
    }
    onProgress?.call(iconNames.length, iconNames.length);
    return null;
  }

  @override
  Future<Failure?> renderSystemModules({
    required ThemeLayout layout,
    required IconStyle style,
    required String iconPack,
    required String wallpaperPath,
  }) async {
    calls.add('system');
    for (final m in ThemeModules.system) {
      _write(p.join(layout.module(m), 'theme_values.xml'));
    }
    for (final (m, f) in [
      ('miui.systemui.plugin', 'qs_background_enabled.png'),
      ('com.android.systemui', 'notification_item_bg.9.png'),
      ('com.android.mms', 'miuix_appcompat_action_button_main_new.png'),
      ('com.android.settings', 'ic_wifi_settings.png'),
    ]) {
      _write(p.join(layout.moduleDrawables(m), f));
    }
    return null;
  }

  @override
  Future<Failure?> renderLockscreenFrames({
    required ThemeLayout layout,
    required List<LockElementSpec> elements,
    ProgressCallback? onProgress,
  }) async {
    calls.add('frames');
    frameElements = elements;
    _write(p.join(layout.lockscreenAdvance, 'hour', 'hour_0.png'));
    onProgress?.call(1, 1);
    return null;
  }
}

void main() {
  late Directory tmp;
  late FakeRenderer renderer;
  late String out;

  setUp(() {
    tmp = Directory.systemTemp.createTempSync('builder_test');
    renderer = FakeRenderer();
    out = p.join(tmp.path, 'out');
    File(p.join(tmp.path, 'home.jpg')).writeAsBytesSync([1, 1, 1]);
    File(p.join(tmp.path, 'lock.jpg')).writeAsBytesSync([2, 2, 2]);
    Directory(p.join(tmp.path, 'assets', 'icon')).createSync(recursive: true);
    File(p.join(tmp.path, 'assets', 'bg.png')).writeAsBytesSync([5]);
    File(
      p.join(tmp.path, 'assets', 'icon', 'camera.png'),
    ).writeAsBytesSync([9]);
    File(
      p.join(tmp.path, 'assets', 'icon', 'gallery.png'),
    ).writeAsBytesSync([8]);
    File(p.join(tmp.path, 'Inter.ttf')).writeAsBytesSync([0, 1, 0, 0]);
  });

  tearDown(() => tmp.deleteSync(recursive: true));

  ThemeSpec spec({
    Map<String, Object?>? lockscreen,
    Map<String, Object?>? wallpaper,
    List<Object?>? fonts,
    String title = 'Neon',
  }) => ThemeSpec.fromJson({
    'specVersion': 1,
    'meta': {'title': title, 'designer': 'D', 'authorTag': 'T'},
    'wallpaper': wallpaper ?? {'home': 'home.jpg'},
    'icons': {'pack': 'u1'},
    'lockscreen':
        lockscreen ??
        {
          'assetsDir': 'assets',
          'elements': [
            {'type': 'swipeUpUnlock'},
            {'type': 'hourClock'},
            {'type': 'cameraIcon'},
          ],
        },
    'fonts': fonts ?? [],
  });

  BuildOptions options() => BuildOptions(baseDir: tmp.path, outDir: out);

  Future<(BuildResult?, Failure?)> build(
    ThemeSpec s, [
    List<BuildProgress>? progress,
  ]) => ThemeBuilder(renderer).build(s, options(), onProgress: progress?.add);

  Archive open(String mtz) =>
      ZipDecoder().decodeBytes(File(mtz).readAsBytesSync());

  Archive inner(Archive root, String name) => ZipDecoder().decodeBytes(
    Uint8List.fromList(root.findFile(name)!.content as List<int>),
  );

  test('builds a complete .mtz and reports progress in order', () async {
    final progress = <BuildProgress>[];
    final (result, failure) = await build(spec(), progress);

    expect(failure, isNull, reason: failure?.message);
    expect(result!.mtzPath, p.join(out, 'Neon.mtz'));
    expect(result.workspacePath, p.join(out, 'Neon'));
    expect(renderer.calls, ['icons', 'system', 'frames']);
    expect(progress.map((e) => e.step).toSet().toList(), BuildStep.values);

    final root = open(result.mtzPath);
    final names = root.files.where((f) => f.isFile).map((f) => f.name).toSet();
    expect(
      names,
      containsAll([
        'description.xml',
        'plugin_config.xml',
        'wallpaper/default_wallpaper.jpg',
        'wallpaper/default_lock_wallpaper.jpg',
        ...ThemeModules.packed,
      ]),
    );

    final lock = inner(
      root,
      'lockscreen',
    ).files.where((f) => f.isFile).map((f) => f.name);
    expect(
      lock,
      containsAll([
        'advance/manifest.xml',
        'advance/bg.png',
        'advance/hour/hour_0.png',
      ]),
    );
    expect(File(p.join(out, 'Neon', 'theme.spec.json')).existsSync(), isTrue);
  });

  test('a separate lock wallpaper is used for the lock screen only', () async {
    await build(spec(wallpaper: {'home': 'home.jpg', 'lock': 'lock.jpg'}));
    final w = p.join(out, 'Neon', 'wallpaper');
    expect(File(p.join(w, 'default_wallpaper.jpg')).readAsBytesSync(), [
      1,
      1,
      1,
    ]);
    expect(File(p.join(w, 'default_lock_wallpaper.jpg')).readAsBytesSync(), [
      2,
      2,
      2,
    ]);
  });

  test(
    'lockscreen assets are copied and theme icons override the defaults',
    () async {
      await build(spec());
      final ls = p.join(out, 'Neon', 'lockscreen', 'advance');
      expect(File(p.join(ls, 'bg.png')).readAsBytesSync(), [5]);
      // The theme's own camera icon (written by the renderer) replaces the default.
      expect(File(p.join(ls, 'icon', 'camera.png')).readAsBytesSync(), [7, 7]);
      // No theme icon for gallery, so the default stays.
      expect(File(p.join(ls, 'icon', 'gallery.png')).readAsBytesSync(), [8]);
    },
  );

  test('the manifest is written from the spec elements', () async {
    await build(
      spec(
        lockscreen: {
          'assetsDir': 'assets',
          'bgAlpha': 0.5,
          'elements': [
            {'type': 'swipeUpUnlock'},
            {'type': 'hourClock'},
          ],
        },
      ),
    );
    final manifest = File(
      p.join(out, 'Neon', 'lockscreen', 'advance', 'manifest.xml'),
    ).readAsStringSync();
    expect(manifest, contains('hour/hour_'));
    expect(manifest, contains('alpha="128"'));
    expect(renderer.frameElements.map((e) => e.type), [
      ElementType.swipeUpUnlock,
      ElementType.hourClock,
    ]);
  });

  test('fonts reach the renderer with their family names', () async {
    final s = spec(
      lockscreen: {
        'assetsDir': 'assets',
        'elements': [
          {'type': 'swipeUpUnlock'},
          {'type': 'hourClock', 'font': 'gf:Inter'},
        ],
      },
      fonts: [
        {'ref': 'gf:Inter', 'path': 'Inter.ttf'},
      ],
    );
    final (_, failure) = await build(s);
    expect(failure, isNull, reason: failure?.message);
    expect(
      renderer.calls.indexOf('fonts'),
      lessThan(renderer.calls.indexOf('frames')),
    );
    expect(renderer.fonts.single.family, 'Inter');
    expect(renderer.fonts.single.path, p.join(tmp.path, 'Inter.ttf'));
  });

  test('a font without a file fails before anything is written', () async {
    final s = spec(
      lockscreen: {
        'assetsDir': 'assets',
        'elements': [
          {'type': 'swipeUpUnlock'},
          {'type': 'hourClock', 'font': 'gf:Inter'},
        ],
      },
    );
    final (result, failure) = await build(s);
    expect(result, isNull);
    expect(failure!.message, contains('gf:Inter'));
    expect(Directory(out).existsSync(), isFalse);
  });

  test('no lockscreen elements means no lockscreen module', () async {
    final (result, failure) = await build(spec(lockscreen: {'elements': []}));
    expect(failure, isNull, reason: failure?.message);
    expect(renderer.calls, ['icons', 'system']);
    expect(open(result!.mtzPath).findFile('lockscreen'), isNull);
  });

  group('workspace safety', () {
    test('a rebuild replaces a folder the builder created', () async {
      await build(spec());
      final stale = File(p.join(out, 'Neon', 'stale.txt'))
        ..writeAsStringSync('x');
      final (_, failure) = await build(spec());
      expect(failure, isNull, reason: failure?.message);
      expect(stale.existsSync(), isFalse);
    });

    test('a foreign folder is never deleted', () async {
      final mine = File(p.join(out, 'Neon', 'keep.txt'))
        ..createSync(recursive: true)
        ..writeAsStringSync('precious');
      final (result, failure) = await build(spec());
      expect(result, isNull);
      expect(failure!.message, contains('not created by the theme builder'));
      expect(mine.readAsStringSync(), 'precious');
    });

    test('assetsDir inside the output folder is refused', () async {
      final inside = p.join(out, 'Neon', 'lockscreen', 'advance');
      Directory(inside).createSync(recursive: true);
      File(p.join(out, 'Neon', buildMarkerName)).writeAsStringSync('');
      File(p.join(inside, 'bg.png')).writeAsBytesSync([1]);
      final (result, failure) = await build(
        spec(
          lockscreen: {
            'assetsDir': inside,
            'elements': [
              {'type': 'swipeUpUnlock'},
            ],
          },
        ),
      );
      expect(result, isNull);
      expect(failure!.message, contains('overlaps'));
      expect(File(p.join(inside, 'bg.png')).existsSync(), isTrue);
    });
  });

  group('failures', () {
    test('a missing wallpaper is reported', () async {
      final (result, failure) = await build(
        spec(wallpaper: {'home': 'nope.jpg'}),
      );
      expect(result, isNull);
      expect(failure!.message, contains('Wallpaper not found'));
    });

    test('an empty icon pack is reported', () async {
      renderer.pack = [];
      final (_, failure) = await build(spec());
      expect(failure!.message, contains('no icons'));
    });

    test('a renderer failure stops the build and leaves no .mtz', () async {
      renderer.failIcons = const ExportFailure('boom');
      final (result, failure) = await build(spec());
      expect(result, isNull);
      expect(failure!.message, 'boom');
      expect(renderer.calls, ['icons']);
      expect(File(p.join(out, 'Neon.mtz')).existsSync(), isFalse);
    });

    test('lockscreen elements without assetsDir fail', () async {
      final (_, failure) = await build(
        spec(
          lockscreen: {
            'elements': [
              {'type': 'swipeUpUnlock'},
            ],
          },
        ),
      );
      expect(failure!.message, contains('assetsDir'));
    });
  });
}
