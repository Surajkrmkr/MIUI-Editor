import 'dart:math';

import 'package:flutter/material.dart';
import 'package:theme_core/theme_core.dart';

import '../lock_element.dart';
import 'calendar_style_art.dart';
import 'calendar_studio_art.dart';

/// Calendar panels added after the first set. Colours: `unlockAccent` is the
/// page, `borderColor` and `strokeColor` the two inks, `color` the text.
const extraCalendarStyles = {
  ...studioCalendarStyles,
  CalendarStyle.notebookSpiral,
  CalendarStyle.tearOff,
  CalendarStyle.chalkboard,
  CalendarStyle.graphPaper,
  CalendarStyle.washiTape,
  CalendarStyle.retroLcd,
  CalendarStyle.windowChrome,
  CalendarStyle.editorial,
  CalendarStyle.ledger,
  CalendarStyle.postageStamp,
};

/// Paints the background art of an [extraCalendarStyles] panel; [k] converts
/// theme pixels to canvas pixels and [panel] is the page outline.
void paintExtraCalendarPanel(
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
  final ink = el.borderColor, ink2 = el.strokeColor;
  double bw([double fallback = 1.2]) =>
      (el.borderWidth > 0 ? el.borderWidth : fallback) * k;
  Paint line(Color c, double width, {StrokeCap cap = StrokeCap.butt}) => Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = width
    ..strokeCap = cap
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
  final weekday = l.weekdayRow;

  switch (el.calendarStyle) {
    case CalendarStyle.notebookSpiral:
      canvas.save();
      canvas.clipRRect(panel);
      for (var r = 0; r < rows; r++) {
        final y = rowTop(r + 1);
        canvas.drawLine(
          Offset(inner.left - colW * .15, y),
          Offset(inner.right + colW * .15, y),
          line(soft(ink2, .4), 1 * k),
        );
      }
      for (final x in [w * .03, w * .037]) {
        canvas.drawLine(Offset(x, 0), Offset(x, h), line(soft(ink2, .7), k));
      }
      canvas.restore();
      const loops = 13;
      for (var i = 0; i < loops; i++) {
        final x = w * .08 + i * w * .84 / (loops - 1);
        final y = h * .045;
        canvas.drawCircle(Offset(x, y), 3.6 * k, fill(soft(ink, .3)));
        canvas.drawLine(
          Offset(x, y - 11 * k),
          Offset(x, y + 7 * k),
          line(ink, 3 * k, cap: StrokeCap.round),
        );
        canvas.drawLine(
          Offset(x - .8 * k, y - 9 * k),
          Offset(x - .8 * k, y + 4 * k),
          line(Colors.white.withValues(alpha: .45), 1 * k),
        );
      }
    case CalendarStyle.tearOff:
      canvas.save();
      canvas.clipRRect(panel);
      canvas.drawRect(
        Rect.fromLTWH(0, h * .955, w, h * .045),
        fill(Colors.black.withValues(alpha: .12)),
      );
      for (var i = 0; i < 3; i++) {
        canvas.drawLine(
          Offset(0, h * .955 + i * h * .014),
          Offset(w, h * .955 + i * h * .014),
          line(Colors.black.withValues(alpha: .12), .8 * k),
        );
      }
      canvas.restore();
      dashed(
        Offset(w * .04, h * .062),
        Offset(w * .96, h * .062),
        5 * k,
        3.5 * k,
        line(soft(ink2, .55), 1.1 * k),
      );
      for (final x in [w * .09, w * .91]) {
        canvas.drawCircle(Offset(x, h * .03), 3 * k, fill(soft(ink, .55)));
        canvas.drawCircle(
          Offset(x, h * .03),
          3 * k,
          line(Colors.black.withValues(alpha: .25), .8 * k),
        );
      }
      if (weekday != null) {
        final first = sc(l.cell(weekday, 0)), last = sc(l.cell(weekday, 6));
        final band = Rect.fromLTRB(
          0,
          first.top + first.height * .06,
          w,
          first.bottom - first.height * .06,
        );
        canvas.drawRect(band, fill(ink));
        canvas.drawRect(
          Rect.fromLTWH(band.left, band.bottom, w, 1.4 * k),
          fill(Colors.black.withValues(alpha: .15)),
        );
        canvas.drawCircle(
          Offset(first.left - colW * .02, band.center.dy),
          .8 * k,
          fill(soft(el.unlockAccent, .6)),
        );
        canvas.drawCircle(
          Offset(last.right + colW * .02, band.center.dy),
          .8 * k,
          fill(soft(el.unlockAccent, .6)),
        );
      }
    case CalendarStyle.chalkboard:
      canvas.save();
      canvas.clipRRect(panel);
      for (final (x, y, a) in [
        (.2, .3, -.5),
        (.7, .55, -.45),
        (.45, .8, -.6),
        (.85, .15, -.5),
      ]) {
        canvas.save();
        canvas.translate(w * x, h * y);
        canvas.rotate(a);
        canvas.drawLine(
          Offset(-w * .35, 0),
          Offset(w * .35, 0),
          line(Colors.white.withValues(alpha: .045), 16 * k),
        );
        canvas.restore();
      }
      canvas.restore();
      canvas.drawRRect(panel.deflate(3.5 * k), line(ink, 7 * k));
      canvas.drawRRect(
        panel.deflate(3.5 * k),
        line(Colors.black.withValues(alpha: .25), 1 * k),
      );
      canvas.drawRRect(
        panel.deflate(8.5 * k),
        line(Colors.white.withValues(alpha: .22), 1 * k),
      );
      if (weekday != null) {
        final y = sc(l.cell(weekday, 0)).bottom + 2.5 * k;
        dashed(
          Offset(inner.left, y),
          Offset(inner.right, y),
          7 * k,
          4 * k,
          line(soft(ink2, .85), 1.6 * k, cap: StrokeCap.round),
        );
      }
      for (final (x, y) in [(.1, .955), (.14, .965), (.9, .96)]) {
        canvas.drawCircle(
          Offset(w * x, h * y),
          1.3 * k,
          fill(Colors.white.withValues(alpha: .5)),
        );
      }
    case CalendarStyle.graphPaper:
      canvas.save();
      canvas.clipRRect(panel);
      final step = min(colW, rowH) / 2;
      final minor = line(soft(ink2, .16), .8 * k);
      for (var x = inner.left; x <= w; x += step) {
        canvas.drawLine(Offset(x, 0), Offset(x, h), minor);
      }
      for (var x = inner.left - step; x >= 0; x -= step) {
        canvas.drawLine(Offset(x, 0), Offset(x, h), minor);
      }
      for (var y = inner.top; y <= h; y += step) {
        canvas.drawLine(Offset(0, y), Offset(w, y), minor);
      }
      for (var y = inner.top - step; y >= 0; y -= step) {
        canvas.drawLine(Offset(0, y), Offset(w, y), minor);
      }
      final major = line(soft(ink2, .34), 1.1 * k);
      for (var c = 0; c <= 7; c++) {
        canvas.drawLine(
          Offset(inner.left + c * colW, inner.top),
          Offset(inner.left + c * colW, inner.bottom),
          major,
        );
      }
      for (var r = 0; r <= rows; r++) {
        canvas.drawLine(
          Offset(inner.left, rowTop(r)),
          Offset(inner.right, rowTop(r)),
          major,
        );
      }
      canvas.restore();
      for (final (x, y) in [(0.0, 0.0), (w, 0.0), (0.0, h), (w, h)]) {
        final dx = x == 0 ? 1 : -1, dy = y == 0 ? 1 : -1;
        canvas.drawLine(
          Offset(x + dx * 5 * k, y + dy * 11 * k),
          Offset(x + dx * 5 * k, y + dy * 5 * k),
          line(ink, 1.4 * k),
        );
        canvas.drawLine(
          Offset(x + dx * 5 * k, y + dy * 5 * k),
          Offset(x + dx * 11 * k, y + dy * 5 * k),
          line(ink, 1.4 * k),
        );
      }
    case CalendarStyle.washiTape:
      final stitch = Path()..addRRect(panel.deflate(6 * k));
      for (final m in stitch.computeMetrics()) {
        for (var d = 0.0; d < m.length; d += 7 * k) {
          canvas.drawPath(
            m.extractPath(d, d + 3.5 * k),
            line(soft(ink, .45), 1 * k),
          );
        }
      }
      void tape(Offset c, double angle, Color color) {
        final len = w * .24, th = h * .042;
        canvas.save();
        canvas.translate(c.dx, c.dy);
        canvas.rotate(angle);
        final path = Path()..moveTo(-len / 2, -th / 2);
        const teeth = 4;
        path.lineTo(len / 2, -th / 2);
        for (var i = 0; i < teeth; i++) {
          final y = -th / 2 + th * (i + .5) / teeth;
          path.lineTo(len / 2 - 2.2 * k, y);
          path.lineTo(len / 2, y + th / teeth / 2);
        }
        path.lineTo(len / 2, th / 2);
        path.lineTo(-len / 2, th / 2);
        for (var i = teeth - 1; i >= 0; i--) {
          final y = -th / 2 + th * (i + .5) / teeth;
          path.lineTo(-len / 2 + 2.2 * k, y + th / teeth / 2);
          path.lineTo(-len / 2, y);
        }
        path.close();
        canvas.drawShadow(
          path,
          Colors.black.withValues(alpha: .6),
          1.2 * k,
          false,
        );
        canvas.drawPath(path, fill(soft(color, .82)));
        canvas.save();
        canvas.clipPath(path);
        for (var x = -len / 2; x < len / 2; x += 6 * k) {
          canvas.drawLine(
            Offset(x, -th / 2),
            Offset(x + th, th / 2),
            line(Colors.white.withValues(alpha: .28), 2 * k),
          );
        }
        canvas.restore();
        canvas.restore();
      }

      tape(Offset(w * .12, h * .018), -.5, ink2);
      tape(Offset(w * .88, h * .018), .5, ink);
    case CalendarStyle.retroLcd:
      canvas.save();
      canvas.clipRRect(panel);
      for (var r = 0; r < rows; r++) {
        for (var c = 0; c < 7; c++) {
          if (r < l.firstDateRow && r != weekday) continue;
          final cell = sc(l.cell(r, c)).deflate(2 * k);
          canvas.drawRRect(
            RRect.fromRectAndRadius(cell, Radius.circular(2 * k)),
            fill(soft(el.color, .07)),
          );
        }
      }
      for (var y = 0.0; y < h; y += 3 * k) {
        canvas.drawLine(
          Offset(0, y),
          Offset(w, y),
          line(Colors.black.withValues(alpha: .05), 1 * k),
        );
      }
      final glow = Rect.fromLTWH(0, 0, w, h * .12);
      canvas.drawRect(
        glow,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.black.withValues(alpha: .22), Colors.transparent],
          ).createShader(glow),
      );
      for (var i = 0; i < 4; i++) {
        final x = w - 44 * k + i * 7 * k;
        canvas.drawRect(
          Rect.fromLTWH(
            x,
            h * .074 - (2 + i * 2.2) * k,
            4.5 * k,
            (2 + i * 2.2) * k,
          ),
          fill(soft(el.color, .75)),
        );
      }
      canvas.restore();
      canvas.drawRRect(panel.deflate(2.5 * k), line(ink, 5 * k));
      canvas.drawRRect(
        panel.deflate(5.5 * k),
        line(Colors.black.withValues(alpha: .3), 1 * k),
      );
    case CalendarStyle.windowChrome:
      canvas.save();
      canvas.clipRRect(panel);
      final bar = h * .085;
      canvas.drawRect(Rect.fromLTWH(0, 0, w, bar), fill(soft(ink2, .22)));
      canvas.drawLine(
        Offset(0, bar),
        Offset(w, bar),
        line(soft(ink, .7), 1 * k),
      );
      for (var r = l.firstDateRow; r < rows; r++) {
        if ((r - l.firstDateRow).isOdd) {
          canvas.drawRect(
            Rect.fromLTRB(0, rowTop(r), w, rowTop(r + 1)),
            fill(soft(ink2, .07)),
          );
        }
      }
      canvas.restore();
      final dot = bar * .2;
      for (var i = 0; i < 3; i++) {
        canvas.drawCircle(
          Offset(w * .045 + dot * 1.35 + i * dot * 2.9, bar / 2),
          dot,
          fill(
            const [Color(0xFFFF5F57), Color(0xFFFEBC2E), Color(0xFF28C840)][i],
          ),
        );
      }
      canvas.drawRRect(panel, line(ink, bw()));
    case CalendarStyle.editorial:
      canvas.drawRect(
        Rect.fromLTWH(inner.left, inner.top - 5.5 * k, inner.width, 3.4 * k),
        fill(ink),
      );
      canvas.drawRect(
        Rect.fromLTWH(inner.left, inner.top - 13 * k, 28 * k, 5 * k),
        fill(ink2),
      );
      for (var r = 0; r < rows; r++) {
        final y = rowTop(r + 1);
        final header = r == weekday;
        canvas.drawLine(
          Offset(inner.left, y),
          Offset(inner.right, y),
          line(header ? ink : soft(ink, .22), (header ? 1.4 : .8) * k),
        );
      }
      canvas.drawLine(
        Offset(inner.left, inner.bottom + 4 * k),
        Offset(inner.right, inner.bottom + 4 * k),
        line(ink, 1 * k),
      );
    case CalendarStyle.ledger:
      final first = weekday ?? 0;
      final grid = line(soft(ink2, .38), .9 * k);
      for (var c = 0; c <= 7; c++) {
        canvas.drawLine(
          Offset(inner.left + c * colW, rowTop(first)),
          Offset(inner.left + c * colW, inner.bottom),
          grid,
        );
      }
      for (var r = first; r <= rows; r++) {
        canvas.drawLine(
          Offset(inner.left, rowTop(r)),
          Offset(inner.right, rowTop(r)),
          grid,
        );
      }
      if (weekday != null) {
        final y = rowTop(weekday + 1);
        canvas.drawLine(
          Offset(inner.left, y + 2.6 * k),
          Offset(inner.right, y + 2.6 * k),
          line(ink2, 1.1 * k),
        );
        canvas.drawLine(
          Offset(inner.left, y),
          Offset(inner.right, y),
          line(ink2, 1.1 * k),
        );
      }
      for (final x in [w * .02, w * .028]) {
        canvas.drawLine(
          Offset(x, h * .03),
          Offset(x, h * .97),
          line(soft(ink, .8), 1 * k),
        );
      }
      for (var x = w * .06; x < w * .96; x += 9 * k) {
        canvas.drawCircle(Offset(x, h * .02), .9 * k, fill(soft(ink, .4)));
        canvas.drawCircle(Offset(x, h * .98), .9 * k, fill(soft(ink, .4)));
      }
    case CalendarStyle.postageStamp:
      final bites = Path();
      final spacing = 11 * k, radius = 3.3 * k;
      final nx = max(2, (w / spacing).round()),
          ny = max(2, (h / spacing).round());
      for (var i = 0; i <= nx; i++) {
        for (final y in [0.0, h]) {
          bites.addOval(
            Rect.fromCircle(center: Offset(i * w / nx, y), radius: radius),
          );
        }
      }
      for (var i = 0; i <= ny; i++) {
        for (final x in [0.0, w]) {
          bites.addOval(
            Rect.fromCircle(center: Offset(x, i * h / ny), radius: radius),
          );
        }
      }
      final stamp = Path.combine(
        PathOperation.difference,
        Path()..addRect(Offset.zero & size),
        bites,
      );
      canvas.drawShadow(
        stamp,
        Colors.black.withValues(alpha: .5),
        2 * k,
        false,
      );
      canvas.drawPath(stamp, fill(el.unlockAccent));
      canvas.drawRect(
        (Offset.zero & size).deflate(8 * k),
        line(soft(ink, .8), bw(1)),
      );
      for (var i = 0; i < 4; i++) {
        final path = Path()..moveTo(w * .5, h * .016 + i * 4.6 * k);
        for (var x = 0.0; x <= w * .42; x += 2 * k) {
          path.lineTo(
            w * .5 + x,
            h * .016 + i * 4.6 * k + sin(x / (5 * k)) * 1.6 * k,
          );
        }
        canvas.drawPath(
          path,
          line(soft(ink2, .55), 1.2 * k, cap: StrokeCap.round),
        );
      }
      canvas.drawCircle(
        Offset(w * .44, h * .038),
        h * .026,
        line(soft(ink2, .55), 1.3 * k),
      );
    default:
      paintStudioCalendarPanel(canvas, size, el, l, k, panel);
  }
}
