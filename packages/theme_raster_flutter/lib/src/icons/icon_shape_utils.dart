import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:theme_core/theme_core.dart' show IconShape;
import 'icon_shape_border.dart';

/// Builds every [IconShape] as a single closed [Path] fitted to any rect.
///
/// Geometry is relative to the rect, so a 45px preview and a 180px export
/// produce the same shape. [radius] (0–[maxRadius]) controls roundness.
abstract final class IconShapeUtils {
  static const double maxRadius = 20;

  static ShapeBorder getBorder(
    IconShape shape,
    double radius, {
    double borderWidth = 0,
    Color borderColor = Colors.transparent,
    double scale = 1.0,
    int? seed,
  }) => IconShapeBorder(
    shape: shape,
    radius: radius,
    borderWidth: borderWidth * scale,
    borderColor: borderColor,
    seed: seed ?? 0,
  );

  static Path path(
    IconShape shape,
    Rect rect, {
    double radius = 10,
    int seed = 0,
  }) {
    if (rect.isEmpty) return Path();
    final t = (radius / maxRadius).clamp(0.0, 1.0);
    final s = rect.shortestSide;
    // Higher radius => softer waves on the polar shapes.
    final soft = 1.35 - 0.7 * t;

    switch (shape) {
      case IconShape.squircle:
        final n = 2.4 * math.pow(20 / 2.4, math.pow(1 - t, 1.4));
        return _superellipse(rect, n.toDouble());
      case IconShape.circle:
        return Path()..addOval(rect);
      case IconShape.square:
        return Path()..addRRect(
          RRect.fromRectAndRadius(rect, Radius.circular(s * .5 * t)),
        );
      case IconShape.cookie4:
        return _polar(rect, (a) => _wave(a, 4, .11 * soft, math.pi / 4));
      case IconShape.cookie7:
        return _polar(rect, (a) => _wave(a, 7, .09 * soft, 0));
      case IconShape.scallop:
        return _polar(rect, (a) => _wave(a, 12, .055 * soft, 0));
      case IconShape.clover:
        return _polar(rect, (a) => _lobes(a, 4, .3 * soft, .6, math.pi / 4));
      case IconShape.flower:
        return _polar(rect, (a) => _lobes(a, 8, .2 * soft, .75, 0));
      case IconShape.sunny:
        return _roundedPolygon(_star(rect, 8, .8), s * (.04 + .1 * t));
      case IconShape.burst:
        return _roundedPolygon(_star(rect, 12, .84), s * (.02 + .06 * t));
      case IconShape.arch:
        final r = Radius.circular(s * (.06 + .24 * t));
        final top = Radius.circular(rect.width / 2);
        return Path()..addRRect(
          RRect.fromRectAndCorners(
            rect,
            topLeft: top,
            topRight: top,
            bottomLeft: r,
            bottomRight: r,
          ),
        );
      case IconShape.pill:
        return _diagonalPill(rect);
      case IconShape.hexagon:
        return _roundedPolygon(_fit(_regular(6), rect), s * (.04 + .16 * t));
      case IconShape.pentagon:
        return _roundedPolygon(_fit(_regular(5), rect), s * (.04 + .16 * t));
      case IconShape.diamond:
        return _roundedPolygon(_fit(_regular(4), rect), s * (.06 + .2 * t));
      case IconShape.leaf:
        final big = Radius.circular(s * (.25 + .25 * t));
        final small = Radius.circular(s * (.04 + .12 * t));
        return Path()..addRRect(
          RRect.fromRectAndCorners(
            rect,
            topLeft: big,
            bottomRight: big,
            topRight: small,
            bottomLeft: small,
          ),
        );
      case IconShape.heart:
        return _heart(rect);
      case IconShape.shield:
        return _roundedPolygon(
          _fit(const [
            Offset(0, .08),
            Offset(.5, 0),
            Offset(1, .08),
            Offset(1, .52),
            Offset(.5, 1),
            Offset(0, .52),
          ], rect),
          s * (.05 + .15 * t),
        );
      case IconShape.blob:
        return _blob(rect, seed, soft);
    }
  }

  // ── Polar helpers (r is a 0..1 factor of the half-extent) ────────────────

  static double _wave(double a, int n, double amp, double off) =>
      1 - amp * (1 - math.cos(n * (a + math.pi / 2 - off))) / 2;

  static double _lobes(double a, int n, double amp, double sharp, double off) =>
      1 -
      amp +
      amp * math.pow(math.cos(n / 2 * (a + math.pi / 2 - off)).abs(), sharp);

  static Path _polar(Rect rect, double Function(double) r, {int steps = 240}) {
    final c = rect.center;
    final rx = rect.width / 2, ry = rect.height / 2;
    final path = Path();
    for (var i = 0; i <= steps; i++) {
      final a = -math.pi / 2 + 2 * math.pi * i / steps;
      final f = r(a);
      final p = Offset(
        c.dx + rx * f * math.cos(a),
        c.dy + ry * f * math.sin(a),
      );
      i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
    }
    return path..close();
  }

