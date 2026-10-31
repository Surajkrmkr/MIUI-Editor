import 'dart:math';

import '../values/rgba.dart';
import 'element_enums.dart';
import 'geometry.dart';
import 'lock_element_spec.dart';
import 'maml_dates.dart';

/// One number of a countdown ticker, in theme pixels (before `scale`).
class TickerSlot {
  const TickerSlot({
    required this.offset,
    required this.center,
    required this.size,
    required this.color,
  });

  /// Steps from the current value; 0 is the middle slot.
  final int offset;
  final Pt center;
  final double size;
  final Rgba color;

  bool get isCurrent => offset == 0;
}

/// Geometry and values of a countdown ticker, shared by the editor painter
/// and the MAML export so the panel PNG and the live numbers line up.
class TickerLayout {
  TickerLayout.of(this.el) : count = el.tickerCount;

  final LockElementSpec el;
  final int count;

  TickerStyle get style => el.tickerStyle;
  TickerSource get source => el.tickerSource;
  double get w => el.width;
  double get h => el.height;
  int get half => count ~/ 2;
  double get colW => w / count;

  /// Room around the panel for glows in the exported PNG.
  double get exportInset => h * .35;

  Rgba get currentColor => el.strokeColor.a > 0 ? el.strokeColor : el.color;

  /// Where the guide line, ticks, track or wave sit.
  double get guideY => switch (style) {
    TickerStyle.glowLine || TickerStyle.pulseWave => h * .26,
    TickerStyle.rulerTicks => h * .7,
    TickerStyle.progressTrack => h * .86,
    TickerStyle.dialArc => h * .12,
    _ => h / 2,
  };

  /// The progress track; its fill grows with what is left.
  Rect2 get track => Rect2.fromLTWH(w * .04, guideY - h * .035, w * .92, h * .07);

  double _y(int o) => switch (style) {
    TickerStyle.glowLine || TickerStyle.pulseWave => h * .66,
    TickerStyle.rulerTicks => h * .36,
    TickerStyle.progressTrack => h * .42,
    TickerStyle.dialArc =>
      h * .4 + (1 - cos(o * .3)) / (1 - cos(max(1, half) * .3)) * h * .34,
    _ => h / 2,
  };

  double _scale(int o) {
    final d = o.abs();
    return switch (style) {
      TickerStyle.perspectiveFloor => max(.5, 1.5 - .18 * d),
      TickerStyle.focusLens => d == 0 ? 1.45 : .82,
      TickerStyle.neonRing || TickerStyle.odometer => d == 0 ? 1.25 : .95,
      _ => d == 0 ? 1.15 : 1,
    };
  }

  double _fade(int o) {
    final d = o.abs();
    return switch (style) {
      TickerStyle.odometer => .6,
      TickerStyle.scanBeam => .38,
      TickerStyle.focusLens => max(.2, .75 - .12 * d),
      _ => max(.15, 1 - .17 * d),
    };
  }

  List<TickerSlot> get slots => [for (var o = -half; o <= half; o++) _slot(o)];

  TickerSlot _slot(int o) => TickerSlot(
    offset: o,
    center: Pt((o + half + .5) * colW, _y(o)),
    size: el.fontSize * lockscreenScreenRatio * _scale(o),
    color: o == 0
        ? currentColor
        : el.color.withOpacity(el.color.opacity * _fade(o)),
  );

  // ── Values ────────────────────────────────────────────────────────────────

  static int _daysInMonth(DateTime d) => DateTime(d.year, d.month + 1, 0).day;
  static int _daysInYear(DateTime d) =>
      DateTime(d.year + 1).difference(DateTime(d.year)).inDays;
  static int _dayOfYear(DateTime d) =>
      DateTime(d.year, d.month, d.day).difference(DateTime(d.year)).inDays + 1;

  /// Largest value the source can show, used for wrapping and progress.
  int maxValue(DateTime now) => switch (source) {
    TickerSource.seconds => 59,
    TickerSource.monthDaysLeft => _daysInMonth(now) - 1,
    TickerSource.yearDaysLeft => _daysInYear(now) - 1,
  };

  int current(DateTime now) => switch (source) {
    TickerSource.seconds => now.second,
    TickerSource.monthDaysLeft => _daysInMonth(now) - now.day,
    TickerSource.yearDaysLeft => _daysInYear(now) - _dayOfYear(now),
  };

  /// The number [offset] steps from now; null past the ends of a day count.
  int? valueAt(DateTime now, int offset) {
    final v = current(now) + offset;
    if (source == TickerSource.seconds) return v % 60;
    return v < 0 || v > maxValue(now) ? null : v;
  }

  /// Seconds read like a clock (`05`); day counts stay plain.
  String format(int value) => source == TickerSource.seconds
      ? value.toString().padLeft(2, '0')
      : '$value';

  String get mamlFormat => source == TickerSource.seconds ? '%02d' : '%d';

  /// How much is left, 0–1, for the progress track.
  double progress(DateTime now) => current(now) / max(1, maxValue(now));

  // ── MAML ──────────────────────────────────────────────────────────────────

  String get _id => el.name.replaceAll(RegExp(r'[^A-Za-z0-9_]'), '_');
  String get varCurrent => 'ticker_${_id}_v';
  String get varMax => 'ticker_${_id}_max';

  /// `<Var>`s for the current value and its maximum.
  String get varsXml {
    final (value, top) = switch (source) {
      TickerSource.seconds => ('#second', '59'),
      TickerSource.monthDaysLeft => (
        '${MamlDates.monthDays}-#date',
        '${MamlDates.monthDays}-1',
      ),
      TickerSource.yearDaysLeft => (
        '${MamlDates.yearDays}-${MamlDates.dayOfYear}',
        '${MamlDates.yearDays}-1',
      ),
    };
    return "<Var name='$varCurrent' expression='$value'/>"
        "<Var name='$varMax' expression='$top'/>";
  }

  /// MAML expression for the number [offset] steps from now.
  String valueExp(int offset) => source == TickerSource.seconds
      ? '((#$varCurrent+${offset + 600})%60)'
      : '(#$varCurrent+($offset))';

  /// Hides numbers past either end of a day count.
  String visibleExp(int offset) => source == TickerSource.seconds
      ? '1'
      : 'ge(${valueExp(offset)},0)*le(${valueExp(offset)},#$varMax)';
}
