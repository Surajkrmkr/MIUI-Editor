import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:miui_icon_generator/theme_editor/core/constants/path_constants.dart';
import 'package:miui_icon_generator/theme_editor/domain/entities/element_widget.dart';
import 'package:miui_icon_generator/theme_editor/domain/entities/user_profile.dart';
import 'package:miui_icon_generator/theme_editor/data/repositories/preset_repository_impl.dart';
import 'package:miui_icon_generator/theme_editor/domain/usecases/build_theme_spec.dart';
import 'package:miui_icon_generator/theme_editor/presentation/providers/icon_editor_provider.dart';
import 'package:miui_icon_generator/theme_editor/presentation/providers/lockscreen_provider.dart';
import 'package:miui_icon_generator/theme_editor/presentation/providers/service_providers.dart';
import 'package:miui_icon_generator/theme_editor/presentation/providers/spec_loader.dart';
import 'package:miui_icon_generator/theme_editor/presentation/providers/spec_provider.dart';
import 'package:miui_icon_generator/theme_editor/presentation/providers/user_profile_provider.dart';
import 'package:miui_icon_generator/theme_editor/presentation/providers/wallpaper_provider.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:theme_core/theme_core.dart';

import 'fixtures/lock_elements.dart';

void main() {
  late Directory tmp;
  late String wallpaper;
  late ProviderContainer container;

  const week = '12', folder = '3';
  final profile = kUserProfiles[UserProfileType.suraj]!;
  ThemeLayout layout([String name = 'Neon']) =>
      ThemeLayout(PathConstants.themePath(week, name));

  const style = IconEditorState(
    margin: 6,
    radius: 12,
    bgColor: Color(0xFF112233),
    bgColor2: Color(0xFF445566),
    bgGradStart: Alignment.topCenter,
    bgGradEnd: Alignment.bottomCenter,
    bgColors: [Color(0xFF010203), Color(0xFF040506)],
    randomColors: true,
    iconColor: Color(0xFFEEEEEE),
    borderColor: Color(0x80FFFFFF),
    accentColor: Color(0xFF3D7BFF),
    shape: IconShape.heart,
    effect: IconEffect.neon,
    texture: IconTexture.paper,
    ccTemplate: ControlCenterTemplate.miniDots,
  );

  setUp(() async {
    tmp = Directory.systemTemp.createTempSync('spec_loader_test');
    PathConstants.customBasePath = '${tmp.path}/';
    wallpaper = p.join(tmp.path, 'walls', 'wall.png');
    File(wallpaper)
      ..createSync(recursive: true)
      ..writeAsBytesSync(
        img.encodePng(
          img.Image(width: 40, height: 90)..clear(img.ColorRgb8(30, 60, 90)),
        ),
      );
    SharedPreferences.setMockInitialValues({});
    container = ProviderContainer(
      overrides: [
        sharedPrefsProvider.overrideWithValue(
          await SharedPreferences.getInstance(),
        ),
      ],
    );
  });

  tearDown(() {
    container.dispose();
    PathConstants.customBasePath = '';
    tmp.deleteSync(recursive: true);
  });

  /// The spec the editor would write for this theme.
  ThemeSpec editorSpec({
    UserProfile? withProfile,
    List<LockElement>? elements,
    String themeName = 'Neon',
    String? wallpaperPath,
    String? homeWallpaperPath,
  }) {
    final themeLayout = layout(themeName);
    return buildThemeSpec(
      themeName: themeName,
      wallpaperPath: wallpaperPath ?? wallpaper,
      homeWallpaperPath: homeWallpaperPath,
      designer: 'Designer',
      authorTag: 'Dg',
      uiVersion: '17',
      profile: withProfile ?? profile,
      style: style.toStyle(),
      elements: elements ?? const [kitchenSink],
      bgAlpha: .25,
      week: week,
      folder: folder,
      lockscreenAssetsDir: themeLayout.lockscreenAdvance,
      outputDir: themeLayout.parentDir,
    );
  }

  Future<Failure?> open(ThemeSpec spec, {String? week}) => container.read(
    themeSpecLoaderProvider,
  )(spec, baseDir: tmp.path, week: week);

  testWidgets('opening a spec and reading it back gives the same spec', (
    tester,
  ) async {
    await tester.runAsync(() async {
      final spec = editorSpec();
      final failure = await open(spec);
      expect(failure, isNull, reason: failure?.message);

      expect(container.read(themeSpecProvider)!.toJson(), spec.toJson());
    });
  });

  testWidgets('the spec title names the theme, not the wallpaper file', (
    tester,
  ) async {
    await tester.runAsync(() async {
      await open(editorSpec());
      final ws = container.read(wallpaperProvider);
      expect(ws.currentThemeName, 'Neon');
      expect(ws.currentPath, wallpaper);
      expect((ws.weekNum, ws.folderNum), (week, folder));
      expect(Directory(layout().root).existsSync(), isTrue);
    });
  });

  testWidgets('opening a custom home wallpaper keeps lockscreen wallpaper active', (
    tester,
  ) async {
    await tester.runAsync(() async {
      final homeWallpaper = p.join(tmp.path, 'walls', 'home.png');
      File(homeWallpaper)
        ..createSync(recursive: true)
        ..writeAsBytesSync(File(wallpaper).readAsBytesSync());

      final spec = editorSpec(homeWallpaperPath: homeWallpaper);
      final failure = await open(spec);

      expect(failure, isNull, reason: failure?.message);
      final state = container.read(wallpaperProvider);
      expect(state.currentPath, wallpaper);
      expect(state.homeWallpaperEnabled, isTrue);
      expect(state.homeWallpaperPath, homeWallpaper);
      expect(container.read(themeSpecProvider)!.wallpaper.toJson(), {
        'home': homeWallpaper,
        'lock': wallpaper,
      });
    });
  });

  testWidgets('the spec style wins over the colors taken from the wallpaper', (
    tester,
  ) async {
    await tester.runAsync(() async {
      await open(editorSpec());
      final s = container.read(iconEditorProvider);
      expect(s.bgColors, style.bgColors);
      expect(s.accentColor, style.accentColor);
      expect(s.shape, IconShape.heart);
      expect(s.ccTemplate, style.ccTemplate);
    });
  });

  testWidgets(
    'a spec-backed preset changes lockscreen without switching theme',
    (tester) async {
      await tester.runAsync(() async {
        final presetElement = kitchenSink.copyWith(font: 'Roboto');
        final spec = editorSpec(elements: [presetElement]);
        final currentWallpaper = p.join(tmp.path, 'walls', 'current.png');
        File(currentWallpaper)
          ..createSync(recursive: true)
          ..writeAsBytesSync(File(wallpaper).readAsBytesSync());
        final currentProfile = kUserProfiles[UserProfileType.rajat]!;
        await open(
          editorSpec(
            withProfile: currentProfile,
            themeName: 'Current Theme',
            wallpaperPath: currentWallpaper,
          ),
        );
        container.read(iconEditorProvider.notifier)
          ..setIconShape(IconShape.circle)
          ..setCcTemplate(ControlCenterTemplate.frostedGlass);

        final presetFile = File(
          p.join(PathConstants.presetPath, 'Neon', 'preset.json'),
        )..createSync(recursive: true);
        presetFile.writeAsStringSync(jsonEncode(spec.toJson()));

        final (elements, readFailure) = await PresetRepositoryImpl().load(
          presetFile.path,
        );
        expect(readFailure, isNull);
        expect(
          elements!.single.toJson(),
          presetElement
              .copyWith(
                unlockIconPath: p.join(
                  p.dirname(presetFile.path),
                  'unlock/icon.png',
                ),
                unlockTargetPath: p.join(
                  p.dirname(presetFile.path),
                  'unlock/target.png',
                ),
              )
              .toJson(),
        );

        final failure = await container
            .read(lockscreenProvider.notifier)
            .loadPreset(presetFile.path);
        expect(failure, isNull, reason: failure?.message);

        final workspace = container.read(wallpaperProvider);
        expect(workspace.currentPath, currentWallpaper);
        expect(workspace.currentThemeName, 'Current Theme');
        expect(
          container.read(activeUserProfileProvider)!.type,
          currentProfile.type,
        );
        expect(
          container.read(activeUserProfileProvider)!.iconFolder,
          currentProfile.iconFolder,
        );
        expect(container.read(iconEditorProvider).shape, IconShape.circle);
        expect(
          container.read(iconEditorProvider).ccTemplate,
          ControlCenterTemplate.frostedGlass,
        );
        final currentSpec = container.read(themeSpecProvider)!;
        expect(currentSpec.lockscreen.bgAlpha, spec.lockscreen.bgAlpha);
        expect(currentSpec.lockscreen.elements.single.type, kitchenSink.type);
      });
    },
  );

  testWidgets('saving a preset writes its spec and lockscreen preview', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (_) => const SizedBox(key: ValueKey('preset-context')),
        ),
      ),
    );
    await tester.runAsync(() async {
      await open(editorSpec(elements: const []));
      final context = tester.element(
        find.byKey(const ValueKey('preset-context')),
      );
      final failure = await container
          .read(lockscreenProvider.notifier)
          .savePreset('AI Sample', context: context);
      expect(failure, isNull, reason: failure?.message);

      final presetDir = Directory(
        p.join(PathConstants.presetPath, 'AI Sample'),
      );
      final presetFile = File(p.join(presetDir.path, 'preset.json'));
      expect(
        jsonDecode(presetFile.readAsStringSync()),
        editorSpec(elements: const []).toJson(),
      );
      final preview = img.decodePng(
        File(p.join(presetDir.path, 'preview.png')).readAsBytesSync(),
      );
      expect(preview, isNotNull);
    });
  });

  testWidgets(
    'an icon pack that is not the profile\'s becomes the style override',
    (tester) async {
      await tester.runAsync(() async {
        final pack = profile.iconFolder == 'u3' ? 'u4' : 'u3';
        final other = UserProfile(
          type: profile.type,
          iconFolder: pack,
          avatarAsset: profile.avatarAsset,
          fontApiUrl: profile.fontApiUrl,
          displayName: profile.displayName,
          authorTag: profile.authorTag,
        );
        final spec = editorSpec(withProfile: other);
        await open(spec);

        expect(container.read(activeUserProfileProvider)!.iconFolder, pack);
        expect(container.read(themeSpecProvider)!.toJson(), spec.toJson());
      });
    },
  );

  testWidgets('a spec without a week needs one, and the given week is used', (
    tester,
  ) async {
    await tester.runAsync(() async {
      final json = editorSpec().toJson()..remove('workspace');
      final spec = ThemeSpec.fromJson(json);

      final failure = await open(spec);
      expect(failure, isA<ValidationFailure>());
      expect(failure!.message, contains('week'));
      expect(container.read(wallpaperProvider).currentPath, isNull);

      expect(await open(spec, week: '7'), isNull);
      expect(container.read(wallpaperProvider).weekNum, '7');
    });
  });

  testWidgets('a missing wallpaper is reported and changes nothing', (
    tester,
  ) async {
    await tester.runAsync(() async {
      File(wallpaper).deleteSync();
      final failure = await open(editorSpec());
      expect(failure!.message, contains('Wallpaper not found'));
      expect(container.read(wallpaperProvider).currentPath, isNull);
    });
  });

  testWidgets('relative wallpaper paths resolve against the spec folder', (
    tester,
  ) async {
    await tester.runAsync(() async {
      final json = editorSpec().toJson();
      (json['wallpaper'] as Map)['home'] = p.join('walls', 'wall.png');
      expect(await open(ThemeSpec.fromJson(json)), isNull);
      expect(container.read(wallpaperProvider).currentPath, wallpaper);
    });
  });

  group('readThemeSpecFile', () {
    test('reads a spec the editor saved', () async {
      final file = File(p.join(tmp.path, 'Neon.json'))
        ..writeAsStringSync(jsonEncode(editorSpec().toJson()));
      final (spec, failure) = await readThemeSpecFile(file.path);
      expect(failure, isNull);
      expect(spec!.meta.title, 'Neon');
    });

    test('says what is wrong with a spec', () async {
      final file = File(p.join(tmp.path, 'bad.json'))
        ..writeAsStringSync('{"specVersion": 1}');
      final (spec, failure) = await readThemeSpecFile(file.path);
      expect(spec, isNull);
      expect(failure, isA<ValidationFailure>());
      expect(failure!.message, isNotEmpty);
    });

    test('reports invalid JSON and missing files', () async {
      final bad = File(p.join(tmp.path, 'broken.json'))..writeAsStringSync('{');
      expect((await readThemeSpecFile(bad.path)).$2, isA<ValidationFailure>());
      expect(
        (await readThemeSpecFile(p.join(tmp.path, 'none.json'))).$2,
        isA<ExportFailure>(),
      );
    });
  });

  testWidgets('save as writes the open theme to the chosen path', (
    tester,
  ) async {
    await tester.runAsync(() async {
      final spec = editorSpec();
      await open(spec);

      final target = p.join(tmp.path, 'out', 'Neon.json');
      Directory(p.dirname(target)).createSync();
      final failure = await container.read(themeSpecSaveAsProvider)(target);
      expect(failure, isNull, reason: failure?.message);
      expect(jsonDecode(File(target).readAsStringSync()), spec.toJson());
    });
  });

  test('save as without an open theme fails instead of writing', () async {
    final failure = await container.read(themeSpecSaveAsProvider)(
      p.join(tmp.path, 'x.json'),
    );
    expect(failure, isA<ValidationFailure>());
    expect(File(p.join(tmp.path, 'x.json')).existsSync(), isFalse);
  });

  test(
    'a wallpaper name only replaces the file name for its own wallpaper',
    () {
      const state = WallpaperState(
        paths: ['/a/one.png', '/a/two.png'],
        namedTheme: (path: '/a/one.png', name: 'Neon'),
      );
      expect(state.currentThemeName, 'Neon');
      expect(state.copyWith(index: 1).currentThemeName, 'two');
    },
  );
}
