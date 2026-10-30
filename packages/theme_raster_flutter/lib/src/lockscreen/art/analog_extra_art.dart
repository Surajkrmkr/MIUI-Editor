import 'dart:math';

import 'package:flutter/material.dart';
import 'package:theme_core/theme_core.dart';
import 'package:theme_core/lockscreen_layout.dart' show AnalogPart;

/// Analog faces added after the first abstract set; each one paints its own
/// face, clipping and rim ticks so it needs no help from the shared painter.
const extraAnalogStyles = {
  AnalogStyle.atomicStar,
  AnalogStyle.honeycomb,
  AnalogStyle.gearwork,
  AnalogStyle.radarSweep,
  AnalogStyle.petalBloom,
  AnalogStyle.ringedPlanet,
  AnalogStyle.stainedGlass,
  AnalogStyle.blueprint,
  AnalogStyle.vinylRecord,
  AnalogStyle.gaugeDial,
};

Color _soft(Color c, double a) => c.withValues(alpha: (c.a * a).clamp(0, 1));

/// Paints [style] in a square of [size]; `face` fills the disc, `ticks` and
/// `accent` are the two ink colours.
void paintExtraAnalogDial(
  Canvas canvas,
  Size size,
  AnalogStyle style,
  Color face,
  Color ticks,
  Color accent,
) {
  canvas.save();
  canvas.translate(size.width / 2, size.height / 2);
  canvas.scale(size.width * .44);
  final fill = Paint()
    ..isAntiAlias = true
    ..style = PaintingStyle.fill;
  final stroke = Paint()
    ..isAntiAlias = true
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round;
  void disc(Offset c, double r, Color color) =>
      canvas.drawCircle(c, r, fill..color = color);
  void ring(Offset c, double r, double w, Color color) => canvas.drawCircle(
    c,
    r,
    stroke
      ..strokeWidth = w
      ..color = color,
  );
  void line(Offset a, Offset b, double w, Color color) => canvas.drawLine(
    a,
    b,
    stroke
      ..strokeWidth = w
      ..color = color,
  );
  Offset polar(double angle, double radius) =>
      Offset(cos(angle), sin(angle)) * radius;

  disc(Offset.zero, 1, face);
  canvas.save();
  canvas.clipPath(Path()..addOval(const Rect.fromLTWH(-1, -1, 2, 2)));

  switch (style) {
    case AnalogStyle.atomicStar:
      for (var i = 0; i < 24; i++) {
        final a = i * pi / 12 - pi / 2;
        final long = i % 3 == 0;
        final mid = i % 3 == 1;
        final tip = long ? .9 : (mid ? .66 : .5);
        final half = long ? .045 : .03;
        final kite = Path()
          ..moveTo(0, 0)
          ..lineTo(polar(a - .09, tip * .45).dx, polar(a - .09, tip * .45).dy)
          ..lineTo(polar(a, tip).dx, polar(a, tip).dy)
          ..lineTo(polar(a + .09, tip * .45).dx, polar(a + .09, tip * .45).dy)
          ..close();
        canvas.drawPath(
          kite,
          fill..color = _soft(long ? ticks : accent, long ? .85 : .55),
        );
        if (long) disc(polar(a, .9), half * .9, accent);
        if (half > 0 && !long && !mid) disc(polar(a, .5), .018, ticks);
      }
      ring(Offset.zero, .36, .012, _soft(ticks, .6));
      disc(Offset.zero, .1, face);
      ring(Offset.zero, .1, .02, accent);
    case AnalogStyle.honeycomb:
      const s = .27;
      Path hexagon(Offset c, double r) {
        final p = Path();
        for (var i = 0; i < 6; i++) {
          final a = pi / 6 + i * pi / 3;
          final v = c + Offset(cos(a), sin(a)) * r;
          i == 0 ? p.moveTo(v.dx, v.dy) : p.lineTo(v.dx, v.dy);
        }
        return p..close();
      }

      for (var q = -5; q <= 5; q++) {
        for (var r = -5; r <= 5; r++) {
          final c = Offset(s * sqrt(3) * (q + r / 2), s * 1.5 * r);
          if (c.distance > 1.2) continue;
          final cell = hexagon(c, s * .94);
          final key = (q * 3 + r * 5) % 7;
          if (key == 0) {
            canvas.drawPath(cell, fill..color = _soft(accent, .55));
          } else if ((q - r) % 4 == 0) {
            canvas.drawPath(cell, fill..color = _soft(ticks, .16));
          }
          canvas.drawPath(
            cell,
            stroke
              ..strokeWidth = .016
              ..color = _soft(ticks, .5),
          );
        }
      }
      canvas.drawPath(hexagon(Offset.zero, .2), fill..color = face);
      canvas.drawPath(
        hexagon(Offset.zero, .2),
        stroke
          ..strokeWidth = .03
          ..color = accent,
      );
    case AnalogStyle.gearwork:
      Path gear(Offset c, double outer, double inner, int teeth, double turn) {
        final step = 2 * pi / teeth;
        final p = Path();
        for (var i = 0; i < teeth; i++) {
          final a = i * step + turn;
          for (final (da, r) in [
            (-.32, inner),
            (-.2, outer),
            (.2, outer),
            (.32, inner),
          ]) {
            final v = c + polar(a + da * step, r);
            (i == 0 && da == -.32)
                ? p.moveTo(v.dx, v.dy)
                : p.lineTo(v.dx, v.dy);
          }
        }
        return p..close();
      }

      canvas.drawPath(
        gear(Offset.zero, 1.02, .88, 36, 0),
        fill..color = _soft(ticks, .9),
      );
      disc(Offset.zero, .84, face);
      ring(Offset.zero, .8, .012, _soft(ticks, .5));
      final big = gear(const Offset(-.34, .3), .34, .26, 12, .1);
      canvas.drawPath(big, fill..color = _soft(accent, .85));
      disc(const Offset(-.34, .3), .13, face);
      ring(const Offset(-.34, .3), .13, .02, ticks);
      final small = gear(const Offset(.36, -.3), .24, .18, 9, .3);
      canvas.drawPath(small, fill..color = _soft(ticks, .7));
      disc(const Offset(.36, -.3), .09, face);
      final tiny = gear(const Offset(.42, .38), .17, .12, 7, 0);
      canvas.drawPath(tiny, fill..color = _soft(accent, .5));
      disc(const Offset(.42, .38), .05, face);
    case AnalogStyle.radarSweep:
      for (final r in [.25, .5, .75]) {
        ring(Offset.zero, r, .012, _soft(ticks, .4));
      }
      line(const Offset(-1, 0), const Offset(1, 0), .008, _soft(ticks, .35));
      line(const Offset(0, -1), const Offset(0, 1), .008, _soft(ticks, .35));
      final wedge = Paint()
        ..shader = SweepGradient(
          colors: [_soft(accent, 0), _soft(accent, 0), _soft(accent, .7)],
          stops: const [0, .62, 1],
          transform: const GradientRotation(-pi / 2 - 2 * pi * .38 + .05),
        ).createShader(Rect.fromCircle(center: Offset.zero, radius: 1));
      canvas.drawCircle(Offset.zero, .98, wedge);
      for (final (a, r, s) in [
        (-2.3, .62, .03),
        (-.6, .4, .024),
        (.9, .7, .03),
        (2.4, .35, .022),
        (-1.4, .82, .02),
      ]) {
        disc(polar(a, r), s * 1.9, _soft(accent, .25));
        disc(polar(a, r), s, accent);
      }
    case AnalogStyle.petalBloom:
      for (var ringIndex = 0; ringIndex < 2; ringIndex++) {
        final outer = ringIndex == 0;
        for (var i = 0; i < 12; i++) {
          canvas.save();
          canvas.rotate(i * pi / 6 + (outer ? 0 : pi / 12));
          final rect = Rect.fromCenter(
            center: Offset(0, outer ? -.6 : -.36),
            width: outer ? .3 : .2,
            height: outer ? .72 : .42,
          );
          canvas.drawOval(
            rect,
            fill
              ..color = _soft(
                outer ? (i.isEven ? accent : ticks) : face,
                outer ? (i.isEven ? .6 : .38) : .55,
              ),
          );
          if (!outer) {
            canvas.drawOval(
              rect,
              stroke
                ..strokeWidth = .012
                ..color = _soft(accent, .7),
            );
          }
          canvas.restore();
        }
      }
      disc(Offset.zero, .17, face);
      ring(Offset.zero, .17, .025, accent);
      for (var i = 0; i < 8; i++) {
        disc(polar(i * pi / 4, .09), .016, ticks);
      }
    case AnalogStyle.ringedPlanet:
      for (final (x, y, s) in [
        (-.78, -.5, .02),
        (.7, -.62, .016),
        (.82, .18, .022),
        (-.62, .62, .018),
        (.2, .86, .014),
        (-.2, -.84, .016),
        (.5, .62, .012),
        (-.86, .1, .014),
      ]) {
        disc(Offset(x, y), s, _soft(ticks, .7));
      }
      canvas.save();
      canvas.rotate(-.42);
      final ringRect = Rect.fromCenter(
        center: Offset.zero,
        width: 1.8,
        height: .52,
      );
      canvas.drawArc(
        ringRect,
        pi,
        pi,
        false,
        stroke
          ..strokeWidth = .075
          ..color = _soft(accent, .55),
      );
      canvas.restore();
      final planet = Rect.fromCircle(center: Offset.zero, radius: .38);
      canvas.drawCircle(
        Offset.zero,
        .38,
        Paint()
          ..shader = RadialGradient(
            center: const Alignment(-.4, -.5),
            colors: [
              Color.lerp(ticks, Colors.white, .35)!,
              ticks,
              Color.lerp(ticks, face, .6)!,
            ],
            stops: const [0, .55, 1],
          ).createShader(planet),
      );
      canvas.save();
      canvas.rotate(-.42);
      canvas.drawArc(
        ringRect,
        0,
        pi,
        false,
        stroke
          ..strokeWidth = .075
          ..color = _soft(accent, .95),
      );
      canvas.restore();
      ring(Offset.zero, .8, .01, _soft(ticks, .35));
      disc(polar(-.5, .8), .05, accent);
      disc(polar(2.4, .8), .035, ticks);
    case AnalogStyle.stainedGlass:
      final palette = [
        _soft(ticks, .8),
        _soft(accent, .75),
        _soft(Color.lerp(ticks, accent, .5)!, .8),
        _soft(Colors.white, .55),
      ];
      Path sector(double a0, double a1, double r0, double r1) => Path()
        ..arcTo(
          Rect.fromCircle(center: Offset.zero, radius: r1),
          a0,
          a1 - a0,
          true,
        )
        ..arcTo(
          Rect.fromCircle(center: Offset.zero, radius: r0),
          a1,
          a0 - a1,
          false,
        )
        ..close();
      for (var i = 0; i < 12; i++) {
        final a0 = i * pi / 6 - pi / 2 - pi / 12;
        final a1 = a0 + pi / 6;
        canvas.drawPath(
          sector(a0, a1, .12, .52),
          fill..color = palette[(i + 1) % 4],
        );
        canvas.drawPath(
          sector(a0, a1, .52, 1.02),
          fill..color = palette[(i * 3) % 4],
        );
      }
      final lead = stroke
        ..strokeWidth = .028
        ..strokeCap = StrokeCap.butt
        ..color = _soft(face, .95);
      for (var i = 0; i < 12; i++) {
        final a = i * pi / 6 - pi / 2 - pi / 12;
        canvas.drawLine(polar(a, .12), polar(a, 1.02), lead);
      }
      ring(Offset.zero, .52, .028, face);
      ring(Offset.zero, .12, .028, face);
      disc(Offset.zero, .1, face);
    case AnalogStyle.blueprint:
      final grid = stroke
        ..strokeWidth = .006
        ..strokeCap = StrokeCap.butt
        ..color = _soft(ticks, .22);
      for (var i = -5; i <= 5; i++) {
        final v = i * .2;
        canvas.drawLine(Offset(v, -1), Offset(v, 1), grid);
        canvas.drawLine(Offset(-1, v), Offset(1, v), grid);
      }
      line(const Offset(-1, 0), const Offset(1, 0), .012, _soft(ticks, .55));
      line(const Offset(0, -1), const Offset(0, 1), .012, _soft(ticks, .55));
      for (var i = 0; i < 48; i++) {
        final a = i * pi / 24;
        if (i % 2 == 0) {
          canvas.drawArc(
            Rect.fromCircle(center: Offset.zero, radius: .7),
            a,
            pi / 24 * .8,
            false,
            stroke
              ..strokeWidth = .014
              ..color = _soft(ticks, .8),
          );
        }
      }
      canvas.drawArc(
        Rect.fromCircle(center: Offset.zero, radius: .34),
        -pi / 2,
        1.05,
        false,
        stroke
          ..strokeWidth = .02
          ..color = accent,
      );
      line(const Offset(-.78, .66), const Offset(.78, .66), .01, accent);
      for (final x in [-.78, .78]) {
        line(Offset(x, .6), Offset(x, .72), .01, accent);
      }
      line(const Offset(0, .6), const Offset(0, .72), .01, accent);
      for (final a in [-.9, -.2, 2.3]) {
        ring(polar(a, .7), .04, .012, accent);
      }
    case AnalogStyle.vinylRecord:
      for (var i = 0; i < 22; i++) {
        ring(
          Offset.zero,
          .36 + i * .028,
          .006,
          _soft(ticks, i % 5 == 0 ? .38 : .16),
        );
      }
      for (final turn in [0.0, pi]) {
        canvas.drawCircle(
          Offset.zero,
          1,
          Paint()
            ..shader = SweepGradient(
              colors: [
                _soft(Colors.white, 0),
                _soft(Colors.white, .2),
                _soft(Colors.white, 0),
              ],
              stops: const [0, .06, .12],
              transform: GradientRotation(turn - .4),
            ).createShader(Rect.fromCircle(center: Offset.zero, radius: 1)),
        );
      }
      disc(Offset.zero, .31, accent);
      ring(Offset.zero, .25, .012, _soft(face, .6));
      ring(Offset.zero, .18, .008, _soft(face, .45));
      disc(Offset.zero, .05, face);
    case AnalogStyle.gaugeDial:
      const start = 3 * pi / 4;
      const sweep = 3 * pi / 2;
      final track = Rect.fromCircle(center: Offset.zero, radius: .78);
      canvas.drawArc(
        track,
        start,
        sweep,
        false,
        stroke
          ..strokeWidth = .09
          ..strokeCap = StrokeCap.butt
          ..color = _soft(ticks, .2),
      );
      canvas.drawArc(
        track,
        start + sweep * .72,
        sweep * .28,
        false,
        stroke
          ..strokeWidth = .09
          ..color = _soft(accent, .9),
      );
      for (var i = 0; i <= 40; i++) {
        final a = start + sweep * i / 40;
        final major = i % 5 == 0;
        line(
          polar(a, major ? .56 : .62),
          polar(a, .68),
          major ? .022 : .01,
          _soft(i / 40 > .72 ? accent : ticks, major ? .95 : .55),
        );
      }
      ring(Offset.zero, .22, .014, _soft(ticks, .5));
      disc(Offset.zero, .06, accent);
    default:
      break;
  }
  canvas.restore();
  for (var i = 0; i < 12; i++) {
    final a = i * pi / 6;
    disc(Offset(sin(a), -cos(a)) * .93, i % 3 == 0 ? .024 : .009, ticks);
  }
  canvas.restore();
}

