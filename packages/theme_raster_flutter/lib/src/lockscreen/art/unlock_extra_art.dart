import 'dart:math';

import 'package:flutter/material.dart';
import 'package:theme_core/theme_core.dart';

import '../lock_element.dart';
import 'unlock_studio_art.dart';

/// Tap-to-unlock skins added after the first set.
const extraTapSkins = {
  ...studioTapSkins,
  UnlockSkin.hexBadge,
  UnlockSkin.ticketPunch,
  UnlockSkin.keycap,
  UnlockSkin.domeRay,
  UnlockSkin.radarPulse,
  UnlockSkin.gemDiamond,
  UnlockSkin.shieldCrest,
  UnlockSkin.speechBubble,
  UnlockSkin.dialKnob,
  UnlockSkin.sealScallop,
};

/// Slide-to-unlock skins added after the first set.
const extraSlideSkins = {
  ...studioSlideSkins,
  UnlockSkin.dotTrail,
  UnlockSkin.zipper,
  UnlockSkin.rulerSlide,
  UnlockSkin.sunMoon,
  UnlockSkin.bracketTrack,
  UnlockSkin.stairSteps,
  UnlockSkin.ropeBead,
  UnlockSkin.slotPlate,
  UnlockSkin.waveTrack,
  UnlockSkin.pixelRun,
};

Color _alpha(Color c, double o) =>
    c.withValues(alpha: (c.a * o).clamp(0, 1).toDouble());

Color _lighten(Color c, double amount) {
  final hsl = HSLColor.fromColor(c);
  return hsl.withLightness((hsl.lightness + amount).clamp(0, 1)).toColor();
}

