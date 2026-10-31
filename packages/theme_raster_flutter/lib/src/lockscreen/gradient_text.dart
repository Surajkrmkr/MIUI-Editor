import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'wallpaper_glass.dart';

class GradientText extends StatelessWidget {
  const GradientText(
    this.text, {
    super.key,
    required this.gradient,
    this.style,
    this.strokeWidth = 0,
    this.strokeColor = Colors.transparent,
    this.blurRadius = 0,
    this.isWallpaperGlass = false,
    this.glassBlur = 14,
    this.glassTint = 0.22,
    this.glassRim = 0.8,
    this.glassEdgeLight = false,
    this.glassShadow = const BoxShadow(
      color: Color(0x29000000),
      blurRadius: 8,
      offset: Offset(0, 1.5),
    ),
  });

  final String text;
  final TextStyle? style;
  final Gradient gradient;
  final double strokeWidth;
  final Color strokeColor;
  final double blurRadius;

  /// Glyphs show the blurred background of the enclosing
  /// [WallpaperGlassScope], tinted by [gradient] at [glassTint] strength.
  final bool isWallpaperGlass;
  final double glassBlur, glassTint, glassRim;
  final BoxShadow glassShadow;
  final bool glassEdgeLight;

  @override
  Widget build(BuildContext context) {
    final baseStyle = style ?? const TextStyle();
    final hasStroke = strokeWidth > 0 && strokeColor.a > 0;
    final hasBlur = blurRadius > 0;
    final blurFilter = hasBlur
        ? MaskFilter.blur(BlurStyle.normal, blurRadius)
        : null;

    Widget gradientLayer(
      Gradient layerGradient, {
      PaintingStyle paintingStyle = PaintingStyle.fill,
      double layerStrokeWidth = 0,
    }) {
      return _GlyphShaderMask(
        gradient: layerGradient,
        child: Text(
          text,
          style: baseStyle.copyWith(
            foreground: Paint()
              ..style = paintingStyle
              ..strokeWidth = layerStrokeWidth
              ..strokeJoin = StrokeJoin.round
              ..color = Colors.white
              ..maskFilter = paintingStyle == PaintingStyle.fill
                  ? blurFilter
                  : null,
          ),
        ),
      );
    }

    if (isWallpaperGlass) {
      final top = gradient.colors.first;
      final bottom = gradient.colors.last;
      final tint = glassTint.clamp(0.0, 1.0);
      final shadow = glassShadow;
      Paint shadowPaint(PaintingStyle style) => Paint()
        ..style = style
        ..strokeWidth = shadow.spreadRadius * 2
        ..strokeJoin = StrokeJoin.round
        ..color = shadow.color.withValues(alpha: 1)
        ..maskFilter = shadow.blurSigma > 0
            ? MaskFilter.blur(BlurStyle.normal, shadow.blurSigma)
            : null;
      return Stack(
        alignment: Alignment.center,
        children: [
          if (shadow.color.a > 0)
            Transform.translate(
              offset: shadow.offset,
              // Opaque layers faded together, so fill and spread don't stack.
              child: Opacity(
                opacity: shadow.color.a,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Text(
                      text,
                      style: baseStyle.copyWith(
                        foreground: shadowPaint(PaintingStyle.fill),
                      ),
                    ),
                    if (shadow.spreadRadius > 0)
                      Text(
                        text,
                        style: baseStyle.copyWith(
                          foreground: shadowPaint(PaintingStyle.stroke),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          GlassBackdropFill(
            blur: glassBlur,
            child: Text(text, style: baseStyle.copyWith(color: Colors.white)),
          ),
          if (tint > 0)
            gradientLayer(
              LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  top.withValues(alpha: (top.a * tint * 1.3).clamp(0, 1)),
                  bottom.withValues(alpha: bottom.a * tint * .7),
                ],
              ),
            ),
          gradientLayer(glassSheen),
          if (glassEdgeLight) _EdgeLight(text: text, style: baseStyle),
          if (glassRim > 0)
            _InnerRim(text: text, style: baseStyle, width: glassRim),
        ],
      );
    }

    if (!hasStroke && !hasBlur) {
      return gradientLayer(gradient);
    }

    return Stack(
      alignment: Alignment.center,
      children: [
        // Outside stroke, drawn behind the fill.
        if (hasStroke)
          Text(
            text,
            style: baseStyle.copyWith(
              foreground: Paint()
                ..style = PaintingStyle.stroke
                ..strokeWidth = strokeWidth * 2
                ..strokeJoin = StrokeJoin.round
                ..strokeCap = StrokeCap.round
                ..color = strokeColor,
            ),
          ),
        gradientLayer(gradient),
      ],
    );
  }
}

/// Light catching the glyphs' inner edges: a soft highlight inside the
/// top-left edges and a faint shade inside the bottom-right ones.
class _EdgeLight extends StatelessWidget {
  const _EdgeLight({required this.text, required this.style});

  final String text;
  final TextStyle style;

  @override
  Widget build(BuildContext context) => CustomPaint(
    foregroundPainter: _EdgeLightPainter(
      text,
      DefaultTextStyle.of(context).style.merge(style),
    ),
    child: Text(text, style: style.copyWith(color: Colors.transparent)),
  );
}

class _EdgeLightPainter extends CustomPainter {
  const _EdgeLightPainter(this.text, this.style);

  final String text;
  final TextStyle style;

  @override
  void paint(Canvas canvas, Size size) {
    final glyphs = TextPainter(
      text: TextSpan(
        text: text,
        style: style.copyWith(foreground: Paint()..color = Colors.white),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final bounds = (Offset.zero & size).inflate(size.longestSide);
    paintGlassEdgeLight(
      canvas,
      bounds,
      (style.fontSize ?? 35) / 35,
      (shift) => glyphs.paint(canvas, shift),
    );
    glyphs.dispose();
  }

  @override
  bool shouldRepaint(_EdgeLightPainter oldDelegate) =>
      text != oldDelegate.text || style != oldDelegate.style;
}

/// A light rim of [width] drawn only inside the glyphs, so it reads as one
/// edge rather than a band straddling the outline.
class _InnerRim extends StatelessWidget {
  const _InnerRim({
    required this.text,
    required this.style,
    required this.width,
  });

  final String text;
  final TextStyle style;
  final double width;

  @override
  Widget build(BuildContext context) => CustomPaint(
    foregroundPainter: _InnerRimPainter(
      text,
      DefaultTextStyle.of(context).style.merge(style),
      width,
    ),
    child: Text(text, style: style.copyWith(color: Colors.transparent)),
  );
}

class _InnerRimPainter extends CustomPainter {
  const _InnerRimPainter(this.text, this.style, this.width);

  final String text;
  final TextStyle style;
  final double width;

  TextPainter _layout(Paint paint) => TextPainter(
    text: TextSpan(
      text: text,
      style: style.copyWith(color: null, foreground: paint),
    ),
    textDirection: TextDirection.ltr,
  )..layout();

  @override
  void paint(Canvas canvas, Size size) {
    final bounds = (Offset.zero & size).inflate(size.longestSide);
    final stroke = _layout(
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = width * 2
        ..strokeJoin = StrokeJoin.round
        ..shader = glassRimGradient.createShader(Offset.zero & size),
    );
    final mask = _layout(Paint()..color = const Color(0xFFFFFFFF));
    canvas.saveLayer(bounds, Paint());
    stroke.paint(canvas, Offset.zero);
    canvas.saveLayer(bounds, Paint()..blendMode = BlendMode.dstIn);
    mask.paint(canvas, Offset.zero);
    canvas
      ..restore()
      ..restore();
    stroke.dispose();
    mask.dispose();
  }

  @override
  bool shouldRepaint(_InnerRimPainter oldDelegate) =>
      text != oldDelegate.text ||
      style != oldDelegate.style ||
      width != oldDelegate.width;
}

/// A srcIn [ShaderMask] whose mask reaches past the child's box, so glyphs
/// that overflow the line box (display fonts at height 1) are tinted too.
class _GlyphShaderMask extends SingleChildRenderObjectWidget {
  const _GlyphShaderMask({required this.gradient, super.child});

  final Gradient gradient;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderGlyphShaderMask(gradient);

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderGlyphShaderMask renderObject,
  ) => renderObject.gradient = gradient;
}

class _RenderGlyphShaderMask extends RenderProxyBox {
  _RenderGlyphShaderMask(this._gradient);

  Gradient _gradient;
  set gradient(Gradient value) {
    if (value == _gradient) return;
    _gradient = value;
    markNeedsPaint();
  }

  @override
  ShaderMaskLayer? get layer => super.layer as ShaderMaskLayer?;

  @override
  bool get alwaysNeedsCompositing => child != null;

  @override
  void paint(PaintingContext context, Offset offset) {
    if (child == null) {
      layer = null;
      return;
    }
    final pad = size.longestSide;
    // The shader is in mask-rect space; keep the gradient on the text box.
    layer ??= ShaderMaskLayer();
    layer!
      ..shader = _gradient.createShader(Offset(pad, pad) & size)
      ..maskRect = (offset & size).inflate(pad)
      ..blendMode = BlendMode.srcIn;
    context.pushLayer(layer!, super.paint, offset);
  }
}
