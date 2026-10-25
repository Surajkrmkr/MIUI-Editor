import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

class GradientText extends StatelessWidget {
  const GradientText(
    this.text, {
    super.key,
    required this.gradient,
    this.style,
    this.strokeWidth = 0,
    this.strokeColor = Colors.transparent,
    this.blurRadius = 0,
    this.isLiquidGlass = false,
    this.isFrostedGlass = false,
  });

  final String text;
  final TextStyle? style;
  final Gradient gradient;
  final double strokeWidth;
  final Color strokeColor;
  final double blurRadius;
  final bool isLiquidGlass;

  /// Translucent glyphs fading downwards with a soft halo and a light rim;
  /// baked into the fill so exported clock PNGs look the same on device.
  final bool isFrostedGlass;

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

    if (isFrostedGlass) {
      final top = gradient.colors.first;
      final bottom = gradient.colors.last;
      return Stack(
        alignment: Alignment.center,
        children: [
          // Shadow, not MaskFilter BlurStyle.outer: that crashes Impeller on text.
          Text(
            text,
            style: baseStyle.copyWith(
              color: Colors.transparent,
              shadows: [
                Shadow(
                  color: top.withValues(alpha: top.a * .35),
                  blurRadius: 6,
                ),
              ],
            ),
          ),
          gradientLayer(
            LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                top.withValues(alpha: top.a * .8),
                Color.lerp(top, bottom, .5)!.withValues(alpha: top.a * .42),
                bottom.withValues(alpha: bottom.a * .14),
              ],
              stops: const [0, .55, 1],
            ),
          ),
          gradientLayer(
            const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xD9FFFFFF), Color(0x40FFFFFF), Color(0x14FFFFFF)],
              stops: [0, .5, 1],
            ),
            paintingStyle: PaintingStyle.stroke,
            layerStrokeWidth: .8,
          ),
        ],
      );
    }

    if (!hasStroke && !hasBlur && !isLiquidGlass) {
      return gradientLayer(gradient);
    }

    return Stack(
      alignment: Alignment.center,
      children: [
        // 1. Outside Stroke Outline (drawn BEHIND the fill)
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

        // 2. Liquid Glass Ambient Shadow
        if (isLiquidGlass)
          Text(
            text,
            style: baseStyle.copyWith(
              color: Colors.transparent,
              shadows: [
                Shadow(
                  color: Colors.black.withValues(alpha: 0.45),
                  blurRadius: 12,
                ),
              ],
            ),
          ),

        // 3. Main Text Body Fill (with Gradient Shader + Blur if set)
        if (isLiquidGlass)
          gradientLayer(
            LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                (baseStyle.color ?? Colors.white),
                (baseStyle.color ?? Colors.white).withValues(alpha: 0.70),
                const Color(0xFFD6E8FF).withValues(alpha: 0.85),
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
          )
        else
          gradientLayer(gradient),

        // 4. Liquid Glass 3D Bevel Rim Stroke
        if (isLiquidGlass)
          gradientLayer(
            const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFFFFFFF),
                Color(0xCCFFFFFF),
                Color(0x2033CCFF),
                Color(0x80FFFFFF),
              ],
              stops: [0.0, 0.35, 0.70, 1.0],
            ),
            paintingStyle: PaintingStyle.stroke,
            layerStrokeWidth: 2.0,
          ),

        // 5. Liquid Glass Top Specular Sheen Overlay
        if (isLiquidGlass)
          gradientLayer(
            const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xF0FFFFFF),
                Color(0x50FFFFFF),
                Color(0x05FFFFFF),
                Color(0x35FFFFFF),
              ],
              stops: [0.0, 0.35, 0.65, 1.0],
            ),
          ),
      ],
    );
  }
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
