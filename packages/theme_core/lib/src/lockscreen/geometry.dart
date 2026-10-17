/// Minimal geometry types, so layout math can run without `dart:ui`.
library;

class Pt {
  const Pt(this.dx, this.dy);

  final double dx, dy;

  @override
  bool operator ==(Object other) =>
      other is Pt && other.dx == dx && other.dy == dy;

  @override
  int get hashCode => Object.hash(dx, dy);

  @override
  String toString() => 'Pt($dx, $dy)';
}

class Size2 {
  const Size2(this.width, this.height);

  final double width, height;

  @override
  bool operator ==(Object other) =>
      other is Size2 && other.width == width && other.height == height;

  @override
  int get hashCode => Object.hash(width, height);

  @override
  String toString() => 'Size2($width, $height)';
}

class Rect2 {
  const Rect2.fromLTRB(this.left, this.top, this.right, this.bottom);

  const Rect2.fromLTWH(double left, double top, double width, double height)
    : this.fromLTRB(left, top, left + width, top + height);

  factory Rect2.fromCenter({
    required Pt center,
    required double width,
    required double height,
  }) => Rect2.fromLTRB(
    center.dx - width / 2,
    center.dy - height / 2,
    center.dx + width / 2,
    center.dy + height / 2,
  );

  final double left, top, right, bottom;

  double get width => right - left;
  double get height => bottom - top;
  Pt get center => Pt(left + width / 2, top + height / 2);

  @override
  bool operator ==(Object other) =>
      other is Rect2 &&
      other.left == left &&
      other.top == top &&
      other.right == right &&
      other.bottom == bottom;

  @override
  int get hashCode => Object.hash(left, top, right, bottom);

  @override
  String toString() => 'Rect2($left, $top, $right, $bottom)';
}

/// Rectangle with one uniform corner radius.
class RRect2 {
  const RRect2(this.rect, this.radius);

  final Rect2 rect;
  final double radius;

  double get left => rect.left;
  double get top => rect.top;
  double get width => rect.width;
  double get height => rect.height;
}
