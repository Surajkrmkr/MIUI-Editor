import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:morphable_shape/morphable_shape.dart';
import 'package:miui_icon_generator/theme_editor/domain/entities/icon_shape.dart';

class IconShapeUtils {
  /// Returns a [ShapeBorder] based on the selected [IconShape].
  /// [radius] is the base logical radius from the UI.
  /// [scale] is 1.0 for preview and 4.0 for export.
  /// [seed] can be used to generate variants for the 'blob' shape.
  static ShapeBorder getBorder(IconShape shape, double radius,
      {double borderWidth = 0,
      Color borderColor = Colors.transparent,
      double scale = 1.0,
      int? seed}) {
    final scaledRadius = radius * scale;
    final scaledBorderWidth = borderWidth * scale;

    final border = scaledBorderWidth > 0
        ? DynamicBorderSide(
            width: scaledBorderWidth,
            color: borderColor,
          )
        : DynamicBorderSide.none;

    switch (shape) {
      case IconShape.squircle:
        return RectangleShapeBorder(
          borderRadius: DynamicBorderRadius.all(
            DynamicRadius.circular((scaledRadius * 2.2).toPXLength),
          ),
          border: border,
        );
      case IconShape.hexagon:
        return PolygonShapeBorder(
          sides: 6,
          cornerRadius: scaledRadius.toPXLength,
          border: border,
        );
      case IconShape.octagon:
        return PolygonShapeBorder(
          sides: 8,
          cornerRadius: scaledRadius.toPXLength,
          border: border,
        );
      case IconShape.pentagon:
        return PolygonShapeBorder(
          sides: 5,
          cornerRadius: scaledRadius.toPXLength,
          border: border,
        );
      case IconShape.shield:
        return RectangleShapeBorder(
          borderRadius: DynamicBorderRadius.only(
            topLeft: DynamicRadius.circular(scaledRadius.toPXLength),
            topRight: DynamicRadius.circular(scaledRadius.toPXLength),
            bottomLeft: DynamicRadius.circular((scaledRadius * 4).toPXLength),
            bottomRight: DynamicRadius.circular((scaledRadius * 4).toPXLength),
          ),
          border: border,
        );
      case IconShape.ticket:
        return RectangleShapeBorder(
          borderRadius: DynamicBorderRadius.all(
            DynamicRadius.circular(scaledRadius.toPXLength),
          ),
          cornerStyles: const RectangleCornerStyles.all(CornerStyle.concave),
          border: border,
        );
      case IconShape.pebble:
        return RectangleShapeBorder(
          borderRadius: DynamicBorderRadius.only(
            topLeft: DynamicRadius.circular((scaledRadius * 3.5).toPXLength),
            topRight: DynamicRadius.circular(scaledRadius.toPXLength),
            bottomLeft: DynamicRadius.circular((scaledRadius * 2).toPXLength),
            bottomRight: DynamicRadius.circular((scaledRadius * 4.5).toPXLength),
          ),
          border: border,
        );
      case IconShape.blob:
        final rnd = math.Random(seed ?? 0);
        return RectangleShapeBorder(
          borderRadius: DynamicBorderRadius.only(
            topLeft: DynamicRadius.circular(
                (scaledRadius * (2 + rnd.nextDouble() * 3)).toPXLength),
            topRight: DynamicRadius.circular(
                (scaledRadius * (1 + rnd.nextDouble() * 4)).toPXLength),
            bottomLeft: DynamicRadius.circular(
                (scaledRadius * (2 + rnd.nextDouble() * 2)).toPXLength),
            bottomRight: DynamicRadius.circular(
                (scaledRadius * (3 + rnd.nextDouble() * 3)).toPXLength),
          ),
          border: border,
        );
      case IconShape.star:
        return StarShapeBorder(
          corners: 5,
          inset: 45.toPercentLength,
          cornerRadius: (scaledRadius / 2).toPXLength,
          insetRadius: (scaledRadius / 2).toPXLength,
          border: border,
        );
      case IconShape.diamond:
        return PolygonShapeBorder(
          sides: 4,
          cornerRadius: (scaledRadius / 1.2).toPXLength,
          border: border,
        );
      case IconShape.cloud:
        return StarShapeBorder(
          corners: 8,
          inset: 15.toPercentLength,
          cornerRadius: (scaledRadius * 2.2).toPXLength,
          insetRadius: (scaledRadius * 2.2).toPXLength,
          border: border,
        );
      case IconShape.triangle:
        return TriangleShapeBorder(
          point1: const DynamicOffset(Length(50, unit: LengthUnit.percent), Length(0)),
          point2: const DynamicOffset(Length(100, unit: LengthUnit.percent), Length(100, unit: LengthUnit.percent)),
          point3: const DynamicOffset(Length(0), Length(100, unit: LengthUnit.percent)),
          border: border,
        );
      case IconShape.heart:
        // A much more accurate and aesthetic heart shape path
        return PathShapeBorder(
          border: border,
          path: DynamicPath(
            size: const Size(100, 100),
            nodes: [
              DynamicNode(position: const Offset(50, 100)), // Bottom tip
              DynamicNode(
                position: const Offset(5, 35),
                prev: const Offset(15, 80),
                next: const Offset(-5, 0),
              ),
              DynamicNode(
                position: const Offset(50, 25),
                prev: const Offset(10, -15),
                next: const Offset(90, -15),
              ),
              DynamicNode(
                position: const Offset(95, 35),
                prev: const Offset(105, 0),
                next: const Offset(85, 80),
              ),
            ],
          ),
        );
      case IconShape.capsule:
        return RectangleShapeBorder(
          borderRadius: const DynamicBorderRadius.all(
            DynamicRadius.circular(Length(50, unit: LengthUnit.percent)),
          ),
          border: border,
        );
      case IconShape.leaf:
        return RectangleShapeBorder(
          borderRadius: DynamicBorderRadius.only(
            topLeft: DynamicRadius.circular((scaledRadius * 4).toPXLength),
            bottomRight: DynamicRadius.circular((scaledRadius * 4).toPXLength),
            topRight: DynamicRadius.circular(scaledRadius.toPXLength),
            bottomLeft: DynamicRadius.circular(scaledRadius.toPXLength),
          ),
          border: border,
        );
      case IconShape.ring:
        return StarShapeBorder(
          corners: 40,
          inset: 0.toPercentLength,
          cornerRadius: (scaledRadius * 2.5).toPXLength,
          border: border,
        );
      case IconShape.trapezoid:
        return TrapezoidShapeBorder(
          inset: 12.toPercentLength,
          border: border,
        );
    }
  }
}
