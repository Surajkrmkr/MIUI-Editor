import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:miui_icon_generator/theme_editor/domain/entities/icon_effect.dart';
import 'package:miui_icon_generator/theme_editor/domain/entities/icon_texture.dart';

class IconVisualUtils {
  /// Applies a texture overlay to the canvas within the given [path].
  static void applyTexture(
      ui.Canvas canvas, ui.Path path, IconTexture texture, ui.Rect rect, 
      {double scale = 1.0, double opacity = 1.0}) {
    if (texture == IconTexture.none) return;

    canvas.save();
    canvas.clipPath(path);

    switch (texture) {
      case IconTexture.leather:
        _drawLeather(canvas, rect, scale, opacity);
        break;
      case IconTexture.paper:
        _drawPaper(canvas, rect, scale, opacity);
        break;
      case IconTexture.metal:
        _drawMetal(canvas, rect, scale, opacity);
        break;
      case IconTexture.carbonFiber:
        _drawCarbonFiber(canvas, rect, scale, opacity);
        break;
      case IconTexture.wood:
        _drawWood(canvas, rect, scale, opacity);
        break;
      case IconTexture.granite:
        _drawGranite(canvas, rect, scale, opacity);
        break;
      case IconTexture.jeans:
        _drawJeans(canvas, rect, scale, opacity);
        break;
      case IconTexture.velvet:
        _drawVelvet(canvas, rect, scale, opacity);
        break;
      case IconTexture.rust:
        _drawRust(canvas, rect, scale, opacity);
        break;
      case IconTexture.concrete:
        _drawConcrete(canvas, rect, scale, opacity);
        break;
      case IconTexture.silk:
        _drawSilk(canvas, rect, scale, opacity);
        break;
      default:
        break;
    }
    canvas.restore();
  }

  /// Applies an effect (shader-like) to the icon background.
  static void applyEffect(ui.Canvas canvas, ui.Path path, IconEffect effect,
      ui.Rect rect, Color baseColor, 
      {double intensity = 1.0, double blur = 20.0, double elevation = 4.0}) {
    if (effect == IconEffect.none) return;

    canvas.save();
    canvas.clipPath(path);

    switch (effect) {
      case IconEffect.glass:
        _drawGlass(canvas, rect, intensity, blur, elevation);
        break;
      case IconEffect.neon:
        _drawNeon(canvas, path, baseColor, intensity, blur, elevation);
        break;
      case IconEffect.liquid:
        _drawLiquid(canvas, rect, baseColor, intensity, blur, elevation);
        break;
      case IconEffect.holographic:
        _drawHolographic(canvas, rect, intensity, blur, elevation);
        break;
      case IconEffect.glitch:
        _drawGlitch(canvas, rect, intensity, blur, elevation);
        break;
      case IconEffect.ember:
        _drawEmber(canvas, rect, intensity, blur, elevation);
        break;
      case IconEffect.ocean:
        _drawOcean(canvas, rect, intensity, blur, elevation);
        break;
      case IconEffect.cyberpunk:
        _drawCyberpunk(canvas, path, rect, intensity, blur, elevation);
        break;
      case IconEffect.golden:
        _drawGolden(canvas, rect, intensity, blur, elevation);
        break;
      case IconEffect.frost:
        _drawFrost(canvas, rect, intensity, blur, elevation);
        break;
      default:
        break;
    }
    canvas.restore();
  }

  // ── Textures ───────────────────────────────────────────────────────────────

  static void _drawLeather(ui.Canvas canvas, ui.Rect rect, double scale, double opacity) {
    final rnd = math.Random(42);
    final paint = ui.Paint()..color = Colors.black.withValues(alpha: 0.15 * opacity);
    final count = (200 / scale).clamp(10, 1000).toInt();
    for (var i = 0; i < count; i++) {
      final x = rect.left + rnd.nextDouble() * rect.width;
      final y = rect.top + rnd.nextDouble() * rect.height;
      canvas.drawCircle(Offset(x, y), (2.0 + rnd.nextDouble() * 2) * scale, paint);
    }
  }

  static void _drawPaper(ui.Canvas canvas, ui.Rect rect, double scale, double opacity) {
    final paint = ui.Paint()
      ..color = Colors.white.withValues(alpha: 0.27 * opacity)
      ..strokeWidth = 2.0 * scale;
    final rnd = math.Random(123);
    final count = (120 / scale).clamp(5, 500).toInt();
    for (var i = 0; i < count; i++) {
      final x = rect.left + rnd.nextDouble() * rect.width;
      final y = rect.top + rnd.nextDouble() * rect.height;
      canvas.drawLine(Offset(x, y), Offset(x + 15 * scale, y + 5 * scale), paint);
    }
  }