/// Draws the hand of an [extraAnalogStyles] face pointing up from [c]; false
/// when the style uses the shared hand.
bool paintExtraAnalogHand(
  Canvas canvas,
  Offset c,
  double r,
  AnalogPart part,
  AnalogStyle style,
  Color color,
  Color accent,
) {
  if (!extraAnalogStyles.contains(style)) return false;
  final hour = part == AnalogPart.hour, minute = part == AnalogPart.minute;
  final length = r * (hour ? .46 : (minute ? .68 : .78));
  final paint = Paint()
    ..isAntiAlias = true
    ..color = color;
  final stroke = Paint()
    ..isAntiAlias = true
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..color = color;
  final second = part == AnalogPart.second;
  Offset up(double d) => c - Offset(0, d);
  void secondHand() {
    canvas.drawLine(
      up(-r * .14),
      up(length),
      stroke
        ..color = accent
        ..strokeWidth = r * .018,
    );
    canvas.drawCircle(c, r * .045, Paint()..color = accent);
  }

  void shadow(Path p) => canvas.drawPath(
    p.shift(Offset(r * .012, r * .02)),
    Paint()
      ..color = Colors.black.withValues(alpha: .3)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * .015),
  );

  if (second) {
    secondHand();
    return true;
  }
  final w = r * (hour ? .05 : .036);

  switch (style) {
    case AnalogStyle.atomicStar:
      final kite = Path()
        ..moveTo(c.dx, c.dy - length)
        ..lineTo(c.dx + w, c.dy - length * .3)
        ..lineTo(c.dx, c.dy + r * .08)
        ..lineTo(c.dx - w, c.dy - length * .3)
        ..close();
      shadow(kite);
      canvas.drawPath(kite, paint);
      canvas.drawCircle(up(length), w * .55, Paint()..color = accent);
    case AnalogStyle.gearwork:
      final body = RRect.fromLTRBR(
        c.dx - w * .8,
        c.dy - length,
        c.dx + w * .8,
        c.dy + r * .08,
        Radius.circular(w * .8),
      );
      shadow(Path()..addRRect(body));
      canvas.drawRRect(
        body,
        stroke
          ..strokeWidth = r * .014
          ..color = color,
      );
      canvas.drawRRect(
        body.deflate(r * .012),
        Paint()..color = color.withValues(alpha: .22),
      );
      canvas.drawCircle(c, r * .07, Paint()..color = color);
      canvas.drawCircle(c, r * .03, Paint()..color = accent);
    case AnalogStyle.radarSweep:
      canvas.drawLine(
        c,
        up(length),
        stroke..strokeWidth = r * (hour ? .028 : .02),
      );
      canvas.drawCircle(up(length), r * .045, paint);
      canvas.drawCircle(c, r * .05, paint);
    case AnalogStyle.petalBloom:
      final petal = Rect.fromCenter(
        center: up(length / 2),
        width: w * 2.4,
        height: length,
      );
      shadow(Path()..addOval(petal));
      canvas.drawOval(petal, paint);
      canvas.drawOval(
        petal.deflate(r * .018),
        Paint()..color = Colors.white.withValues(alpha: .35),
      );
      canvas.drawCircle(c, r * .05, Paint()..color = accent);
    case AnalogStyle.ringedPlanet:
      final spike = Path()
        ..moveTo(c.dx, c.dy - length)
        ..lineTo(c.dx + w * .8, c.dy)
        ..lineTo(c.dx - w * .8, c.dy)
        ..close();
      shadow(spike);
      canvas.drawPath(spike, paint);
      canvas.drawCircle(c, r * .05, paint);
    case AnalogStyle.stainedGlass:
      final bar = RRect.fromLTRBR(
        c.dx - w * .9,
        c.dy - length,
        c.dx + w * .9,
        c.dy + r * .06,
        Radius.circular(w * .9),
      );
      shadow(Path()..addRRect(bar));
      canvas.drawRRect(
        bar.inflate(r * .012),
        Paint()..color = Colors.black.withValues(alpha: .55),
      );
      canvas.drawRRect(bar, paint);
      canvas.drawCircle(c, r * .06, Paint()..color = accent);
    case AnalogStyle.blueprint:
      for (final dx in [-w * .55, w * .55]) {
        canvas.drawLine(
          c + Offset(dx, 0),
          up(length * .92) + Offset(dx * .4, 0),
          stroke..strokeWidth = r * .012,
        );
      }
      canvas.drawLine(
        up(length * .92) + Offset(-w * .55, 0),
        up(length),
        stroke..strokeWidth = r * .012,
      );
      canvas.drawLine(
        up(length * .92) + Offset(w * .55, 0),
        up(length),
        stroke..strokeWidth = r * .012,
      );
      canvas.drawCircle(
        c,
        r * .055,
        stroke
          ..style = PaintingStyle.stroke
          ..strokeWidth = r * .014,
      );
    case AnalogStyle.vinylRecord:
      canvas.drawLine(
        up(-r * .1),
        up(length),
        stroke..strokeWidth = r * (hour ? .026 : .018),
      );
      canvas.save();
      canvas.translate(c.dx, c.dy - length);
      canvas.rotate(.35);
      final head = RRect.fromLTRBR(
        -r * .035,
        -r * .07,
        r * .035,
        r * .02,
        Radius.circular(r * .012),
      );
      canvas.drawRRect(head, paint);
      canvas.restore();
      canvas.drawCircle(c, r * .045, paint);
    case AnalogStyle.gaugeDial:
      final needle = Path()
        ..moveTo(c.dx, c.dy - length)
        ..lineTo(c.dx + w * .75, c.dy + r * .02)
        ..lineTo(c.dx - w * .75, c.dy + r * .02)
        ..close();
      shadow(needle);
      canvas.drawPath(needle, paint);
      canvas.drawCircle(c, r * .08, paint);
      canvas.drawCircle(c, r * .035, Paint()..color = accent);
    default:
      final hex = Path();
      for (var i = 0; i < 6; i++) {
        final a = pi / 6 + i * pi / 3;
        final v = c + Offset(cos(a), sin(a)) * r * .075;
        i == 0 ? hex.moveTo(v.dx, v.dy) : hex.lineTo(v.dx, v.dy);
      }
      hex.close();
      canvas.drawLine(
        c,
        up(length),
        stroke..strokeWidth = r * (hour ? .034 : .024),
      );
      canvas.drawPath(hex, paint);
  }
  return true;
}
