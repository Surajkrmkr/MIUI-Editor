import 'dart:math';

import 'package:flutter/material.dart';
import 'package:theme_core/theme_core.dart';

import '../lock_element.dart';
import 'calendar_style_art.dart';

/// Suraj's studio calendar panels. Colours as in the other extra styles:
/// `unlockAccent` is the page, `borderColor` and `strokeColor` the two inks.
const studioCalendarStyles = {
  CalendarStyle.blueprintGrid,
  CalendarStyle.sunsetBands,
  CalendarStyle.pixelArcade,
  CalendarStyle.leatherStitch,
  CalendarStyle.paperLayers,
  CalendarStyle.starryNight,
  CalendarStyle.terrazzoChips,
  CalendarStyle.ribbonHeader,
  CalendarStyle.plannerTab,
  CalendarStyle.holoGlass,
};

void paintStudioCalendarPanel(
  Canvas canvas,
  Size size,
  LockElement el,
  CalendarLayout l,
  double k,
  RRect panel,
) {
  Rect sc(Rect r) =>
      Rect.fromLTWH(r.left * k, r.top * k, r.width * k, r.height * k);
  Color soft(Color c, double a) =>
      c.withValues(alpha: (c.a * a).clamp(0.0, 1.0));
  final w = size.width, h = size.height;
  final inner = sc(l.inner);
  final rowH = l.rowH * k, colW = l.colW * k;
  final rows = el.calendarDisplayRows;
  final page = el.unlockAccent;
  final ink = el.borderColor, ink2 = el.strokeColor;
  double bw([double fallback = 1.2]) =>
      (el.borderWidth > 0 ? el.borderWidth : fallback) * k;
  Paint line(Color c, double width, {StrokeCap cap = StrokeCap.butt}) => Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = width
    ..strokeCap = cap
    ..strokeJoin = StrokeJoin.round
    ..color = c;
  Paint fill(Color c) => Paint()..color = c;
  void dashed(Offset a, Offset b, double dash, double gap, Paint paint) {
    final total = (b - a).distance;
    final dir = (b - a) / total;
    for (var d = 0.0; d < total; d += dash + gap) {
      canvas.drawLine(a + dir * d, a + dir * min(d + dash, total), paint);
    }
  }

  double rowTop(int r) => inner.top + r * rowH;
  Path star4(Offset c, double r) {
    final p = Path();
    for (var i = 0; i < 8; i++) {
      final a = -pi / 2 + i * pi / 4;
      final v = c + Offset(cos(a), sin(a)) * (i.isEven ? r : r * .32);
      i == 0 ? p.moveTo(v.dx, v.dy) : p.lineTo(v.dx, v.dy);
    }
    return p..close();
  }

  switch (el.calendarStyle) {
    case CalendarStyle.blueprintGrid:
      canvas.save();
      canvas.clipRRect(panel);
      final step = min(colW, rowH) / 2;
      for (var x = inner.left; x <= w; x += step) {
        final major =
            ((x - inner.left) / colW - ((x - inner.left) / colW).round())
                .abs() <
            .01;
        canvas.drawLine(
          Offset(x, 0),
          Offset(x, h),
          line(soft(ink, major ? .3 : .13), (major ? 1.1 : .7) * k),
        );
      }
      for (var y = inner.top; y <= h; y += step) {
        canvas.drawLine(
          Offset(0, y),
          Offset(w, y),
          line(soft(ink, .13), .7 * k),
        );
      }
      canvas.restore();
      canvas.drawRect(
        Rect.fromLTWH(0, 0, w, h).deflate(5 * k),
        line(soft(ink, .8), bw(1.4)),
      );
      for (final c in [
        Offset(w * .05, h * .06),
        Offset(w * .95, h * .06),
        Offset(w * .05, h * .94),
        Offset(w * .95, h * .94),
      ]) {
        canvas.drawCircle(c, 3.4 * k, line(soft(ink2, .9), 1 * k));
        canvas.drawLine(
          c - Offset(6 * k, 0),
          c + Offset(6 * k, 0),
          line(soft(ink2, .9), 1 * k),
        );
        canvas.drawLine(
          c - Offset(0, 6 * k),
          c + Offset(0, 6 * k),
          line(soft(ink2, .9), 1 * k),
        );
      }
    case CalendarStyle.sunsetBands:
      canvas.save();
      canvas.clipRRect(panel);
      canvas.drawRect(
        Offset.zero & size,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [page, Color.lerp(page, ink, .75)!, ink2],
            stops: const [0, .62, 1],
          ).createShader(Offset.zero & size),
      );
      final sun = Offset(w * .86, h * .3);
      canvas.drawCircle(sun, h * .11, fill(soft(Colors.white, .32)));
      for (var i = 0; i < 5; i++) {
        final y = sun.dy + h * .02 + i * h * .028;
        canvas.drawRect(
          Rect.fromLTWH(w * .55, y, w * .5, (i + 1) * .9 * k),
          fill(Color.lerp(page, ink, .6 + i * .08)!),
        );
      }
      for (var i = 0; i < 4; i++) {
        canvas.drawLine(
          Offset(0, h * (.7 + i * .075)),
          Offset(w, h * (.7 + i * .075)),
          line(Colors.white.withValues(alpha: .14), (1 + i * .5) * k),
        );
      }
      canvas.restore();
      canvas.drawRRect(
        panel.deflate(1 * k),
        line(Colors.white.withValues(alpha: .35), 1.4 * k),
      );
    case CalendarStyle.pixelArcade:
      final p = max(3 * k, w * .012);
      Path notched(double inset) {
        final r = Rect.fromLTWH(0, 0, w, h).deflate(inset);
        return Path()
          ..moveTo(r.left + p, r.top)
          ..lineTo(r.right - p, r.top)
          ..lineTo(r.right - p, r.top + p)
          ..lineTo(r.right, r.top + p)
          ..lineTo(r.right, r.bottom - p)
          ..lineTo(r.right - p, r.bottom - p)
          ..lineTo(r.right - p, r.bottom)
          ..lineTo(r.left + p, r.bottom)
          ..lineTo(r.left + p, r.bottom - p)
          ..lineTo(r.left, r.bottom - p)
          ..lineTo(r.left, r.top + p)
          ..lineTo(r.left + p, r.top + p)
          ..close();
      }

      canvas.drawPath(notched(0), fill(page));
      canvas.save();
      canvas.clipPath(notched(0));
      for (var y = 0.0; y < h; y += p) {
        canvas.drawRect(
          Rect.fromLTWH(0, y, w, p * .35),
          fill(Colors.black.withValues(alpha: .14)),
        );
      }
      canvas.restore();
      canvas.drawPath(
        notched(p * .5),
        line(ink, p * .9, cap: StrokeCap.square),
      );
      canvas.drawPath(
        notched(p * 2.1),
        line(soft(ink2, .55), p * .4, cap: StrokeCap.square),
      );
      for (final (x, y) in [(.12, .03), (.17, .03), (.22, .03)]) {
        canvas.drawRect(
          Rect.fromLTWH(w * x, h * y, p, p),
          fill(soft(ink2, .9)),
        );
      }
    case CalendarStyle.leatherStitch:
      canvas.drawRRect(panel, fill(page));
      final rng = Random(7);
      canvas.save();
      canvas.clipRRect(panel);
      for (var i = 0; i < 220; i++) {
        canvas.drawCircle(
          Offset(rng.nextDouble() * w, rng.nextDouble() * h),
          (.5 + rng.nextDouble() * 1.2) * k,
          fill(Colors.black.withValues(alpha: .07)),
        );
      }
      canvas.restore();
      canvas.drawRRect(panel.deflate(4 * k), line(ink, 8 * k));
      canvas.drawRRect(
        panel.deflate(8.5 * k),
        line(Colors.white.withValues(alpha: .14), 1 * k),
      );
      canvas.drawRRect(
        panel.deflate(0.8 * k),
        line(Colors.black.withValues(alpha: .3), 1.2 * k),
      );
      final st = panel.deflate(15 * k);
      final path = Path()..addRRect(st);
      for (final m in path.computeMetrics()) {
        for (var d = 0.0; d < m.length; d += 9 * k) {
          final seg = m.extractPath(d, min(d + 5 * k, m.length));
          canvas.drawPath(
            seg,
            line(soft(ink2, .95), 1.8 * k, cap: StrokeCap.round),
          );
        }
      }
    case CalendarStyle.paperLayers:
      canvas.drawRRect(panel, fill(Color.lerp(page, ink, .55)!));
      for (var i = 1; i <= 3; i++) {
        final r = panel.deflate(w * .01 * i);
        canvas.drawRRect(
          r.shift(Offset(0, 1.6 * k)),
          fill(Colors.black.withValues(alpha: .22)),
        );
        canvas.drawRRect(
          r,
          fill(i == 3 ? page : Color.lerp(page, ink, .45 - i * .14)!),
        );
      }
      canvas.drawRRect(
        panel.deflate(w * .03),
        line(Colors.white.withValues(alpha: .5), .8 * k),
      );
    case CalendarStyle.starryNight:
      canvas.save();
      canvas.clipRRect(panel);
      canvas.drawRect(
        Offset.zero & size,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [page, Color.lerp(page, ink, .8)!],
          ).createShader(Offset.zero & size),
      );
      final rng = Random(11);
      for (var i = 0; i < 46; i++) {
        final c = Offset(rng.nextDouble() * w, rng.nextDouble() * h);
        final big = i % 9 == 0;
        if (big) {
          canvas.drawPath(star4(c, 4.2 * k), fill(soft(ink2, .9)));
        } else {
          canvas.drawCircle(
            c,
            (.5 + rng.nextDouble() * .9) * k,
            fill(soft(Colors.white, .35 + rng.nextDouble() * .5)),
          );
        }
      }
      final moon = Path.combine(
        PathOperation.difference,
        Path()..addOval(
          Rect.fromCircle(center: Offset(w * .9, h * .07), radius: h * .045),
        ),
        Path()..addOval(
          Rect.fromCircle(
            center: Offset(w * .9 + h * .02, h * .07 - h * .012),
            radius: h * .04,
          ),
        ),
      );
      canvas.drawPath(moon, fill(soft(ink2, .95)));
      canvas.restore();
      canvas.drawRRect(panel.deflate(1 * k), line(soft(ink2, .55), 1.2 * k));
    case CalendarStyle.terrazzoChips:
      canvas.save();
      canvas.clipRRect(panel);
      final rng = Random(3);
      final palette = [ink, ink2, el.colorSecondary];
      for (var i = 0; i < 46; i++) {
        final c = Offset(rng.nextDouble() * w, rng.nextDouble() * h);
        final s = h * (.012 + rng.nextDouble() * .026);
        canvas.save();
        canvas.translate(c.dx, c.dy);
        canvas.rotate(rng.nextDouble() * pi);
        final chip = Path()
          ..moveTo(-s, -s * .5)
          ..lineTo(s * .8, -s * .7)
          ..lineTo(s, s * .4)
          ..lineTo(-s * .3, s * .8)
          ..close();
        canvas.drawPath(chip, fill(soft(palette[i % 3], .34)));
        canvas.restore();
      }
      canvas.restore();
      canvas.drawRRect(panel.deflate(2 * k), line(soft(ink, .45), 1.4 * k));
    case CalendarStyle.ribbonHeader:
      canvas.drawRRect(panel.deflate(1 * k), line(soft(ink2, .6), 1.2 * k));
      final top = l.monthRow != null ? rowTop(0) : h * .02;
      final band = Rect.fromLTRB(
        w * .05,
        top,
        w * .95,
        top + (l.monthRow != null ? rowH : h * .08),
      );
      final tail = band.height * .3;
      final left = Path()
        ..moveTo(band.left - w * .035, band.top + tail)
        ..lineTo(band.left, band.top + tail)
        ..lineTo(band.left, band.bottom + tail)
        ..lineTo(band.left - w * .035, band.bottom + tail)
        ..lineTo(band.left - w * .01, band.center.dy + tail)
        ..close();
      final right = Path()
        ..moveTo(band.right + w * .035, band.top + tail)
        ..lineTo(band.right, band.top + tail)
        ..lineTo(band.right, band.bottom + tail)
        ..lineTo(band.right + w * .035, band.bottom + tail)
        ..lineTo(band.right + w * .01, band.center.dy + tail)
        ..close();
      final dark = Color.lerp(ink, Colors.black, .28)!;
      canvas.drawPath(left, fill(dark));
      canvas.drawPath(right, fill(dark));
      canvas.drawPath(
        Path()
          ..moveTo(band.left, band.bottom)
          ..lineTo(band.left + w * .025, band.bottom)
          ..lineTo(band.left, band.bottom + tail)
          ..close()
          ..moveTo(band.right, band.bottom)
          ..lineTo(band.right - w * .025, band.bottom)
          ..lineTo(band.right, band.bottom + tail)
          ..close(),
        fill(Colors.black.withValues(alpha: .35)),
      );
      canvas.drawRect(band, fill(ink));
      dashed(
        Offset(band.left + 4 * k, band.top + 3 * k),
        Offset(band.right - 4 * k, band.top + 3 * k),
        4 * k,
        3 * k,
        line(Colors.white.withValues(alpha: .6), .9 * k),
      );
      dashed(
        Offset(band.left + 4 * k, band.bottom - 3 * k),
        Offset(band.right - 4 * k, band.bottom - 3 * k),
        4 * k,
        3 * k,
        line(Colors.white.withValues(alpha: .6), .9 * k),
      );
    case CalendarStyle.plannerTab:
      canvas.save();
      canvas.clipRRect(panel);
      canvas.drawRect(Rect.fromLTWH(0, 0, w * .022, h), fill(ink));
      final tabs = [ink, ink2, el.colorSecondary, ink];
      for (var i = 0; i < 4; i++) {
        final ty = h * (.14 + i * .2);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(w * .975, ty, w * .03, h * .12),
            Radius.circular(w * .008),
          ),
          fill(soft(tabs[i], .9)),
        );
      }
      if (l.weekdayRow case final row?) {
        final first = sc(l.cell(row, 0));
        canvas.drawRect(
          Rect.fromLTRB(
            inner.left - 3 * k,
            first.top,
            inner.right + 3 * k,
            first.bottom,
          ),
          fill(soft(ink, .14)),
        );
      }
      for (var r = l.firstDateRow + 1; r < rows; r++) {
        dashed(
          Offset(inner.left, rowTop(r)),
          Offset(inner.right, rowTop(r)),
          4 * k,
          3 * k,
          line(soft(ink2, .45), .9 * k),
        );
      }
      for (final y in [h * .25, h * .75]) {
        canvas.drawCircle(
          Offset(w * .008, y),
          2.4 * k,
          fill(soft(Colors.black, .35)),
        );
      }
      canvas.restore();
      canvas.drawRRect(panel.deflate(.6 * k), line(soft(ink, .35), 1.1 * k));
    case CalendarStyle.holoGlass:
      canvas.save();
      canvas.clipRRect(panel);
      canvas.drawRect(
        Offset.zero & size,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              page,
              Color.lerp(page, ink, .5)!,
              Color.lerp(page, ink2, .55)!,
              Color.lerp(page, el.colorSecondary, .4)!,
              page,
            ],
            stops: const [0, .3, .55, .8, 1],
          ).createShader(Offset.zero & size),
      );
      canvas.drawRect(
        Offset.zero & size,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topLeft,
            end: const Alignment(.2, .2),
            colors: [
              Colors.white.withValues(alpha: .55),
              Colors.white.withValues(alpha: 0),
            ],
          ).createShader(Offset.zero & size),
      );
      for (var i = 0; i < 4; i++) {
        final x = w * (.2 + i * .22);
        canvas.drawLine(
          Offset(x, 0),
          Offset(x - h * .35, h),
          line(Colors.white.withValues(alpha: .16), (3 - i * .5) * k),
        );
      }
      canvas.restore();
      canvas.drawRRect(
        panel.deflate(1 * k),
        line(Colors.white.withValues(alpha: .7), bw(1.4)),
      );
    default:
      break;
  }
}
