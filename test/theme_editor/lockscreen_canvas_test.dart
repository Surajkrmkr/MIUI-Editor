import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:miui_icon_generator/theme_editor/domain/entities/element_widget.dart';
import 'package:miui_icon_generator/theme_editor/presentation/features/lockscreen/widgets/element_widget_preview.dart';
import 'package:miui_icon_generator/theme_editor/presentation/providers/element_provider.dart';
import 'package:miui_icon_generator/theme_editor/presentation/providers/service_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:theme_raster_flutter/theme_raster_flutter.dart';

/// Characterization test for the editor's lockscreen canvas. Regenerate the
/// golden with `UPDATE_GOLDENS=1 flutter test`.
const _goldenPath = 'test/theme_editor/goldens/lockscreen_canvas.json';

/// Per-channel tolerance on cell means, for antialiasing differences.
const _tolerance = 3;

class _Fixed extends ElementNotifier {
  _Fixed(this.fixed);
  final ElementState fixed;

  @override
  ElementState build() => fixed;
}

List<LockElement> _elements() => [
  for (final t in ElementType.values)
    LockElement(
      type: t,
      dx: 20,
      dy: 40,
      color: const Color(0xFFEEDD99),
      colorSecondary: const Color(0xFF3355FF),
      width: 300,
      height: 160,
      radius: 18,
    ),
  for (final s in AnalogStyle.values)
    LockElement(
      type: ElementType.analogClock,
      instanceId: s.name,
      analogStyle: s,
      width: 300,
      height: 300,
    ),
  for (final s in ShortcutStyle.values)
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
    ),
  for (final t in [
    ElementType.tapToUnlock,
    ElementType.slideToUnlock,
    ElementType.dragToUnlock,
  ])
    for (final s in UnlockSkin.values)
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
  // Placement: scale, rotation and alignment.
  const LockElement(
    type: ElementType.hourClock,
    instanceId: 'placed',
    dx: 0,
    dy: -100,
    scale: 1.5,
    angle: 20,
    align: Alignment(-0.4, 0.1),
    color: Color(0xFFFFFFFF),
  ),
];

Map<String, Object> _describe(img.Image image) {
  const cols = 3, rows = 6;
  final cells = <int>[];
  for (var r = 0; r < rows; r++) {
    for (var c = 0; c < cols; c++) {
      final x0 = image.width * c ~/ cols, x1 = image.width * (c + 1) ~/ cols;
      final y0 = image.height * r ~/ rows, y1 = image.height * (r + 1) ~/ rows;
      final sums = [0.0, 0.0, 0.0, 0.0];
      for (var y = y0; y < y1; y++) {
        for (var x = x0; x < x1; x++) {
          final p = image.getPixel(x, y);
          sums[0] += p.r;
          sums[1] += p.g;
          sums[2] += p.b;
          sums[3] += p.a;
        }
      }
      final n = (x1 - x0) * (y1 - y0);
      cells.addAll([for (final s in sums) (s / n).round()]);
    }
  }
  return {'w': image.width, 'h': image.height, 'cells': cells};
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
  final gc = (g['cells'] as List).cast<int>();
  final ac = (a['cells'] as List).cast<int>();
  for (var i = 0; i < gc.length; i++) {
    if ((gc[i] - ac[i]).abs() > _tolerance) {
      yield 'pixels changed: $key cell ${i ~/ 4}';
      return;
    }
  }
}

void main() {
  testWidgets(
    'lockscreen canvas matches the golden',
    (tester) async {
      lockscreenNow = () => DateTime(2026, 2, 8, 14, 36, 55);
      addTearDown(() => lockscreenNow = DateTime.now);
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(600, 900);
      addTearDown(tester.view.reset);
      await tester.runAsync(loadSdkFonts);
      SharedPreferences.setMockInitialValues({});
      final prefs = await tester.runAsync(SharedPreferences.getInstance);

      final actual = <String, Map<String, Object>>{};
      for (final el in _elements()) {
        final key = GlobalKey();
        await tester.pumpWidget(
          ProviderScope(
            key: UniqueKey(),
            overrides: [
              sharedPrefsProvider.overrideWithValue(prefs!),
              elementProvider.overrideWith(
                () => _Fixed(ElementState(elements: [el])),
              ),
            ],
            child: MaterialApp(
              debugShowCheckedModeBanner: false,
              home: Align(
                alignment: Alignment.topLeft,
                child: RepaintBoundary(
                  key: key,
                  child: const ElementWidgetPreview(),
                ),
              ),
            ),
          ),
        );
        // Image, SVG and font loading complete outside the fake-async zone.
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 60)),
        );
        await tester.pump();

        final bytes = await tester.runAsync(() async {
          final boundary =
              key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
          final image = await boundary.toImage();
          final data = await image.toByteData(format: ui.ImageByteFormat.png);
          return data!.buffer.asUint8List();
        });
        actual[el.name] = _describe(img.decodePng(Uint8List.fromList(bytes!))!);
      }

      final sorted = Map.fromEntries(
        actual.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
      );
      expect(sorted.length, _elements().length);

      final golden = File(_goldenPath);
      if (Platform.environment['UPDATE_GOLDENS'] == '1' ||
          !golden.existsSync()) {
        golden.writeAsStringSync(
          '${const JsonEncoder.withIndent(' ').convert(sorted)}\n',
        );
        // ignore: avoid_print
        print('Wrote golden: $_goldenPath (${sorted.length} canvases)');
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
    },
    timeout: const Timeout(Duration(minutes: 5)),
  );
}
