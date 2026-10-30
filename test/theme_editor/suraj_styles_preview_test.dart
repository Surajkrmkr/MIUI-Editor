import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart' show FontLoader;
import 'package:flutter_test/flutter_test.dart';
import 'package:miui_icon_generator/theme_editor/domain/entities/builtin_widget_styles.dart';
import 'package:miui_icon_generator/theme_editor/domain/entities/element_widget.dart';
import 'package:miui_icon_generator/theme_editor/domain/entities/suraj_widget_styles.dart';
import 'package:miui_icon_generator/theme_editor/domain/entities/widget_style.dart';
import 'package:theme_raster_flutter/theme_raster_flutter.dart'
    show LockscreenCanvas, loadSdkFonts;

/// Set SURAJ_PREVIEW_DIR to write a contact sheet per category.
const _wallpaper = Color(0xFF3A3F4B);

Future<void> _sheet(
  WidgetTester tester,
  String name,
  List<(String, List<LockElement>, Color)> cells,
) async {
  if (cells.isEmpty) return;
  final dir = Platform.environment['SURAJ_PREVIEW_DIR'];
  const cellW = 300.0, cellH = 330.0, cols = 5;
  final key = GlobalKey();
  final rows = (cells.length + cols - 1) ~/ cols;
  tester.view.devicePixelRatio = 2;
  tester.view.physicalSize = Size(cellW * cols * 2, cellH * rows * 2);
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    Directionality(
      textDirection: TextDirection.ltr,
      child: MediaQuery(
        data: const MediaQueryData(),
        child: RepaintBoundary(
          key: key,
          child: ColoredBox(
            color: Colors.black,
            child: Wrap(
              children: [
                for (final (label, elements, background) in cells)
                  SizedBox(
                    width: cellW,
                    height: cellH,
                    child: Column(
                      children: [
                        SizedBox(
                          width: cellW,
                          height: 300,
                          child: ColoredBox(
                            color: background,
                            child: ClipRect(
                              child: OverflowBox(
                                alignment: Alignment(
                                  0,
                                  (elements
                                              .map((e) => e.dy)
                                              .reduce((a, b) => a + b) /
                                          elements.length /
                                          150)
                                      .clamp(-1.0, 1.0),
                                ),
                                minHeight: 600,
                                maxHeight: 600,
                                minWidth: 0,
                                maxWidth: cellW,
                                child: DefaultTextStyle(
                                  style: const TextStyle(fontFamily: 'Roboto'),
                                  child: LockscreenCanvas(elements: elements),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Text(
                          label,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontFamily: 'Roboto',
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  expect(tester.takeException(), isNull);
  if (dir == null) return;
  await tester.runAsync(() async {
    final boundary =
        key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage();
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    await Directory(dir).create(recursive: true);
    await File('$dir/$name.png').writeAsBytes(bytes!.buffer.asUint8List());
  });
}

void main() {
  final sets = [surajStudioStyles];

  test('Suraj gets ten new looks for each category, all distinct', () {
    final ids = <String>{};
    for (final set in sets) {
      expect(set.user, 'suraj');
      for (final style in set.styles) {
        expect(ids.add(style.id), isTrue, reason: style.id);
      }
    }
    expect(ids.length, 102);
    Iterable<WidgetStyle> of(ElementType t) =>
        sets.expand((s) => s.styles).where((s) => s.type == t);
    expect(of(ElementType.analogClock), hasLength(10));
    // Ten older looks, plus ten new ones in each of the 1, 2 and 6 row layouts.
    expect(of(ElementType.calendarGrid), hasLength(40));
    expect(of(ElementType.tapToUnlock), hasLength(20));
    expect(of(ElementType.slideToUnlock), hasLength(20));
    expect(of(ElementType.shortcutSet), hasLength(12));
    expect(builtinClockSets.where((s) => s.user == 'suraj'), hasLength(10));
    expect(builtinWeatherSets.where((s) => s.user == 'suraj'), hasLength(12));
    expect(builtinBatterySets.where((s) => s.user == 'suraj'), hasLength(12));
    // Every look names its own art, so none reuses an earlier one.
    final looks = <Object?>{
      for (final s in of(ElementType.analogClock)) s.appearance['analogStyle'],
      for (final s in of(ElementType.calendarGrid))
        s.appearance['calendarStyle'],
      for (final s in of(ElementType.shortcutSet))
        s.appearance['shortcutStyle'],
      for (final s in [
        ...of(ElementType.tapToUnlock),
        ...of(ElementType.slideToUnlock),
      ])
        s.appearance['unlockSkin'],
    };
    expect(looks, hasLength(82));
    final shared = builtinStyleSets
        .where((s) => s.user != 'suraj' || !sets.contains(s))
        .expand((s) => s.styles);
    final taken = {
      for (final s in shared) ...[
        s.appearance['analogStyle'],
        s.appearance['calendarStyle'],
        s.appearance['unlockSkin'],
        s.appearance['shortcutStyle'],
      ],
    };
    expect(looks.intersection(taken), isEmpty);
  });

  testWidgets('every new look renders', (tester) async {
    await tester.runAsync(loadSdkFonts);
    // SURAJ_FONT_DIR holds <Family name>.ttf files, to preview clock sets in
    // their real fonts instead of Roboto.
    final fontDir = Platform.environment['SURAJ_FONT_DIR'];
    if (fontDir != null) {
      await tester.runAsync(() async {
        for (final file in Directory(fontDir).listSync().whereType<File>()) {
          if (!file.path.endsWith('.ttf')) continue;
          final name = file.uri.pathSegments.last.replaceAll('.ttf', '');
          final loader = FontLoader(name)
            ..addFont(
              Future.value(ByteData.sublistView(file.readAsBytesSync())),
            );
          await loader.load();
        }
      });
    }
    for (final (name, set, type) in [
      ('analog', surajStudioStyles, ElementType.analogClock),
      ('calendar', surajStudioStyles, ElementType.calendarGrid),
      ('tap', surajStudioStyles, ElementType.tapToUnlock),
      ('slide', surajStudioStyles, ElementType.slideToUnlock),
      ('shortcut', surajStudioStyles, ElementType.shortcutSet),
    ]) {
      await _sheet(tester, name, [
        for (final s in set.styles.where((s) => s.type == type))
          (s.name, [s.applyTo(LockElement(type: type))], _wallpaper),
      ]);
    }
    for (final (name, all) in [
      ('weather', builtinWeatherSets),
      ('battery', builtinBatterySets),
    ]) {
      await _sheet(tester, name, [
        for (final p in all) (p.name, p.elements, p.background),
      ]);
    }
    await _sheet(tester, 'clock', [
      for (final p in builtinClockSets.where((p) => p.user == 'suraj'))
        (
          p.name,
          [
            for (final e in p.elements)
              fontDir == null ? e.copyWith(font: 'Roboto') : e,
          ],
          p.background,
        ),
    ]);
  });
}