  static void _drawMetal(ui.Canvas canvas, ui.Rect rect, double scale, double opacity) {
    final linePaint = ui.Paint()
      ..color = Colors.white.withValues(alpha: 0.23 * opacity)
      ..strokeWidth = 1.8 * scale;
    final step = (8 * scale).clamp(2, 100).toDouble();
    for (var i = 0.0; i < rect.height; i += step) {
      canvas.drawLine(Offset(rect.left, rect.top + i),
          Offset(rect.right, rect.top + i), linePaint);
    }
  }

  static void _drawCarbonFiber(ui.Canvas canvas, ui.Rect rect, double scale, double opacity) {
    final size = 12.0 * scale; 
    final p1 = ui.Paint()..color = Colors.black.withValues(alpha: 0.3 * opacity);
    final p2 = ui.Paint()..color = Colors.white.withValues(alpha: 0.12 * opacity);
    for (var x = rect.left; x < rect.right; x += size) {
      for (var y = rect.top; y < rect.bottom; y += size) {
        if ((x / size).floor() % 2 == (y / size).floor() % 2) {
          canvas.drawRect(ui.Rect.fromLTWH(x, y, size, size), p1);
        } else {
          canvas.drawRect(ui.Rect.fromLTWH(x, y, size, size), p2);
        }
      }
    }
  }

  static void _drawWood(ui.Canvas canvas, ui.Rect rect, double scale, double opacity) {
    final paint = ui.Paint()
      ..color = Colors.black.withValues(alpha: 0.23 * opacity)
      ..style = ui.PaintingStyle.stroke
      ..strokeWidth = 5.0 * scale;
    final step = (20 * scale).clamp(5, 100).toDouble();
    for (var i = 0.0; i < rect.width; i += step) {
      final p = ui.Path();
      p.moveTo(rect.left + i, rect.top);
      p.quadraticBezierTo(
          rect.left + i + 15 * scale, rect.top + rect.height / 2, rect.left + i, rect.bottom);
      canvas.drawPath(p, paint);
    }
  }

  static void _drawGranite(ui.Canvas canvas, ui.Rect rect, double scale, double opacity) {
    final rnd = math.Random(77);
    final count = (150 / scale).clamp(10, 800).toInt();
    for (var i = 0; i < count; i++) {
      final p = ui.Paint()
        ..color = (rnd.nextBool() ? Colors.black : Colors.white).withValues(alpha: 0.3 * opacity);
      final dotSize = 10.0 * scale;
      canvas.drawRect(
          ui.Rect.fromLTWH(rect.left + rnd.nextDouble() * rect.width,
              rect.top + rnd.nextDouble() * rect.height, dotSize, dotSize),
          p);
    }
  }

  static void _drawJeans(ui.Canvas canvas, ui.Rect rect, double scale, double opacity) {
    final paint = ui.Paint()
      ..color = Colors.white.withValues(alpha: 0.2 * opacity)
      ..strokeWidth = 2.5 * scale;
    final step = (12 * scale).clamp(2, 50).toDouble();
    for (var i = -rect.height; i < rect.width; i += step) {
      canvas.drawLine(Offset(rect.left + i, rect.top),
          Offset(rect.left + i + rect.height, rect.bottom), paint);
    }
  }

  static void _drawVelvet(ui.Canvas canvas, ui.Rect rect, double scale, double opacity) {
    final paint = ui.Paint()
      ..shader = ui.Gradient.radial(
          rect.center,
          (rect.width / 1.1) * scale,
          [
            Colors.white.withValues(alpha: 0.39 * opacity),
            Colors.transparent,
          ],
          const [0.0, 1.0]);
    canvas.drawRect(rect, paint);
  }

  static void _drawRust(ui.Canvas canvas, ui.Rect rect, double scale, double opacity) {
    final rnd = math.Random(66);
    const rustColor = Color(0xFF4E2612); 
    final count = (100 / scale).clamp(10, 500).toInt();
    for (var i = 0; i < count; i++) {
      final p = ui.Paint()
        ..color = rustColor.withValues(alpha: 0.55 * opacity)
        ..maskFilter = ui.MaskFilter.blur(ui.BlurStyle.normal, 8 * scale);
      canvas.drawCircle(
          Offset(rect.left + rnd.nextDouble() * rect.width,
              rect.top + rnd.nextDouble() * rect.height),
          (8 + rnd.nextDouble() * 12) * scale,
          p);
    }
  }