/// Paints the track (or, for tap controls, the whole button body) of an
/// extra skin; false when [el] doesn't use one.
bool paintExtraUnlockTrack(Canvas canvas, Size size, LockElement el, double k) {
  final tap = extraTapSkins.contains(el.unlockSkin);
  if (!tap && !extraSlideSkins.contains(el.unlockSkin)) return false;
  final w = size.width, h = size.height;
  final opacity = el.unlockBackgroundOpacity.clamp(0, 1).toDouble();
  final base = _alpha(el.colorSecondary, opacity);
  final blend = _alpha(
    Color.lerp(el.colorSecondary, el.unlockAccent, .45)!,
    opacity,
  );
  final accent = el.unlockAccent;
  final ink = el.color;
  final border = el.borderWidth * k;
  final hasText = el.unlockText.isNotEmpty;

  Paint fillOf(Rect r, [Color? a, Color? b]) => Paint()
    ..shader = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [a ?? base, b ?? blend],
    ).createShader(r);
  Paint stroke(Color c, double width, {StrokeCap cap = StrokeCap.round}) =>
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = width
        ..strokeCap = cap
        ..strokeJoin = StrokeJoin.round
        ..color = c;
  void outline(Path p) {
    if (border > 0) canvas.drawPath(p, stroke(el.borderColor, border));
  }

  void pill(Rect r, {double? radius}) {
    final rr = RRect.fromRectAndRadius(
      r,
      Radius.circular(
        min(radius ?? el.effectiveUnlockCornerRadius * k, r.height / 2),
      ),
    );
    canvas.drawRRect(rr, fillOf(r));
    if (border > 0) {
      canvas.drawRRect(rr.deflate(border / 2), stroke(el.borderColor, border));
    }
  }

  Path polygon(Offset c, double r, int n, double turn, {double squash = 1}) {
    final p = Path();
    for (var i = 0; i < n; i++) {
      final a = turn + i * 2 * pi / n;
      final v = c + Offset(cos(a) * squash, sin(a)) * r;
      i == 0 ? p.moveTo(v.dx, v.dy) : p.lineTo(v.dx, v.dy);
    }
    return p..close();
  }

  switch (el.unlockSkin) {
    case UnlockSkin.hexBadge:
      final area = hasText ? h * .78 : h;
      final c = Offset(w / 2, area / 2);
      final r = min(w, area) / 2 * .97;
      final hex = polygon(c, r, 6, -pi / 2, squash: .94);
      canvas.drawPath(hex, fillOf(Rect.fromCircle(center: c, radius: r)));
      canvas.drawPath(
        polygon(c, r * .8, 6, -pi / 2, squash: .94),
        stroke(_alpha(accent, .85), r * .035),
      );
      for (var i = 0; i < 6; i++) {
        final a = -pi / 2 + i * pi / 3;
        canvas.drawCircle(
          c + Offset(cos(a) * .94, sin(a)) * r * .9,
          r * .03,
          Paint()..color = _alpha(accent, .9),
        );
      }
      outline(hex);
    case UnlockSkin.ticketPunch:
      final corner = min(el.effectiveUnlockCornerRadius * k, h * .25);
      final split = w * .7;
      final body = Path()
        ..addRRect(
          RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(corner)),
        );
      final bites = Path()
        ..addOval(Rect.fromCircle(center: Offset(0, h / 2), radius: h * .13))
        ..addOval(Rect.fromCircle(center: Offset(w, h / 2), radius: h * .13))
        ..addOval(Rect.fromCircle(center: Offset(split, 0), radius: h * .1))
        ..addOval(Rect.fromCircle(center: Offset(split, h), radius: h * .1));
      final ticket = Path.combine(PathOperation.difference, body, bites);
      canvas.drawPath(ticket, fillOf(Offset.zero & size));
      var y = h * .16;
      while (y < h * .84) {
        canvas.drawLine(
          Offset(split, y),
          Offset(split, min(y + h * .07, h * .84)),
          stroke(_alpha(accent, .85), h * .02),
        );
        y += h * .12;
      }
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(h * .1, h * .1, split - h * .22, h * .8),
          Radius.circular(corner * .5),
        ),
        stroke(_alpha(accent, .35), h * .012),
      );
      outline(ticket);
    case UnlockSkin.keycap:
      final corner = min(el.effectiveUnlockCornerRadius * k, h * .22);
      final face = Rect.fromLTWH(0, 0, w, h * .84);
      final plate = RRect.fromRectAndRadius(
        face.shift(Offset(0, h * .14)),
        Radius.circular(corner),
      );
      canvas.drawRRect(
        plate,
        Paint()
          ..color = _alpha(_lighten(el.colorSecondary, -.22), max(opacity, .6)),
      );
      final top = RRect.fromRectAndRadius(face, Radius.circular(corner));
      canvas.drawRRect(
        top,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              _alpha(_lighten(el.colorSecondary, .1), max(opacity, .6)),
              base,
            ],
          ).createShader(face),
      );
      final dish = top.deflate(h * .07);
      canvas.drawRRect(
        dish,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withValues(alpha: .18),
              Colors.white.withValues(alpha: .1),
            ],
          ).createShader(dish.outerRect),
      );
      canvas.drawRRect(
        top.deflate(h * .012),
        stroke(Colors.white.withValues(alpha: .28), h * .02),
      );
      if (border > 0) canvas.drawRRect(top, stroke(el.borderColor, border));
    case UnlockSkin.domeRay:
      final r = min(w / 2 * .9, h * .66);
      final baseY = h * .92;
      final c = Offset(w / 2, baseY);
      final dome = Path()
        ..moveTo(c.dx - r, baseY)
        ..arcTo(Rect.fromCircle(center: c, radius: r), pi, pi, false)
        ..close();
      canvas.drawPath(dome, fillOf(Rect.fromCircle(center: c, radius: r)));
      canvas.drawArc(
        Rect.fromCircle(center: c, radius: r * .86),
        pi + .15,
        pi - .3,
        false,
        stroke(_alpha(accent, .55), r * .035),
      );
      for (var i = 0; i < 9; i++) {
        final a = pi + .38 + i * (pi - .76) / 8;
        final dir = Offset(cos(a), sin(a));
        canvas.drawLine(
          c + dir * r * 1.1,
          c + dir * r * (i.isEven ? 1.34 : 1.24),
          stroke(_alpha(accent, i.isEven ? .95 : .6), r * .04),
        );
      }
      canvas.drawLine(
        Offset(c.dx - r * 1.15, baseY),
        Offset(c.dx + r * 1.15, baseY),
        stroke(_alpha(accent, .9), r * .05),
      );
      outline(dome);
    case UnlockSkin.radarPulse:
      final area = hasText ? h * .78 : h;
      final c = Offset(w / 2, area / 2);
      final r = min(w, area) / 2 * .86;
      for (var i = 3; i >= 1; i--) {
        canvas.drawCircle(
          c,
          r * (.52 + i * .16),
          stroke(_alpha(accent, .62 / i), r * .05),
        );
      }
      final core = Rect.fromCircle(center: c, radius: r * .56);
      canvas.drawCircle(c, r * .56, fillOf(core));
      if (border > 0) {
        canvas.drawCircle(c, r * .56, stroke(el.borderColor, border));
      }
      for (var i = 0; i < 4; i++) {
        final dir = Offset(cos(i * pi / 2), sin(i * pi / 2));
        canvas.drawLine(
          c + dir * r * 1.06,
          c + dir * r * 1.18,
          stroke(_alpha(accent, .9), r * .05),
        );
      }
    case UnlockSkin.gemDiamond:
      final area = hasText ? h * .78 : h;
      final c = Offset(w / 2, area / 2);
      final rv = min(area / 2, w / 2 / .84) * .98;
      final rh = rv * .84;
      final outer = [
        c + Offset(0, -rv),
        c + Offset(rh, 0),
        c + Offset(0, rv),
        c + Offset(-rh, 0),
      ];
      final inner = [
        c + Offset(0, -rv * .5),
        c + Offset(rh * .5, 0),
        c + Offset(0, rv * .5),
        c + Offset(-rh * .5, 0),
      ];
      final gem = Path()..addPolygon(outer, true);
      canvas.drawPath(gem, fillOf(gem.getBounds()));
      for (var j = 0; j < 4; j++) {
        final facet = Path()
          ..addPolygon([
            outer[j],
            outer[(j + 1) % 4],
            inner[(j + 1) % 4],
            inner[j],
          ], true);
        canvas.drawPath(
          facet,
          Paint()
            ..color = j.isEven
                ? Colors.white.withValues(alpha: .16)
                : Colors.black.withValues(alpha: .14),
        );
      }
      canvas.drawPath(
        Path()..addPolygon(inner, true),
        stroke(_alpha(accent, .8), rv * .03),
      );
      for (var j = 0; j < 4; j++) {
        canvas.drawLine(
          outer[j],
          inner[j],
          stroke(_alpha(accent, .5), rv * .02),
        );
      }
      outline(gem);
    case UnlockSkin.shieldCrest:
      final area = hasText ? h * .8 : h;
      final left = w * .08, right = w * .92, top = h * .03, bottom = area * .98;
      final cx = w / 2;
      Path shield(double inset) {
        final l = left + inset, r = right - inset, t = top + inset;
        final b = bottom - inset * 1.2, m = t + (b - t) * .5;
        return Path()
          ..moveTo(l, t + (b - t) * .06)
          ..quadraticBezierTo(cx, t - (b - t) * .08, r, t + (b - t) * .06)
          ..lineTo(r, m)
          ..cubicTo(
            r,
            m + (b - m) * .7,
            cx + (r - cx) * .35,
            b - (b - m) * .15,
            cx,
            b,
          )
          ..cubicTo(
            cx - (r - cx) * .35,
            b - (b - m) * .15,
            l,
            m + (b - m) * .7,
            l,
            m,
          )
          ..close();
      }

      final outerShield = shield(0);
      canvas.drawPath(outerShield, fillOf(outerShield.getBounds()));
      canvas.drawPath(shield(w * .045), stroke(_alpha(accent, .8), w * .012));
      outline(outerShield);
    case UnlockSkin.speechBubble:
      final corner = min(el.effectiveUnlockCornerRadius * k, h * .25);
      final bodyRect = Rect.fromLTWH(0, 0, w, h * .8);
      final bubble = Path.combine(
        PathOperation.union,
        Path()..addRRect(
          RRect.fromRectAndRadius(bodyRect, Radius.circular(corner)),
        ),
        Path()
          ..moveTo(w * .16, h * .76)
          ..lineTo(w * .36, h * .76)
          ..lineTo(w * .15, h * .99)
          ..close(),
      );
      canvas.drawPath(bubble, fillOf(Offset.zero & size));
      canvas.drawPath(
        Path()..addRRect(
          RRect.fromRectAndRadius(
            bodyRect.deflate(h * .05),
            Radius.circular(corner * .7),
          ),
        ),
        stroke(_alpha(accent, .35), h * .012),
      );
      outline(bubble);
    case UnlockSkin.dialKnob:
      final area = hasText ? h * .78 : h;
      final c = Offset(w / 2, area / 2);
      final r = min(w, area) / 2 * .8;
      const lit = 6;
      for (var i = 0; i < 11; i++) {
        final a = 3 * pi / 4 + i * (3 * pi / 2) / 10;
        canvas.drawCircle(
          c + Offset(cos(a), sin(a)) * r * 1.2,
          r * .05,
          Paint()..color = _alpha(accent, i < lit ? .95 : .3),
        );
      }
      final knurl = Path();
      const teeth = 40;
      for (var i = 0; i < teeth * 2; i++) {
        final a = i * pi / teeth;
        final v = c + Offset(cos(a), sin(a)) * r * (i.isEven ? 1 : .955);
        i == 0 ? knurl.moveTo(v.dx, v.dy) : knurl.lineTo(v.dx, v.dy);
      }
      knurl.close();
      canvas.drawCircle(
        c + Offset(0, r * .06),
        r,
        Paint()
          ..color = Colors.black.withValues(alpha: .4)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * .06),
      );
      canvas.drawPath(
        knurl,
        Paint()
          ..shader = RadialGradient(
            center: const Alignment(-.4, -.5),
            colors: [_lighten(el.colorSecondary, .18), base],
          ).createShader(Rect.fromCircle(center: c, radius: r)),
      );
      canvas.drawCircle(
        c,
        r * .76,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withValues(alpha: .14),
              Colors.black.withValues(alpha: .2),
            ],
          ).createShader(Rect.fromCircle(center: c, radius: r * .76)),
      );
      canvas.drawLine(
        c + Offset(0, -r * .62),
        c + Offset(0, -r * .86),
        stroke(accent, r * .08),
      );
      outline(knurl);
    case UnlockSkin.sealScallop:
      final area = hasText ? h * .78 : h;
      final c = Offset(w / 2, area / 2);
      final r = min(w, area) / 2 * .96;
      final scallop = Path();
      const n = 360;
      for (var i = 0; i <= n; i++) {
        final a = i * 2 * pi / n;
        final v = c + Offset(cos(a), sin(a)) * r * (.92 + .08 * cos(a * 18));
        i == 0 ? scallop.moveTo(v.dx, v.dy) : scallop.lineTo(v.dx, v.dy);
      }
      scallop.close();
      canvas.drawPath(scallop, fillOf(Rect.fromCircle(center: c, radius: r)));
      final dash = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * .03
        ..strokeCap = StrokeCap.round
        ..color = _alpha(accent, .85);
      for (var i = 0; i < 36; i++) {
        canvas.drawArc(
          Rect.fromCircle(center: c, radius: r * .76),
          i * pi / 18,
          pi / 36,
          false,
          dash,
        );
      }
      canvas.drawCircle(
        c,
        r * .66,
        Paint()..color = Colors.black.withValues(alpha: .12),
      );
      outline(scallop);

    // ── Slide tracks ──────────────────────────────────────────────────────
    case UnlockSkin.dotTrail:
      pill(Offset.zero & size, radius: h / 2);
      final x0 = h * 1.05, x1 = w - h * .6;
      final n = max(2, ((x1 - x0) / (h * .26)).floor());
      for (var i = 0; i <= n; i++) {
        final t = i / n;
        canvas.drawCircle(
          Offset(x0 + (x1 - x0) * t, h / 2),
          h * (.03 + .035 * t),
          Paint()..color = _alpha(ink, .2 + .7 * t),
        );
      }
      canvas.drawCircle(
        Offset(w - h * .5, h / 2),
        h * .2,
        stroke(accent, h * .035),
      );
      canvas.drawCircle(
        Offset(w - h * .5, h / 2),
        h * .07,
        Paint()..color = accent,
      );
    case UnlockSkin.zipper:
      pill(Offset.zero & size, radius: h * .2);
      final x0 = h * 1.3, x1 = w - h * .3;
      canvas.drawLine(
        Offset(x0, h / 2),
        Offset(x1, h / 2),
        stroke(_alpha(accent, .45), h * .03),
      );
      var i = 0;
      for (var x = x0; x < x1; x += h * .16, i++) {
        final up = i.isEven;
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(
              x,
              h / 2 + (up ? -h * .13 : h * .01),
              h * .08,
              h * .12,
            ),
            Radius.circular(h * .02),
          ),
          Paint()..color = _alpha(accent, up ? .95 : .6),
        );
      }
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(w - h * .26, h * .3, h * .1, h * .4),
          Radius.circular(h * .03),
        ),
        Paint()..color = _alpha(accent, .9),
      );
    case UnlockSkin.rulerSlide:
      pill(Offset.zero & size, radius: h * .22);
      final step = h * .12;
      var i = 0;
      for (var x = h * .5; x < w - h * .3; x += step, i++) {
        final major = i % 5 == 0;
        final len = h * (major ? .2 : .1);
        final paint = stroke(
          _alpha(ink, major ? .75 : .38),
          h * .014,
          cap: StrokeCap.butt,
        );
        canvas.drawLine(Offset(x, h * .12), Offset(x, h * .12 + len), paint);
        canvas.drawLine(Offset(x, h * .88), Offset(x, h * .88 - len), paint);
      }
    case UnlockSkin.sunMoon:
      final rect = Offset.zero & size;
      final rr = RRect.fromRectAndRadius(rect, Radius.circular(h / 2));
      canvas.drawRRect(
        rr,
        Paint()
          ..shader = LinearGradient(
            colors: [
              _alpha(accent, max(opacity, .5)),
              _alpha(Color.lerp(accent, el.colorSecondary, .6)!, opacity),
              base,
            ],
            stops: const [0, .35, 1],
          ).createShader(rect),
      );
      for (final (x, y, s) in [
        (.58, .3, .022),
        (.7, .62, .016),
        (.78, .28, .018),
        (.64, .72, .012),
        (.86, .5, .014),
      ]) {
        canvas.drawCircle(
          Offset(w * x, h * y),
          h * s,
          Paint()..color = _alpha(ink, .8),
        );
      }
      final moon = Path.combine(
        PathOperation.difference,
        Path()..addOval(
          Rect.fromCircle(center: Offset(w - h * .52, h / 2), radius: h * .2),
        ),
        Path()..addOval(
          Rect.fromCircle(
            center: Offset(w - h * .44, h * .44),
            radius: h * .17,
          ),
        ),
      );
      canvas.drawPath(moon, Paint()..color = _alpha(ink, .9));
      if (border > 0) {
        canvas.drawRRect(
          rr.deflate(border / 2),
          stroke(el.borderColor, border),
        );
      }
    case UnlockSkin.bracketTrack:
      final r = RRect.fromRectAndRadius(
        Offset.zero & size,
        Radius.circular(h * .12),
      );
      canvas.drawRRect(r, fillOf(Offset.zero & size));
      final arm = h * .24;
      final p = stroke(
        _alpha(el.borderWidth > 0 ? el.borderColor : accent, .95),
        max(h * .035, border),
        cap: StrokeCap.square,
      );
      final inset = h * .06;
      for (final (sx, sy) in [(0.0, 0.0), (1.0, 0.0), (0.0, 1.0), (1.0, 1.0)]) {
        final x = inset + sx * (w - inset * 2),
            y = inset + sy * (h - inset * 2);
        final dx = sx == 0 ? 1.0 : -1.0, dy = sy == 0 ? 1.0 : -1.0;
        canvas.drawLine(Offset(x, y), Offset(x + dx * arm, y), p);
        canvas.drawLine(Offset(x, y), Offset(x, y + dy * arm), p);
      }
      var x = h * 1.45;
      while (x < w - h * .5) {
        canvas.drawLine(
          Offset(x, h / 2),
          Offset(min(x + h * .08, w - h * .5), h / 2),
          stroke(_alpha(ink, .55), h * .02),
        );
        x += h * .2;
      }
    case UnlockSkin.stairSteps:
      pill(Offset.zero & size, radius: h / 2);
      const n = 12;
      final x0 = h * 1.0, x1 = w - h * .45;
      final slot = (x1 - x0) / n;
      for (var i = 0; i < n; i++) {
        final t = i / (n - 1);
        final bh = h * (.18 + .5 * t);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(x0 + i * slot, h * .84 - bh, slot * .62, bh),
            Radius.circular(slot * .2),
          ),
          Paint()..color = _alpha(accent, .22 + .7 * t),
        );
      }
    case UnlockSkin.ropeBead:
      pill(Offset.zero & size, radius: h / 2);
      final x0 = h * .95, x1 = w - h * .4;
      for (var strand = 0; strand < 2; strand++) {
        final path = Path();
        for (var x = x0; x <= x1; x += 2) {
          final y = h / 2 + sin((x - x0) / (h * .12) + strand * pi) * h * .055;
          x == x0 ? path.moveTo(x, y) : path.lineTo(x, y);
        }
        canvas.drawPath(
          path,
          stroke(_alpha(strand == 0 ? ink : accent, .85), h * .05),
        );
      }
      canvas.drawCircle(
        Offset(w - h * .3, h / 2),
        h * .13,
        stroke(accent, h * .045),
      );
      canvas.drawLine(
        Offset(w - h * .43, h / 2),
        Offset(x1, h / 2),
        stroke(accent, h * .045),
      );
    case UnlockSkin.slotPlate:
      final rr = RRect.fromRectAndRadius(
        Offset.zero & size,
        Radius.circular(h * .14),
      );
      canvas.drawRRect(
        rr,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_lighten(base, .1), base, _lighten(base, -.1)],
          ).createShader(Offset.zero & size),
      );
      canvas.drawRRect(
        rr.deflate(h * .015),
        stroke(Colors.white.withValues(alpha: .3), h * .02),
      );
      for (final (sx, sy) in [(.12, .22), (.88, .22), (.12, .78), (.88, .78)]) {
        final c = Offset(w * sx, h * sy);
        final sr = h * .055;
        canvas.drawCircle(
          c,
          sr,
          Paint()..color = _lighten(el.colorSecondary, .12),
        );
        canvas.drawCircle(
          c,
          sr,
          stroke(Colors.black.withValues(alpha: .4), h * .012),
        );
        canvas.drawLine(
          c + Offset(-sr * .6, sr * .3),
          c + Offset(sr * .6, -sr * .3),
          stroke(Colors.black.withValues(alpha: .6), h * .014),
        );
      }
      final slot = RRect.fromLTRBR(
        h * .75,
        h * .32,
        w - h * .35,
        h * .68,
        Radius.circular(h * .18),
      );
      canvas.drawRRect(
        slot,
        Paint()..color = Colors.black.withValues(alpha: .5),
      );
      canvas.drawRRect(
        slot.deflate(h * .01),
        stroke(Colors.black.withValues(alpha: .35), h * .03),
      );
      canvas.drawLine(
        Offset(slot.left + h * .1, slot.bottom + h * .015),
        Offset(slot.right - h * .1, slot.bottom + h * .015),
        stroke(Colors.white.withValues(alpha: .25), h * .012),
      );
    case UnlockSkin.waveTrack:
      pill(Offset.zero & size, radius: h / 2);
      final x0 = h * .95, x1 = w - h * .35;
      for (var layer = 0; layer < 2; layer++) {
        final path = Path();
        for (var x = x0; x <= x1; x += 2) {
          final y =
              h / 2 +
              sin((x - x0) / (h * .34) + layer * 1.3) *
                  h *
                  (layer == 0 ? .17 : .11);
          x == x0 ? path.moveTo(x, y) : path.lineTo(x, y);
        }
        canvas.drawPath(
          path,
          stroke(
            layer == 0 ? accent : _alpha(ink, .4),
            h * (layer == 0 ? .045 : .028),
          ),
        );
      }
    case UnlockSkin.pixelRun:
      final p = max(2.0, (h * .07).roundToDouble());
      final path = Path()
        ..moveTo(p, 0)
        ..lineTo(w - p, 0)
        ..lineTo(w - p, p)
        ..lineTo(w, p)
        ..lineTo(w, h - p)
        ..lineTo(w - p, h - p)
        ..lineTo(w - p, h)
        ..lineTo(p, h)
        ..lineTo(p, h - p)
        ..lineTo(0, h - p)
        ..lineTo(0, p)
        ..lineTo(p, p)
        ..close();
      canvas.drawPath(path, fillOf(Offset.zero & size));
      canvas.drawPath(
        path,
        stroke(
          el.borderWidth > 0 ? el.borderColor : accent,
          max(p * .5, border),
          cap: StrokeCap.butt,
        ),
      );
      var i = 0;
      for (var x = h * 1.2; x < w - h * .5; x += p * 2.4, i++) {
        canvas.drawRect(
          Rect.fromLTWH(x, h / 2 - p / 2, p, p),
          Paint()
            ..color = _alpha(i % 3 == 0 ? accent : ink, i % 3 == 0 ? .95 : .3),
        );
      }
    default:
      return paintStudioUnlockTrack(canvas, size, el, k);
  }
  return true;
}

