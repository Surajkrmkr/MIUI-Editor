import 'dart:math';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../domain/entities/element_widget.dart';

/// Geometry of a styled calendar in theme pixels (before `scale`).
class CalendarLayout {
  CalendarLayout.of(this.el)
    : inner = Rect.fromLTRB(
        el.width * .04,
        el.height * .1,
        el.width * .96,
        el.height * .9,
      );

  final LockElement el;
  final Rect inner;

  double get rowH => inner.height / el.calendarDisplayRows;
  double get colW => inner.width / 7;
  int? get monthRow => el.calendarShowMonth ? 0 : null;
  int? get weekdayRow =>
      el.calendarShowWeekdays ? (el.calendarShowMonth ? 1 : 0) : null;
  int get firstDateRow => el.calendarDisplayRows - el.calendarWeekRows;

  Rect cell(int row, int col) => Rect.fromLTWH(
    inner.left + col * colW,
    inner.top + row * rowH,
    colW,
    rowH,
  );

  bool get showsDates => el.calendarStyle != CalendarStyle.plusCircles;

  /// Weekday labels in column order.
  List<String> get labels => switch (el.calendarStyle) {
    CalendarStyle.pillColumn => const [
      'Sun',
      'Mon',
      'Tue',
      'Wed',
      'Thu',
      'Fri',
      'Sat',
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
  RRect highlight(int row, int col) {
    final c = cell(row, col);
    if (el.calendarStyle == CalendarStyle.pillColumn &&
        el.calendarWeekRows == 1 &&
        weekdayRow != null) {
      final top = cell(weekdayRow!, col).top - rowH * .12;
      final r = Rect.fromLTRB(
        c.left + colW * .14,
        top,
        c.right - colW * .14,
        c.bottom + rowH * .12,
      );
      return RRect.fromRectAndRadius(r, Radius.circular(r.width / 2));
    }
    final r = Rect.fromCenter(
      center: c.center,
      width: min(colW * .72, rowH * 1.05),
      height: rowH * .82,
    );
    return RRect.fromRectAndRadius(r, Radius.circular(r.height * .45));
  }

  double get panelRadius => min(
    el.height *
        switch (el.calendarStyle) {
          CalendarStyle.pillColumn => .16,
          CalendarStyle.plusCircles => .14,
          _ => .3,
        },
    el.width * .08,
  );

  Color labelColor(int col) =>
      el.calendarStyle == CalendarStyle.stripHeader && (col == 0 || col == 6)
      ? el.strokeColor
      : el.color;

  /// Text colour of today's date on top of the highlight.
  Color get todayText =>
      el.calendarStyle == CalendarStyle.stripHeader ? el.borderColor : el.color;
}

/// Static background (panel, header strip, circles) exported as one PNG.
class CalendarStyleArt {
  const CalendarStyleArt._();

  static Widget panel(LockElement el, double k) => SizedBox(
    width: el.width * k,
    height: el.height * k,
    child: CustomPaint(painter: _PanelPainter(el, k)),
  );

  static const _pad = .03;
  static double exportInset(LockElement el) => el.width * _pad;

  static Widget exportPanel(LockElement el) {
    const k = 1 / 3;
    return Padding(
      padding: EdgeInsets.all(exportInset(el) * k),
      child: panel(el, k),
    );
  }
}

/// Editor preview: static panel plus today's highlight, labels and dates.
class CalendarStylePreview extends StatelessWidget {
  const CalendarStylePreview({super.key, required this.element});
  final LockElement element;

  @override
  Widget build(BuildContext context) {
    const k = 1 / AppConstants.screenRatio;
    final el = element;
    final l = CalendarLayout.of(el);
    final now = DateTime.now();
    final dates = el.calendarDates(now);
    TextStyle style(Color color) => TextStyle(
      color: color,
      fontSize: el.fontSize,
      fontWeight: el.fontWeight,
      height: 1,
    );
    Widget at(Rect r, Widget child) => Positioned(
      left: r.left * k,
      top: r.top * k,
      width: r.width * k,
      height: r.height * k,
      child: Center(child: child),
    );
    bool isToday(DateTime? d) =>
        d != null &&
        d.year == now.year &&
        d.month == now.month &&
        d.day == now.day;
    final children = <Widget>[CalendarStyleArt.panel(el, k)];
    if (l.showsDates) {
      for (var i = 0; i < dates.length; i++) {
        if (!isToday(dates[i])) continue;
        final h = l.highlight(l.firstDateRow + i ~/ 7, i % 7);
        children.add(
          Positioned(
            left: h.left * k,
            top: h.top * k,
            width: h.width * k,
            height: h.height * k,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: el.colorSecondary,
                borderRadius: BorderRadius.circular(h.tlRadiusX * k),
              ),
            ),
          ),
        );
      }
    }
    if (l.monthRow case final row?) {
      children.add(
        at(
          Rect.fromLTWH(
            l.inner.left,
            l.cell(row, 0).top,
            l.inner.width,
            l.rowH,
          ),
          Text(
            '${const ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'][now.month - 1]} ${now.year}',
            style: style(el.color),
          ),
        ),
      );
    }
    if (l.weekdayRow case final row?) {
      for (var c = 0; c < 7; c++) {
        children.add(
          at(l.cell(row, c), Text(l.labels[c], style: style(l.labelColor(c)))),
        );
      }
    }
    if (l.showsDates) {
      for (var i = 0; i < dates.length; i++) {
        final d = dates[i];
        if (d == null) continue;
        children.add(
          at(
            l.cell(l.firstDateRow + i ~/ 7, i % 7),
            Text('${d.day}', style: style(isToday(d) ? l.todayText : el.color)),
          ),
        );
      }
    }
    return SizedBox(
      width: el.width * k,
      height: el.height * k,
      child: Stack(clipBehavior: Clip.none, children: children),
    );
  }
}

