import 'package:flutter/material.dart';
import 'package:theme_core/lockscreen_layout.dart'
    show Pt, RRect2, Rect2, Size2;
import 'package:theme_core/theme_core.dart';

/// Bridges Flutter value types to the pure-Dart ones in theme_core.
extension ColorToRgba on Color {
  Rgba toRgba() => Rgba(toARGB32());
}

extension RgbaToColor on Rgba {
  Color toColor() => Color(argb);
}

extension AlignmentGeometryToAlignment2 on AlignmentGeometry {
  Alignment2 toAlignment2() {
    final a = resolve(TextDirection.ltr);
    return Alignment2(a.x, a.y);
  }
}

extension Alignment2ToAlignment on Alignment2 {
  Alignment toAlignment() => Alignment(x, y);
}

extension Rect2ToRect on Rect2 {
  Rect toRect() => Rect.fromLTRB(left, top, right, bottom);
}

extension RRect2ToRRect on RRect2 {
  RRect toRRect() =>
      RRect.fromRectAndRadius(rect.toRect(), Radius.circular(radius));
}

extension PtToOffset on Pt {
  Offset toOffset() => Offset(dx, dy);
}

extension Size2ToSize on Size2 {
  Size toSize() => Size(width, height);
}
