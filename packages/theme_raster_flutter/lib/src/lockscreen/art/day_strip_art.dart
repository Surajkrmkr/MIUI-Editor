import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:theme_core/theme_core.dart';
import 'package:theme_core/lockscreen_layout.dart'
    show DayStripLayout, DayStripSlot;
import '../../adapters.dart';
import '../lock_element.dart';
import '../lock_element_spec_bridge.dart';
import '../lockscreen_clock.dart';

/// Static day strip background (slots and today's highlight) as one PNG.
class DayStripArt {
  const DayStripArt._();

  static Widget panel(LockElement el, double k) => SizedBox(
    width: el.width * k,
    height: el.height * k,
    child: CustomPaint(painter: _StripPainter(el, k)),
  );

  static double exportInset(LockElement el) =>
      DayStripLayout.of(el.toSpec()).exportInset;

  static Widget exportPanel(LockElement el) {
    const k = 1 / 3;
    return Padding(
      padding: EdgeInsets.all(exportInset(el) * k),
      child: panel(el, k),
    );
  }
}

/// Editor preview: the panel plus weekday labels around today.
class DayStripPreview extends StatelessWidget {
  const DayStripPreview({super.key, required this.element});
  final LockElement element;

  @override
  Widget build(BuildContext context) {
    const k = 1 / lockscreenScreenRatio;
    final el = element;
    final l = DayStripLayout.of(el.toSpec());
    final now = lockscreenNow();
    Widget at(Offset c, String text, double size, Color color, FontWeight w) =>
        Positioned(
          left: c.dx * k - 300,
          top: c.dy * k - 100,
          width: 600,
          height: 200,
          child: Center(
            child: Text(
              text,
              maxLines: 1,
              style: TextStyle(
                color: color,
                fontSize: size * k,
                fontWeight: w,
                height: 1,
              ),
            ),
          ),
        );
    return SizedBox(
      width: el.width * k,
      height: el.height * k,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          DayStripArt.panel(el, k),
          for (final s in l.slots) ...[
            at(
              s.label.toOffset(),
              l.labelFor(now.add(Duration(days: s.offset))),
              s.labelSize,
              s.color.toColor(),
              el.fontWeight,
            ),
            if (s.date case final d?)
              at(
                d.toOffset(),
                '${now.add(Duration(days: s.offset)).day}',
                s.dateSize,
                s.dateColor.toColor(),
                FontWeight.w700,
              ),
          ],
        ],
      ),
    );
  }
}

class _StripPainter extends CustomPainter {
  _StripPainter(this.el, this.k);
  final LockElement el;
  final double k;

  Color get fill => el.unlockAccent;
  Color get today => el.colorSecondary;
  Color get line => el.borderColor;
  double outline(double fallback) =>
      (el.borderWidth > 0 ? el.borderWidth : fallback) * k;

  static Color _a(Color c, double a) =>
      c.withValues(alpha: (c.a * a).clamp(0.0, 1.0));

  Paint _fill(Color c) => Paint()..color = c;
  Paint _stroke(Color c, double width) => Paint()
    ..color = c
    ..style = PaintingStyle.stroke
    ..strokeWidth = width
    ..strokeCap = StrokeCap.round;
  Paint _glow(Color c, double blur) => Paint()
    ..color = c
    ..maskFilter = MaskFilter.blur(BlurStyle.normal, blur);