  static void _drawConcrete(ui.Canvas canvas, ui.Rect rect, double scale, double opacity) {
    final rnd = math.Random(88);
    final paint = ui.Paint()..color = Colors.black.withValues(alpha: 0.27 * opacity);
    final count = (300 / scale).clamp(20, 1500).toInt();
    for (var i = 0; i < count; i++) {
      canvas.drawCircle(
          Offset(rect.left + rnd.nextDouble() * rect.width,
              rect.top + rnd.nextDouble() * rect.height),
          2.5 * scale,
          paint);
    }
  }

  static void _drawSilk(ui.Canvas canvas, ui.Rect rect, double scale, double opacity) {
    final paint = ui.Paint()
      ..shader = ui.Gradient.linear(
          rect.topLeft,
          rect.bottomRight,
          [
            Colors.white.withValues(alpha: 0.47 * opacity),
            Colors.transparent,
            Colors.white.withValues(alpha: 0.47 * opacity),
          ],
          const [0.0, 0.5, 1.0]);
    canvas.drawRect(rect, paint);
  }

  // ── Effects ────────────────────────────────────────────────────────────────

  static void _drawGlass(ui.Canvas canvas, ui.Rect rect, double intensity, double blur, double elevation) {
    canvas.drawRect(
        rect,
        ui.Paint()
          ..shader = ui.Gradient.linear(
              rect.topLeft,
              rect.bottomRight,
              [
                Colors.white.withValues(alpha: 0.7 * intensity),
                Colors.white.withValues(alpha: 0.2 * intensity),
                Colors.white.withValues(alpha: 0.47 * intensity),
              ],
              const [
                0.0,
                0.4,
                1.0
              ]));
    canvas.drawRect(
        rect,
        ui.Paint()
          ..style = ui.PaintingStyle.stroke
          ..strokeWidth = elevation
          ..shader = ui.Gradient.linear(
              rect.topLeft,
              rect.bottomRight,
              [Colors.white.withValues(alpha: intensity), Colors.white.withAlpha(0)],
              const [0.0, 1.0]));
  }

  static void _drawNeon(ui.Canvas canvas, ui.Path path, Color color, double intensity, double blur, double elevation) {
    final glowPaint = ui.Paint()
      ..style = ui.PaintingStyle.stroke
      ..strokeWidth = elevation * 4
      ..color = color.withValues(alpha: intensity)
      ..maskFilter = ui.MaskFilter.blur(ui.BlurStyle.outer, blur);
    canvas.drawPath(path, glowPaint);

    canvas.drawPath(
        path,
        ui.Paint()
          ..style = ui.PaintingStyle.stroke
          ..strokeWidth = elevation
          ..color = Colors.white.withValues(alpha: intensity));
  }

  static void _drawLiquid(ui.Canvas canvas, ui.Rect rect, Color color, double intensity, double blur, double elevation) {
    canvas.drawRect(
        rect,
        ui.Paint()
          ..shader = ui.Gradient.radial(
              rect.center,
              rect.width,
              [color.withValues(alpha: 0.7 * intensity), Colors.black.withValues(alpha: 0.39 * intensity)],
              const [0.0, 1.0])
          ..blendMode = ui.BlendMode.screen); 

    final rnd = math.Random(99);
    for (var i = 0; i < 15; i++) {
      final p = ui.Paint()
        ..color = Colors.white.withValues(alpha: 0.23 * intensity) 
        ..maskFilter = ui.MaskFilter.blur(ui.BlurStyle.normal, blur / 6);
      canvas.drawCircle(
          Offset(rect.left + rnd.nextDouble() * rect.width,
              rect.top + rnd.nextDouble() * rect.height),
          (12 + rnd.nextDouble() * 18) * (elevation / 4),
          p);
    }
  }

