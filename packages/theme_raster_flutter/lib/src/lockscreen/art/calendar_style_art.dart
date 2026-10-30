import 'dart:math';
import 'package:flutter/material.dart';
import 'package:theme_core/theme_core.dart';
import 'package:theme_core/lockscreen_layout.dart' as core;
import '../../adapters.dart';
import '../lock_element.dart';
import '../lock_element_spec_bridge.dart';
import '../lockscreen_clock.dart';
import 'calendar_extra_art.dart';

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
                border: el.calendarStyle == CalendarStyle.neoBrutalism
                    ? Border.all(
                        color: el.borderColor,
                        width: (el.borderWidth > 0 ? el.borderWidth : 2.5) * k,
                      )
                    : el.calendarStyle == CalendarStyle.neonCyber ||
                          el.calendarStyle == CalendarStyle.cyberMatrix
                    ? Border.all(color: el.strokeColor, width: 1.5 * k)
                    : el.calendarStyle == CalendarStyle.outlineRings ||
                          el.calendarStyle == CalendarStyle.polarArc
                    ? Border.all(color: el.borderColor, width: 1.5 * k)
                    : el.calendarStyle == CalendarStyle.bracketModern
                    ? Border.all(color: el.strokeColor, width: 1.5 * k)
                    : (el.borderWidth > 0
                          ? Border.all(
                              color: el.borderColor,
                              width: el.borderWidth * k,
                            )
                          : null),
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
    Color soft(Color c, double a) =>
        c.withValues(alpha: (c.a * a).clamp(0.0, 1.0));

    if (el.calendarStyle != CalendarStyle.neoBrutalism &&
        el.calendarStyle != CalendarStyle.floatingBadges &&
        el.calendarStyle != CalendarStyle.ticketStub &&
        el.calendarStyle != CalendarStyle.postageStamp) {
      canvas.drawRRect(panel, Paint()..color = el.unlockAccent);
    }

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
      case CalendarStyle.pillColumn:
        if (el.calendarWeekRows == 1 && l.weekdayRow != null) {
          final borderPaint = Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = (el.borderWidth > 0 ? el.borderWidth : 1.5) * k
            ..color = el.borderColor;
          canvas.drawRRect(panel, borderPaint);
        }
      case CalendarStyle.glassCard:
        canvas.save();
        canvas.clipRRect(panel);
        final sheenRect = Rect.fromLTWH(0, 0, size.width, size.height * 0.35);
        canvas.drawRect(
          sheenRect,
          Paint()
            ..shader = LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [soft(el.strokeColor, 0.4), soft(el.strokeColor, 0.0)],
            ).createShader(sheenRect),
        );
        canvas.drawLine(
          Offset(l.panelRadius * k, 1.2 * k),
          Offset(size.width - l.panelRadius * k, 1.2 * k),
          Paint()
            ..color = soft(el.strokeColor, 0.5)
            ..strokeWidth = 1.0 * k,
        );
        canvas.restore();
        canvas.drawRRect(
          panel,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = (el.borderWidth > 0 ? el.borderWidth : 1.2) * k
            ..color = el.borderColor,
        );
      case CalendarStyle.neonCyber:
        canvas.drawRRect(
          panel,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = (el.borderWidth > 0 ? el.borderWidth : 1.5) * k
            ..color = el.borderColor,
        );
        final bracketPaint = Paint()
          ..color = el.strokeColor
          ..strokeWidth = 2.0 * k
          ..strokeCap = StrokeCap.square;
        final bLen = min(size.width, size.height) * 0.08;
        canvas.drawLine(Offset(0, bLen), Offset.zero, bracketPaint);
        canvas.drawLine(Offset.zero, Offset(bLen, 0), bracketPaint);
        canvas.drawLine(
          Offset(size.width - bLen, 0),
          Offset(size.width, 0),
          bracketPaint,
        );
        canvas.drawLine(
          Offset(size.width, 0),
          Offset(size.width, bLen),
          bracketPaint,
        );
        canvas.drawLine(
          Offset(0, size.height - bLen),
          Offset(0, size.height),
          bracketPaint,
        );
        canvas.drawLine(
          Offset(0, size.height),
          Offset(bLen, size.height),
          bracketPaint,
        );
        canvas.drawLine(
          Offset(size.width - bLen, size.height),
          Offset(size.width, size.height),
          bracketPaint,
        );
        canvas.drawLine(
          Offset(size.width, size.height),
          Offset(size.width, size.height - bLen),
          bracketPaint,
        );
        if (l.weekdayRow case final row?) {
          final y = sc(l.cell(row, 0)).bottom + 3.0 * k;
          final linePaint = Paint()
            ..color = soft(el.strokeColor, 0.75)
            ..strokeWidth = 1.2 * k;
          canvas.drawLine(
            Offset(size.width * 0.06, y),
            Offset(size.width * 0.94, y),
            linePaint,
          );
          canvas.drawCircle(
            Offset(size.width * 0.06, y),
            2.0 * k,
            Paint()..color = el.strokeColor,
          );
          canvas.drawCircle(
            Offset(size.width * 0.94, y),
            2.0 * k,
            Paint()..color = el.strokeColor,
          );
        }
      case CalendarStyle.neoBrutalism:
        final offset = 4.0 * k;
        final shadowRRect = RRect.fromRectAndRadius(
          Rect.fromLTWH(
            offset,
            offset,
            size.width - offset,
            size.height - offset,
          ),
          Radius.circular(l.panelRadius * k),
        );
        canvas.drawRRect(shadowRRect, Paint()..color = el.borderColor);
        final cardRRect = RRect.fromRectAndRadius(
          Rect.fromLTWH(0, 0, size.width - offset, size.height - offset),
          Radius.circular(l.panelRadius * k),
        );
        canvas.drawRRect(cardRRect, Paint()..color = el.unlockAccent);
        canvas.drawRRect(
          cardRRect,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = (el.borderWidth > 0 ? el.borderWidth : 2.5) * k
            ..color = el.borderColor,
        );
        if (l.weekdayRow case final row?) {
          final r = sc(l.cell(row, 0));
          final y = r.bottom + 2.0 * k;
          canvas.drawLine(
            Offset(0, y),
            Offset(size.width - offset, y),
            Paint()
              ..color = el.borderColor
              ..strokeWidth =
                  (el.borderWidth > 0 ? el.borderWidth : 2.5) * 0.7 * k,
          );
        }
      case CalendarStyle.bentoGrid:
        canvas.drawRRect(
          panel,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = (el.borderWidth > 0 ? el.borderWidth : 1.2) * k
            ..color = el.borderColor,
        );
        if (l.weekdayRow case final row?) {
          final first = sc(l.cell(row, 0)), last = sc(l.cell(row, 6));
          final tile = Rect.fromLTRB(
            first.left - 2 * k,
            first.top - 2 * k,
            last.right + 2 * k,
            first.bottom + 2 * k,
          );
          canvas.drawRRect(
            RRect.fromRectAndRadius(tile, Radius.circular(8 * k)),
            Paint()..color = soft(el.strokeColor, 0.18),
          );
        }
        final tilePaint = Paint()..color = soft(el.strokeColor, 0.08);
        for (var r = 0; r < el.calendarWeekRows; r++) {
          for (var c = 0; c < 7; c++) {
            final cell = sc(l.cell(l.firstDateRow + r, c));
            final inset = 3.0 * k;
            final tileR = Rect.fromLTRB(
              cell.left + inset,
              cell.top + inset,
              cell.right - inset,
              cell.bottom - inset,
            );
            canvas.drawRRect(
              RRect.fromRectAndRadius(tileR, Radius.circular(6 * k)),
              tilePaint,
            );
          }
        }
      case CalendarStyle.gradientAura:
        canvas.save();
        canvas.clipRRect(panel);
        final aura1 = Rect.fromCircle(
          center: Offset(size.width * 0.22, size.height * 0.2),
          radius: size.width * 0.55,
        );
        canvas.drawOval(
          aura1,
          Paint()
            ..shader = RadialGradient(
              colors: [soft(el.borderColor, 0.6), soft(el.borderColor, 0.0)],
            ).createShader(aura1),
        );
        final aura2 = Rect.fromCircle(
          center: Offset(size.width * 0.82, size.height * 0.8),
          radius: size.width * 0.52,
        );
        canvas.drawOval(
          aura2,
          Paint()
            ..shader = RadialGradient(
              colors: [soft(el.strokeColor, 0.55), soft(el.strokeColor, 0.0)],
            ).createShader(aura2),
        );
        canvas.restore();
        canvas.drawRRect(
          panel,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = (el.borderWidth > 0 ? el.borderWidth : 1.2) * k
            ..color = soft(el.strokeColor, 0.6),
        );
      case CalendarStyle.minimalDots:
        canvas.drawRRect(
          panel,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = (el.borderWidth > 0 ? el.borderWidth : 1.0) * k
            ..color = el.borderColor,
        );
        final dotPaint = Paint()..color = soft(el.strokeColor, 0.6);
        final dotR = 1.5 * k;
        for (var r = 0; r <= el.calendarDisplayRows; r++) {
          for (var c = 0; c <= 7; c++) {
            final x = (l.inner.left + c * l.colW) * k;
            final y = (l.inner.top + r * l.rowH) * k;
            canvas.drawCircle(Offset(x, y), dotR, dotPaint);
          }
        }
      case CalendarStyle.splitFlap:
        canvas.drawRRect(
          panel,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = (el.borderWidth > 0 ? el.borderWidth : 1.5) * k
            ..color = el.borderColor,
        );
        final flapLine = Paint()
          ..color = soft(el.strokeColor, 0.5)
          ..strokeWidth = 1.0 * k;
        for (var r = 0; r < el.calendarDisplayRows; r++) {
          final cy = (l.inner.top + (r + 0.5) * l.rowH) * k;
          canvas.drawLine(
            Offset(l.inner.left * k, cy),
            Offset(l.inner.right * k, cy),
            flapLine,
          );
        }
      case CalendarStyle.capsuleRow:
        if (l.weekdayRow case final row?) {
          final first = sc(l.cell(row, 0)), last = sc(l.cell(row, 6));
          final cap = Rect.fromLTRB(
            first.left - 4 * k,
            first.top - 2 * k,
            last.right + 4 * k,
            first.bottom + 2 * k,
          );
          canvas.drawRRect(
            RRect.fromRectAndRadius(cap, Radius.circular(cap.height / 2)),
            Paint()..color = el.strokeColor,
          );
        }
        canvas.drawRRect(
          panel,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = (el.borderWidth > 0 ? el.borderWidth : 1.5) * k
            ..color = el.borderColor,
        );
      case CalendarStyle.floatingBadges:
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(0, 3 * k, size.width, size.height),
            Radius.circular(l.panelRadius * k),
          ),
          Paint()..color = soft(el.borderColor, 0.25),
        );
        canvas.drawRRect(panel, Paint()..color = el.unlockAccent);
        if (l.weekdayRow case final row?) {
          final bPaint = Paint()..color = soft(el.strokeColor, 0.16);
          for (var c = 0; c < 7; c++) {
            final cell = sc(l.cell(row, c));
            final badge = Rect.fromCenter(
              center: cell.center,
              width: cell.width * 0.84,
              height: cell.height * 0.78,
            );
            canvas.drawRRect(
              RRect.fromRectAndRadius(badge, Radius.circular(5 * k)),
              bPaint,
            );
          }
        }
        canvas.drawRRect(
          panel,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = (el.borderWidth > 0 ? el.borderWidth : 1.2) * k
            ..color = el.borderColor,
        );
      case CalendarStyle.abstractGeometric:
        canvas.save();
        canvas.clipRRect(panel);
        canvas.drawArc(
          Rect.fromCircle(
            center: Offset(size.width, 0),
            radius: size.width * 0.38,
          ),
          pi / 2,
          pi / 2,
          true,
          Paint()..color = soft(el.strokeColor, 0.22),
        );
        canvas.drawRect(
          Rect.fromLTWH(0, size.height - 18 * k, 38 * k, 18 * k),
          Paint()..color = soft(el.borderColor, 0.25),
        );
        canvas.drawCircle(
          Offset(size.width * 0.88, size.height * 0.72),
          14 * k,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.0 * k
            ..color = soft(el.strokeColor, 0.35),
        );
        canvas.restore();
        canvas.drawRRect(
          panel,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = (el.borderWidth > 0 ? el.borderWidth : 1.5) * k
            ..color = el.borderColor,
        );
      case CalendarStyle.outlineRings:
        canvas.drawRRect(
          panel,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = (el.borderWidth > 0 ? el.borderWidth : 1.5) * k
            ..color = el.borderColor,
        );
        final insetPanel = panel.deflate(3.5 * k);
        canvas.drawRRect(
          insetPanel,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.0 * k
            ..color = soft(el.strokeColor, 0.5),
        );
        final ringPaint = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.8 * k
          ..color = soft(el.strokeColor, 0.2);
        for (var r = 0; r < el.calendarWeekRows; r++) {
          for (var c = 0; c < 7; c++) {
            final center = sc(l.cell(l.firstDateRow + r, c)).center;
            final rad = min(l.colW, l.rowH) * 0.38 * k;
            canvas.drawCircle(center, rad, ringPaint);
          }
        }
      case CalendarStyle.monolith:
        canvas.save();
        canvas.clipRRect(panel);
        final pillarW = 6.0 * k;
        canvas.drawRect(
          Rect.fromLTWH(0, 0, pillarW, size.height),
          Paint()..color = el.strokeColor,
        );
        canvas.restore();
        canvas.drawRRect(
          panel,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = (el.borderWidth > 0 ? el.borderWidth : 1.5) * k
            ..color = el.borderColor,
        );
      case CalendarStyle.bracketModern:
        final bPaint = Paint()
          ..color = el.strokeColor
          ..strokeWidth = (el.borderWidth > 0 ? el.borderWidth : 2.0) * k
          ..strokeCap = StrokeCap.square;
        final arm = min(size.width, size.height) * 0.12;
        canvas.drawLine(Offset(0, arm), Offset.zero, bPaint);
        canvas.drawLine(Offset.zero, Offset(arm, 0), bPaint);
        canvas.drawLine(
          Offset(size.width - arm, 0),
          Offset(size.width, 0),
          bPaint,
        );
        canvas.drawLine(Offset(size.width, 0), Offset(size.width, arm), bPaint);
        canvas.drawLine(
          Offset(0, size.height - arm),
          Offset(0, size.height),
          bPaint,
        );
        canvas.drawLine(
          Offset(0, size.height),
          Offset(arm, size.height),
          bPaint,
        );
        canvas.drawLine(
          Offset(size.width - arm, size.height),
          Offset(size.width, size.height),
          bPaint,
        );
        canvas.drawLine(
          Offset(size.width, size.height),
          Offset(size.width, size.height - arm),
          bPaint,
        );
        if (l.weekdayRow case final row?) {
          final y = sc(l.cell(row, 0)).bottom + 2.0 * k;
          canvas.drawLine(
            Offset(size.width * 0.08, y),
            Offset(size.width * 0.92, y),
            Paint()
              ..color = el.borderColor
              ..strokeWidth = 1.0 * k,
          );
        }
      case CalendarStyle.softNeumorphism:
        final highlightR = RRect.fromRectAndRadius(
          Rect.fromLTWH(-1.5 * k, -1.5 * k, size.width, size.height),
          Radius.circular(l.panelRadius * k),
        );
        canvas.drawRRect(
          highlightR,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = (el.borderWidth > 0 ? el.borderWidth : 2.0) * k
            ..color = soft(el.strokeColor, 0.6),
        );
        final shadowR = RRect.fromRectAndRadius(
          Rect.fromLTWH(1.5 * k, 1.5 * k, size.width, size.height),
          Radius.circular(l.panelRadius * k),
        );
        canvas.drawRRect(
          shadowR,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = (el.borderWidth > 0 ? el.borderWidth : 2.0) * k
            ..color = soft(el.borderColor, 0.5),
        );
      case CalendarStyle.lunarPhase:
        canvas.save();
        canvas.clipRRect(panel);
        final moonCenter = Offset(size.width * 0.88, size.height * 0.18);
        final moonR = 13.0 * k;
        final moonPaint = Paint()..color = el.strokeColor;
        final moonPath = Path()
          ..addOval(Rect.fromCircle(center: moonCenter, radius: moonR));
        final cutPath = Path()
          ..addOval(
            Rect.fromCircle(
              center: moonCenter - Offset(4.0 * k, 2.0 * k),
              radius: moonR * 0.88,
            ),
          );
        canvas.drawPath(
          Path.combine(PathOperation.difference, moonPath, cutPath),
          moonPaint,
        );
        final starPaint = Paint()..color = el.borderColor;
        void star(double x, double y, double r) =>
            canvas.drawCircle(Offset(x, y), r, starPaint);
        star(size.width * 0.12, size.height * 0.15, 1.2 * k);
        star(size.width * 0.72, size.height * 0.12, 1.0 * k);
        star(size.width * 0.18, size.height * 0.82, 1.3 * k);
        star(size.width * 0.82, size.height * 0.85, 1.0 * k);
        canvas.restore();
        canvas.drawRRect(
          panel,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = (el.borderWidth > 0 ? el.borderWidth : 1.2) * k
            ..color = el.borderColor,
        );
      case CalendarStyle.polarArc:
        canvas.save();
        canvas.clipRRect(panel);
        final arcCenter = Offset(size.width * 0.5, size.height * 0.15);
        final gaugePaint = Paint()
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round;
        for (var i = 0; i < 4; i++) {
          final rad = size.width * (0.35 + i * 0.16);
          gaugePaint
            ..strokeWidth = (1.0 + i * 0.4) * k
            ..color = soft(
              i.isEven ? el.borderColor : el.strokeColor,
              0.25 + i * 0.12,
            );
          canvas.drawArc(
            Rect.fromCircle(center: arcCenter, radius: rad),
            pi * 0.15,
            pi * 0.7,
            false,
            gaugePaint,
          );
        }
        final tickPaint = Paint()
          ..color = soft(el.strokeColor, 0.55)
          ..strokeWidth = 1.2 * k;
        for (var i = 0; i < 18; i++) {
          final angle = pi * 0.2 + (i / 17) * pi * 0.6;
          final p1 =
              arcCenter + Offset(cos(angle), sin(angle)) * (size.width * 0.5);
          final p2 =
              arcCenter +
              Offset(cos(angle), sin(angle)) * (size.width * 0.5 + 4.0 * k);
          canvas.drawLine(p1, p2, tickPaint);
        }
        canvas.restore();
        canvas.drawRRect(
          panel,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = (el.borderWidth > 0 ? el.borderWidth : 1.5) * k
            ..color = el.borderColor,
        );
      case CalendarStyle.cyberMatrix:
        canvas.save();
        canvas.clipRRect(panel);
        final barPaint = Paint()..strokeWidth = 1.2 * k;
        for (var i = 0; i < 12; i++) {
          final x = size.width - (8.0 + i * 3.5) * k;
          barPaint.color = soft(el.strokeColor, i % 3 == 0 ? 0.7 : 0.25);
          canvas.drawLine(Offset(x, 6 * k), Offset(x, 18 * k), barPaint);
        }
        if (l.weekdayRow case final row?) {
          final y = sc(l.cell(row, 0)).bottom + 3.0 * k;
          final techLine = Paint()
            ..color = soft(el.strokeColor, 0.8)
            ..strokeWidth = 1.2 * k;
          canvas.drawLine(
            Offset(size.width * 0.05, y),
            Offset(size.width * 0.45, y),
            techLine,
          );
          final pulse = Path()
            ..moveTo(size.width * 0.45, y)
            ..lineTo(size.width * 0.48, y - 3.5 * k)
            ..lineTo(size.width * 0.52, y + 3.5 * k)
            ..lineTo(size.width * 0.55, y)
            ..lineTo(size.width * 0.95, y);
          canvas.drawPath(
            pulse,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.2 * k
              ..color = el.borderColor,
          );
        }
        canvas.restore();
        canvas.drawRRect(
          panel,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = (el.borderWidth > 0 ? el.borderWidth : 1.5) * k
            ..color = el.borderColor,
        );
        final tagPaint = Paint()
          ..color = el.strokeColor
          ..strokeWidth = 2.0 * k;
        canvas.drawLine(Offset(0, 10 * k), Offset(10 * k, 0), tagPaint);
        canvas.drawLine(
          Offset(size.width - 10 * k, size.height),
          Offset(size.width, size.height - 10 * k),
          tagPaint,
        );
      case CalendarStyle.ticketStub:
        final notchY = l.weekdayRow != null
            ? sc(l.cell(l.weekdayRow!, 0)).bottom + 3.0 * k
            : size.height * 0.35;
        final notchR = 7.0 * k;
        final ticketPath = Path()
          ..moveTo(0, l.panelRadius * k)
          ..quadraticBezierTo(0, 0, l.panelRadius * k, 0)
          ..lineTo(size.width - l.panelRadius * k, 0)
          ..quadraticBezierTo(size.width, 0, size.width, l.panelRadius * k)
          ..lineTo(size.width, notchY - notchR)
          ..arcToPoint(
            Offset(size.width, notchY + notchR),
            radius: Radius.circular(notchR),
            clockwise: false,
          )
          ..lineTo(size.width, size.height - l.panelRadius * k)
          ..quadraticBezierTo(
            size.width,
            size.height,
            size.width - l.panelRadius * k,
            size.height,
          )
          ..lineTo(l.panelRadius * k, size.height)
          ..quadraticBezierTo(
            0,
            size.height,
            0,
            size.height - l.panelRadius * k,
          )
          ..lineTo(0, notchY + notchR)
          ..arcToPoint(
            Offset(0, notchY - notchR),
            radius: Radius.circular(notchR),
            clockwise: false,
          )
          ..close();
        canvas.drawPath(ticketPath, Paint()..color = el.unlockAccent);
        canvas.drawPath(
          ticketPath,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = (el.borderWidth > 0 ? el.borderWidth : 1.5) * k
            ..color = el.borderColor,
        );
        final stitchPaint = Paint()
          ..color = soft(el.strokeColor, 0.7)
          ..strokeWidth = 1.2 * k;
        final dashW = 4.0 * k;
        final spaceW = 3.0 * k;
        var curX = notchR + 4.0 * k;
        while (curX < size.width - notchR - 4.0 * k) {
          final nextX = min(curX + dashW, size.width - notchR - 4.0 * k);
          canvas.drawLine(
            Offset(curX, notchY),
            Offset(nextX, notchY),
            stitchPaint,
          );
          curX += dashW + spaceW;
        }
      default:
        if (extraCalendarStyles.contains(el.calendarStyle)) {
          paintExtraCalendarPanel(canvas, size, el, l, k, panel);
        }
    }
  }

  @override
  bool shouldRepaint(covariant _PanelPainter old) => old.el != el || old.k != k;
}
