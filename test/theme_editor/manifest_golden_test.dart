import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:miui_icon_generator/theme_editor/domain/entities/element_widget.dart';
import 'package:miui_icon_generator/theme_editor/presentation/providers/element_provider.dart';
import 'package:miui_icon_generator/theme_editor/presentation/providers/lockscreen_provider.dart';

import 'fixtures/lock_elements.dart';

/// Pins the generated lockscreen `manifest.xml` across element types and styles.
/// Regenerate with `UPDATE_GOLDENS=1 flutter test`; set `DUMP_MANIFESTS=1` to
/// write every manifest to build/manifest_dump/ for diffing.
const _goldenPath = 'test/theme_editor/goldens/manifest_hashes.json';

typedef _Case = ({String id, List<LockElement> elements, double bgAlpha});

List<_Case> _cases() {
  final out = <_Case>[];
  void add(String id, List<LockElement> els, {double bgAlpha = 0}) =>
      out.add((id: id, elements: els, bgAlpha: bgAlpha));

  add('empty', const []);
  add('empty_bgAlpha', const [], bgAlpha: .35);

  for (final t in ElementType.values) {
    add('type/${t.name}', [LockElement(type: t)]);
  }

  for (final s in CalendarStyle.values) {
    for (final rows in [1, 2, 6]) {
      add('calendar/${s.name}/rows$rows', [
        LockElement(
          type: ElementType.calendarGrid,
          calendarStyle: s,
          calendarRows: rows,
          calendarShowMonth: rows != 2,
          calendarShowWeekdays: rows != 1,
          width: 420,
          height: 360,
          color: const Color(0xFFEEEEEE),
          strokeColor: const Color(0xFFCC3333),
          borderColor: const Color(0xFF112233),
          colorSecondary: const Color(0xFF3355FF),
        ),
      ]);
    }
  }

  for (final s in ShortcutStyle.values) {
    for (final e in ShortcutEdge.values) {
      add('shortcut/${s.name}/${e.name}', [
        LockElement(
          type: ElementType.shortcutSet,
          shortcutStyle: s,
          shortcutEdge: e,
          width: 300,
          dx: 12,
          dy: -20,
          angle: 15,
          scale: 1.2,
        ),
      ]);
    }
  }
  add('shortcut/custom_apps', const [
    LockElement(
      type: ElementType.shortcutSet,
      shortcutApps: 'camera,gallery,com.example.app,torch',
    ),
  ]);

  for (final t in [
    ElementType.tapToUnlock,
    ElementType.slideToUnlock,
    ElementType.dragToUnlock,
    ElementType.swipeUpUnlock,
  ]) {
    for (final s in UnlockSkin.values) {
      for (final a in [
        Alignment.centerLeft,
        Alignment.center,
        Alignment.centerRight,
      ]) {
        add('unlock/${t.name}/${s.name}/${a.toString()}', [
          LockElement(
            type: t,
            unlockSkin: s,
            align: a,
            width: 360,
            height: 120,
            unlockText: 'Slide',
            unlockInline: s.index.isEven,
            unlockAccent: const Color(0xFF22AA66),
            colorSecondary: const Color(0xFF334455),
          ),
        ]);
      }
    }
    for (final icon in UnlockIcon.values) {
      add('unlock/${t.name}/icon_${icon.name}', [
        LockElement(type: t, unlockIcon: icon, unlockIconPath: 'unlock/i.png'),
      ]);
    }
  }

  for (final s in AnalogStyle.values) {
    add('analog/${s.name}', [
      LockElement(type: ElementType.analogClock, analogStyle: s),
    ]);
  }

  for (final t in [
    ElementType.hourClock,
    ElementType.dateTimeText1,
    ElementType.normalText1,
    ElementType.weatherTemp,
    ElementType.batteryText,
  ]) {
    for (final a in [
      Alignment.centerLeft,
      Alignment.center,
      Alignment.centerRight,
    ]) {
      add('text/${t.name}/${a.toString()}', [
        LockElement(
          type: t,
          align: a,
          fontWeight: FontWeight.w700,
          color: const Color(0xCC336699),
          strokeWidth: 2,
          strokeColor: const Color(0xFF111111),
          useSeparateColors: true,
          colorDigit1: const Color(0xFF445566),
          colorDigit2: const Color(0xFF778899),
          isShort: true,
          isWrap: true,
          angle: 30,
          dx: 25,
          dy: -40,
          scale: .9,
        ),
      ]);
    }
  }

  add('animations/many', [
    const LockElement(
      type: ElementType.hourClock,
      animations: [
        ElementAnimationTrack(
          type: ElementAnimation.position,
          startX: 3,
          startY: 4,
        ),
        ElementAnimationTrack(
          type: ElementAnimation.rotation,
          ease: MamlEase.bounceEaseOut,
        ),
        ElementAnimationTrack(type: ElementAnimation.alpha, loop: false),
        ElementAnimationTrack(
          type: ElementAnimation.scale,
          ease: MamlEase.elasticEaseInOut,
        ),
        ElementAnimationTrack(
          type: ElementAnimation.size,
          amount: 20,
          offsetY: 5,
        ),
      ],
    ),
    const LockElement(
      type: ElementType.rectangleShape,
      animation: ElementAnimation.size,
      animationDuration: 800,
    ),
  ]);

  add('global/video', const [LockElement(type: ElementType.videoWallpaper)]);
  add('global/weather', const [
    LockElement(type: ElementType.weatherTemp),
    LockElement(type: ElementType.weatherIconClock),
  ]);
  add('global/steps', const [
    LockElement(type: ElementType.stepsCount),
    LockElement(
      type: ElementType.arcShape,
      progressSource: ArcProgressSource.steps,
    ),
  ]);
  add('global/hidden', [
    const LockElement(type: ElementType.hourClock, isVisible: false),
    const LockElement(type: ElementType.minClock),
  ]);
  add('global/instances', const [
    LockElement(
      type: ElementType.normalText1,
      instanceId: '2',
      text: 'A & B <c>',
    ),
    LockElement(type: ElementType.normalText1, instanceId: '3', text: "it's"),
  ]);
  add('global/kitchen_sink', const [kitchenSink]);
  add('global/everything', [
    for (final t in ElementType.values) LockElement(type: t),
  ], bgAlpha: .5);

  return out;
}

