import 'dart:math';
import 'package:flutter/material.dart';

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
  });

  final String text;
  final TextStyle? style;
  final Gradient gradient;
  final double strokeWidth;
  final Color strokeColor;
  final double blurRadius;
  final bool isLiquidGlass;

  @override
  Widget build(BuildContext context) {
    final baseStyle = style ?? const TextStyle();
    final hasStroke = strokeWidth > 0 && strokeColor.a > 0;
    final hasBlur = blurRadius > 0;
    final blurFilter = hasBlur ? MaskFilter.blur(BlurStyle.normal, blurRadius) : null;

    final TextPainter tp = TextPainter(
      text: TextSpan(text: text, style: baseStyle),
      textDirection: TextDirection.ltr,
    )..layout();
    final Rect bounds = Rect.fromLTWH(0, 0, max(1.0, tp.width), max(1.0, tp.height));
    final Shader fillShader = gradient.createShader(bounds);

    if (!hasStroke && !hasBlur && !isLiquidGlass) {
      return Text(
        text,
        style: baseStyle.copyWith(
          foreground: Paint()
            ..style = PaintingStyle.fill
            ..shader = fillShader,
        ),
      );
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
              foreground: Paint()
                ..style = PaintingStyle.fill
                ..color = Colors.black.withValues(alpha: 0.45)
                ..maskFilter = const MaskFilter.blur(BlurStyle.outer, 12.0),
            ),
          ),

        // 3. Main Text Body Fill (with Gradient Shader + Blur if set)
        if (isLiquidGlass)
          Text(
            text,
            style: baseStyle.copyWith(
              foreground: Paint()
                ..style = PaintingStyle.fill
                ..shader = LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    (baseStyle.color ?? Colors.white),
                    (baseStyle.color ?? Colors.white).withValues(alpha: 0.70),
                    const Color(0xFFD6E8FF).withValues(alpha: 0.85),
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ).createShader(bounds)
                ..maskFilter = blurFilter,
            ),
          )
        else
          Text(
            text,
            style: baseStyle.copyWith(
              foreground: Paint()
                ..style = PaintingStyle.fill
                ..shader = fillShader
                ..maskFilter = blurFilter,
            ),
          ),

        // 4. Liquid Glass 3D Bevel Rim Stroke
        if (isLiquidGlass)
          Text(
            text,
            style: baseStyle.copyWith(
              foreground: Paint()
                ..style = PaintingStyle.stroke
                ..strokeWidth = 2.0
                ..strokeJoin = StrokeJoin.round
                ..shader = const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFFFFFFF),
                    Color(0xCCFFFFFF),
                    Color(0x2033CCFF),
                    Color(0x80FFFFFF),
                  ],
                  stops: [0.0, 0.35, 0.70, 1.0],
                ).createShader(bounds),
            ),
          ),

        // 5. Liquid Glass Top Specular Sheen Overlay
        if (isLiquidGlass)
          Text(
            text,
            style: baseStyle.copyWith(
              foreground: Paint()
                ..style = PaintingStyle.fill
                ..shader = const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xF0FFFFFF),
                    Color(0x50FFFFFF),
                    Color(0x05FFFFFF),
                    Color(0x35FFFFFF),
                  ],
                  stops: [0.0, 0.35, 0.65, 1.0],
                ).createShader(bounds),
            ),
          ),
      ],
    );
  }
}

