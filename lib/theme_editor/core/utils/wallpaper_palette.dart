import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// Colours extracted from a wallpaper for theming (vivid primary/secondary
/// plus soft light/dark tones). Falls back to sensible tones for greyscale art.
class WallpaperPalette {
  const WallpaperPalette({
    required this.primary,
    required this.secondary,
    required this.light,
    required this.dark,
  });

  final Color primary, secondary, light, dark;

  @override
  bool operator ==(Object other) =>
      other is WallpaperPalette &&
      other.primary == primary &&
      other.secondary == secondary &&
      other.light == light &&
      other.dark == dark;

  @override
  int get hashCode => Object.hash(primary, secondary, light, dark);

  /// Builds a palette from a single colour (used when no wallpaper is loaded).
  factory WallpaperPalette.fromSeed(Color seed, [Color? second]) {
    final h = HSLColor.fromColor(seed);
    return WallpaperPalette(
      primary: _vivid(h),
      secondary: _vivid(
        second != null
            ? HSLColor.fromColor(second)
            : h.withHue((h.hue + 40) % 360),
      ),
      light: h.withSaturation(.35).withLightness(.9).toColor(),
      dark: h.withSaturation(.3).withLightness(.14).toColor(),
    );
  }

  static Future<WallpaperPalette> fromImage(ui.Image image) async {
    const w = 48, h = 96;
    final rec = ui.PictureRecorder();
    Canvas(rec).drawImageRect(
      image,
      Offset.zero & Size(image.width.toDouble(), image.height.toDouble()),
      const Rect.fromLTWH(0, 0, 48, 96),
      Paint()..filterQuality = FilterQuality.medium,
    );
    final small = await rec.endRecording().toImage(w, h);
    final data = (await small.toByteData(format: ui.ImageByteFormat.rawRgba))!;
    small.dispose();

    // 12 hue buckets weighted by saturation, plus overall average.
    final weight = List<double>.filled(12, 0);
    final sums = List.generate(12, (_) => [0.0, 0.0, 0.0]);
    var r0 = 0.0, g0 = 0.0, b0 = 0.0;
    const n = w * h;
    for (var i = 0; i < n; i++) {
      final c = Color.fromARGB(
        255,
        data.getUint8(i * 4),
        data.getUint8(i * 4 + 1),
        data.getUint8(i * 4 + 2),
      );
      r0 += c.r;
      g0 += c.g;
      b0 += c.b;
      final hsl = HSLColor.fromColor(c);
      if (hsl.lightness < .08 || hsl.lightness > .96) continue;
      final bin = (hsl.hue / 30).floor() % 12;
      final wgt = hsl.saturation * (1 - (hsl.lightness - .5).abs());
      weight[bin] += wgt;
      sums[bin][0] += c.r * wgt;
      sums[bin][1] += c.g * wgt;
      sums[bin][2] += c.b * wgt;
    }
    final avg = Color.from(alpha: 1, red: r0 / n, green: g0 / n, blue: b0 / n);
    final order = List.generate(12, (i) => i)
      ..sort((a, b) => weight[b].compareTo(weight[a]));

    Color binColor(int i) => Color.from(
      alpha: 1,
      red: sums[i][0] / weight[i],
      green: sums[i][1] / weight[i],
      blue: sums[i][2] / weight[i],
    );

    final total = weight.fold<double>(0, (a, b) => a + b);
    if (total < n * .02) return WallpaperPalette.fromSeed(avg);

    final first = order.first;
    // Secondary: the strongest bucket at least 60° away from the primary.
    final second = order
        .skip(1)
        .firstWhere(
          (i) => weight[i] > 0 && _hueDistance(i * 30.0, first * 30.0) >= 60,
          orElse: () => -1,
        );
    final p = HSLColor.fromColor(binColor(first));
    final s = second >= 0
        ? HSLColor.fromColor(binColor(second))
        : p.withHue((p.hue + 45) % 360);
    final a = HSLColor.fromColor(avg);
    return WallpaperPalette(
      primary: _vivid(p),
      secondary: _vivid(s),
      light: a
          .withSaturation(math.min(a.saturation, .4))
          .withLightness(.9)
          .toColor(),
      dark: a
          .withSaturation(math.min(a.saturation, .35))
          .withLightness(.14)
          .toColor(),
    );
  }

  /// Saturated, mid-light version that reads well as a UI fill.
  static Color _vivid(HSLColor h) => h
      .withSaturation(h.saturation.clamp(.55, .9))
      .withLightness(h.lightness.clamp(.5, .62))
      .toColor();

  static double _hueDistance(double a, double b) {
    final d = (a - b).abs() % 360;
    return d > 180 ? 360 - d : d;
  }
}
