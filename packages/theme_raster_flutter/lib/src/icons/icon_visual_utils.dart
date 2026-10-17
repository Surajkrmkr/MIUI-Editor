import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:miui_icon_generator/theme_editor/domain/entities/icon_effect.dart';
import 'package:miui_icon_generator/theme_editor/domain/entities/icon_texture.dart';

/// Paints textures and effects clipped to an icon's background [ui.Path].
///
/// Everything is laid out relative to the path bounds, so any shape and any
/// output size (preview, thumbnail, export) renders the same design.
abstract final class IconVisualUtils {
  /// [scale] is the user's texture scale (1.0 = default grain size); it is
  /// independent of pixel ratio because sizes derive from the shape bounds.
  static void applyTexture(
    ui.Canvas canvas,
    ui.Path path,
    IconTexture texture,
    ui.Rect rect, {
    double scale = 1.0,
    double opacity = 1.0,
  }) {
    if (texture == IconTexture.none || opacity <= 0) return;
    final b = path.getBounds();
    if (b.isEmpty) return;
    final u = b.shortestSide / 100 * scale.clamp(0.1, 5.0);
    final o = opacity.clamp(0.0, 1.0);

    canvas.save();
    canvas.clipPath(path);
    switch (texture) {
      case IconTexture.none:
        break;
      case IconTexture.grain:
        _grain(canvas, b, u, o, 1);
      case IconTexture.paper:
        _paper(canvas, b, u, o);
      case IconTexture.linen:
        _linen(canvas, b, u, o);
      case IconTexture.brushedMetal:
        _brushed(canvas, b, u, o);
      case IconTexture.carbonFiber:
        _carbon(canvas, b, u, o);
      case IconTexture.marble:
        _marble(canvas, b, u, o);
      case IconTexture.terrazzo:
        _terrazzo(canvas, b, u, o);
      case IconTexture.halftone:
        _halftone(canvas, b, u, o);
      case IconTexture.dots:
        _dots(canvas, b, u, o);
      case IconTexture.grid:
        _grid(canvas, b, u, o);
      case IconTexture.stripes:
        _stripes(canvas, b, u, o);
      case IconTexture.waves:
        _waves(canvas, b, u, o);
      case IconTexture.topographic:
        _topographic(canvas, b, u, o);
      case IconTexture.glitter:
        _glitter(canvas, b, u, o);
      case IconTexture.wood:
        _wood(canvas, b, u, o);
      case IconTexture.leather:
        _leather(canvas, b, u, o);
      case IconTexture.concrete:
        _concrete(canvas, b, u, o);
    }
    canvas.restore();
  }

  /// [blur] and [elevation] are in canvas pixels (callers pre-multiply by
  /// pixel ratio for export). [intensity] is 0..1.
  static void applyEffect(
    ui.Canvas canvas,
    ui.Path path,
    IconEffect effect,
    ui.Rect rect,
    Color baseColor, {
    double intensity = 1.0,
    double blur = 20.0,
    double elevation = 4.0,
  }) {
    if (effect == IconEffect.none || intensity <= 0) return;
    final b = path.getBounds();
    if (b.isEmpty) return;
    final fx = _Fx(
      canvas: canvas,
      path: path,
      b: b,
      i: intensity.clamp(0.0, 1.0),
      blur: math.max(0, blur),
      depth: math.max(elevation, b.shortestSide / 90),
      base: baseColor,
    );

    canvas.save();
    canvas.clipPath(path);
    switch (effect) {
      case IconEffect.none:
        break;
      case IconEffect.liquidGlass:
        fx.liquidGlass();
      case IconEffect.glass:
        fx.frosted();
      case IconEffect.clay:
        fx.clay();
      case IconEffect.softUi:
        fx.softUi();
      case IconEffect.gloss:
        fx.gloss();
      case IconEffect.aurora:
        fx.aurora();
      case IconEffect.holographic:
        fx.holographic();
      case IconEffect.chrome:
        fx.chrome();
      case IconEffect.gold:
        fx.gold();
      case IconEffect.neon:
        fx.neon();
      case IconEffect.bevel:
        fx.bevel();
      case IconEffect.spotlight:
        fx.spotlight();
    }
    canvas.restore();
  }

  // ── Texture painters ─────────────────────────────────────────────────────