void main() {
  test('manifest.xml output matches the golden for every case', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(lockscreenProvider.notifier);

    final dump = Platform.environment['DUMP_MANIFESTS'] == '1';
    final actual = <String, Map<String, Object>>{};
    for (final c in _cases()) {
      final xml = notifier
          .buildManifest(ElementState(elements: c.elements, bgAlpha: c.bgAlpha))
          .toXmlString();
      actual[c.id] = {
        'len': xml.length,
        'sha': sha256.convert(utf8.encode(xml)).toString().substring(0, 16),
      };
      if (dump) {
        final f = File('build/manifest_dump/${c.id}.xml')
          ..createSync(recursive: true);
        f.writeAsStringSync(xml);
      }
    }

    final golden = File(_goldenPath);
    if (Platform.environment['UPDATE_GOLDENS'] == '1' || !golden.existsSync()) {
      golden.parent.createSync(recursive: true);
      golden.writeAsStringSync(
        '${const JsonEncoder.withIndent(' ').convert(actual)}\n',
      );
      return;
    }
    final expected = (jsonDecode(golden.readAsStringSync()) as Map).map(
      (k, v) => MapEntry(k as String, Map<String, Object>.from(v as Map)),
    );
    final changed = [
      for (final k in {...expected.keys, ...actual.keys})
        if (jsonEncode(expected[k]) != jsonEncode(actual[k])) k,
    ];
    expect(changed, isEmpty, reason: '${changed.length} manifests differ');
  });
}
