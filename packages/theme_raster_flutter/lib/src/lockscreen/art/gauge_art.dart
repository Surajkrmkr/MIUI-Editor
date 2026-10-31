import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:theme_core/theme_core.dart';
import 'package:theme_core/lockscreen_layout.dart'
    show GaugeLayout, GaugeSample, GaugeSlot;
import '../../adapters.dart';
import '../lock_element.dart';
import '../lock_element_spec_bridge.dart';
import '../lockscreen_clock.dart';

const _rad = pi / 180;

/// Static gauge art (tracks, discs, roses) exported as one PNG.
class GaugeArt {
  const GaugeArt._();

  static Widget panel(LockElement el, double k) => SizedBox(
    width: el.width * k,
    height: el.height * k,
    child: CustomPaint(painter: _PanelPainter(el, k)),
  );

  static double exportInset(LockElement el) =>
      GaugeLayout.of(el.toSpec()).exportInset;

  static Widget exportPanel(LockElement el) {
    const k = 1 / 3;
    return Padding(
      padding: EdgeInsets.all(exportInset(el) * k),
      child: panel(el, k),
    );
  }
}

/// Editor preview: panel, live progress and values with sample readings.
class GaugePreview extends StatefulWidget {
  const GaugePreview({super.key, required this.element});
  final LockElement element;

  @override
  State<GaugePreview> createState() => _GaugePreviewState();
}

class _GaugePreviewState extends State<GaugePreview> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Fixed preview clocks (tests, thumbnails) stay still.
    if (identical(lockscreenNow, DateTime.now)) {
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (GaugeSource.parse(
          widget.element.gaugeItems,
        ).any((s) => s == GaugeSource.seconds || s == GaugeSource.todayLeft)) {
          setState(() {});
        }
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const k = 1 / lockscreenScreenRatio;
    final el = widget.element;
    final l = GaugeLayout.of(el.toSpec());
    final sample = GaugeSample(now: lockscreenNow());
    Widget text(Offset c, String s, double size, Color color) => Positioned(
      left: c.dx * k - 150,
      top: c.dy * k - 60,
      width: 300,
      height: 120,
      child: Center(
        child: Text(
          s,
          maxLines: 1,
          style: TextStyle(
            color: color,
            fontSize: size * k,
            fontWeight: FontWeight.w700,
            height: 1,
          ),
        ),
      ),
    );
    return SizedBox(
      width: el.width * k,
      height: el.height * k,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          GaugeArt.panel(el, k),
          Positioned.fill(
            child: CustomPaint(painter: _LivePainter(el, k, sample)),
          ),
          for (final s in l.slots) ...[
            text(
              l.valueAt(s).toOffset(),
              GaugeLayout.value(s.source, sample),
              s.source == GaugeSource.alarm ? l.valueSize * .62 : l.valueSize,
              el.color,
            ),
            text(
              l.captionAt(s).toOffset(),
              GaugeLayout.caption(s.source, sample),
              l.captionSize,
              l.captionColor.toColor(),
            ),
          ],
        ],
      ),
    );
  }
}

Color _a(Color c, double a) => c.withValues(alpha: (c.a * a).clamp(0.0, 1.0));

Paint _stroke(Color c, double w) => Paint()
  ..color = c
  ..style = PaintingStyle.stroke
  ..strokeWidth = w
  ..strokeCap = StrokeCap.round;

/// What the device draws live: progress, segments, ticks and needles.
class _LivePainter extends CustomPainter {
  _LivePainter(this.el, this.k, this.sample);
  final LockElement el;
  final double k;
  final GaugeSample sample;

