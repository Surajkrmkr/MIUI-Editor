import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:theme_core/theme_core.dart';
import 'package:theme_core/lockscreen_layout.dart' show TickerLayout;
import '../../adapters.dart';
import '../lock_element.dart';
import '../lock_element_spec_bridge.dart';
import '../lockscreen_clock.dart';

/// Static countdown ticker background (guide line, ticks, lens…) as one PNG.
class TickerArt {
  const TickerArt._();

  static Widget panel(LockElement el, double k) => SizedBox(
    width: el.width * k,
    height: el.height * k,
    child: CustomPaint(painter: _TickerPainter(el, k)),
  );

  static double exportInset(LockElement el) =>
      TickerLayout.of(el.toSpec()).exportInset;

  static Widget exportPanel(LockElement el) {
    const k = 1 / 3;
    return Padding(
      padding: EdgeInsets.all(exportInset(el) * k),
      child: panel(el, k),
    );
  }
}

/// Editor preview: panel plus the live numbers; seconds tick on screen.
class TickerPreview extends StatefulWidget {
  const TickerPreview({super.key, required this.element});
  final LockElement element;

  @override
  State<TickerPreview> createState() => _TickerPreviewState();
}

class _TickerPreviewState extends State<TickerPreview> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Fixed preview clocks (tests, thumbnails) stay still.
    if (identical(lockscreenNow, DateTime.now)) {
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (widget.element.tickerSource == TickerSource.seconds) {
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
    final l = TickerLayout.of(el.toSpec());
    final now = lockscreenNow();
    final children = <Widget>[TickerArt.panel(el, k)];
    if (el.tickerStyle == TickerStyle.progressTrack) {
      final t = l.track;
      children.add(
        Positioned(
          left: t.left * k,
          top: t.top * k,
          width: t.width * k * l.progress(now).clamp(0.0, 1.0),
          height: t.height * k,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: el.colorSecondary,
              borderRadius: BorderRadius.circular(t.height * k / 2),
            ),
          ),
        ),
      );
    }
    for (final s in l.slots) {
      final v = l.valueAt(now, s.offset);
      if (v == null) continue;
      children.add(
        Positioned(
          left: s.center.dx * k - 200,
          top: s.center.dy * k - 100,
          width: 400,
          height: 200,
          child: Center(
            child: Text(
              l.format(v),
              maxLines: 1,
              style: TextStyle(
                color: s.color.toColor(),
                fontSize: s.size * k,
                fontWeight: s.isCurrent ? FontWeight.w700 : el.fontWeight,
                height: 1,
              ),
            ),
          ),
        ),
      );
    }
    return SizedBox(
      width: el.width * k,
      height: el.height * k,
      child: Stack(clipBehavior: Clip.none, children: children),
    );
  }
}

class _TickerPainter extends CustomPainter {
  _TickerPainter(this.el, this.k);
  final LockElement el;
  final double k;

  Color get glow => el.colorSecondary;
  Color get line => el.borderColor;
  Color get panel => el.unlockAccent;
  double outline(double fallback) =>
      (el.borderWidth > 0 ? el.borderWidth : fallback) * k;

  static Color _a(Color c, double a) =>
      c.withValues(alpha: (c.a * a).clamp(0.0, 1.0));
  Paint _fill(Color c) => Paint()..color = c;
  Paint _stroke(Color c, double width) => Paint()
    ..color = c
    ..style = PaintingStyle.stroke
    ..strokeWidth = width
    ..strokeCap = StrokeCap.round;
  Paint _blur(Paint p, double sigma) =>
      p..maskFilter = MaskFilter.blur(BlurStyle.normal, sigma);

  /// A horizontal line that fades out towards both ends.
  Paint _fadedLine(Color c, double y, double w, double width) =>
      _stroke(c, width)
        ..shader = ui.Gradient.linear(
          Offset(0, y),
          Offset(w, y),
          [_a(c, 0), c, _a(c, 0)],
          const [0, .5, 1],
        );