  static Color _w(double a) =>
      Colors.white.withValues(alpha: a.clamp(0.0, 1.0));
  static Color _k(double a) =>
      Colors.black.withValues(alpha: a.clamp(0.0, 1.0));

  /// Feature count for a cell size, capped so tiny scales stay fast.
  static int _count(Rect b, double cell, int max) =>
      (b.width * b.height / (cell * cell)).clamp(1, max).toInt();

  static Offset _rndIn(math.Random r, Rect b) => Offset(
    b.left + r.nextDouble() * b.width,
    b.top + r.nextDouble() * b.height,
  );

  static void _points(Canvas c, List<Offset> pts, double size, Color color) {
    if (pts.isEmpty) return;
    final raw = Float32List(pts.length * 2);
    for (var i = 0; i < pts.length; i++) {
      raw[i * 2] = pts[i].dx;
      raw[i * 2 + 1] = pts[i].dy;
    }
    c.drawRawPoints(
      ui.PointMode.points,
      raw,
      Paint()
        ..color = color
        ..strokeWidth = size
        ..strokeCap = StrokeCap.round,
    );
  }

  static Paint _line(Color color, double width) => Paint()
    ..color = color
    ..style = PaintingStyle.stroke
    ..strokeWidth = width
    ..strokeCap = StrokeCap.round;

  static void _grain(Canvas c, Rect b, double u, double o, double strength) {
    final r = math.Random(7);
    final n = _count(b, u * 1.6, 5000);
    final dark = <Offset>[], light = <Offset>[];
    for (var i = 0; i < n; i++) {
      (r.nextBool() ? dark : light).add(_rndIn(r, b));
    }
    _points(c, dark, u * .9, _k(.35 * o * strength));
    _points(c, light, u * .9, _w(.28 * o * strength));
  }

  static void _paper(Canvas c, Rect b, double u, double o) {
    _grain(c, b, u, o, .6);
    final r = math.Random(21);
    final p = _line(_w(.3 * o), u * .35);
    for (var i = 0, n = _count(b, u * 14, 300); i < n; i++) {
      final s = _rndIn(r, b);
      final a = r.nextDouble() * math.pi;
      final l = u * (4 + r.nextDouble() * 6);
      c.drawLine(s, s + Offset(math.cos(a), math.sin(a)) * l, p);
    }
  }

  static void _linen(Canvas c, Rect b, double u, double o) {
    final step = u * 2.2;
    final light = _line(_w(.28 * o), u * .6);
    final dark = _line(_k(.16 * o), u * .6);
    var i = 0;
    for (var y = b.top; y < b.bottom && i < 800; y += step, i++) {
      c.drawLine(
        Offset(b.left, y),
        Offset(b.right, y),
        i.isEven ? light : dark,
      );
    }
    i = 0;
    for (var x = b.left; x < b.right && i < 800; x += step, i++) {
      c.drawLine(
        Offset(x, b.top),
        Offset(x, b.bottom),
        i.isEven ? dark : light,
      );
    }
  }

  static void _brushed(Canvas c, Rect b, double u, double o) {
    final r = math.Random(5);
    var i = 0;
    for (var y = b.top; y < b.bottom && i < 1500; y += u * .7, i++) {
      final a = r.nextDouble() * .22 * o;
      c.drawLine(
        Offset(b.left, y),
        Offset(b.right, y),
        _line(r.nextBool() ? _w(a) : _k(a * .8), u * .5),
      );
    }
    c.drawRect(
      b,
      Paint()
        ..shader = ui.Gradient.linear(
          b.topLeft,
          b.bottomRight,
          [_w(0), _w(.28 * o), _w(0), _w(.18 * o), _w(0)],
          const [0, .3, .5, .7, 1],
        ),
    );
  }

  static void _carbon(Canvas c, Rect b, double u, double o) {
    final cell = u * 4;
    final dark = Paint()..color = _k(.35 * o);
    final light = Paint()..color = _w(.1 * o);
    var drawn = 0;
    for (var y = b.top; y < b.bottom && drawn < 6000; y += cell) {
      for (var x = b.left; x < b.right && drawn < 6000; x += cell, drawn++) {
        final ix = ((x - b.left) / cell).round(),
            iy = ((y - b.top) / cell).round();
        final even = (ix + iy).isEven;
        c.drawRect(Rect.fromLTWH(x, y, cell, cell / 2), even ? dark : light);
        c.drawRect(
          Rect.fromLTWH(x, y + cell / 2, cell, cell / 2),
          even ? light : dark,
        );
      }
    }
  }