class _PanelPainter extends CustomPainter {
  _PanelPainter(this.el, this.k);
  final LockElement el;
  final double k;

  @override
  void paint(Canvas canvas, Size size) {
    final l = CalendarLayout.of(el);
    Rect sc(Rect r) =>
        Rect.fromLTWH(r.left * k, r.top * k, r.width * k, r.height * k);
    final panel = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(l.panelRadius * k),
    );
    canvas.drawRRect(panel, Paint()..color = el.unlockAccent);

    switch (el.calendarStyle) {
      case CalendarStyle.stripHeader:
        if (l.weekdayRow case final row?) {
          final first = sc(l.cell(row, 0)), last = sc(l.cell(row, 6));
          final strip = Rect.fromLTRB(
            first.left - first.width * .1,
            first.top + first.height * .08,
            last.right + last.width * .1,
            first.bottom - first.height * .08,
          );
          canvas.drawRRect(
            RRect.fromRectAndRadius(strip, Radius.circular(strip.height / 2)),
            Paint()..color = el.borderColor,
          );
        }
      case CalendarStyle.plusCircles:
        for (var row = 0; row < el.calendarWeekRows; row++) {
          for (var col = 0; col < 7; col++) {
            final c = sc(l.cell(l.firstDateRow + row, col));
            final r = min(c.width * .4, c.height * .48);
            canvas.drawCircle(c.center, r, Paint()..color = el.borderColor);
            final plus = Paint()
              ..color = el.strokeColor
              ..strokeWidth = r * .1
              ..strokeCap = StrokeCap.round;
            canvas.drawLine(
              c.center - Offset(r * .34, 0),
              c.center + Offset(r * .34, 0),
              plus,
            );
            canvas.drawLine(
              c.center - Offset(0, r * .34),
              c.center + Offset(0, r * .34),
              plus,
            );
          }
        }
      default:
    }
  }

  @override
  bool shouldRepaint(covariant _PanelPainter old) => old.el != el || old.k != k;
}