  static Path _superellipse(Rect rect, double n, {int steps = 200}) {
    final c = rect.center;
    final rx = rect.width / 2, ry = rect.height / 2;
    final e = 2 / n;
    final path = Path();
    for (var i = 0; i <= steps; i++) {
      final a = 2 * math.pi * i / steps;
      final ca = math.cos(a), sa = math.sin(a);
      final x = c.dx + rx * ca.sign * math.pow(ca.abs(), e);
      final y = c.dy + ry * sa.sign * math.pow(sa.abs(), e);
      i == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
    }
    return path..close();
  }

  static Path _blob(Rect rect, int seed, double soft) {
    final rnd = math.Random(seed);
    final amps = List.generate(3, (_) => (.03 + rnd.nextDouble() * .06) * soft);
    final phases = List.generate(3, (_) => rnd.nextDouble() * 2 * math.pi);
    final total = 1 + amps.reduce((a, b) => a + b);
    return _polar(rect, (a) {
      var r = 1.0;
      for (var k = 0; k < 3; k++) {
        r += amps[k] * math.cos((k + 2) * a + phases[k]);
      }
      return r / total;
    });
  }

  // ── Polygon helpers ──────────────────────────────────────────────────────

  static List<Offset> _regular(int sides) => List.generate(sides, (i) {
    final a = -math.pi / 2 + 2 * math.pi * i / sides;
    return Offset(math.cos(a), math.sin(a));
  });

  static List<Offset> _star(Rect rect, int points, double inner) {
    final c = rect.center;
    final rx = rect.width / 2, ry = rect.height / 2;
    return List.generate(points * 2, (i) {
      final a = -math.pi / 2 + math.pi * i / points;
      final r = i.isEven ? 1.0 : inner;
      return Offset(c.dx + rx * r * math.cos(a), c.dy + ry * r * math.sin(a));
    });
  }

  /// Uniformly scales [pts] to fit and centre inside [rect].
  static List<Offset> _fit(List<Offset> pts, Rect rect) {
    var minX = double.infinity, minY = double.infinity;
    var maxX = -double.infinity, maxY = -double.infinity;
    for (final p in pts) {
      minX = math.min(minX, p.dx);
      maxX = math.max(maxX, p.dx);
      minY = math.min(minY, p.dy);
      maxY = math.max(maxY, p.dy);
    }
    final k = math.min(rect.width / (maxX - minX), rect.height / (maxY - minY));
    final ox = rect.center.dx - (minX + maxX) / 2 * k;
    final oy = rect.center.dy - (minY + maxY) / 2 * k;
    return [for (final p in pts) Offset(p.dx * k + ox, p.dy * k + oy)];
  }

  static Path _roundedPolygon(List<Offset> pts, double corner) {
    final path = Path();
    final n = pts.length;
    for (var i = 0; i < n; i++) {
      final v = pts[i];
      final d1 = pts[(i - 1 + n) % n] - v;
      final d2 = pts[(i + 1) % n] - v;
      final l1 = d1.distance, l2 = d2.distance;
      if (l1 == 0 || l2 == 0) continue;
      final r = math.min(corner, math.min(l1, l2) / 2);
      final a = v + d1 / l1 * r;
      final b = v + d2 / l2 * r;
      i == 0 ? path.moveTo(a.dx, a.dy) : path.lineTo(a.dx, a.dy);
      path.quadraticBezierTo(v.dx, v.dy, b.dx, b.dy);
    }
    return path..close();
  }

  static Path _diagonalPill(Rect rect) {
    final s = rect.shortestSide;
    // Width/length chosen so the 45° capsule exactly fills the square.
    final w = s * .56;
    final l = w + (s - w) * math.sqrt2;
    final c = rect.center;
    // Sampled (not a rotated RRect) so getBounds() is exact for effects.
    final half = (l - w) / 2, rad = w / 2;
    final cos = math.cos(-math.pi / 4), sin = math.sin(-math.pi / 4);
    final path = Path();
    for (var i = 0; i <= 120; i++) {
      final right = i <= 60;
      final a = right
          ? -math.pi / 2 + math.pi * i / 60
          : math.pi / 2 + math.pi * (i - 60) / 60;
      final x = (right ? half : -half) + rad * math.cos(a);
      final y = rad * math.sin(a);
      final px = c.dx + x * cos - y * sin, py = c.dy + x * sin + y * cos;
      i == 0 ? path.moveTo(px, py) : path.lineTo(px, py);
    }
    return path..close();
  }

  static Path _heart(Rect rect) {
    final pts = <Offset>[];
    for (var i = 0; i < 200; i++) {
      final u = 2 * math.pi * i / 200;
      final x = 16 * math.pow(math.sin(u), 3).toDouble();
      final y =
          -(13 * math.cos(u) -
              5 * math.cos(2 * u) -
              2 * math.cos(3 * u) -
              math.cos(4 * u));
      pts.add(Offset(x, y));
    }
    final fitted = _fit(pts, rect);
    final path = Path()..moveTo(fitted.first.dx, fitted.first.dy);
    for (final p in fitted.skip(1)) {
      path.lineTo(p.dx, p.dy);
    }
    return path..close();
  }
}
