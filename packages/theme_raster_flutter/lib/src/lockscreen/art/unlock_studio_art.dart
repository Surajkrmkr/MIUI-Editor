import 'dart:math';

import 'package:flutter/material.dart';
import 'package:theme_core/theme_core.dart';

import '../lock_element.dart';

/// Suraj's studio tap-to-unlock skins; the body is drawn centred like the
/// default tap layout (icon in the middle, text underneath).
const studioTapSkins = {
  UnlockSkin.petalFlower,
  UnlockSkin.cloudPuff,
  UnlockSkin.roundTriangle,
  UnlockSkin.capsuleSplit,
  UnlockSkin.viewfinder,
  UnlockSkin.droplet,
  UnlockSkin.homePlate,
  UnlockSkin.nightSky,
  UnlockSkin.layeredDiscs,
  UnlockSkin.ribbonBanner,
};

/// Suraj's studio slide-to-unlock skins.
const studioSlideSkins = {
  UnlockSkin.batteryCharge,
  UnlockSkin.gradientRail,
  UnlockSkin.arrowTrack,
  UnlockSkin.filmStrip,
  UnlockSkin.dualPill,
  UnlockSkin.stubTicket,
  UnlockSkin.starPath,
  UnlockSkin.keyhole,
  UnlockSkin.glassTube,
  UnlockSkin.heartbeat,
};

Color _alpha(Color c, double o) =>
    c.withValues(alpha: (c.a * o).clamp(0, 1).toDouble());

Color _lighten(Color c, double amount) {
  final hsl = HSLColor.fromColor(c);
  return hsl.withLightness((hsl.lightness + amount).clamp(0, 1)).toColor();
}

Paint _stroke(Color c, double width, {StrokeCap cap = StrokeCap.round}) =>
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..strokeCap = cap
      ..strokeJoin = StrokeJoin.round
      ..color = c;

/// Closed polygon through [points] with corners rounded by [radius].
Path _roundedPoly(List<Offset> points, double radius) {
  final path = Path();
  final n = points.length;
  for (var i = 0; i < n; i++) {
    final prev = points[(i + n - 1) % n],
        p = points[i],
        next = points[(i + 1) % n];
    final toPrev = prev - p, toNext = next - p;
    final a = p + toPrev / toPrev.distance * min(radius, toPrev.distance / 2);
    final b = p + toNext / toNext.distance * min(radius, toNext.distance / 2);
    i == 0 ? path.moveTo(a.dx, a.dy) : path.lineTo(a.dx, a.dy);
    path.quadraticBezierTo(p.dx, p.dy, b.dx, b.dy);
  }
  return path..close();
}

Path _star(Offset c, double r, {int points = 5, double inner = .46}) {
  final path = Path();
  for (var i = 0; i < points * 2; i++) {
    final a = -pi / 2 + i * pi / points;
    final v = c + Offset(cos(a), sin(a)) * r * (i.isEven ? 1 : inner);
    i == 0 ? path.moveTo(v.dx, v.dy) : path.lineTo(v.dx, v.dy);
  }
  return path..close();
}

/// Everything a skin painter needs, derived once from the element.
class _Ctx {
  _Ctx(this.canvas, this.size, this.el, this.k)
    : w = size.width,
      h = size.height,
      opacity = el.unlockBackgroundOpacity.clamp(0, 1).toDouble(),
      accent = el.unlockAccent,
      ink = el.color,
      border = el.borderWidth * k,
      hasText = el.unlockText.isNotEmpty {
    base = _alpha(el.colorSecondary, opacity);
    blend = _alpha(Color.lerp(el.colorSecondary, accent, .45)!, opacity);
  }

  final Canvas canvas;
  final Size size;
  final LockElement el;
  final double k, w, h, opacity, border;
  final Color accent, ink;
  final bool hasText;
  late final Color base, blend;

  /// Centre and radius of a round body, matching the default tap layout.
  Offset get center => Offset(w / 2, hasText ? h * .38 : h / 2);
  double get radius => min(w, hasText ? h * .7 : h) / 2 * .96;

