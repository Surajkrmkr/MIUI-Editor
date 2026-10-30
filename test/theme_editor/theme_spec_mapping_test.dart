import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:miui_icon_generator/theme_editor/domain/entities/element_widget.dart';
import 'package:miui_icon_generator/theme_editor/domain/entities/builtin_widget_styles.dart';
import 'package:miui_icon_generator/theme_editor/domain/entities/lock_element_spec_bridge.dart';
import 'package:miui_icon_generator/theme_editor/domain/entities/user_profile.dart';
import 'package:miui_icon_generator/theme_editor/domain/entities/widget_style.dart'
    as editor_style;
import 'package:miui_icon_generator/theme_editor/domain/usecases/build_theme_spec.dart';
import 'package:miui_icon_generator/theme_editor/presentation/providers/icon_editor_provider.dart';
import 'package:miui_icon_generator/theme_editor/presentation/providers/element_provider.dart';
import 'package:theme_core/theme_core.dart';

import 'fixtures/lock_elements.dart';

void main() {
  final profile = kUserProfiles[UserProfileType.suraj]!;

  const state = IconEditorState(
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

  ThemeSpec build({
    String designer = 'Suraj',
    List<LockElement>? elements,
    String? homeWallpaperPath,
  }) => buildThemeSpec(
    themeName: 'Neon',
    wallpaperPath: '/walls/neon.jpg',
    homeWallpaperPath: homeWallpaperPath,
    designer: designer,
    authorTag: 'Sj',
    uiVersion: '17',
    profile: profile,
    style: state.toStyle(),
    elements: elements ?? const [kitchenSink],
    bgAlpha: .25,
    week: '12',
    folder: '3',
    lockscreenAssetsDir: '/themes/Neon/lockscreen/advance',
    outputDir: '/themes',
  );

  test('the editor state becomes a spec that survives JSON', () {
    final spec = build();
    expect(spec.meta.title, 'Neon');
    expect(spec.meta.profile, 'suraj');
    expect(spec.icons.pack, profile.iconFolder);
    expect(spec.systemUi.accent, const Rgba(0xFF3D7BFF));
    expect(spec.lockscreen.bgAlpha, .25);
    expect(spec.output.dir, '/themes');

    final json = jsonDecode(jsonEncode(spec.toJson()));
    expect(ThemeSpec.fromJson(json).toJson(), json);
  });

  test(
    'custom homescreen wallpaper keeps the active wallpaper as lockscreen',
    () {
      final spec = build(homeWallpaperPath: '/walls/home.jpg');
      expect(spec.wallpaper.home, '/walls/home.jpg');
      expect(spec.wallpaper.lock, '/walls/neon.jpg');
    },
  );

  test(
    'built-in clock presets are complete and flashlight is a system icon',
    () {
      expect(editor_style.WidgetStyle.supports(ElementType.hourClock), isTrue);
      expect(builtinClockSets, hasLength(25));
      expect(builtinClockSets.every((set) => set.elements.length > 1), isTrue);
      expect(ElementType.flashlightIcon.isIcon, isTrue);
      expect(
        kElementGroups['System Icons'],
        contains(ElementType.flashlightIcon),
      );
      expect(
        builtinShortcutStyles.styles.any(
          (style) => style.appearance['shortcutApps'] == 'flashlight,camera',
        ),
        isFalse,
      );
    },
  );

  test('clock sets replace clock parts in one undoable operation', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(elementProvider.notifier);
    notifier.setAll(const [
      LockElement(type: ElementType.hourClock),
      LockElement(type: ElementType.minClock),
      LockElement(type: ElementType.normalText1),
    ]);

    notifier.applyClockSet(builtinClockSets.first.elements);
    final applied = container.read(elementProvider).elements;
    expect(
      applied.where((element) => clockSetElementTypes.contains(element.type)),
      hasLength(builtinClockSets.first.elements.length),
    );
    expect(
      applied.any((element) => element.type == ElementType.normalText1),
      isTrue,
    );

    notifier.undo();
    final restored = container.read(elementProvider).elements;
    expect(restored.map((element) => element.type), [
      ElementType.hourClock,
      ElementType.minClock,
      ElementType.normalText1,
    ]);
  });

  test('flashlight system icon emits the MAML torch toggle button', () {
    final xml = const ManifestBuilder().build(const [
      LockElementSpec(type: ElementType.flashlightIcon),
    ]).toXmlString();
    expect(xml, contains("src='icon/flashlight.png'"));
    expect(xml, contains("<VariableCommand name='lightSwitch'"));
    expect(xml, contains("action='miui.intent.action.TOGGLE_TORCH'"));
    expect(xml, contains("name='miui.intent.extra.IS_ENABLE'"));
  });

  test('lockscreen elements are carried over unchanged', () {
    final spec = build(
      elements: [
        kitchenSink,
        const LockElement(type: ElementType.hourClock),
      ],
    );
    expect(spec.lockscreen.elements.map((e) => e.toJson()).toList(), [
      kitchenSink.toJson(),
      const LockElement(type: ElementType.hourClock).toJson(),
    ]);
  });

  test('fonts that need a file are listed once, without paths', () {
    final spec = build(
      elements: const [
        LockElement(type: ElementType.hourClock, font: 'gf:Inter'),
        LockElement(type: ElementType.minClock, font: 'gf:Inter'),
        LockElement(type: ElementType.dateClock, font: 'Roboto'),
        LockElement(
          type: ElementType.weekClock,
          font: 'rf:Fira|https://x.test/f.ttf',
        ),
      ],
    );
    expect(spec.fonts.map((f) => f.ref), [
      'gf:Inter',
      'rf:Fira|https://x.test/f.ttf',
    ]);
    expect(spec.fonts.every((f) => f.path == null), isTrue);
  });

  test('icon editor state round-trips through the spec', () {
    final spec = build();
    final restored = IconEditorState.fromStyle(spec.iconStyle);
    final again = build().icons.toJson();
    expect(
      IconsSpec.fromStyle(
        restored.toStyle(),
        pack: profile.iconFolder,
      ).toJson(),
      again,
    );
    expect(restored.accentColor, state.accentColor);
    expect(restored.ccTemplate, state.ccTemplate);
    expect(restored.bgGradStart, Alignment.topCenter);
    expect(restored.bgColors, state.bgColors);
  });

  test('elements read back from a spec equal the originals', () {
    final spec = ThemeSpec.fromJson(jsonDecode(jsonEncode(build().toJson())));
    final back = spec.lockscreen.elements.single.toLockElement();
    expect(back.toJson(), kitchenSink.toJson());
  });
}
