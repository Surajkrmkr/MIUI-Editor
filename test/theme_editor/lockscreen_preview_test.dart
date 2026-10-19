import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:theme_core/theme_core.dart';
import 'package:theme_raster_flutter/theme_raster_flutter.dart';

void main() {
  late Directory tmp;
  late ThemeLayout layout;

  setUp(() {
    tmp = Directory.systemTemp.createTempSync('lockscreen_preview_test');
    layout = ThemeLayout(p.join(tmp.path, 'Theme'));
  });
  tearDown(() => tmp.deleteSync(recursive: true));

  void solid(String path, int w, int h, img.Color c) {
    File(path)
      ..createSync(recursive: true)
      ..writeAsBytesSync(
        img.encodePng(img.Image(width: w, height: h)..clear(c)),
      );
  }

  Future<img.Image> render(
    WidgetTester tester,
    List<LockElementSpec> elements, {
    double bgAlpha = 0,
    String name = 'preview.png',
  }) async {
    await tester.pumpWidget(const SizedBox());
    final context = tester.element(find.byType(SizedBox));
    final out = p.join(tmp.path, name);
    final failure = await tester.runAsync(
      () => const LockscreenPreviewRenderer().render(
        context: context,
        layout: layout,
        elements: elements,
        bgAlpha: bgAlpha,
        outPath: out,
      ),
    );
    expect(failure, isNull, reason: failure?.message);
    return img.decodePng(File(out).readAsBytesSync())!;
  }

  testWidgets('draws the wallpaper at 2x of the 277x600 canvas', (
    tester,
  ) async {
    await tester.runAsync(loadSdkFonts);
    solid(
      p.join(layout.lockscreenAdvance, 'bg.png'),
      20,
      40,
      img.ColorRgb8(0, 0, 200),
    );

    final im = await render(tester, const []);

    expect((im.width, im.height), (554, 1200));
    for (final (x, y) in [(0, 0), (553, 1199), (277, 600)]) {
      expect(im.getPixel(x, y).b, 200, reason: 'pixel $x,$y');
    }
  });

  testWidgets(
    'the base lockscreen sits inside the screen, clear of the edges',
    (tester) async {
      await tester.runAsync(loadSdkFonts);
      solid(layout.defaultLockWallpaper, 20, 40, img.ColorRgb8(0, 0, 0));
      final elements = ThemeSpec.parse(
        baseSpec(title: 'T'),
      ).spec!.lockscreen.elements;

      final im = await render(tester, elements);

      var left = im.width, right = 0, top = im.height, bottom = 0;
      for (var y = 0; y < im.height; y++) {
        for (var x = 0; x < im.width; x++) {
          final c = im.getPixel(x, y);
          if (c.r + c.g + c.b > 60) {
            if (x < left) left = x;
            if (x > right) right = x;
            if (y < top) top = y;
            if (y > bottom) bottom = y;
          }
        }
      }
      // 12 canvas units of margin is 24 px at 2x.
      expect(left, greaterThanOrEqualTo(24));
      expect(im.width - 1 - right, greaterThanOrEqualTo(24));
      expect(top, greaterThan(100), reason: 'clock starts below the top zone');
      expect(
        im.height - 1 - bottom,
        greaterThanOrEqualTo(60),
        reason: 'unlock keeps a bottom margin',
      );
      expect(bottom, greaterThan(1000), reason: 'unlock sits near the bottom');
    },
  );

  testWidgets('a transparent bg.png lets the wallpaper show', (tester) async {
    await tester.runAsync(loadSdkFonts);
    solid(layout.defaultLockWallpaper, 20, 40, img.ColorRgb8(0, 200, 0));
    File(p.join(layout.lockscreenAdvance, 'bg.png'))
      ..createSync(recursive: true)
      ..writeAsBytesSync(
        img.encodePng(img.Image(width: 20, height: 40, numChannels: 4)),
      );

    final im = await render(tester, const []);

    expect(im.getPixel(10, 10).g, 200);
  });

  testWidgets('falls back to the lock wallpaper when bg.png is absent', (
    tester,
  ) async {
    solid(layout.defaultLockWallpaper, 20, 40, img.ColorRgb8(0, 200, 0));
    final im = await render(tester, const []);
    expect(im.getPixel(10, 10).g, 200);
  });

  testWidgets('bgAlpha darkens the wallpaper', (tester) async {
    solid(layout.defaultLockWallpaper, 20, 40, img.ColorRgb8(0, 200, 0));
    final im = await render(tester, const [], bgAlpha: .5);
    expect(im.getPixel(10, 10).g, inInclusiveRange(95, 105));
  });

  testWidgets('an element uses its exported PNG from lockscreen/advance', (
    tester,
  ) async {
    solid(layout.defaultLockWallpaper, 20, 40, img.ColorRgb8(0, 0, 0));
    solid(
      p.join(layout.lockscreenAdvance, 'icon', 'camera.png'),
      100,
      100,
      img.ColorRgb8(255, 0, 0),
    );

    final im = await render(tester, const [
      LockElementSpec(type: ElementType.cameraIcon, width: 200, height: 200),
    ]);

    expect(im.getPixel(277, 600).r, 255);
    expect(im.getPixel(277, 600).g, 0);
    expect(im.getPixel(20, 20).r, 0);
  });

  testWidgets('text is drawn with a real font, not placeholder blocks', (
    tester,
  ) async {
    await tester.runAsync(loadSdkFonts);
    solid(layout.defaultLockWallpaper, 20, 40, img.ColorRgb8(0, 0, 0));

    final im = await render(tester, const [
      LockElementSpec(
        type: ElementType.hourClock,
        color: Rgba.rgb(255, 255, 255),
      ),
    ]);

    var lit = 0, minX = im.width, maxX = 0, minY = im.height, maxY = 0;
    for (final px in im) {
      if (px.r > 128) {
        lit++;
        if (px.x < minX) minX = px.x;
        if (px.x > maxX) maxX = px.x;
        if (px.y < minY) minY = px.y;
        if (px.y > maxY) maxY = px.y;
      }
    }
    expect(lit, greaterThan(200));
    // A block glyph would fill its box; "02" in Roboto leaves holes.
    expect(lit / ((maxX - minX + 1) * (maxY - minY + 1)), lessThan(0.7));
  });

  testWidgets('two renders of the same spec are identical', (tester) async {
    solid(layout.defaultLockWallpaper, 20, 40, img.ColorRgb8(10, 20, 30));
    const elements = [
      LockElementSpec(type: ElementType.calendarGrid, width: 420, height: 330),
      LockElementSpec(type: ElementType.analogClock, width: 300, height: 300),
    ];
    final a = await render(tester, elements, name: 'a.png');
    final b = await render(tester, elements, name: 'b.png');
    expect(
      Uint8List.fromList(a.toUint8List()),
      Uint8List.fromList(b.toUint8List()),
    );
  });

  testWidgets('the real clock is restored afterwards', (tester) async {
    solid(layout.defaultLockWallpaper, 20, 40, img.ColorRgb8(0, 0, 0));
    final before = lockscreenNow;
    await render(tester, const []);
    expect(lockscreenNow, same(before));
  });
}