  Paint fill(Rect r, [Color? a, Color? b]) => Paint()
    ..shader = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [a ?? base, b ?? blend],
    ).createShader(r);

  void outline(Path p) {
    if (border > 0) canvas.drawPath(p, _stroke(el.borderColor, border));
  }

  void pill(Rect r, {double? radius}) {
    final rr = RRect.fromRectAndRadius(
      r,
      Radius.circular(
        min(radius ?? el.effectiveUnlockCornerRadius * k, r.height / 2),
      ),
    );
    canvas.drawRRect(rr, fill(r));
    if (border > 0) {
      canvas.drawRRect(rr.deflate(border / 2), _stroke(el.borderColor, border));
    }
  }
}

/// Paints the track, or for tap controls the whole body, of a studio skin;
/// false for other skins.
bool paintStudioUnlockTrack(
  Canvas canvas,
  Size size,
  LockElement el,
  double k,
) {
  final c = _Ctx(canvas, size, el, k);
  final w = c.w, h = c.h;
  final accent = c.accent, ink = c.ink;
  final ctr = c.center;
  final r = c.radius;
  switch (el.unlockSkin) {
    // ── Tap bodies ────────────────────────────────────────────────────────
    case UnlockSkin.petalFlower:
      for (var i = 0; i < 8; i++) {
        canvas.save();
        canvas.translate(ctr.dx, ctr.dy);
        canvas.rotate(i * pi / 4);
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(0, -r * .56),
            width: r * .56,
            height: r * .86,
          ),
          Paint()..color = i.isEven ? c.blend : c.base,
        );
        canvas.restore();
      }
      final core = Rect.fromCircle(center: ctr, radius: r * .52);
      canvas.drawCircle(ctr, r * .52, c.fill(core));
      canvas.drawCircle(ctr, r * .52, _stroke(_alpha(accent, .85), r * .04));
      if (c.border > 0) {
        canvas.drawCircle(ctr, r * .52, _stroke(el.borderColor, c.border));
      }
    case UnlockSkin.cloudPuff:
      final dy = r * .1;
      final cloud = Path()
        ..addRRect(
          RRect.fromLTRBR(
            ctr.dx - r * .92,
            ctr.dy + dy,
            ctr.dx + r * .92,
            ctr.dy + r * .62 + dy,
            Radius.circular(r * .3),
          ),
        );
      for (final (x, y, rr) in [
        (-.45, .1, .4),
        (.02, -.16, .52),
        (.5, .12, .36),
      ]) {
        cloud.addOval(
          Rect.fromCircle(
            center: ctr + Offset(r * x, r * y + dy),
            radius: r * rr,
          ),
        );
      }
      final merged = cloud;
      canvas.drawPath(merged, c.fill(merged.getBounds()));
      canvas.drawArc(
        Rect.fromCircle(
          center: ctr + Offset(r * .02, -r * .16 + dy),
          radius: r * .4,
        ),
        pi * 1.05,
        pi * .5,
        false,
        _stroke(_alpha(accent, .6), r * .035),
      );
      c.outline(merged);
    case UnlockSkin.roundTriangle:
      final tri = _roundedPoly([
        ctr + Offset(0, -r),
        ctr + Offset(r * .98, r * .8),
        ctr + Offset(-r * .98, r * .8),
      ], r * .2);
      canvas.drawPath(tri, c.fill(tri.getBounds()));
      final inner = _roundedPoly([
        ctr + Offset(0, -r * .66),
        ctr + Offset(r * .68, r * .56),
        ctr + Offset(-r * .68, r * .56),
      ], r * .12);
      canvas.drawPath(inner, _stroke(_alpha(accent, .65), r * .035));
      c.outline(tri);
    case UnlockSkin.capsuleSplit:
      final disc = Path()..addOval(Rect.fromCircle(center: ctr, radius: r));
      canvas.save();
      canvas.clipPath(disc);
      final box = Rect.fromCircle(center: ctr, radius: r);
      canvas.drawRect(box, c.fill(box));
      canvas.drawRect(
        Rect.fromLTRB(box.left, box.top, box.right, ctr.dy),
        Paint()..color = _alpha(accent, .85),
      );
      canvas.drawRect(
        Rect.fromLTRB(box.left, ctr.dy - r * .07, box.right, ctr.dy + r * .07),
        Paint()..color = Colors.black.withValues(alpha: .55),
      );
      canvas.restore();
      canvas.drawCircle(ctr, r * .34, Paint()..color = c.base);
      canvas.drawCircle(ctr, r * .34, _stroke(_alpha(ink, .8), r * .05));
      canvas.drawCircle(ctr, r, _stroke(_alpha(ink, .7), r * .035));
      c.outline(disc);
    case UnlockSkin.viewfinder:
      final area = c.hasText ? h * .78 : h;
      final body = RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, w, area),
        Radius.circular(min(el.effectiveUnlockCornerRadius * k, area * .14)),
      );
      canvas.drawRRect(body, c.fill(body.outerRect));
      final arm = min(w, area) * .2;
      final p = _stroke(
        _alpha(el.borderWidth > 0 ? el.borderColor : accent, .95),
        max(area * .03, c.border),
        cap: StrokeCap.square,
      );
      final inset = area * .07;
      for (final (sx, sy) in [(0.0, 0.0), (1.0, 0.0), (0.0, 1.0), (1.0, 1.0)]) {
        final x = inset + sx * (w - inset * 2);
        final y = inset + sy * (area - inset * 2);
        final dx = sx == 0 ? 1.0 : -1.0, dy = sy == 0 ? 1.0 : -1.0;
        canvas.drawLine(Offset(x, y), Offset(x + dx * arm, y), p);
        canvas.drawLine(Offset(x, y), Offset(x, y + dy * arm), p);
      }
      final mid = Offset(w / 2, area / 2);
      for (final d in [
        const Offset(1, 0),
        const Offset(-1, 0),
        const Offset(0, 1),
        const Offset(0, -1),
      ]) {
        canvas.drawLine(
          mid + d * area * .3,
          mid + d * area * .38,
          _stroke(_alpha(ink, .55), area * .015),
        );
      }
    case UnlockSkin.droplet:
      final cy = ctr.dy + r * .16;
      final cr = r * .8;
      final drop = Path()
        ..moveTo(ctr.dx, ctr.dy - r * .98)
        ..cubicTo(
          ctr.dx + cr * .12,
          ctr.dy - r * .5,
          ctr.dx + cr,
          cy - cr * .75,
          ctr.dx + cr,
          cy,
        )
        ..arcToPoint(
          Offset(ctr.dx - cr, cy),
          radius: Radius.circular(cr),
          clockwise: true,
        )
        ..cubicTo(
          ctr.dx - cr,
          cy - cr * .75,
          ctr.dx - cr * .12,
          ctr.dy - r * .5,
          ctr.dx,
          ctr.dy - r * .98,
        )
        ..close();
      canvas.drawPath(drop, c.fill(drop.getBounds()));
      canvas.drawArc(
        Rect.fromCircle(center: Offset(ctr.dx, cy), radius: cr * .74),
        pi * .62,
        pi * .3,
        false,
        _stroke(Colors.white.withValues(alpha: .6), r * .05),
      );
      c.outline(drop);
    case UnlockSkin.homePlate:
      final plate = _roundedPoly([
        ctr + Offset(0, -r),
        ctr + Offset(r * .92, -r * .22),
        ctr + Offset(r * .92, r * .9),
        ctr + Offset(-r * .92, r * .9),
        ctr + Offset(-r * .92, -r * .22),
      ], r * .16);
      canvas.drawPath(plate, c.fill(plate.getBounds()));
      canvas.drawPath(
        _roundedPoly([
          ctr + Offset(0, -r * .74),
          ctr + Offset(r * .7, -r * .14),
          ctr + Offset(r * .7, r * .68),
          ctr + Offset(-r * .7, r * .68),
          ctr + Offset(-r * .7, -r * .14),
        ], r * .1),
        _stroke(_alpha(accent, .55), r * .03),
      );
      c.outline(plate);
    case UnlockSkin.nightSky:
      final disc = Path()..addOval(Rect.fromCircle(center: ctr, radius: r));
      canvas.drawPath(
        disc,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              _alpha(Color.lerp(el.colorSecondary, accent, .55)!, c.opacity),
              c.base,
            ],
          ).createShader(Rect.fromCircle(center: ctr, radius: r)),
      );
      for (final (x, y, s) in [
        (-.55, -.5, .1),
        (.6, -.28, .07),
        (-.3, .62, .08),
        (.52, .55, .1),
        (-.72, .1, .05),
        (.1, -.78, .06),
      ]) {
        canvas.drawPath(
          _star(ctr + Offset(r * x, r * y), r * s, points: 4, inner: .3),
          Paint()..color = _alpha(ink, .9),
        );
      }
      canvas.drawCircle(ctr, r, _stroke(_alpha(accent, .55), r * .035));
      c.outline(disc);
    case UnlockSkin.layeredDiscs:
      for (var i = 2; i >= 0; i--) {
        final rr = r * (.82 - i * .06);
        final center = ctr + Offset(0, r * .12 - i * r * .17);
        final rect = Rect.fromCircle(center: center, radius: rr);
        canvas.drawCircle(
          center,
          rr,
          i == 0
              ? c.fill(rect)
              : (Paint()..color = _alpha(accent, i == 1 ? .5 : .28)),
        );
        canvas.drawCircle(
          center,
          rr,
          _stroke(_alpha(ink, i == 0 ? .6 : .25), r * .02),
        );
      }
      if (c.border > 0) {
        canvas.drawCircle(
          ctr + Offset(0, r * .12),
          r * .82,
          _stroke(el.borderColor, c.border),
        );
      }
    case UnlockSkin.ribbonBanner:
      final bodyH = c.hasText ? h * .74 : h * .9;
      final main = Rect.fromLTWH(w * .1, 0, w * .8, bodyH * .82);
      final tails = Path()
        ..moveTo(0, bodyH * .16)
        ..lineTo(w * .22, bodyH * .16)
        ..lineTo(w * .22, bodyH)
        ..lineTo(0, bodyH)
        ..lineTo(w * .06, bodyH * .58)
        ..close()
        ..moveTo(w, bodyH * .16)
        ..lineTo(w * .78, bodyH * .16)
        ..lineTo(w * .78, bodyH)
        ..lineTo(w, bodyH)
        ..lineTo(w * .94, bodyH * .58)
        ..close();
      canvas.drawPath(tails, Paint()..color = _lighten(c.blend, -.08));
      canvas.drawPath(
        Path()
          ..moveTo(w * .1, bodyH * .82)
          ..lineTo(w * .22, bodyH * .82)
          ..lineTo(w * .22, bodyH)
          ..close()
          ..moveTo(w * .9, bodyH * .82)
          ..lineTo(w * .78, bodyH * .82)
          ..lineTo(w * .78, bodyH)
          ..close(),
        Paint()..color = Colors.black.withValues(alpha: .35),
      );
      final rr = RRect.fromRectAndRadius(
        main,
        Radius.circular(
          min(el.effectiveUnlockCornerRadius * k, main.height * .2),
        ),
      );
      canvas.drawRRect(rr, c.fill(main));
      canvas.drawRRect(
        rr.deflate(main.height * .08),
        _stroke(_alpha(accent, .45), main.height * .02),
      );
      if (c.border > 0) canvas.drawRRect(rr, _stroke(el.borderColor, c.border));

    // ── Slide tracks ──────────────────────────────────────────────────────
    case UnlockSkin.batteryCharge:
      final bodyW = w - h * .14;
      final body = RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, bodyW, h),
        Radius.circular(h * .22),
      );
      canvas.drawRRect(body, c.fill(body.outerRect));
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(w - h * .12, h * .33, h * .12, h * .34),
          Radius.circular(h * .05),
        ),
        Paint()..color = _alpha(accent, .9),
      );
      canvas.drawRRect(
        body.deflate(h * .02),
        _stroke(
          _alpha(el.borderWidth > 0 ? el.borderColor : accent, .9),
          max(h * .04, c.border),
        ),
      );
      final x0 = h * 1.3, x1 = bodyW - h * .14;
      final cells = max(3, ((x1 - x0) / (h * .26)).floor());
      final cw = (x1 - x0) / cells;
      for (var i = 0; i < cells; i++) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(x0 + i * cw, h * .24, cw * .72, h * .52),
            Radius.circular(h * .05),
          ),
          Paint()..color = _alpha(accent, .12 + .3 * i / cells),
        );
      }
    case UnlockSkin.gradientRail:
      canvas.drawRRect(
        RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(h / 2)),
        Paint()..color = _alpha(c.base, .55),
      );
      final x0 = h * .9, x1 = w - h * .5;
      final line = Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = h * .045
        ..shader = LinearGradient(
          colors: [_alpha(ink, .3), accent],
        ).createShader(Rect.fromLTRB(x0, 0, x1, h));
      canvas.drawLine(
        Offset(x0, h / 2),
        Offset(x1, h / 2),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = h * .1
          ..color = _alpha(accent, .5)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, h * .05),
      );
      canvas.drawLine(Offset(x0, h / 2), Offset(x1, h / 2), line);
      canvas.drawCircle(
        Offset(w - h * .4, h / 2),
        h * .17,
        _stroke(accent, h * .04),
      );
      canvas.drawCircle(
        Offset(w - h * .4, h / 2),
        h * .06,
        Paint()..color = accent,
      );
    case UnlockSkin.arrowTrack:
      c.pill(Offset.zero & size, radius: h / 2);
      final x0 = h * 1.1, x1 = w - h * .45;
      final step = h * .32;
      final n = max(2, ((x1 - x0) / step).floor());
      for (var i = 0; i <= n; i++) {
        final t = i / n;
        final x = x0 + (x1 - x0) * t;
        final s = h * (.1 + .06 * t);
        canvas.drawPath(
          Path()
            ..moveTo(x - s * .5, h / 2 - s)
            ..lineTo(x + s * .5, h / 2)
            ..lineTo(x - s * .5, h / 2 + s),
          _stroke(_alpha(i.isEven ? accent : ink, .2 + .75 * t), h * .04),
        );
      }
    case UnlockSkin.filmStrip:
      final rr = RRect.fromRectAndRadius(
        Offset.zero & size,
        Radius.circular(h * .1),
      );
      canvas.drawRRect(rr, c.fill(Offset.zero & size));
      final hole = Paint()..color = _alpha(ink, .6);
      for (var x = h * .18; x < w - h * .2; x += h * .2) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(x, h * .07, h * .1, h * .07),
            Radius.circular(h * .02),
          ),
          hole,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(x, h * .86, h * .1, h * .07),
            Radius.circular(h * .02),
          ),
          hole,
        );
      }
      for (var x = h * 1.55; x + h * .8 < w - h * .1; x += h * 1.0) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(x, h * .22, h * .8, h * .56),
            Radius.circular(h * .04),
          ),
          _stroke(_alpha(ink, .22), h * .014),
        );
      }
      if (c.border > 0) canvas.drawRRect(rr, _stroke(el.borderColor, c.border));
    case UnlockSkin.dualPill:
      final rr = RRect.fromRectAndRadius(
        Offset.zero & size,
        Radius.circular(h / 2),
      );
      canvas.drawRRect(rr, c.fill(Offset.zero & size));
      canvas.save();
      canvas.clipRRect(rr);
      canvas.drawPath(
        Path()
          ..moveTo(w * .56, 0)
          ..lineTo(w, 0)
          ..lineTo(w, h)
          ..lineTo(w * .56 - h * .3, h)
          ..close(),
        Paint()..color = _alpha(accent, .3),
      );
      canvas.drawLine(
        Offset(w * .56, 0),
        Offset(w * .56 - h * .3, h),
        _stroke(_alpha(accent, .8), h * .03),
      );
      canvas.restore();
      if (c.border > 0) {
        canvas.drawRRect(
          rr.deflate(c.border / 2),
          _stroke(el.borderColor, c.border),
        );
      }
    case UnlockSkin.stubTicket:
      final cut = w * .8;
      final body = Path.combine(
        PathOperation.difference,
        Path()..addRRect(
          RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(h * .2)),
        ),
        Path()
          ..addOval(Rect.fromCircle(center: Offset(cut, 0), radius: h * .12))
          ..addOval(Rect.fromCircle(center: Offset(cut, h), radius: h * .12)),
      );
      canvas.drawPath(body, c.fill(Offset.zero & size));
      var y = h * .2;
      while (y < h * .8) {
        canvas.drawLine(
          Offset(cut, y),
          Offset(cut, min(y + h * .08, h * .8)),
          _stroke(_alpha(accent, .8), h * .022),
        );
        y += h * .14;
      }
      for (var i = 0; i < 2; i++) {
        final x = cut + h * .24 + i * h * .2;
        canvas.drawPath(
          Path()
            ..moveTo(x, h * .38)
            ..lineTo(x + h * .1, h / 2)
            ..lineTo(x, h * .62),
          _stroke(_alpha(accent, .5 + i * .4), h * .04),
        );
      }
      c.outline(body);
    case UnlockSkin.starPath:
      c.pill(Offset.zero & size, radius: h / 2);
      final x0 = h * 1.05, x1 = w - h * .65;
      final n = max(2, ((x1 - x0) / (h * .3)).floor());
      for (var i = 0; i <= n; i++) {
        final t = i / n;
        canvas.drawPath(
          _star(Offset(x0 + (x1 - x0) * t, h / 2), h * (.05 + .07 * t)),
          Paint()..color = _alpha(i.isEven ? accent : ink, .25 + .7 * t),
        );
      }
      canvas.drawPath(
        _star(Offset(w - h * .42, h / 2), h * .2),
        _stroke(accent, h * .035),
      );
    case UnlockSkin.keyhole:
      c.pill(Offset.zero & size, radius: h / 2);
      final x0 = h * .95, x1 = w - h * .75;
      canvas.drawLine(
        Offset(x0, h / 2),
        Offset(x1, h / 2),
        _stroke(_alpha(ink, .3), h * .03),
      );
      final kc = Offset(w - h * .42, h * .42);
      final hole = Path()
        ..addOval(Rect.fromCircle(center: kc, radius: h * .13))
        ..moveTo(kc.dx - h * .06, kc.dy + h * .08)
        ..lineTo(kc.dx + h * .06, kc.dy + h * .08)
        ..lineTo(kc.dx + h * .1, kc.dy + h * .3)
        ..lineTo(kc.dx - h * .1, kc.dy + h * .3)
        ..close();
      canvas.drawPath(hole, Paint()..color = _alpha(accent, .95));
    case UnlockSkin.glassTube:
      final rr = RRect.fromRectAndRadius(
        Offset.zero & size,
        Radius.circular(h / 2),
      );
      canvas.drawRRect(rr, Paint()..color = _alpha(c.base, .6));
      final liquid = rr.deflate(h * .1);
      canvas.drawRRect(
        liquid,
        Paint()
          ..shader = LinearGradient(
            colors: [_alpha(accent, .05), _alpha(accent, .45)],
          ).createShader(liquid.outerRect),
      );
      canvas.drawLine(
        Offset(h * .6, h * .2),
        Offset(w - h * .6, h * .2),
        _stroke(Colors.white.withValues(alpha: .4), h * .035),
      );
      canvas.drawRRect(
        rr.deflate(h * .012),
        _stroke(Colors.white.withValues(alpha: .3), h * .024),
      );
      if (c.border > 0) {
        canvas.drawRRect(
          rr.deflate(c.border / 2),
          _stroke(el.borderColor, c.border),
        );
      }
    case UnlockSkin.heartbeat:
      c.pill(Offset.zero & size, radius: h / 2);
      final x0 = h * 1.0, x1 = w - h * .35;
      final period = h * 1.5;
      const beat = [
        (0.0, 0.0),
        (.28, 0.0),
        (.34, -.1),
        (.4, 0.0),
        (.46, 0.0),
        (.5, .07),
        (.56, -.34),
        (.62, .22),
        (.67, 0.0),
        (.8, 0.0),
        (.86, -.07),
        (.92, 0.0),
        (1.0, 0.0),
      ];
      final path = Path()..moveTo(x0, h / 2);
      for (var s = x0; s < x1; s += period) {
        for (final (px, py) in beat) {
          path.lineTo(min(s + px * period, x1), h / 2 + py * h);
        }
      }
      canvas.drawPath(path, _stroke(_alpha(accent, .3), h * .08));
      canvas.drawPath(path, _stroke(_alpha(accent, .95), h * .035));
    default:
      return false;
  }
  return true;
}

