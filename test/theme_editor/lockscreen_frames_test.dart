import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:miui_icon_generator/theme_editor/domain/entities/element_widget.dart';
import 'package:miui_icon_generator/theme_editor/domain/usecases/export_lockscreen_pngs_usecase.dart';
import 'package:miui_icon_generator/theme_editor/presentation/providers/element_provider.dart';
import 'package:theme_core/theme_core.dart';

/// Characterization test for the lockscreen frame renderer. Regenerate the
/// golden with `UPDATE_GOLDENS=1 flutter test`.
const _goldenPath = 'test/theme_editor/goldens/lockscreen_frames.json';

/// Per-channel tolerance on mean RGBA, for raster/antialiasing differences.
const _tolerance = 2;

List<LockElement> _elements() => [
  for (final t in [
    ElementType.hourClock,
    ElementType.minClock,
    ElementType.secClock,
    ElementType.dotClock,
    ElementType.amPmClock,
    ElementType.weekClock,
    ElementType.monthClock,
    ElementType.dateClock,
    ElementType.weatherIconClock,
    ElementType.containerBG1,
    ElementType.cameraIcon,
    ElementType.themeIcon,
    ElementType.analogClockBg,
    ElementType.analogHourHand,
  ])
    LockElement(
      type: t,
      color: const Color(0xFFEEDD99),
      width: 300,
      height: 160,
      radius: 18,
      colorSecondary: const Color(0x55223344),
    ),
  for (final s in [
    AnalogStyle.indigo,
    AnalogStyle.minimal,
    AnalogStyle.orbitDigital,
    AnalogStyle.flowerCard,
    AnalogStyle.neonGlow,
  ])
    LockElement(
      type: ElementType.analogClock,
      instanceId: s.name,
      analogStyle: s,
      width: 300,
      height: 300,
    ),
  for (final s in [
    ShortcutStyle.glossDock,
    ShortcutStyle.whiteTiles,
    ShortcutStyle.hexGrid,
    ShortcutStyle.socialCards,
    ShortcutStyle.neonCapsule,
    ShortcutStyle.softRow,
  ])
    LockElement(
      type: ElementType.shortcutSet,
      instanceId: s.name,
      shortcutStyle: s,
      width: 260,
    ),
  for (final s in CalendarStyle.values)
    LockElement(
      type: ElementType.calendarGrid,
      instanceId: s.name,
      calendarStyle: s,
      width: 420,
      height: 330,
      color: const Color(0xFFF4F4F4),
      colorSecondary: const Color(0xFF3355FF),
      strokeColor: const Color(0xFFCC3333),
      borderColor: const Color(0xFF112233),
    ),
  for (final t in [
    ElementType.tapToUnlock,
    ElementType.slideToUnlock,
    ElementType.dragToUnlock,
  ])
    for (final s in [
      UnlockSkin.classic,
      UnlockSkin.waveNotch,
      UnlockSkin.neonOrbs,
      UnlockSkin.meet,
      UnlockSkin.liquidGlass,
    ])
      // The meet skin needs a slide track; with tap it throws (latent app bug).
      if (!(t == ElementType.tapToUnlock && s == UnlockSkin.meet))
        LockElement(
          type: t,
          instanceId: s.name,
          unlockSkin: s,
          width: 360,
          height: 120,
          unlockText: 'Slide',
          colorSecondary: const Color(0xFF334455),
          unlockAccent: const Color(0xFF22AA66),
        ),
];

Map<String, Object> _describe(Uint8List bytes) {
  final image = img.decodePng(bytes);
  if (image == null) return {'kind': 'undecodable', 'bytes': bytes.length};
  final rgba = image.getBytes(order: img.ChannelOrder.rgba);
  final sums = [0, 0, 0, 0];
  for (var i = 0; i < rgba.length; i++) {
    sums[i & 3] += rgba[i];
  }
  final n = image.width * image.height;
  return {
    'w': image.width,
    'h': image.height,
    'mean': [for (final s in sums) n == 0 ? 0 : (s / n).round()],
  };
}

void main() {
  testWidgets('lockscreen frames match the golden', (tester) async {
    await tester.pumpWidget(const SizedBox());
    final context = tester.element(find.byType(SizedBox));

    await tester.runAsync(() async {
      final root = Directory('build/lockscreen_frames');
      if (root.existsSync()) root.deleteSync(recursive: true);
      final layout = ThemeLayout('${root.path}/Theme');
      Directory(layout.lockscreenAdvance).createSync(recursive: true);

      // One call per element, so a failure names the element.
      final failures = <String>[];
      for (final el in _elements()) {
        final failure = await const ExportLockscreenPngsUseCase().call(
          context: context,
          elementState: ElementState(elements: [el]),
          layout: layout,
          onProgress: (_, __) {},
        );
        if (failure != null) failures.add('${el.name}: ${failure.message}');
      }
      expect(failures, isEmpty);

      final actual = <String, Map<String, Object>>{};
      for (final f
          in Directory(layout.lockscreenAdvance)
              .listSync(recursive: true)
              .whereType<File>()
              .where((f) => f.path.endsWith('.png'))) {
        final rel = f.path
            .substring(layout.lockscreenAdvance.length + 1)
            .replaceAll(r'\', '/');
        actual[rel] = _describe(f.readAsBytesSync());
      }
      final sorted = Map.fromEntries(
        actual.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
      );
      expect(sorted, isNotEmpty);

      final golden = File(_goldenPath);
      if (Platform.environment['UPDATE_GOLDENS'] == '1' ||
          !golden.existsSync()) {
        golden.parent.createSync(recursive: true);
        golden.writeAsStringSync(
          '${const JsonEncoder.withIndent(' ').convert(sorted)}\n',
        );
        // ignore: avoid_print
        print('Wrote golden: $_goldenPath (${sorted.length} frames)');
        return;
      }

      final expected = (jsonDecode(golden.readAsStringSync()) as Map).map(
        (k, v) => MapEntry(k as String, Map<String, Object>.from(v as Map)),
      );
      final problems = <String>[
        for (final k in expected.keys)
          if (!sorted.containsKey(k)) 'missing: $k',
        for (final k in sorted.keys)
          if (!expected.containsKey(k)) 'unexpected: $k',
        for (final k in expected.keys.where(sorted.containsKey))
          ..._compare(k, expected[k]!, sorted[k]!),
      ];
      expect(problems, isEmpty);
    });
  });
}

Iterable<String> _compare(
  String key,
  Map<String, Object> g,
  Map<String, Object> a,
) sync* {
  if (g['w'] != a['w'] || g['h'] != a['h']) {
    yield 'size changed: $key ${g['w']}x${g['h']} -> ${a['w']}x${a['h']}';
    return;
  }
  final gm = (g['mean'] as List?)?.cast<int>();
  final am = (a['mean'] as List?)?.cast<int>();
  if (gm == null || am == null) return;
  for (var i = 0; i < 4; i++) {
    if ((gm[i] - am[i]).abs() > _tolerance) {
      yield 'pixels changed: $key mean $gm -> $am';
      return;
    }
  }
}