  @override
  void paint(Canvas canvas, Size size) {
    final l = GaugeLayout.of(el.toSpec());
    final (start, sweep) = l.arc;
    final r = l.ringRadius * k;
    final weight = l.weight * k;
    final ink = el.colorSecondary;
    for (final s in l.slots) {
      final c = s.center.toOffset() * k;
      final ring = Rect.fromCircle(center: c, radius: r);
      final f = GaugeLayout.fraction(s.source, sample);
      if (s.source == GaugeSource.compass) {
        canvas.drawArc(
          ring,
          (start - 7 + sample.azimuth) * _rad,
          14 * _rad,
          false,
          _stroke(ink, weight),
        );
        continue;
      }
      switch (l.style) {
        case GaugeStyle.segmentRing:
          for (var i = 0; i < (f * 10 + .999).floor(); i++) {
            canvas.drawArc(
              ring,
              (start + 3 + i * 36) * _rad,
              30 * _rad,
              false,
              _stroke(ink, weight),
            );
          }
        case GaugeStyle.tickDial:
          for (var i = 0; i < (f * 30 + .999).floor(); i++) {
            final a = (-90 + i * 12) * _rad;
            final d = Offset(cos(a), sin(a));
            canvas.drawLine(
              c + d * (r - weight / 2),
              c + d * (r + weight / 2),
              _stroke(ink, weight * .3),
            );
          }
        case GaugeStyle.pieFill:
          canvas.drawArc(
            ring,
            start * _rad,
            sweep * f * _rad,
            true,
            Paint()..color = ink,
          );
        default:
          canvas.drawArc(
            ring,
            start * _rad,
            sweep * f * _rad,
            false,
            _stroke(ink, weight),
          );
      }
      if (l.style == GaugeStyle.neonOrbit) {
        final a = (start + sweep * f) * _rad;
        canvas.drawCircle(
          c + Offset(cos(a), sin(a)) * r,
          weight * 1.3,
          Paint()..color = Colors.white,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_LivePainter old) =>
      old.el != el || old.sample.now != sample.now;
}

/// Static per-style art; nothing here changes on the device.
class _PanelPainter extends CustomPainter {
  _PanelPainter(this.el, this.k);
  final LockElement el;
  final double k;

  @override
  void paint(Canvas canvas, Size size) {
    final l = GaugeLayout.of(el.toSpec());
    final track = el.unlockAccent;
    final line = el.borderColor;
    final glow = el.colorSecondary;
    final (start, sweep) = l.arc;
    final r = l.ringRadius * k;
    final weight = l.weight * k;
    for (final GaugeSlot s in l.slots) {
      final c = s.center.toOffset() * k;
      final ring = Rect.fromCircle(center: c, radius: r);
      final outer = s.radius * k;
      switch (l.style) {
        case GaugeStyle.openArc:
          canvas.drawArc(
            ring,
            start * _rad,
            sweep * _rad,
            false,
            _stroke(track, weight),
          );

        case GaugeStyle.fullRing:
          canvas.drawCircle(c, r, _stroke(track, weight));

        case GaugeStyle.glassDisc:
          canvas.drawCircle(
            c.translate(0, outer * .06),
            outer,
            Paint()
              ..color = Colors.black.withValues(alpha: .25)
              ..maskFilter = MaskFilter.blur(BlurStyle.normal, outer * .1),
          );
          canvas.drawCircle(
            c,
            outer,
            Paint()
              ..shader = ui.Gradient.linear(
                c.translate(-outer, -outer),
                c.translate(outer, outer),
                [_a(track, 1), _a(track, .55)],
              ),
          );
          canvas.drawCircle(
            c,
            outer - .6 * k,
            _stroke(_a(Colors.white, .35), 1.2 * k),
          );
          canvas.drawCircle(c, r, _stroke(_a(line, .25), weight));

        case GaugeStyle.tickDial:
          for (var i = 0; i < 30; i++) {
            final a = (-90 + i * 12) * _rad;
            final d = Offset(cos(a), sin(a));
            canvas.drawLine(
              c + d * (r - weight / 2),
              c + d * (r + weight / 2),
              _stroke(track, weight * .3),
            );
          }
          canvas.drawCircle(c, r - weight * .9, _stroke(_a(line, .3), 1 * k));

        case GaugeStyle.segmentRing:
          for (var i = 0; i < 10; i++) {
            canvas.drawArc(
              ring,
              (start + 3 + i * 36) * _rad,
              30 * _rad,
              false,
              _stroke(track, weight),
            );
          }

        case GaugeStyle.neonOrbit:
          canvas.drawCircle(
            c,
            r,
            _stroke(_a(glow, .35), weight * 4)
              ..maskFilter = MaskFilter.blur(BlurStyle.normal, weight * 2),
          );
          canvas.drawCircle(c, r, _stroke(track, weight));
          canvas.drawCircle(
            c,
            r - weight * 3,
            Paint()..color = _a(Colors.black, .35),
          );

        case GaugeStyle.pieFill:
          canvas.drawCircle(c, outer, Paint()..color = track);
          canvas.drawCircle(c, outer - .8 * k, _stroke(line, 1.6 * k));

        case GaugeStyle.halfDial:
          canvas.drawArc(
            ring,
            start * _rad,
            sweep * _rad,
            false,
            _stroke(track, weight),
          );
          for (final a in [180.0, 0.0]) {
            final d = Offset(cos(a * _rad), sin(a * _rad));
            canvas.drawLine(
              c + d * (r + weight * .8),
              c + d * (r + weight * 1.4),
              _stroke(_a(line, .6), 1.4 * k),
            );
          }

        case GaugeStyle.compassRose:
          canvas.drawCircle(c, r, _stroke(track, weight));
          for (var i = 0; i < 8; i++) {
            final a = (-90 + i * 45) * _rad;
            final d = Offset(cos(a), sin(a));
            final major = i.isEven;
            if (major) {
              final tip = c + d * (r - weight * 1.2);
              final n = Offset(-d.dy, d.dx) * weight * .9;
              canvas.drawPath(
                Path()
                  ..moveTo(tip.dx, tip.dy)
                  ..lineTo(
                    (tip - d * weight * 2 + n).dx,
                    (tip - d * weight * 2 + n).dy,
                  )
                  ..lineTo(
                    (tip - d * weight * 2 - n).dx,
                    (tip - d * weight * 2 - n).dy,
                  )
                  ..close(),
                Paint()..color = i == 0 ? glow : _a(line, .7),
              );
            } else {
              canvas.drawCircle(
                c + d * (r - weight * 1.6),
                weight * .35,
                Paint()..color = _a(line, .5),
              );
            }
          }

        case GaugeStyle.bezelBold:
          canvas.drawCircle(c, outer, Paint()..color = line);
          canvas.drawCircle(c, r - weight / 2, Paint()..color = track);
          canvas.drawCircle(c, r, _stroke(_a(Colors.black, .45), weight * .7));
          canvas.drawArc(
            Rect.fromCircle(center: c, radius: outer - .8 * k),
            200 * _rad,
            140 * _rad,
            false,
            _stroke(_a(Colors.white, .45), 1.4 * k),
          );
      }
    }
  }

  @override
  bool shouldRepaint(_PanelPainter old) => old.el != el || old.k != k;
}
