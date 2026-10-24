import 'dart:math';

import '../values/rgba.dart';
import 'element_enums.dart';
import 'geometry.dart';
import 'lock_element_spec.dart';

/// Geometry of a styled calendar in theme pixels (before `scale`).
class CalendarLayout {
  CalendarLayout.of(this.el)
    : inner = Rect2.fromLTRB(
        el.width * .04,
        el.height * .1,
        el.width * .96,
        el.height * .9,
      );

  final LockElementSpec el;
  final Rect2 inner;

  double get rowH => inner.height / el.calendarDisplayRows;
  double get colW => inner.width / 7;
  int? get monthRow => el.calendarShowMonth ? 0 : null;
  int? get weekdayRow =>
      el.calendarShowWeekdays ? (el.calendarShowMonth ? 1 : 0) : null;
  int get firstDateRow => el.calendarDisplayRows - el.calendarWeekRows;

  Rect2 cell(int row, int col) => Rect2.fromLTWH(
    inner.left + col * colW,
    inner.top + row * rowH,
    colW,
    rowH,
  );

  bool get showsDates => el.calendarStyle != CalendarStyle.plusCircles;

  /// Weekday labels in column order.
  List<String> get labels => switch (el.calendarStyle) {
    CalendarStyle.pillColumn ||
    CalendarStyle.glassCard ||
    CalendarStyle.capsuleRow ||
    CalendarStyle.floatingBadges ||
    CalendarStyle.ticketStub ||
    CalendarStyle.softNeumorphism => const [
      'Sun',
      'Mon',
      'Tue',
      'Wed',
      'Thu',
      'Fri',
      'Sat',
    ],
    CalendarStyle.minimalDots ||
    CalendarStyle.polarArc ||
    CalendarStyle.monolith => const [
      'S',
      'M',
      'T',
      'W',
      'T',
      'F',
      'S',
    ],
    CalendarStyle.plusCircles => const [
      'MON',
      'TUE',
      'WED',
      'THU',
      'FRI',
      'SAT',
      'SUN',
    ],
    _ => const ['SUN', 'MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT'],
  };

  /// Today's highlight for the date cell at [row]/[col].
  RRect2 highlight(int row, int col) {
    final c = cell(row, col);
    if ((el.calendarStyle == CalendarStyle.pillColumn ||
            el.calendarStyle == CalendarStyle.capsuleRow) &&
        el.calendarWeekRows == 1 &&
        weekdayRow != null) {
      final top = cell(weekdayRow!, col).top - rowH * .12;
      final r = Rect2.fromLTRB(
        c.left + colW * .14,
        top,
        c.right - colW * .14,
        c.bottom + rowH * .12,
      );
      return RRect2(r, r.width / 2);
    }
    if (el.calendarStyle == CalendarStyle.neoBrutalism ||
        el.calendarStyle == CalendarStyle.cyberMatrix) {
      final r = Rect2.fromCenter(
        center: c.center,
        width: min(colW * .82, rowH * 1.05),
        height: rowH * .84,
      );
      return RRect2(r, el.calendarStyle == CalendarStyle.cyberMatrix ? 2.0 : 4.0);
    }
    if (el.calendarStyle == CalendarStyle.bentoGrid ||
        el.calendarStyle == CalendarStyle.ticketStub) {
      final r = Rect2.fromCenter(
        center: c.center,
        width: colW * .84,
        height: rowH * .84,
      );
      return RRect2(r, el.calendarStyle == CalendarStyle.ticketStub ? 6.0 : 10.0);
    }
    if (el.calendarStyle == CalendarStyle.minimalDots ||
        el.calendarStyle == CalendarStyle.outlineRings ||
        el.calendarStyle == CalendarStyle.lunarPhase ||
        el.calendarStyle == CalendarStyle.polarArc) {
      final side = min(colW * .78, rowH * .82);
      final r = Rect2.fromCenter(
        center: c.center,
        width: side,
        height: side,
      );
      return RRect2(r, side / 2);
    }
    final r = Rect2.fromCenter(
      center: c.center,
      width: min(colW * .72, rowH * 1.05),
      height: rowH * .82,
    );
    return RRect2(r, r.height * .45);
  }

  double get panelRadius => min(
    el.height *
        switch (el.calendarStyle) {
          CalendarStyle.pillColumn => .16,
          CalendarStyle.plusCircles => .14,
          CalendarStyle.neoBrutalism => .12,
          CalendarStyle.neonCyber ||
          CalendarStyle.cyberMatrix => .10,
          CalendarStyle.monolith => .12,
          CalendarStyle.bracketModern => .12,
          CalendarStyle.ticketStub => .16,
          CalendarStyle.capsuleRow => .20,
          CalendarStyle.gradientAura ||
          CalendarStyle.polarArc => .25,
          CalendarStyle.bentoGrid => .22,
          CalendarStyle.softNeumorphism => .22,
          CalendarStyle.glassCard => .20,
          _ => .3,
        },
    el.width * .08,
  );

  Rgba labelColor(int col) {
    if ((col == 0 || col == 6) &&
        (el.calendarStyle == CalendarStyle.stripHeader ||
            el.calendarStyle == CalendarStyle.neonCyber ||
            el.calendarStyle == CalendarStyle.neoBrutalism ||
            el.calendarStyle == CalendarStyle.minimalDots ||
            el.calendarStyle == CalendarStyle.lunarPhase ||
            el.calendarStyle == CalendarStyle.monolith ||
            el.calendarStyle == CalendarStyle.splitFlap ||
            el.calendarStyle == CalendarStyle.polarArc ||
            el.calendarStyle == CalendarStyle.cyberMatrix ||
            el.calendarStyle == CalendarStyle.ticketStub ||
            el.calendarStyle == CalendarStyle.gradientAura)) {
      if (el.strokeColor.a > 0) return el.strokeColor;
    }
    return el.color;
  }

  /// Text colour of today's date on top of the highlight.
  Rgba get todayText => switch (el.calendarStyle) {
    CalendarStyle.stripHeader ||
    CalendarStyle.neoBrutalism ||
    CalendarStyle.splitFlap ||
    CalendarStyle.capsuleRow ||
    CalendarStyle.cyberMatrix ||
    CalendarStyle.ticketStub =>
      el.borderColor.a > 0 ? el.borderColor : el.unlockAccent,
    _ => el.color,
  };

  /// Space around the exported panel PNG, so its shadow isn't clipped.
  double get exportInset => el.width * .03;
}
