/// Position in a box, `-1..1` on each axis (same convention as Flutter's
/// `Alignment`), without the Flutter dependency.
class Alignment2 {
  const Alignment2(this.x, this.y);

  final double x;
  final double y;

  static const topLeft = Alignment2(-1, -1);
  static const topCenter = Alignment2(0, -1);
  static const topRight = Alignment2(1, -1);
  static const centerLeft = Alignment2(-1, 0);
  static const center = Alignment2(0, 0);
  static const centerRight = Alignment2(1, 0);
  static const bottomLeft = Alignment2(-1, 1);
  static const bottomCenter = Alignment2(0, 1);
  static const bottomRight = Alignment2(1, 1);

  static const _legacyNames = <String, Alignment2>{
    'Alignment.topLeft': topLeft,
    'Alignment.topCenter': topCenter,
    'Alignment.topRight': topRight,
    'Alignment.centerLeft': centerLeft,
    'Alignment.center': center,
    'Alignment.centerRight': centerRight,
    'Alignment.bottomLeft': bottomLeft,
    'Alignment.bottomCenter': bottomCenter,
    'Alignment.bottomRight': bottomRight,
  };

  /// Reads a legacy name such as `Alignment.topLeft` (as stored in preset
  /// JSON), or a two-number list `[x, y]`; null when neither.
  static Alignment2? tryParse(Object? json) {
    if (json is String) return _legacyNames[json];
    if (json is List && json.length == 2) {
      final x = json[0], y = json[1];
      if (x is num && y is num) return Alignment2(x.toDouble(), y.toDouble());
    }
    return null;
  }

  /// Name preset JSON has always used; anything off the 3x3 grid falls back
  /// to `Alignment.center`, matching how the app reads it back.
  String toLegacyString() {
    for (final e in _legacyNames.entries) {
      if (e.value == this) return e.key;
    }
    return 'Alignment.center';
  }

  List<double> toJson() => [x, y];

  @override
  bool operator ==(Object other) =>
      other is Alignment2 && other.x == x && other.y == y;

  @override
  int get hashCode => Object.hash(x, y);

  @override
  String toString() => 'Alignment2($x, $y)';
}
