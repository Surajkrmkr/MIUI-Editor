import 'dart:math';
import 'package:flutter/material.dart';
import 'package:theme_core/theme_core.dart';
import 'package:theme_core/lockscreen_layout.dart' as core;
import '../../adapters.dart';
import '../lock_element.dart';
import '../lock_element_spec_bridge.dart';
import '../lockscreen_clock.dart';

/// Geometry of a styled calendar in theme pixels (before `scale`); the math
/// lives in theme_core, this adds Flutter types for the painters.
class CalendarLayout {
  CalendarLayout.of(LockElement el)
    : this._(el, core.CalendarLayout.of(el.toSpec()));

  CalendarLayout._(this.el, this._c) : inner = _c.inner.toRect();

  final LockElement el;
  final core.CalendarLayout _c;
  final Rect inner;

  double get rowH => _c.rowH;
  double get colW => _c.colW;
  int? get monthRow => _c.monthRow;
  int? get weekdayRow => _c.weekdayRow;
  int get firstDateRow => _c.firstDateRow;
  bool get showsDates => _c.showsDates;
  List<String> get labels => _c.labels;
  double get panelRadius => _c.panelRadius;

  Rect cell(int row, int col) => _c.cell(row, col).toRect();

  /// Today's highlight for the date cell at [row]/[col].
  RRect highlight(int row, int col) => _c.highlight(row, col).toRRect();

  Color labelColor(int col) => _c.labelColor(col).toColor();

  /// Text colour of today's date on top of the highlight.
  Color get todayText => _c.todayText.toColor();
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
    const k = 1 / lockscreenScreenRatio;
    final el = element;
    final l = CalendarLayout.of(el);
    final now = lockscreenNow();
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