  @override
  void paint(Canvas canvas, Size size) {
    final l = TickerLayout.of(el.toSpec());
    final w = size.width, h = size.height;
    final cx = w / 2, colW = l.colW * k, gy = l.guideY * k;
    Offset at(int o) {
      final c = l.slots[o + l.half].center;
      return Offset(c.dx * k, c.dy * k);
    }

    switch (el.tickerStyle) {
      case TickerStyle.glowLine:
        canvas.drawLine(
          Offset(0, gy),
          Offset(w, gy),
          _fadedLine(line, gy, w, outline(1.4)),
        );
        final flare = Rect.fromCenter(
          center: Offset(cx, gy),
          width: colW * 1.8,
          height: h * .14,
        );
        canvas.drawOval(flare, _blur(_fill(_a(glow, .8)), h * .06));
        canvas.drawOval(
          flare.deflate(h * .03),
          _blur(_fill(Colors.white), h * .02),
        );
        canvas.drawLine(
          Offset(cx - colW * .9, gy),
          Offset(cx + colW * .9, gy),
          _stroke(Colors.white, outline(1.4) * 1.6),
        );

      case TickerStyle.rulerTicks:
        for (var i = 0; i <= l.count * 5; i++) {
          final x = i * colW / 5;
          final major = i % 5 == 0;
          final fade = 1 - (x - cx).abs() / (w / 2) * .8;
          canvas.drawLine(
            Offset(x, gy),
            Offset(x, gy + h * (major ? .16 : .08)),
            _stroke(_a(line, fade * (major ? .8 : .45)), outline(1.2)),
          );
        }
        canvas.drawLine(
          Offset(cx, gy - h * .06),
          Offset(cx, gy + h * .26),
          _stroke(glow, outline(1.2) * 2.2),
        );
        canvas.drawPath(
          Path()
            ..moveTo(cx - h * .05, h)
            ..lineTo(cx + h * .05, h)
            ..lineTo(cx, h - h * .07)
            ..close(),
          _fill(glow),
        );

      case TickerStyle.focusLens:
        canvas.drawLine(
          Offset(0, h / 2),
          Offset(w, h / 2),
          _fadedLine(_a(line, .35), h / 2, w, outline(1)),
        );
        final r = min(colW * .78, h * .47);
        final c = Offset(cx, h / 2);
        canvas.drawCircle(
          c.translate(0, h * .04),
          r,
          _blur(_fill(Colors.black.withValues(alpha: .35)), h * .06),
        );
        canvas.drawCircle(
          c,
          r,
          Paint()
            ..shader = ui.Gradient.radial(
              c.translate(-r * .3, -r * .3),
              r * 1.3,
              [_a(glow, .35), _a(glow, .08)],
            ),
        );
        canvas.drawCircle(c, r, _stroke(line, outline(2)));
        canvas.drawArc(
          Rect.fromCircle(center: c, radius: r * .82),
          pi * 1.1,
          pi * .45,
          false,
          _stroke(Colors.white.withValues(alpha: .55), outline(2) * 1.2),
        );

      case TickerStyle.odometer:
        final frame = RRect.fromRectAndRadius(
          Offset.zero & size,
          Radius.circular(h * .22),
        );
        canvas.drawRRect(
          frame.shift(Offset(0, h * .04)),
          _blur(_fill(Colors.black.withValues(alpha: .4)), h * .06),
        );
        canvas.drawRRect(frame, _fill(panel));
        canvas.save();
        canvas.clipRRect(frame);
        canvas.drawRect(
          Offset.zero & size,
          Paint()
            ..shader = ui.Gradient.linear(
              Offset.zero,
              Offset(0, h),
              [
                Colors.black.withValues(alpha: .6),
                Colors.black.withValues(alpha: 0),
                Colors.black.withValues(alpha: .6),
              ],
              [0, .5, 1],
            ),
        );
        for (var i = 1; i < l.count; i++) {
          canvas.drawLine(
            Offset(i * colW, 0),
            Offset(i * colW, h),
            _stroke(_a(line, .22), 1 * k),
          );
        }
        canvas.restore();
        final win = RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(cx, h / 2),
            width: colW * 1.08,
            height: h * .82,
          ),
          Radius.circular(h * .12),
        );
        canvas.drawRRect(win, _fill(_a(glow, .16)));
        canvas.drawRRect(win, _stroke(glow, outline(2)));
        canvas.drawRRect(
          frame.deflate(.6 * k),
          _stroke(_a(line, .45), 1.2 * k),
        );

      case TickerStyle.pulseWave:
        final wave = Path()..moveTo(0, gy);
        for (var x = 0.0; x <= w; x += w / 240) {
          final d = (x - cx) / (w / 2);
          final env = exp(-d * d * 9);
          wave.lineTo(x, gy - sin((x - cx) / colW * pi * 2) * h * .14 * env);
        }
        canvas.drawPath(wave, _fadedLine(line, gy, w, outline(1.6)));
        final crest = Offset(cx, gy);
        canvas.drawCircle(crest, h * .06, _blur(_fill(glow), h * .05));
        canvas.drawCircle(crest, h * .03, _fill(Colors.white));