/// Paints the sliding thumb of a studio slide skin; false for other skins.
bool paintStudioUnlockThumb(
  Canvas canvas,
  Size size,
  LockElement el,
  double k,
) {
  if (!studioSlideSkins.contains(el.unlockSkin)) return false;
  final w = size.width, h = size.height;
  final opacity = el.unlockThumbOpacity.clamp(0, 1).toDouble();
  final accent = el.unlockAccent;
  final ink = el.color;
  final border = el.borderWidth * k;
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
  Paint softShadow(double blur) => Paint()
    ..color = Colors.black.withValues(alpha: .35 * opacity)
    ..maskFilter = MaskFilter.blur(BlurStyle.normal, blur);
  final pad = h * .1;
  final disc = Rect.fromLTWH(
    w / 2 - (h - pad * 2) / 2,
    pad,
    h - pad * 2,
    h - pad * 2,
  );
  final center = Offset(w / 2, h / 2);

  switch (el.unlockSkin) {
    case UnlockSkin.batteryCharge:
      final cell = RRect.fromRectAndRadius(
        Rect.fromLTWH(h * .1, h * .14, w - h * .2, h * .72),
        Radius.circular(h * .16),
      );
      canvas.drawRRect(cell, softShadow(h * .05));
      canvas.drawRRect(
        cell,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              _alpha(_lighten(accent, .2), opacity),
              _alpha(accent, opacity),
            ],
          ).createShader(cell.outerRect),
      );
      canvas.drawRRect(
        cell.deflate(h * .02),
        _stroke(Colors.white.withValues(alpha: .4 * opacity), h * .02),
      );
      if (border > 0) canvas.drawRRect(cell, _stroke(el.borderColor, border));
    case UnlockSkin.gradientRail:
      canvas.drawCircle(
        center,
        h * .36,
        Paint()
          ..color = _alpha(accent, .55 * opacity)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, h * .1),
      );
      canvas.drawCircle(
        center,
        h * .34,
        Paint()..color = _alpha(accent, .16 * opacity),
      );
      canvas.drawCircle(
        center,
        h * .34,
        _stroke(_alpha(accent, opacity), h * .05),
      );
    case UnlockSkin.arrowTrack:
      canvas.drawCircle(
        center,
        h * .44,
        Paint()..color = _alpha(accent, .2 * opacity),
      );
      canvas.drawOval(disc.deflate(h * .04), glossy(disc, lift: .18));
      canvas.drawCircle(
        center,
        h * .34,
        _stroke(Colors.white.withValues(alpha: .6 * opacity), h * .022),
      );
    case UnlockSkin.filmStrip:
      final frame = RRect.fromRectAndRadius(
        Rect.fromLTWH(h * .08, h * .12, w - h * .16, h * .76),
        Radius.circular(h * .08),
      );
      canvas.drawRRect(frame, Paint()..color = _alpha(accent, .3 * opacity));
      canvas.drawRRect(
        frame,
        _stroke(_alpha(accent, opacity), max(h * .05, border)),
      );
      final arm = h * .16;
      for (final (sx, sy) in [(0.0, 0.0), (1.0, 0.0), (0.0, 1.0), (1.0, 1.0)]) {
        final x = frame.left + sx * frame.width;
        final y = frame.top + sy * frame.height;
        final dx = sx == 0 ? 1.0 : -1.0, dy = sy == 0 ? 1.0 : -1.0;
        final p = _stroke(
          Colors.white.withValues(alpha: .85 * opacity),
          h * .03,
          cap: StrokeCap.square,
        );
        canvas.drawLine(Offset(x, y), Offset(x + dx * arm, y), p);
        canvas.drawLine(Offset(x, y), Offset(x, y + dy * arm), p);
      }
    case UnlockSkin.dualPill:
      canvas.drawCircle(center, h * .44, softShadow(h * .06));
      canvas.drawOval(disc, glossy(disc, lift: .28));
      canvas.drawLine(
        Offset(w / 2 + h * .1, disc.top + h * .06),
        Offset(w / 2 - h * .1, disc.bottom - h * .06),
        _stroke(_alpha(ink, .45), h * .025),
      );
      canvas.drawCircle(center, h * .36, _stroke(_alpha(ink, .35), h * .02));
    case UnlockSkin.stubTicket:
      final body = Path.combine(
        PathOperation.difference,
        Path()..addRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(h * .06, h * .08, w - h * .12, h * .84),
            Radius.circular(h * .4),
          ),
        ),
        Path()
          ..addOval(
            Rect.fromCircle(center: Offset(w * .68, h * .08), radius: h * .09),
          )
          ..addOval(
            Rect.fromCircle(center: Offset(w * .68, h * .92), radius: h * .09),
          ),
      );
      canvas.drawPath(body, softShadow(h * .05));
      canvas.drawPath(
        body,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              _alpha(_lighten(accent, .2), opacity),
              _alpha(accent, opacity),
            ],
          ).createShader(body.getBounds()),
      );
      var y = h * .2;
      while (y < h * .8) {
        canvas.drawLine(
          Offset(w * .68, y),
          Offset(w * .68, min(y + h * .07, h * .8)),
          _stroke(Colors.black.withValues(alpha: .3), h * .02),
        );
        y += h * .13;
      }
      if (border > 0) canvas.drawPath(body, _stroke(el.borderColor, border));
    case UnlockSkin.starPath:
      final star = _star(center, h * .45, inner: .5);
      canvas.drawPath(star.shift(Offset(0, h * .03)), softShadow(h * .05));
      canvas.drawPath(star, glossy(star.getBounds()));
      canvas.drawPath(
        star,
        _stroke(Colors.white.withValues(alpha: .5 * opacity), h * .02),
      );
    case UnlockSkin.keyhole:
      final bow = Path.combine(
        PathOperation.difference,
        Path()..addOval(disc),
        Path()..addOval(Rect.fromCircle(center: center, radius: h * .13)),
      );
      canvas.drawPath(bow.shift(Offset(0, h * .03)), softShadow(h * .05));
      canvas.drawPath(bow, glossy(disc, lift: .26));
      canvas.drawCircle(
        center,
        h * .3,
        _stroke(Colors.white.withValues(alpha: .45 * opacity), h * .02),
      );
    case UnlockSkin.glassTube:
      canvas.drawCircle(
        center,
        h * .38,
        Paint()
          ..shader = RadialGradient(
            colors: [
              _alpha(accent, .12 * opacity),
              _alpha(accent, .6 * opacity),
            ],
            stops: const [.55, 1],
          ).createShader(disc),
      );
      canvas.drawCircle(
        center,
        h * .38,
        _stroke(Colors.white.withValues(alpha: .55 * opacity), h * .025),
      );
      canvas.drawOval(
        Rect.fromLTWH(
          disc.left + disc.width * .2,
          disc.top + disc.height * .12,
          disc.width * .34,
          disc.height * .18,
        ),
        Paint()..color = Colors.white.withValues(alpha: .6 * opacity),
      );
    case UnlockSkin.heartbeat:
      canvas.drawCircle(
        center,
        h * .46,
        Paint()..color = _alpha(accent, .16 * opacity),
      );
      canvas.drawCircle(
        center,
        h * .4,
        _stroke(_alpha(accent, .45 * opacity), h * .02),
      );
      canvas.drawOval(disc.deflate(h * .06), glossy(disc));
    default:
      return false;
  }
  return true;
}
