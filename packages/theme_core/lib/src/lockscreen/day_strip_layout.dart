import 'dart:math';

import '../values/rgba.dart';
import 'element_enums.dart';
import 'geometry.dart';
import 'lock_element_spec.dart';

/// One day of a day strip, in theme pixels (before `scale`).
class DayStripSlot {
  const DayStripSlot({
    required this.offset,
    required this.box,
    required this.radius,
    required this.label,
    required this.labelSize,
    required this.color,
    this.date,
    Rgba? dateColor,
  }) : dateColor = dateColor ?? color;

  /// Days from today; 0 is today, always the middle slot.
  final int offset;
  final Rect2 box;
  final double radius;
  final Pt label;
  final double labelSize;
  final Rgba color;

  /// Centre of the date number, for styles that show one.
  final Pt? date;
  final Rgba dateColor;

  bool get isToday => offset == 0;
  double get dateSize => labelSize * 1.75;
}

/// Geometry of a day strip; shared by the editor painter and the MAML export
/// so the static panel PNG and the live weekday text line up.
class DayStripLayout {
  DayStripLayout.of(this.el) : count = el.dayStripCount;

  final LockElementSpec el;
  final int count;

  DayStripStyle get style => el.dayStripStyle;
  double get w => el.width;
  double get h => el.height;

  /// Room around the panel for glows and shadows in the exported PNG.
  double get exportInset => h * .3;

  bool get upperCase => !const {
    DayStripStyle.dotIndicator,
    DayStripStyle.fadeCarousel,
    DayStripStyle.softClay,
  }.contains(style);

  bool get showsDate =>
      style == DayStripStyle.dateStack || style == DayStripStyle.calendarTear;

  /// Gap between slots; the segmented bar's segments touch.
  double get gap => switch (style) {
    DayStripStyle.segmentedBar => 0,
    DayStripStyle.dotIndicator ||
    DayStripStyle.underlineTabs ||
    DayStripStyle.fadeCarousel ||
    DayStripStyle.bracketMono => w * .02,
    _ => w * .045 / (count / 3),
  };

  double get slotW => (w - gap * (count - 1)) / count;

  /// Height of a pill-shaped slot.
  double get pillH => switch (style) {
    DayStripStyle.segmentedBar => h * .62,
    DayStripStyle.neoBrutal => h * .64,
    DayStripStyle.orbitArc => h * .46,
    _ => h * .6,
  };

  /// Today's text; without a set colour, black or white against the highlight.
  Rgba get todayText => el.strokeColor.a > 0
      ? el.strokeColor
      : el.colorSecondary.luminance > .5
      ? const Rgba(0xFF111111)
      : const Rgba(0xFFFFFFFF);

  /// Text colour for inactive days, dimmed by distance for some styles.
  Rgba inactiveColor(int offset) {
    final base = el.color;
    final fade = switch (style) {
      DayStripStyle.fadeCarousel => max(.22, 1 - .3 * offset.abs()),
      DayStripStyle.dotIndicator || DayStripStyle.underlineTabs => .55,
      DayStripStyle.bracketMono => .42,
      DayStripStyle.neonTube => .7,
      _ => 1.0,
    };
    return base.withOpacity(base.opacity * fade);
  }

  double sizeScale(int offset) => switch (style) {
    DayStripStyle.fadeCarousel => max(.6, 1 - .14 * offset.abs()),
    DayStripStyle.orbitArc => offset == 0 ? 1.12 : 1,
    _ => 1,
  };

  List<DayStripSlot> get slots {
    final base = el.fontSize * lockscreenScreenRatio;
    final mid = count ~/ 2;
    return [
      for (var i = 0; i < count; i++)
        _slot(i - mid, i * (slotW + gap), base * sizeScale(i - mid)),
    ];
  }

  DayStripSlot _slot(int o, double left, double size) {
    final color = o == 0 ? todayText : inactiveColor(o);
    final cx = left + slotW / 2;
    DayStripSlot pill(double top, double height, double radius) =>
        DayStripSlot(
          offset: o,
          box: Rect2.fromLTWH(left, top, slotW, height),
          radius: radius,
          label: Pt(cx, top + height / 2),
          labelSize: size,
          color: color,
        );
    switch (style) {
      case DayStripStyle.dateStack:
        return DayStripSlot(
          offset: o,
          box: Rect2.fromLTWH(left, 0, slotW, h),
          radius: min(slotW, h) * .28,
          label: Pt(cx, h * .3),
          date: Pt(cx, h * .66),
          labelSize: size,
          color: color,
        );
      case DayStripStyle.calendarTear:
        return DayStripSlot(
          offset: o,
          box: Rect2.fromLTWH(left, 0, slotW, h),
          radius: min(slotW, h) * .14,
          label: Pt(cx, h * .19),
          date: Pt(cx, h * .66),
          labelSize: size,
          color: color,
          // The label sits on the coloured band, the date on the paper.
          dateColor: o == 0 ? el.colorSecondary : el.borderColor,
        );
      case DayStripStyle.circleBadges:
        final d = min(slotW, h) * .92;
        return DayStripSlot(
          offset: o,
          box: Rect2.fromCenter(center: Pt(cx, h / 2), width: d, height: d),
          radius: d / 2,
          label: Pt(cx, h / 2),
          labelSize: size,
          color: color,
        );
      case DayStripStyle.orbitArc:
        final ph = pillH * (o == 0 ? 1.18 : 1);
        final edge = max(1, count ~/ 2);
        final cy = h * .32 + (1 - cos(o * .45)) / (1 - cos(edge * .45)) * h * .36;
        return DayStripSlot(
          offset: o,
          box: Rect2.fromCenter(
            center: Pt(cx, cy),
            width: slotW * (o == 0 ? 1.06 : .92),
            height: ph,
          ),
          radius: ph / 2,
          label: Pt(cx, cy),
          labelSize: size,
          color: color,
        );
      case DayStripStyle.dotIndicator:
      case DayStripStyle.underlineTabs:
        return pill(0, h * .78, 0);
      case DayStripStyle.neoBrutal:
        return pill((h - pillH) / 2 - h * .05, pillH, h * .08);
      case DayStripStyle.bracketMono:
        return pill((h - pillH) / 2, pillH, 0);
      default:
        return pill((h - pillH) / 2, pillH, pillH / 2);
    }
  }

  static const _upper = 'SUNMONTUEWEDTHUFRISAT';
  static const _title = 'SunMonTueWedThuFriSat';

  /// Weekday label for [d] (Dart weekday: Monday = 1 … Sunday = 7).
  String labelFor(DateTime d) {
    final i = d.weekday % 7;
    return (upperCase ? _upper : _title).substring(i * 3, i * 3 + 3);
  }

  /// MAML expression for the weekday label [offset] days from today.
  String labelExp(int offset) =>
      "substr('${upperCase ? _upper : _title}',"
      '((#day_of_week-1+${offset + 70})%7)*3,3)';
}