  static void _marble(Canvas c, Rect b, double u, double o) {
    final r = math.Random(3);
    for (var v = 0; v < 7; v++) {
      final p = Path()
        ..moveTo(b.left - u * 5, b.top + r.nextDouble() * b.height);
      p.cubicTo(
        b.left + b.width * .3,
        b.top + r.nextDouble() * b.height,
        b.left + b.width * .7,
        b.top + r.nextDouble() * b.height,
        b.right + u * 5,
        b.top + r.nextDouble() * b.height,
      );
      final light = v.isEven;
      c.drawPath(
        p,
        _line(
          light ? _w(.5 * o) : _k(.22 * o),
          u * (light ? .6 + r.nextDouble() * 1.8 : .4),
        )..maskFilter = MaskFilter.blur(BlurStyle.normal, u * .5),
      );
    }
  }

  static void _terrazzo(Canvas c, Rect b, double u, double o) {
    final r = math.Random(17);
    final tones = [_w(.55 * o), _k(.35 * o), _w(.3 * o), _k(.2 * o)];
    for (var i = 0, n = _count(b, u * 9, 400); i < n; i++) {
      final ctr = _rndIn(r, b);
      final size = u * (1.2 + r.nextDouble() * 2.6);
      final sides = 3 + r.nextInt(3);
      final rot = r.nextDouble() * math.pi;
      final p = Path();
      for (var k = 0; k < sides; k++) {
        final a = rot + 2 * math.pi * k / sides;
        final rr = size * (.7 + r.nextDouble() * .5);
        final pt = ctr + Offset(math.cos(a), math.sin(a)) * rr;
        k == 0 ? p.moveTo(pt.dx, pt.dy) : p.lineTo(pt.dx, pt.dy);
      }
      c.drawPath(p..close(), Paint()..color = tones[i % tones.length]);
    }
  }

  static void _halftone(Canvas c, Rect b, double u, double o) {
    final g = u * 5;
    final paint = Paint()..color = _w(.55 * o);
    var drawn = 0;
    for (var y = b.top; y < b.bottom + g && drawn < 4000; y += g) {
      for (var x = b.left; x < b.right + g && drawn < 4000; x += g, drawn++) {
        final f = ((x - b.left) / b.width + (y - b.top) / b.height) / 2;
        c.drawCircle(Offset(x, y), g * .5 * f.clamp(.05, 1.0), paint);
      }
    }
  }

  static void _dots(Canvas c, Rect b, double u, double o) {
    final g = u * 6;
    final pts = <Offset>[];
    for (var y = b.top + g / 2; y < b.bottom && pts.length < 4000; y += g) {
      for (var x = b.left + g / 2; x < b.right && pts.length < 4000; x += g) {
        pts.add(Offset(x, y));
      }
    }
    _points(c, pts, g * .42, _w(.55 * o));
  }

  static void _grid(Canvas c, Rect b, double u, double o) {
    final g = u * 6;
    final thin = _line(_w(.35 * o), u * .45);
    final bold = _line(_w(.6 * o), u * .75);
    var i = 0;
    for (var x = b.left; x <= b.right && i < 600; x += g, i++) {
      c.drawLine(
        Offset(x, b.top),
        Offset(x, b.bottom),
        i % 4 == 0 ? bold : thin,
      );
    }
    i = 0;
    for (var y = b.top; y <= b.bottom && i < 600; y += g, i++) {
      c.drawLine(
        Offset(b.left, y),
        Offset(b.right, y),
        i % 4 == 0 ? bold : thin,
      );
    }
  }

  static void _stripes(Canvas c, Rect b, double u, double o) {
    final step = u * 5;
    final p = _line(_w(.35 * o), u * 2);
    var i = 0;
    for (var x = b.left - b.height; x < b.right && i < 800; x += step, i++) {
      c.drawLine(Offset(x, b.bottom), Offset(x + b.height, b.top), p);
    }
  }

