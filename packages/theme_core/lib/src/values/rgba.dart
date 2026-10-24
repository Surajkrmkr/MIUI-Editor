import 'dart:math' as math;

/// 32-bit ARGB color without any Flutter dependency.
///
/// Hex strings use Android's `#AARRGGBB` order (same as the existing MAML
/// output), not CSS's `#RRGGBBAA`.
class Rgba {
  const Rgba(this.argb)
    : assert(argb >= 0 && argb <= 0xFFFFFFFF, 'argb must fit in 32 bits');

  const Rgba.fromARGB(int a, int r, int g, int b)
    : argb =
          ((a & 0xFF) << 24) |
          ((r & 0xFF) << 16) |
          ((g & 0xFF) << 8) |
          (b & 0xFF);

  /// Opaque color from `#RRGGBB`-style channels.
  const Rgba.rgb(int r, int g, int b) : this.fromARGB(0xFF, r, g, b);

  final int argb;

  int get a => (argb >> 24) & 0xFF;
  int get alpha => a;
  int get r => (argb >> 16) & 0xFF;
  int get g => (argb >> 8) & 0xFF;
  int get b => argb & 0xFF;

  /// Alpha as 0.0–1.0.
  double get opacity => a / 255;

  /// Accepts `#RGB`, `#RRGGBB` or `#AARRGGBB`; the `#` is optional.
  /// Throws [FormatException] otherwise.
  factory Rgba.fromHex(String hex) =>
      tryParseHex(hex) ?? (throw FormatException('Invalid color "$hex"'));

  static Rgba? tryParseHex(String hex) {
    var s = hex.trim();
    if (s.startsWith('#')) s = s.substring(1);
    if (s.length == 3) {
      s = s.split('').map((c) => '$c$c').join();
    }
    if (s.length == 6) s = 'FF$s';
    if (s.length != 8) return null;
    final v = int.tryParse(s, radix: 16);
    return v == null ? null : Rgba(v);
  }

  /// Reads either the legacy ARGB `int` or a hex string; null when neither.
  static Rgba? tryParse(Object? json) => switch (json) {
    final int v when v >= 0 && v <= 0xFFFFFFFF => Rgba(v),
    final String s => tryParseHex(s),
    _ => null,
  };

  /// Upper-case `#RRGGBB`, or `#AARRGGBB` when [withAlpha] is set.
  String toHex({bool withAlpha = false}) {
    String h(int v) => v.toRadixString(16).padLeft(2, '0');
    final rgb = '${h(r)}${h(g)}${h(b)}';
    return '#${withAlpha ? h(a) : ''}$rgb'.toUpperCase();
  }

  /// Opaque `#FFRRGGBB`, as MAML expects for solid colors.
  String toMamlHex() => '#FF${toHex().substring(1)}';

  Rgba withAlpha(int alpha) => Rgba.fromARGB(alpha, r, g, b);

  Rgba withOpacity(double o) => withAlpha((o.clamp(0.0, 1.0) * 255).round());

  /// WCAG relative luminance (0 black – 1 white), ignoring alpha.
  double get luminance {
    double lin(int c) {
      final s = c / 255;
      return s <= 0.03928
          ? s / 12.92
          : math.pow((s + 0.055) / 1.055, 2.4).toDouble();
    }

    return 0.2126 * lin(r) + 0.7152 * lin(g) + 0.0722 * lin(b);
  }

  /// WCAG contrast ratio, 1–21, ignoring alpha.
  double contrastWith(Rgba other) {
    final l1 = luminance, l2 = other.luminance;
    final hi = math.max(l1, l2), lo = math.min(l1, l2);
    return (hi + 0.05) / (lo + 0.05);
  }

  @override
  bool operator ==(Object other) => other is Rgba && other.argb == argb;

  @override
  int get hashCode => argb.hashCode;

  @override
  String toString() => 'Rgba(${toHex(withAlpha: true)})';
}
