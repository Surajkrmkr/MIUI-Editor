import 'package:flutter/material.dart';
import 'package:theme_core/theme_core.dart' show IconShape;
import 'icon_shape_utils.dart';

/// [ShapeBorder] adapter over [IconShapeUtils.path] for decorations.
class IconShapeBorder extends ShapeBorder {
  const IconShapeBorder({
    required this.shape,
    this.radius = 10,
    this.borderWidth = 0,
    this.borderColor = Colors.transparent,
    this.seed = 0,
  });

  final IconShape shape;
  final double radius;
  final double borderWidth;
  final Color borderColor;
  final int seed;

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.all(borderWidth);

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) =>
      IconShapeUtils.path(shape, rect, radius: radius, seed: seed);

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) =>
      IconShapeUtils.path(
        shape,
        rect.deflate(borderWidth),
        radius: radius,
        seed: seed,
      );

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    if (borderWidth <= 0) return;
    canvas.drawPath(
      getOuterPath(rect.deflate(borderWidth / 2)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = borderWidth
        ..color = borderColor,
    );
  }

  @override
  ShapeBorder scale(double t) => IconShapeBorder(
    shape: shape,
    radius: radius,
    borderWidth: borderWidth * t,
    borderColor: borderColor,
    seed: seed,
  );

  @override
  bool operator ==(Object other) =>
      other is IconShapeBorder &&
      other.shape == shape &&
      other.radius == radius &&
      other.borderWidth == borderWidth &&
      other.borderColor == borderColor &&
      other.seed == seed;

  @override
  int get hashCode =>
      Object.hash(shape, radius, borderWidth, borderColor, seed);
}