  static void _waves(Canvas c, Rect b, double u, double o) {
    final p = _line(_w(.5 * o), u * .8)..strokeJoin = StrokeJoin.round;
    final dx = math.max(u, b.width / 200);
    var i = 0;
    for (var y = b.top; y < b.bottom + u * 6 && i < 300; y += u * 6, i++) {
      final path = Path()..moveTo(b.left, y);
      for (var x = b.left; x <= b.right; x += dx) {
        path.lineTo(
          x,
          y + math.sin((x - b.left) / (u * 12) * 2 * math.pi) * u * 1.5,
        );
      }
      c.drawPath(path, p);
    }
  }

  static void _topographic(Canvas c, Rect b, double u, double o) {
    final r = math.Random(9);
    final ctr = Offset(b.left + b.width * .35, b.top + b.height * .4);
    final p1 = r.nextDouble() * 6, p2 = r.nextDouble() * 6;
    final paint = _line(_w(.5 * o), u * .6)..strokeJoin = StrokeJoin.round;
    final maxR = b.longestSide * 1.2;
    var i = 0;
    for (var rad = u * 4; rad < maxR && i < 150; rad += u * 4, i++) {
      final path = Path();
      for (var k = 0; k <= 90; k++) {
        final a = 2 * math.pi * k / 90;
        final f =
            1 +
            .08 * math.sin(3 * a + p1) +
            .05 * math.sin(5 * a + p2 + rad / (u * 20));
        final pt = ctr + Offset(math.cos(a), math.sin(a)) * rad * f;
        k == 0 ? path.moveTo(pt.dx, pt.dy) : path.lineTo(pt.dx, pt.dy);
      }
      c.drawPath(path..close(), paint);
    }
  }

  static void _glitter(Canvas c, Rect b, double u, double o) {
    final r = math.Random(13);
    for (var i = 0, n = _count(b, u * 7, 600); i < n; i++) {
      final ctr = _rndIn(r, b);
      final s = u * (.6 + r.nextDouble() * 1.8);
      final k = s * .22;
      final star = Path()
        ..moveTo(ctr.dx, ctr.dy - s)
        ..quadraticBezierTo(ctr.dx + k, ctr.dy - k, ctr.dx + s, ctr.dy)
        ..quadraticBezierTo(ctr.dx + k, ctr.dy + k, ctr.dx, ctr.dy + s)
        ..quadraticBezierTo(ctr.dx - k, ctr.dy + k, ctr.dx - s, ctr.dy)
        ..quadraticBezierTo(ctr.dx - k, ctr.dy - k, ctr.dx, ctr.dy - s)
        ..close();
      c.drawPath(star, Paint()..color = _w((.3 + r.nextDouble() * .7) * o));
    }
    _grain(c, b, u * .6, o, .5);
  }

  static void _wood(Canvas c, Rect b, double u, double o) {
    final r = math.Random(31);
    final dy = math.max(u, b.height / 160);
    var i = 0;
    for (
      var x0 = b.left - u * 4;
      x0 < b.right + u * 4 && i < 400;
      x0 += u * 3, i++
    ) {
      final phase = r.nextDouble() * 6;
      final path = Path()..moveTo(x0, b.top);
      for (var y = b.top; y <= b.bottom; y += dy) {
        path.lineTo(x0 + math.sin((y - b.top) / (u * 20) + phase) * u * 3, y);
      }
      c.drawPath(
        path,
        _line(
          _k((.08 + r.nextDouble() * .18) * o),
          u * (.4 + r.nextDouble() * .8),
        ),
      );
    }
    final knot = Offset(b.left + b.width * .68, b.top + b.height * .55);
    for (var k = 1; k <= 4; k++) {
      c.drawOval(
        Rect.fromCenter(center: knot, width: u * 5 * k, height: u * 2.6 * k),
        _line(_k(.16 * o), u * .45),
      );
    }
  }

  static void _leather(Canvas c, Rect b, double u, double o) {
    final r = math.Random(42);
    final shade = <Offset>[], light = <Offset>[];
    for (var i = 0, n = _count(b, u * 3.2, 3500); i < n; i++) {
      final p = _rndIn(r, b);
      shade.add(p + Offset(u * .35, u * .35));
      light.add(p - Offset(u * .35, u * .35));
    }
    _points(c, shade, u * 2.2, _k(.32 * o));
    _points(c, light, u * 1.6, _w(.2 * o));
  }