  static void _drawHolographic(ui.Canvas canvas, ui.Rect rect, double intensity, double blur, double elevation) {
    final colors = [
      Colors.cyanAccent.withValues(alpha: intensity),
      Colors.purpleAccent.withValues(alpha: intensity),
      Colors.blueAccent.withValues(alpha: intensity),
      Colors.pinkAccent.withValues(alpha: intensity),
      Colors.yellowAccent.withValues(alpha: intensity),
      Colors.cyanAccent.withValues(alpha: intensity),
    ];
    const stops = [0.0, 0.2, 0.4, 0.6, 0.8, 1.0];

    canvas.drawRect(
        rect,
        ui.Paint()
          ..shader = ui.Gradient.linear(
            rect.topLeft,
            rect.bottomRight,
            colors,
            stops,
          )
          ..blendMode = ui.BlendMode.overlay);

    canvas.drawRect(
      rect,
      ui.Paint()
        ..shader = ui.Gradient.linear(
            rect.topCenter,
            rect.bottomCenter,
            [
              Colors.white.withValues(alpha: 0.31 * intensity),
              Colors.transparent,
            ],
            const [0.0, 1.0]),
    );
  }

  static void _drawGlitch(ui.Canvas canvas, ui.Rect rect, double intensity, double blur, double elevation) {
    final rnd = math.Random(11);
    for (var i = 0; i < 15; i++) {
      canvas.drawRect(
          ui.Rect.fromLTWH(rect.left, rect.top + rnd.nextDouble() * rect.height,
              rect.width, elevation * 2),
          ui.Paint()
            ..color = (rnd.nextBool() ? Colors.cyanAccent : Colors.purpleAccent)
                .withValues(alpha: 0.86 * intensity));
    }
  }

  static void _drawEmber(ui.Canvas canvas, ui.Rect rect, double intensity, double blur, double elevation) {
    canvas.drawRect(
        rect,
        ui.Paint()
          ..shader = ui.Gradient.radial(
            rect.bottomCenter,
            rect.height,
            [Colors.orangeAccent.withValues(alpha: intensity), Colors.redAccent.withValues(alpha: intensity), Colors.black],
            const [0.0, 0.5, 1.0],
          ));
  }

  static void _drawOcean(ui.Canvas canvas, ui.Rect rect, double intensity, double blur, double elevation) {
    canvas.drawRect(
        rect,
        ui.Paint()
          ..shader = ui.Gradient.linear(
            rect.topCenter,
            rect.bottomCenter,
            [Colors.cyanAccent.withValues(alpha: intensity), Colors.blueAccent.withValues(alpha: intensity), Colors.indigoAccent.withValues(alpha: intensity)],
            const [0.0, 0.5, 1.0],
          ));
  }

  static void _drawCyberpunk(ui.Canvas canvas, ui.Path path, ui.Rect rect, double intensity, double blur, double elevation) {
    canvas.drawRect(rect, ui.Paint()..color = Colors.black);
    canvas.drawPath(
        path,
        ui.Paint()
          ..style = ui.PaintingStyle.stroke
          ..strokeWidth = elevation * 2
          ..color = Colors.yellowAccent.withValues(alpha: intensity));
    canvas.drawPath(
        path,
        ui.Paint()
          ..style = ui.PaintingStyle.stroke
          ..strokeWidth = elevation / 2
          ..color = Colors.white.withValues(alpha: intensity));
  }

  static void _drawGolden(ui.Canvas canvas, ui.Rect rect, double intensity, double blur, double elevation) {
    canvas.drawRect(
        rect,
        ui.Paint()
          ..shader = ui.Gradient.linear(
              rect.topLeft,
              rect.bottomRight,
              [
                const Color(0xFFFFD700).withValues(alpha: intensity),
                const Color(0xFFFFFACD).withValues(alpha: intensity),
                const Color(0xFFDAA520).withValues(alpha: intensity),
                const Color(0xFF63300D).withValues(alpha: intensity)
              ],
              const [
                0.0,
                0.3,
                0.7,
                1.0
              ]));
  }

  static void _drawFrost(ui.Canvas canvas, ui.Rect rect, double intensity, double blur, double elevation) {
    canvas.drawRect(rect, ui.Paint()..color = Colors.white.withValues(alpha: 0.9 * intensity));
    final rnd = math.Random(55);
    for (var i = 0; i < 100; i++) {
      canvas.drawLine(
          Offset(rect.left + rnd.nextDouble() * rect.width,
              rect.top + rnd.nextDouble() * rect.height),
          Offset(rect.left + rnd.nextDouble() * rect.width,
              rect.top + rnd.nextDouble() * rect.height),
          ui.Paint()
            ..color = Colors.blueAccent.withValues(alpha: 0.31 * intensity)
            ..strokeWidth = elevation * 0.75);
    }
  }
}