  @override
  void paint(Canvas canvas, Size size) {
    final l = DayStripLayout.of(el.toSpec());
    final slots = l.slots;
    Rect r(DayStripSlot s) => Rect.fromLTRB(
      s.box.left * k,
      s.box.top * k,
      s.box.right * k,
      s.box.bottom * k,
    );
    RRect rr(DayStripSlot s) =>
        RRect.fromRectAndRadius(r(s), Radius.circular(s.radius * k));
    final todaySlot = slots.firstWhere((s) => s.isToday);
    final h = size.height;
    final w = size.width;

    switch (l.style) {
      case DayStripStyle.glassPills:
        for (final s in slots) {
          final p = rr(s);
          if (s.isToday) {
            canvas.drawRRect(
              p.shift(Offset(0, h * .04)),
              _glow(Colors.black.withValues(alpha: .28), h * .08),
            );
            canvas.drawRRect(p, _fill(today));
          } else {
            canvas.drawRRect(p, _fill(fill));
          }
          canvas.drawRRect(
            p,
            Paint()
              ..shader = ui.Gradient.linear(
                p.outerRect.topCenter,
                p.outerRect.center,
                [
                  Colors.white.withValues(alpha: s.isToday ? .35 : .16),
                  Colors.white.withValues(alpha: 0),
                ],
              ),
          );
          canvas.drawRRect(
            p.deflate(.5 * k),
            _stroke(
              Colors.white.withValues(alpha: s.isToday ? .5 : .22),
              1.2 * k,
            ),
          );
        }

      case DayStripStyle.outlineCapsules:
        for (final s in slots) {
          final p = rr(s);
          if (s.isToday) {
            canvas.drawRRect(p, _glow(_a(today, .55), h * .1));
            canvas.drawRRect(p, _fill(today));
          } else {
            canvas.drawRRect(
              p.deflate(outline(2) / 2),
              _stroke(line, outline(2)),
            );
          }
        }

      case DayStripStyle.neonTube:
        final track = RRect.fromRectAndRadius(
          Rect.fromLTRB(
            0,
            r(todaySlot).top - h * .06,
            w,
            r(todaySlot).bottom + h * .06,
          ),
          Radius.circular(h),
        );
        canvas.drawRRect(track, _fill(fill));
        canvas.drawRRect(
          track.deflate(.6 * k),
          _stroke(_a(line, .25), 1.2 * k),
        );
        final p = rr(todaySlot);
        canvas.drawRRect(p, _fill(_a(today, .22)));
        canvas.drawRRect(
          p,
          _stroke(_a(line, .6), outline(3) * 3)
            ..maskFilter = MaskFilter.blur(BlurStyle.normal, h * .09),
        );
        canvas.drawRRect(p, _stroke(line, outline(3)));
        canvas.drawRRect(
          p,
          _stroke(Colors.white.withValues(alpha: .8), outline(3) * .35),
        );

      case DayStripStyle.dateStack:
        for (final s in slots) {
          final p = rr(s);
          if (s.isToday) {
            canvas.drawRRect(
              p.shift(Offset(0, h * .05)),
              _glow(_a(today, .5), h * .1),
            );
            canvas.drawRRect(p, _fill(today));
            canvas.drawCircle(
              Offset(p.center.dx, p.bottom - h * .08),
              h * .025,
              _fill(l.todayText.toColor()),
            );
          } else {
            canvas.drawRRect(p, _fill(fill));
            canvas.drawRRect(p.deflate(.6 * k), _stroke(_a(line, .5), 1.2 * k));
          }
        }

      case DayStripStyle.dotIndicator:
        for (final s in slots) {
          final c = Offset(r(s).center.dx, h * .86);
          if (s.isToday) {
            canvas.drawCircle(c, h * .085, _glow(_a(today, .5), h * .06));
            canvas.drawCircle(c, h * .06, _fill(today));
            canvas.drawCircle(c, h * .1, _stroke(_a(today, .5), 1.4 * k));
          } else {
            canvas.drawCircle(c, h * .03, _fill(_a(line, .45)));
          }
        }

      case DayStripStyle.underlineTabs:
        final y = h * .88;
        canvas.drawLine(
          Offset(0, y),
          Offset(w, y),
          _stroke(_a(line, .35), outline(1.5)),
        );
        final t = r(todaySlot);
        final bar = Rect.fromCenter(
          center: Offset(t.center.dx, y),
          width: t.width * .62,
          height: h * .09,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(bar, Radius.circular(h)),
          _glow(_a(today, .6), h * .06),
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(bar, Radius.circular(h)),
          _fill(today),
        );

      case DayStripStyle.segmentedBar:
        final t = r(todaySlot);
        final track = RRect.fromRectAndRadius(
          Rect.fromLTRB(0, t.top, w, t.bottom),
          Radius.circular(t.height / 2),
        );
        canvas.drawRRect(track, _fill(fill));
        canvas.drawRRect(
          track.deflate(.6 * k),
          _stroke(_a(line, .35), 1.2 * k),
        );
        for (var i = 1; i < slots.length; i++) {
          if (slots[i].isToday || slots[i - 1].isToday) continue;
          final x = r(slots[i]).left;
          canvas.drawLine(
            Offset(x, t.top + t.height * .28),
            Offset(x, t.bottom - t.height * .28),
            _stroke(_a(line, .4), 1.2 * k),
          );
        }
        final knob = RRect.fromRectAndRadius(
          t.deflate(t.height * .09),
          Radius.circular(t.height / 2),
        );
        canvas.drawRRect(
          knob.shift(Offset(0, h * .02)),
          _glow(Colors.black.withValues(alpha: .3), h * .05),
        );
        canvas.drawRRect(knob, _fill(today));

      case DayStripStyle.circleBadges:
        for (final s in slots) {
          final b = r(s);
          final c = b.center;
          final rad = b.width / 2;
          if (s.isToday) {
            canvas.drawCircle(c, rad * .9, _fill(today));
            canvas.drawCircle(c, rad * 1.04, _stroke(line, outline(2)));
          } else {
            canvas.drawCircle(c, rad * .9, _fill(fill));
            canvas.drawCircle(c, rad * .9, _stroke(_a(line, .35), 1.2 * k));
          }
        }

      case DayStripStyle.neoBrutal:
        for (final s in slots) {
          final p = rr(s);
          final off = const Offset(1, 1) * h * (s.isToday ? .09 : .06);
          canvas.drawRRect(p.shift(off), _fill(line));
          canvas.drawRRect(p, _fill(s.isToday ? today : fill));
          canvas.drawRRect(
            p.deflate(outline(3) / 2),
            _stroke(line, outline(3)),
          );
        }

      case DayStripStyle.calendarTear:
        for (final s in slots) {
          final p = rr(s);
          final b = r(s);
          canvas.drawRRect(
            p.shift(Offset(0, h * .03)),
            _glow(Colors.black.withValues(alpha: .3), h * .05),
          );
          canvas.drawRRect(p, _fill(fill));
          final band = Rect.fromLTRB(
            b.left,
            b.top,
            b.right,
            b.top + b.height * .38,
          );
          canvas.save();
          canvas.clipRRect(p);
          canvas.drawRect(band, _fill(s.isToday ? today : line));
          canvas.restore();
          final dash = _stroke(_a(line, .5), 1.2 * k);
          for (
            var x = b.left + b.width * .08;
            x < b.right - b.width * .08;
            x += b.width * .08
          ) {
            canvas.drawLine(
              Offset(x, band.bottom),
              Offset(x + b.width * .04, band.bottom),
              dash,
            );
          }
          for (final fx in [.3, .7]) {
            canvas.drawCircle(
              Offset(b.left + b.width * fx, b.top + b.height * .05),
              h * .025,
              _fill(Colors.black.withValues(alpha: .35)),
            );
          }
        }

      case DayStripStyle.orbitArc:
        final path = Path();
        for (var i = 0; i < slots.length; i++) {
          final c = r(slots[i]).center;
          i == 0 ? path.moveTo(c.dx, c.dy) : path.lineTo(c.dx, c.dy);
        }
        canvas.drawPath(path, _stroke(_a(line, .45), outline(1.5)));
        for (final s in slots) {
          final p = rr(s);
          if (s.isToday) {
            canvas.drawRRect(p, _glow(_a(today, .6), h * .1));
            canvas.drawRRect(p, _fill(today));
          } else {
            canvas.drawRRect(p, _fill(fill));
            canvas.drawRRect(p.deflate(.6 * k), _stroke(_a(line, .4), 1.2 * k));
          }
        }

      case DayStripStyle.fadeCarousel:
        final t = r(todaySlot);
        final band = Rect.fromLTRB(0, t.top, w, t.bottom);
        canvas.drawRRect(
          RRect.fromRectAndRadius(band, Radius.circular(t.height / 2)),
          Paint()
            ..shader = ui.Gradient.linear(
              band.centerLeft,
              band.centerRight,
              [_a(fill, 0), fill, _a(fill, 0)],
              const [0, .5, 1],
            ),
        );
        final p = rr(todaySlot);
        canvas.drawRRect(
          p.shift(Offset(0, h * .03)),
          _glow(Colors.black.withValues(alpha: .25), h * .06),
        );
        canvas.drawRRect(
          p,
          Paint()
            ..shader = ui.Gradient.linear(
              p.outerRect.topLeft,
              p.outerRect.bottomRight,
              [today, Color.lerp(today, line, .45)!],
            ),
        );

      case DayStripStyle.bracketMono:
        final t = r(todaySlot);
        final arm = t.height * .3;
        final pen = _stroke(today, outline(2.5))..strokeCap = StrokeCap.square;
        for (final (x, dir) in [(t.left, 1.0), (t.right, -1.0)]) {
          canvas.drawPath(
            Path()
              ..moveTo(x + arm * dir, t.top)
              ..lineTo(x, t.top)
              ..lineTo(x, t.bottom)
              ..lineTo(x + arm * dir, t.bottom),
            pen,
          );
        }
        canvas.drawRect(t.deflate(t.height * .14), _fill(_a(today, .14)));
        for (var i = 1; i < slots.length; i++) {
          final x = r(slots[i]).left - l.gap * k / 2;
          canvas.drawLine(
            Offset(x, h * .42),
            Offset(x, h * .58),
            _stroke(_a(line, .35), 1.2 * k),
          );
        }

      case DayStripStyle.softClay:
        for (final s in slots) {
          final p = rr(s);
          final d = h * .05;
          canvas.drawRRect(
            p.shift(Offset(d, d)),
            _glow(Colors.black.withValues(alpha: .35), d * 1.6),
          );
          canvas.drawRRect(
            p.shift(Offset(-d, -d)),
            _glow(Colors.white.withValues(alpha: .28), d * 1.6),
          );
          final base = s.isToday ? today : fill;
          canvas.drawRRect(
            p,
            Paint()
              ..shader = ui.Gradient.linear(
                p.outerRect.topLeft,
                p.outerRect.bottomRight,
                [
                  Color.lerp(base, Colors.white, .12)!,
                  Color.lerp(base, Colors.black, .1)!,
                ],
              ),
          );
        }
    }
  }

  @override
  bool shouldRepaint(_StripPainter old) => old.el != el || old.k != k;
}