  static void _concrete(Canvas c, Rect b, double u, double o) {
    _grain(c, b, u, o, .7);
    final r = math.Random(88);
    final pits = [
      for (var i = 0, n = _count(b, u * 7, 1500); i < n; i++) _rndIn(r, b),
    ];
    _points(c, pits, u * 1.3, _k(.3 * o));
  }
}

/// Effect painters. Every effect only uses the shape path and its bounds,
/// so it follows the outline of any shape.
class _Fx {
  _Fx({
    required this.canvas,
    required this.path,
    required this.b,
    required this.i,
    required this.blur,
    required this.depth,
    required this.base,
  });

  final Canvas canvas;
  final Path path;
  final Rect b;
  final double i, blur, depth;
  final Color base;

  double get w => b.width;
  double get h => b.height;
  double get k => b.shortestSide / 45;
  double get soft => math.max(blur * .25, k * 1.5);

  Color _w(double a) => Colors.white.withValues(alpha: (a * i).clamp(0.0, 1.0));
  Color _k(double a) => Colors.black.withValues(alpha: (a * i).clamp(0.0, 1.0));

  /// Shadow cast inward from the shape edge (canvas is already clipped).
  void _inner(Color color, double radius, Offset offset) {
    final ring = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(b.inflate(radius * 3 + offset.distance + 4))
      ..addPath(path, offset);
    final p = Paint()..color = color;
    if (radius > 0) {
      p.maskFilter = MaskFilter.blur(BlurStyle.normal, radius * .5);
    }
    canvas.drawPath(ring, p);
  }