/// Paints the sliding thumb of an extra slide skin; false for other skins.
bool paintExtraUnlockThumb(Canvas canvas, Size size, LockElement el, double k) {
  if (!extraSlideSkins.contains(el.unlockSkin)) return false;
  final w = size.width, h = size.height;
  final opacity = el.unlockThumbOpacity.clamp(0, 1).toDouble();
  final accent = el.unlockAccent;
  final ink = el.color;
  final border = el.borderWidth * k;
  Paint stroke(Color c, double width, {StrokeCap cap = StrokeCap.round}) =>
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = width
        ..strokeCap = cap
        ..color = c;
  Paint glossy(Rect r, {double lift = .22}) => Paint()
    ..shader = RadialGradient(
      center: const Alignment(-.35, -.45),
      colors: [
        _alpha(_lighten(accent, lift), opacity),
        _alpha(accent, opacity),
        _alpha(_lighten(accent, -.14), opacity),
      ],
      stops: const [0, .6, 1],
    ).createShader(r);
  final pad = h * .1;
  final disc = Rect.fromLTWH(
    w / 2 - (h - pad * 2) / 2,
    pad,
    h - pad * 2,
    h - pad * 2,
  );
  final center = Offset(w / 2, h / 2);

  switch (el.unlockSkin) {
    case UnlockSkin.dotTrail:
      canvas.drawCircle(
        center,
        h * .46,
        Paint()..color = _alpha(accent, .22 * opacity),
      );
      canvas.drawOval(disc.deflate(h * .06), glossy(disc));
      canvas.drawCircle(
        center,
        h * .37,
        stroke(Colors.white.withValues(alpha: .75), h * .025),
      );
    case UnlockSkin.zipper:
      final tab = RRect.fromRectAndRadius(
        Rect.fromLTWH(h * .08, h * .14, w - h * .16, h * .72),
        Radius.circular(h * .22),
      );
      canvas.drawShadow(Path()..addRRect(tab), Colors.black, h * .05, false);
      canvas.drawRRect(
        tab,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              _alpha(_lighten(accent, .25), opacity),
              _alpha(accent, opacity),
              _alpha(_lighten(accent, -.15), opacity),
            ],
          ).createShader(tab.outerRect),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(w * .72, h / 2),
            width: w * .26,
            height: h * .3,
          ),
          Radius.circular(h * .15),
        ),
        Paint()..color = Colors.black.withValues(alpha: .45),
      );
    case UnlockSkin.rulerSlide:
      final bar = RRect.fromRectAndRadius(
        Rect.fromLTWH(w * .12, h * .06, w * .76, h * .88),
        Radius.circular(w * .3),
      );
      canvas.drawShadow(Path()..addRRect(bar), Colors.black, h * .05, false);
      canvas.drawRRect(
        bar,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              _alpha(_lighten(accent, .18), opacity),
              _alpha(accent, opacity),
            ],
          ).createShader(bar.outerRect),
      );
      for (var i = -1; i <= 1; i++) {
        canvas.drawLine(
          Offset(w / 2 + i * w * .14, h * .28),
          Offset(w / 2 + i * w * .14, h * .72),
          stroke(Colors.black.withValues(alpha: .35), h * .018),
        );
      }
    case UnlockSkin.sunMoon:
      final sun = disc.deflate(h * .08);
      final c = sun.center;
      for (var i = 0; i < 12; i++) {
        final a = i * pi / 6;
        final dir = Offset(cos(a), sin(a));
        canvas.drawLine(
          c + dir * sun.width * .58,
          c + dir * sun.width * (i.isEven ? .78 : .7),
          stroke(
            _alpha(Color.lerp(accent, Colors.white, .5)!, opacity),
            h * .03,
          ),
        );
      }
      canvas.drawOval(
        sun,
        Paint()
          ..shader = RadialGradient(
            colors: [
              _alpha(Colors.white, opacity),
              _alpha(Color.lerp(accent, Colors.white, .45)!, opacity),
              _alpha(accent, opacity),
            ],
            stops: const [0, .45, 1],
          ).createShader(sun),
      );
    case UnlockSkin.bracketTrack:
      final arrow = Path()
        ..moveTo(h * .12, h * .2)
        ..lineTo(w - h * .42, h * .2)
        ..lineTo(w - h * .1, h / 2)
        ..lineTo(w - h * .42, h * .8)
        ..lineTo(h * .12, h * .8)
        ..close();
      canvas.drawPath(arrow, Paint()..color = _alpha(accent, opacity));
      canvas.drawPath(
        arrow,
        stroke(
          _alpha(Colors.white, .5 * opacity),
          h * .02,
          cap: StrokeCap.butt,
        ),
      );
      if (border > 0) canvas.drawPath(arrow, stroke(el.borderColor, border));
    case UnlockSkin.stairSteps:
      canvas.drawCircle(
        center,
        h * .44,
        Paint()..color = _alpha(accent, .2 * opacity),
      );
      canvas.drawOval(disc.deflate(h * .04), glossy(disc, lift: .16));
      canvas.drawArc(
        disc.deflate(h * .04),
        pi * 1.1,
        pi * .5,
        false,
        stroke(Colors.white.withValues(alpha: .55), h * .03),
      );
    case UnlockSkin.ropeBead:
      canvas.drawShadow(Path()..addOval(disc), Colors.black, h * .05, false);
      canvas.drawOval(disc, glossy(disc, lift: .3));
      canvas.drawCircle(
        center,
        h * .35,
        stroke(Colors.black.withValues(alpha: .18), h * .02),
      );
      canvas.drawOval(
        Rect.fromLTWH(
          disc.left + disc.width * .2,
          disc.top + disc.height * .1,
          disc.width * .45,
          disc.height * .25,
        ),
        Paint()..color = Colors.white.withValues(alpha: .45),
      );
    case UnlockSkin.slotPlate:
      final knob = RRect.fromRectAndRadius(
        Rect.fromLTWH(h * .1, h * .12, w - h * .2, h * .76),
        Radius.circular(h * .14),
      );
      canvas.drawShadow(Path()..addRRect(knob), Colors.black, h * .07, false);
      canvas.drawRRect(
        knob,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              _alpha(_lighten(accent, .22), opacity),
              _alpha(accent, opacity),
              _alpha(_lighten(accent, -.2), opacity),
            ],
          ).createShader(knob.outerRect),
      );
      for (var i = 0; i < 5; i++) {
        final x = knob.left + knob.width * (.28 + i * .11);
        canvas.drawLine(
          Offset(x, knob.top + h * .1),
          Offset(x, knob.bottom - h * .1),
          stroke(Colors.black.withValues(alpha: .3), h * .016),
        );
      }
    case UnlockSkin.waveTrack:
      canvas.drawCircle(
        center,
        h * .42,
        Paint()..color = _alpha(accent, .2 * opacity),
      );
      canvas.drawOval(disc, glossy(disc));
      canvas.drawCircle(center, h * .3, stroke(_alpha(ink, .7), h * .02));
    case UnlockSkin.pixelRun:
      final p = max(2.0, (h * .07).roundToDouble());
      final block = Rect.fromLTWH(h * .12, h * .12, w - h * .24, h * .76);
      canvas.drawRect(
        block.shift(Offset(p, p)),
        Paint()..color = Colors.black.withValues(alpha: .35 * opacity),
      );
      canvas.drawRect(block, Paint()..color = _alpha(accent, opacity));
      canvas.drawRect(
        Rect.fromLTWH(block.left, block.top, block.width, p),
        Paint()..color = Colors.white.withValues(alpha: .4),
      );
      canvas.drawRect(
        Rect.fromLTWH(block.left, block.top, p, block.height),
        Paint()..color = Colors.white.withValues(alpha: .4),
      );
      canvas.drawRect(
        Rect.fromLTWH(block.left, block.bottom - p, block.width, p),
        Paint()..color = Colors.black.withValues(alpha: .25),
      );
      canvas.drawRect(
        Rect.fromLTWH(block.right - p, block.top, p, block.height),
        Paint()..color = Colors.black.withValues(alpha: .25),
      );
    default:
      return paintStudioUnlockThumb(canvas, size, el, k);
  }
  return true;
}