      case TickerStyle.scanBeam:
        for (var y = h * .08; y < h; y += h * .1) {
          canvas.drawLine(
            Offset(0, y),
            Offset(w, y),
            _fadedLine(_a(line, .12), y, w, 1 * k),
          );
        }
        final beam = Rect.fromCenter(
          center: Offset(cx, h / 2),
          width: colW * 1.2,
          height: h,
        );
        canvas.drawRect(
          beam,
          Paint()
            ..shader = ui.Gradient.linear(
              beam.centerLeft,
              beam.centerRight,
              [_a(glow, 0), _a(glow, .38), _a(glow, 0)],
              const [0, .5, 1],
            ),
        );
        for (final y in [0.0, h]) {
          canvas.drawLine(
            Offset(cx - colW * .32, y),
            Offset(cx + colW * .32, y),
            _blur(_stroke(glow, outline(2)), 1.5 * k),
          );
        }

      case TickerStyle.dialArc:
        final arc = Path();
        for (var o = -l.half; o <= l.half; o++) {
          final p = at(o).translate(0, -h * .24);
          o == -l.half ? arc.moveTo(p.dx, p.dy) : arc.lineTo(p.dx, p.dy);
        }
        canvas.drawPath(arc, _stroke(_a(line, .5), outline(1.4)));
        for (var o = -l.half; o <= l.half; o++) {
          final p = at(o).translate(0, -h * .24);
          canvas.drawLine(
            p,
            p.translate(0, h * .06),
            _stroke(_a(line, 1 - o.abs() * .12), outline(1.4)),
          );
        }
        canvas.drawPath(
          Path()
            ..moveTo(cx - h * .06, gy - h * .07)
            ..lineTo(cx + h * .06, gy - h * .07)
            ..lineTo(cx, gy + h * .04)
            ..close(),
          _fill(glow),
        );

      case TickerStyle.progressTrack:
        final t = l.track;
        final track = RRect.fromRectAndRadius(
          Rect.fromLTWH(t.left * k, t.top * k, t.width * k, t.height * k),
          Radius.circular(t.height * k / 2),
        );
        canvas.drawRRect(track, _fill(panel));
        canvas.drawRRect(track, _stroke(_a(line, .35), 1 * k));
        final mid = at(0);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: mid, width: colW * .95, height: h * .5),
            Radius.circular(h * .14),
          ),
          _fill(_a(glow, .18)),
        );

      case TickerStyle.perspectiveFloor:
        final horizon = h * .78;
        final vanish = Offset(cx, h * .1);
        for (var i = -l.count; i <= l.count; i++) {
          final x = cx + i * colW * .9;
          canvas.drawLine(
            Offset(x, h),
            Offset.lerp(Offset(x, h), vanish, .28)!,
            _stroke(_a(line, .28 * (1 - i.abs() / (l.count + 1))), 1 * k),
          );
        }
        for (var j = 0; j < 4; j++) {
          final y = horizon + (h - horizon) * (j / 3) * (j / 3);
          canvas.drawLine(
            Offset(0, y),
            Offset(w, y),
            _fadedLine(_a(line, .3), y, w, 1 * k),
          );
        }
        canvas.drawLine(
          Offset(0, horizon),
          Offset(w, horizon),
          _blur(_fadedLine(glow, horizon, w, outline(2)), 2 * k),
        );

      case TickerStyle.neonRing:
        final r = min(colW * .62, h * .44);
        final c = Offset(cx, h / 2);
        canvas.drawCircle(c, r, _blur(_stroke(glow, outline(3) * 3), h * .07));
        canvas.drawCircle(c, r, _stroke(glow, outline(3)));
        canvas.drawCircle(
          c,
          r,
          _stroke(Colors.white.withValues(alpha: .75), outline(3) * .35),
        );
        for (var o = -l.half; o <= l.half; o++) {
          if (o == 0) continue;
          canvas.drawCircle(
            at(o).translate(0, h * .36),
            h * .022,
            _fill(_a(line, .5 - o.abs() * .06)),
          );
        }
    }
  }

  @override
  bool shouldRepaint(_TickerPainter old) => old.el != el || old.k != k;
}