  void _rim(double width, List<Color> colors, List<double> stops) {
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = width * 2
        ..shader = ui.Gradient.linear(b.topLeft, b.bottomRight, colors, stops),
    );
  }

  void _fill(ui.Shader shader, {BlendMode mode = BlendMode.srcOver}) =>
      canvas.drawRect(
        b,
        Paint()
          ..shader = shader
          ..blendMode = mode,
      );

  void liquidGlass() {
    _fill(
      ui.Gradient.linear(
        b.topCenter,
        b.bottomCenter,
        [_w(.3), _w(0), _w(.12)],
        const [0, .45, 1],
      ),
    );
    _inner(_w(.55), soft, Offset.zero);
    _rim(
      math.max(depth * .35, k * .8),
      [_w(.95), _w(0), _w(0), _w(.5)],
      const [0, .45, .6, 1],
    );
    canvas.drawOval(
      Rect.fromLTWH(b.left + w * .12, b.top + h * .07, w * .55, h * .26),
      Paint()
        ..color = _w(.25)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, k * 2),
    );
  }

  void frosted() {
    canvas.drawRect(b, Paint()..color = _w(.16));
    _fill(ui.Gradient.linear(b.topLeft, b.center, [_w(.35), _w(0)]));
    _rim(
      math.max(depth * .25, k * .6),
      [_w(.75), _w(.1), _w(.3)],
      const [0, .5, 1],
    );
  }

  void clay() {
    _inner(_k(.32), soft * 1.6, Offset(depth * .6, depth * .6));
    _inner(_w(.5), soft * 1.2, Offset(-depth * .5, -depth * .5));
    _fill(
      ui.Gradient.radial(Offset(b.left + w * .3, b.top + h * .25), w * .6, [
        _w(.18),
        _w(0),
      ]),
    );
  }

  void softUi() {
    _fill(
      ui.Gradient.linear(
        b.topLeft,
        b.bottomRight,
        [_w(.3), _w(0), _k(.22)],
        const [0, .5, 1],
      ),
    );
    _inner(_w(.35), soft * .6, Offset(-depth * .3, -depth * .3));
    _inner(_k(.18), soft * .6, Offset(depth * .3, depth * .3));
  }

  void gloss() {
    final cap = Path()
      ..addOval(
        Rect.fromLTWH(b.left - w * .1, b.top - h * .45, w * 1.2, h * .95),
      );
    canvas.drawPath(
      cap,
      Paint()
        ..shader = ui.Gradient.linear(
          b.topCenter,
          Offset(b.center.dx, b.top + h * .5),
          [_w(.65), _w(.08)],
        ),
    );
    _fill(ui.Gradient.radial(b.bottomCenter, w * .6, [_w(.3), _w(0)]));
    _inner(_w(.35), k, Offset.zero);
  }

  void aurora() {
    final hsl = HSLColor.fromColor(base);
    HSLColor tone(double dh, double l) => hsl
        .withHue((hsl.hue + dh) % 360)
        .withSaturation(math.max(hsl.saturation, .6))
        .withLightness(l);
    final blobs = [
      (Offset(b.left + w * .15, b.top + h * .2), tone(45, .65)),
      (Offset(b.right - w * .1, b.top + h * .35), tone(-45, .58)),
      (Offset(b.center.dx, b.bottom - h * .05), tone(100, .6)),
    ];
    final sigma = w * .2 + blur * .2;
    for (final (pos, color) in blobs) {
      canvas.drawCircle(
        pos,
        w * .45,
        Paint()
          ..color = color.toColor().withValues(alpha: .85 * i)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, sigma),
      );
    }
  }

  void holographic() {
    _fill(
      ui.Gradient.sweep(
        Offset(b.left + w * .3, b.top + h * .3),
        [
          Colors.cyanAccent.withValues(alpha: .6 * i),
          Colors.pinkAccent.withValues(alpha: .6 * i),
          Colors.yellowAccent.withValues(alpha: .6 * i),
          Colors.lightGreenAccent.withValues(alpha: .6 * i),
          Colors.deepPurpleAccent.withValues(alpha: .6 * i),
          Colors.cyanAccent.withValues(alpha: .6 * i),
        ],
        const [0, .2, .4, .6, .8, 1],
      ),
      mode: BlendMode.overlay,
    );
    _fill(
      ui.Gradient.linear(
        b.topLeft,
        b.bottomRight,
        [_w(0), _w(.35), _w(0)],
        const [.3, .5, .7],
      ),
    );
  }

  void chrome() {
    _fill(
      ui.Gradient.linear(
        b.topCenter,
        b.bottomCenter,
        [_w(.85), _w(.15), _k(.35), _w(.55), _w(.1), _w(.5)],
        const [0, .35, .5, .62, .85, 1],
      ),
    );
    _rim(
      math.max(depth * .2, k * .6),
      [_w(.9), _w(.1), _w(.6)],
      const [0, .5, 1],
    );
  }

  void gold() {
    Color g(int argb) => Color(argb).withValues(alpha: .85 * i);
    _fill(
      ui.Gradient.linear(
        b.topLeft,
        b.bottomRight,
        [
          g(0xFFFFE08A),
          g(0xFFD4A017),
          g(0xFF8A5A00),
          g(0xFFFFD86B),
          g(0xFFB8860B),
        ],
        const [0, .35, .5, .65, 1],
      ),
    );
    _fill(
      ui.Gradient.linear(
        b.topCenter,
        b.bottomCenter,
        [_w(.35), _w(0), _w(.2), _w(0)],
        const [0, .4, .6, 1],
      ),
    );
  }

  void neon() {
    final hsl = HSLColor.fromColor(base);
    final glow = hsl.withSaturation(1).withLightness(.7).toColor();
    _fill(
      ui.Gradient.radial(
        b.center,
        b.longestSide * .62,
        [_k(.75), _k(.55), _k(0)],
        const [0, .55, 1],
      ),
    );
    _inner(glow.withValues(alpha: i), soft * 1.6, Offset.zero);
    _inner(glow.withValues(alpha: i), soft * .7, Offset.zero);
    _inner(_w(.8), soft * .3, Offset.zero);
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(depth * .3, k * .7) * 2
        ..color = _w(.9),
    );
  }

  void bevel() {
    final r = k * .8 + blur * .05;
    _fill(ui.Gradient.linear(b.topLeft, b.bottomRight, [_w(.12), _k(.08)]));
    _inner(_w(.55), r, Offset(-depth * .4, -depth * .4));
    _inner(_k(.45), r, Offset(depth * .4, depth * .4));
  }

  void spotlight() {
    _fill(
      ui.Gradient.radial(Offset(b.left + w * .28, b.top + h * .22), w * .9, [
        _w(.5),
        _w(0),
      ]),
    );
    _inner(_k(.35), soft * 1.5, Offset.zero);
  }
}
