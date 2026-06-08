import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../domain/entities/icon_shape.dart';

class IconShapeBorder extends ShapeBorder {
  const IconShapeBorder({
    required this.shape,
    this.radius = 10,
    this.borderWidth = 0,
    this.borderColor = Colors.transparent,
  });

  final IconShape shape;
  final double radius;
  final double borderWidth;
  final Color borderColor;

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.all(borderWidth);

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) {
    return getOuterPath(rect.deflate(borderWidth), textDirection: textDirection);
  }

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    final path = Path();
    final w = rect.width;
    final h = rect.height;
    final center = rect.center;

    switch (shape) {
      case IconShape.squircle:
        path.addRRect(RRect.fromRectAndRadius(rect, Radius.circular(radius * 2)));
        break;
      case IconShape.hexagon:
        _addPolygon(path, center, math.min(w, h) / 2, 6);
        break;
      case IconShape.octagon:
        _addPolygon(path, center, math.min(w, h) / 2, 8);
        break;
      case IconShape.shield:
        path.moveTo(center.dx, rect.top);
        path.lineTo(rect.right, rect.top + h * 0.2);
        path.quadraticBezierTo(rect.right, rect.bottom * 0.8, center.dx, rect.bottom);
        path.quadraticBezierTo(rect.left, rect.bottom * 0.8, rect.left, rect.top + h * 0.2);
        path.close();
        break;
      case IconShape.ticket:
        final r = radius > 0 ? radius : 8.0;
        path.moveTo(rect.left + r, rect.top);
        path.lineTo(rect.right - r, rect.top);
        path.arcToPoint(Offset(rect.right, rect.top + r), radius: Radius.circular(r), clockwise: false);
        path.lineTo(rect.right, rect.bottom - r);
        path.arcToPoint(Offset(rect.right - r, rect.bottom), radius: Radius.circular(r), clockwise: false);
        path.lineTo(rect.left + r, rect.bottom);
        path.arcToPoint(Offset(rect.left, rect.bottom - r), radius: Radius.circular(r), clockwise: false);
        path.lineTo(rect.left, rect.top + r);
        path.arcToPoint(Offset(rect.left + r, rect.top), radius: Radius.circular(r), clockwise: false);
        break;
      case IconShape.pebble:
        path.addRRect(RRect.fromRectAndCorners(
          rect,
          topLeft: Radius.circular(radius * 3),
          topRight: Radius.circular(radius * 1.5),
          bottomLeft: Radius.circular(radius * 2),
          bottomRight: Radius.circular(radius * 4),
        ));
        break;
      case IconShape.blob:
         path.moveTo(rect.left + w * 0.2, rect.top + h * 0.1);
         path.cubicTo(rect.right * 0.8, rect.top - h * 0.1, rect.right + w * 0.1, rect.bottom * 0.5, rect.right * 0.8, rect.bottom * 0.9);
         path.cubicTo(rect.center.dx, rect.bottom + h * 0.1, rect.left - w * 0.1, rect.bottom * 0.8, rect.left + w * 0.1, rect.center.dy);
         path.close();
         break;
      case IconShape.star:
        _addStar(path, center, math.min(w, h) / 2, 5);
        break;
      case IconShape.diamond:
        path.moveTo(center.dx, rect.top);
        path.lineTo(rect.right, center.dy);
        path.lineTo(center.dx, rect.bottom);
        path.lineTo(rect.left, center.dy);
        path.close();
        break;
      case IconShape.cloud:
        final r = math.min(w, h) / 4;
        path.addOval(Rect.fromCircle(center: Offset(rect.left + r, center.dy), radius: r));
        path.addOval(Rect.fromCircle(center: Offset(center.dx, rect.top + r), radius: r * 1.2));
        path.addOval(Rect.fromCircle(center: Offset(rect.right - r, center.dy), radius: r));
        path.addOval(Rect.fromCircle(center: Offset(center.dx, rect.bottom - r), radius: r));
        path.addRect(Rect.fromCenter(center: center, width: r * 2, height: r * 2));
        break;
      default:
        break;
    }

    return path;
  }

  void _addPolygon(Path path, Offset center, double radius, int sides) {
    final angle = (math.pi * 2) / sides;
    path.moveTo(center.dx + radius * math.cos(0), center.dy + radius * math.sin(0));
    for (int i = 1; i <= sides; i++) {
      path.lineTo(center.dx + radius * math.cos(angle * i), center.dy + radius * math.sin(angle * i));
    }
    path.close();
  }

  void _addStar(Path path, Offset center, double radius, int points) {
    final innerRadius = radius / 2;
    final angle = math.pi / points;
    path.moveTo(center.dx + radius * math.cos(-math.pi / 2), center.dy + radius * math.sin(-math.pi / 2));
    for (int i = 1; i < points * 2; i++) {
      final r = i.isEven ? radius : innerRadius;
      path.lineTo(center.dx + r * math.cos(angle * i - math.pi / 2), center.dy + r * math.sin(angle * i - math.pi / 2));
    }
    path.close();
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    if (borderWidth > 0) {
      final paint = Paint()
        ..color = borderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = borderWidth;
      canvas.drawPath(getOuterPath(rect), paint);
    }
  }

  @override
  ShapeBorder scale(double t) => this;
}
