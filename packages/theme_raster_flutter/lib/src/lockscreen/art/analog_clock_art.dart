import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:theme_core/theme_core.dart';
import 'package:theme_core/lockscreen_layout.dart'
    show AnalogPart, OrbitDigital, analogPartSuffix, analogPartsOfSpec;
import '../lock_element.dart';
import '../lock_element_spec_bridge.dart';
import '../lockscreen_clock.dart';

/// Rotating parts drawn for [el], bottom to top.
List<AnalogPart> analogPartsOf(LockElement el) =>
    analogPartsOfSpec(el.toSpec());

/// Draws analog clock parts (dial, or a hand pointing at 12) in a square box.
class AnalogClockArt {
  const AnalogClockArt._();

  /// Custom PNG stored in [LockElement.path] (single-part elements only).
  static String? customPng(LockElement el) =>
      el.type != ElementType.analogClock &&
          el.path.toLowerCase().endsWith('.png') &&
          File(el.path).existsSync()
      ? el.path
      : null;

  /// File suffix of an exported part.
  static String suffix(LockElement el, AnalogPart part) =>
      analogPartSuffix(el.toSpec(), part);

  static Widget part(LockElement el, AnalogPart part, double size) {
    final custom = customPng(el);
    if (custom != null) {
      return SizedBox.square(
        dimension: size,
        child: Image.memory(
          File(custom).readAsBytesSync(),
          fit: BoxFit.contain,
          gaplessPlayback: true,
        ),
      );
    }
    final combined = el.type == ElementType.analogClock;
    final style = combined ? el.analogStyle : AnalogStyle.indigo;
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(
        painter: part == AnalogPart.dial
            ? _DialPainter(
                style,
                el.colorSecondary,
                combined ? el.borderColor : el.color,
                el.width <= 0 ? 0 : el.borderWidth * size / el.width,
                el.unlockAccent,
              )
            : _HandPainter(
                part,
                style,
                combined && part == AnalogPart.second
                    ? el.unlockAccent
                    : combined &&
                          part == AnalogPart.minute &&
                          el.strokeColor.a > 0
                    ? el.strokeColor
                    : el.color,
                el.unlockAccent,
              ),
      ),
    );
  }
}

/// Live editor preview; hands follow the current time.
class AnalogClockPreview extends StatefulWidget {
  const AnalogClockPreview({super.key, required this.element});
  final LockElement element;

  @override
  State<AnalogClockPreview> createState() => _AnalogClockPreviewState();
}

class _AnalogClockPreviewState extends State<AnalogClockPreview> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (widget.element.type != ElementType.analogClockBg) {
      _timer = Timer.periodic(
        const Duration(seconds: 1),
        (_) => setState(() {}),
      );
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final el = widget.element;
    final size = el.width / lockscreenScreenRatio;
    final now = lockscreenNow();
    return SizedBox.square(
      dimension: size,
      child: Stack(
        children: [
          for (final part in analogPartsOf(el))
            Transform.rotate(
              angle: part.angleAt(now) * pi / 180,
              child: AnalogClockArt.part(el, part, size),
            ),
          if (el.type == ElementType.analogClock &&
              el.analogStyle == AnalogStyle.orbitDigital)
            ..._orbitOverlay(el, size, now),
        ],
      ),
    );
  }

  List<Widget> _orbitOverlay(LockElement el, double s, DateTime now) {
    final c = s / 2;
    final ink = el.unlockAccent;
    final disc = el.colorSecondary;
    Widget text(String value, double size, {bool bold = true}) => Text(
      value,
      textAlign: TextAlign.center,
      style: TextStyle(
        color: ink,
        fontSize: size,
        height: 1,
        fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
      ),
    );
    Widget at(Offset center, Widget child) => Positioned(
      left: center.dx - s / 2,
      top: center.dy - s / 2,
      width: s,
      height: s,
      child: Center(child: child),
    );
    Offset orbit(double fraction, double degrees) {
      final a = degrees * pi / 180;
      return Offset(c + sin(a) * s * fraction, c - cos(a) * s * fraction);
    }

    Widget bubble(double r, Widget label) => Container(
      width: s * r * 2,
      height: s * r * 2,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: disc, shape: BoxShape.circle),
      child: label,
    );
    final hour = MediaQuery.maybeAlwaysUse24HourFormatOf(context) ?? false
        ? now.hour
        : (now.hour % 12 == 0 ? 12 : now.hour % 12);
    String two(int v) => v.toString().padLeft(2, '0');
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final secAngle = now.second * 6.0;
    return [
      Positioned.fill(
        child: CustomPaint(
          painter: _StemPainter(
            orbit(OrbitDigital.secondOrbit, secAngle),
            orbit(OrbitDigital.secondStem, secAngle),
            s * .008,
            disc,
          ),
        ),
      ),
      at(Offset(c, c), text(two(hour), s * OrbitDigital.hourText)),
      at(
        Offset(c, c + s * OrbitDigital.dayY),
        text(days[now.weekday - 1], s * OrbitDigital.dayText, bold: false),
      ),
      at(
        Offset(c, c + s * OrbitDigital.dateY),
        text('${two(now.month)}/${two(now.day)}', s * OrbitDigital.dateText),
      ),
      at(
        orbit(OrbitDigital.minuteOrbit, now.minute * 6.0),
        bubble(
          OrbitDigital.minuteBubble,
          text(two(now.minute), s * OrbitDigital.minuteText),
        ),
      ),
      at(
        orbit(OrbitDigital.secondOrbit, secAngle),
        bubble(
          OrbitDigital.secondBubble,
          text(two(now.second), s * OrbitDigital.secondText),
        ),
      ),
    ];
  }
}

class _StemPainter extends CustomPainter {
  const _StemPainter(this.from, this.to, this.width, this.color);
  final Offset from, to;
  final double width;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) => canvas.drawLine(
    from,
    to,
    Paint()
      ..color = color
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round,
  );

  @override
  bool shouldRepaint(covariant _StemPainter old) =>
      old.from != from || old.to != to || old.color != color;
}

class _DialPainter extends CustomPainter {
  const _DialPainter(
    this.style,
    this.face,
    this.ticks,
    this.rim, [
    this.accent = const Color(0xFFFFFFFF),
  ]);
  final AnalogStyle style;
  final Color face, ticks, accent;
  final double rim;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width * .44;
    final circle = Rect.fromCircle(center: c, radius: r);
    final hsl = HSLColor.fromColor(face);
    Color shade(double d) => hsl
        .withLightness((hsl.lightness + d).clamp(0, 1))
        .toColor()
        .withValues(alpha: face.a);
    Offset at(double angle, double radius) =>
        c + Offset(sin(angle), -cos(angle)) * radius;
    Paint line(double width, [double alpha = 1]) => Paint()
      ..color = ticks.withValues(alpha: ticks.a * alpha)
      ..strokeWidth = max(1, width)
      ..strokeCap = StrokeCap.round;

    switch (style) {
      case AnalogStyle.bauhausPop:
      case AnalogStyle.ripple:
      case AnalogStyle.solarEclipse:
      case AnalogStyle.memphis:
      case AnalogStyle.prism:
      case AnalogStyle.ribbon:
      case AnalogStyle.terrazzo:
      case AnalogStyle.contour:
      case AnalogStyle.pixelSun:
      case AnalogStyle.fanFold:
      case AnalogStyle.liquidLoops:
      case AnalogStyle.checkerWave:
      case AnalogStyle.kineticTiles:
      case AnalogStyle.cyberReticle:
      case AnalogStyle.sunsetGrid:
      case AnalogStyle.zenGarden:
      case AnalogStyle.vortex:
      case AnalogStyle.circuitTrace:
      case AnalogStyle.artDeco:
      case AnalogStyle.squirclePebble:
      case AnalogStyle.moireRings:
      case AnalogStyle.brutalistPop:
      case AnalogStyle.holoWarp:
        _paintAbstract(canvas, size);
      case AnalogStyle.indigo:
        canvas.drawCircle(
          c + Offset(r * .06, r * .1),
          r,
          Paint()
            ..color = Colors.black.withValues(alpha: .35 * face.a)
            ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * .08),
        );
        canvas.drawCircle(
          c,
          r,
          Paint()
            ..shader = LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [shade(.06), shade(-.05)],
            ).createShader(circle),
        );
        canvas.drawCircle(
          c,
          r * .97,
          Paint()
            ..shader = LinearGradient(
              begin: Alignment.bottomRight,
              end: Alignment.topLeft,
              colors: [shade(.03), shade(-.02)],
            ).createShader(circle),
        );
        for (var i = 0; i < 4; i++) {
          canvas.drawLine(
            at(i * pi / 2, r * .86),
            at(i * pi / 2, r * .94),
            line(r * .006, .6),
          );
        }
      case AnalogStyle.minimal:
        for (var i = 0; i < 12; i++) {
          final quarter = i % 3 == 0;
          canvas.drawLine(
            at(i * pi / 6, r * (quarter ? .82 : .88)),
            at(i * pi / 6, r * .96),
            line(r * (quarter ? .02 : .012)),
          );
        }
      case AnalogStyle.classic:
        canvas.drawCircle(c, r, Paint()..color = face);
        canvas.drawCircle(
          c,
          r,
          line(max(rim, r * .015))..style = PaintingStyle.stroke,
        );
        for (var i = 0; i < 60; i++) {
          final hour = i % 5 == 0;
          canvas.drawLine(
            at(i * pi / 30, r * (hour ? .8 : .88)),
            at(i * pi / 30, r * .93),
            line(r * (hour ? .025 : .008), hour ? 1 : .6),
          );
        }
      case AnalogStyle.numerals:
        canvas.drawCircle(c, r, Paint()..color = face);
        for (var i = 1; i <= 12; i++) {
          final text = TextPainter(
            text: TextSpan(
              text: '$i',
              style: TextStyle(
                color: ticks,
                fontSize: r * .17,
                fontWeight: FontWeight.w500,
                height: 1,
              ),
            ),
            textDirection: TextDirection.ltr,
          )..layout();
          text.paint(
            canvas,
            at(i * pi / 6, r * .78) - Offset(text.width / 2, text.height / 2),
          );
        }
      case AnalogStyle.dots:
        canvas.drawCircle(c, r, Paint()..color = face);
        for (var i = 0; i < 12; i++) {
          canvas.drawCircle(
            at(i * pi / 6, r * .86),
            r * (i % 3 == 0 ? .045 : .025),
            Paint()..color = ticks,
          );
        }
      case AnalogStyle.ring:
        canvas.drawCircle(c, r, Paint()..color = face);
        final width = max(rim, r * .035);
        canvas.drawCircle(
          c,
          r - width / 2,
          line(width)..style = PaintingStyle.stroke,
        );
        for (var i = 0; i < 4; i++) {
          canvas.drawLine(
            at(i * pi / 2, r * .78),
            at(i * pi / 2, r * .88),
            line(r * .03),
          );
        }
      case AnalogStyle.woodPanel:
        _paintPanel(canvas, size);
      case AnalogStyle.crimsonGlass:
        _paintCrimson(canvas, c, r, shade, at, line);
      case AnalogStyle.romanWall:
        _paintRoman(canvas, c, r, shade, at, line);
      case AnalogStyle.neonGlow:
        canvas.drawCircle(c, r, Paint()..color = face);
        for (final (blur, width, alpha) in [
          (r * .06, r * .05, .55),
          (r * .02, r * .025, .8),
          (0.0, r * .01, 1.0),
        ]) {
          canvas.drawCircle(
            c,
            r * .92,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = width
              ..color =
                  (blur == 0 ? Color.lerp(ticks, Colors.white, .6)! : ticks)
                      .withValues(alpha: alpha)
              ..maskFilter = blur == 0
                  ? null
                  : MaskFilter.blur(BlurStyle.normal, blur),
          );
        }
        for (var i = 0; i < 12; i++) {
          final quarter = i % 3 == 0;
          final from = at(i * pi / 6, r * (quarter ? .7 : .76));
          final to = at(i * pi / 6, r * .82);
          canvas.drawLine(
            from,
            to,
            line(r * .03, .6)
              ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * .02),
          );
          canvas.drawLine(
            from,
            to,
            line(r * (quarter ? .016 : .01))
              ..color = Color.lerp(ticks, Colors.white, .6)!,
          );
        }
      case AnalogStyle.auroraRing:
        canvas.drawCircle(c, r, Paint()..color = face);
        final band = r * .1;
        canvas.drawCircle(
          c,
          r - band / 2,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = band
            ..shader = SweepGradient(
              transform: const GradientRotation(-pi / 2),
              colors: [accent, ticks, shade(.25), accent],
            ).createShader(circle),
        );
        canvas.drawCircle(
          c,
          r - band / 2,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = band * 1.6
            ..shader = SweepGradient(
              transform: const GradientRotation(-pi / 2),
              colors: [
                accent.withValues(alpha: .35),
                ticks.withValues(alpha: .35),
                accent.withValues(alpha: .35),
              ],
            ).createShader(circle)
            ..maskFilter = MaskFilter.blur(BlurStyle.normal, band * .8),
        );
        for (var i = 0; i < 12; i++) {
          canvas.drawCircle(
            at(i * pi / 6, r * .76),
            r * (i % 3 == 0 ? .028 : .014),
            Paint()..color = Color.lerp(ticks, Colors.white, .5)!,
          );
        }
      case AnalogStyle.luxuryGold:
        final bezel = r * .12;
        canvas.drawCircle(
          c + Offset(0, r * .04),
          r,
          Paint()
            ..color = Colors.black.withValues(alpha: .5)
            ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * .05),
        );
        canvas.drawCircle(
          c,
          r,
          Paint()
            ..shader = SweepGradient(
              colors: [
                for (var i = 0; i < 9; i++)
                  i.isEven
                      ? Color.lerp(ticks, Colors.white, .45)!
                      : Color.lerp(ticks, Colors.black, .35)!,
              ],
            ).createShader(circle),
        );
        final faceR = r - bezel;
        final faceRect = Rect.fromCircle(center: c, radius: faceR);
        canvas.drawCircle(
          c,
          faceR,
          Paint()
            ..shader = RadialGradient(
              colors: [shade(.08), shade(-.04)],
            ).createShader(faceRect),
        );
        // Sunburst brushing.
        for (var i = 0; i < 180; i++) {
          canvas.drawLine(
            c,
            at(i * pi / 90, faceR),
            Paint()
              ..strokeWidth = max(.5, r * .004)
              ..color = Colors.white.withValues(alpha: i.isEven ? .035 : 0),
          );
        }
        canvas.drawCircle(
          c,
          faceR,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = r * .012
            ..color = Color.lerp(ticks, Colors.black, .4)!,
        );
        final gold = Paint()
          ..shader = LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color.lerp(ticks, Colors.white, .4)!, ticks],
          ).createShader(faceRect);
        for (var i = 0; i < 12; i++) {
          canvas.save();
          canvas.translate(c.dx, c.dy);
          canvas.rotate(i * pi / 6);
          final w = faceR * (i % 3 == 0 ? .07 : .045);
          for (final dx in i == 0 ? [-w * .8, w * .8] : [0.0]) {
            canvas.drawRRect(
              RRect.fromRectAndRadius(
                Rect.fromCenter(
                  center: Offset(dx, -faceR * .8),
                  width: w,
                  height: faceR * .2,
                ),
                Radius.circular(w * .2),
              ),
              gold,
            );
          }
          canvas.restore();
        }
      case AnalogStyle.frostedGlass:
        canvas.drawCircle(
          c + Offset(0, r * .05),
          r,
          Paint()
            ..color = Colors.black.withValues(alpha: .18)
            ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * .08),
        );
        canvas.drawCircle(
          c,
          r,
          Paint()
            ..shader = LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color.lerp(face, Colors.white, .25)!,
                face,
                face.withValues(alpha: face.a * .6),
              ],
            ).createShader(circle),
        );
        canvas.drawCircle(
          c,
          r,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = max(rim, r * .012)
            ..shader = LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withValues(alpha: .85),
                Colors.white.withValues(alpha: .05),
                Colors.white.withValues(alpha: .4),
              ],
            ).createShader(circle),
        );
        canvas.save();
        canvas.clipPath(Path()..addOval(circle));
        canvas.drawOval(
          Rect.fromCenter(
            center: c + Offset(-r * .3, -r * .62),
            width: r * 1.4,
            height: r * .7,
          ),
          Paint()
            ..color = Colors.white.withValues(alpha: .16)
            ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * .12),
        );
        canvas.restore();
        for (var i = 0; i < 12; i++) {
          final quarter = i % 3 == 0;
          canvas.drawLine(
            at(i * pi / 6, r * (quarter ? .76 : .82)),
            at(i * pi / 6, r * .88),
            line(r * (quarter ? .022 : .012), quarter ? 1 : .7),
          );
        }
      case AnalogStyle.orbit:
        canvas.drawCircle(c, r, Paint()..color = face);
        for (final orbit in [.42, .62, .82]) {
          canvas.drawCircle(
            c,
            r * orbit,
            line(r * .006, .3)..style = PaintingStyle.stroke,
          );
        }
        for (var i = 0; i < 12; i++) {
          canvas.drawCircle(
            at(i * pi / 6, r * .94),
            r * (i % 3 == 0 ? .022 : .01),
            Paint()..color = ticks,
          );
        }
      case AnalogStyle.orbitDigital:
        final s = size.width;
        final dash = Paint()
          ..color = face
          ..strokeWidth = s * .008
          ..strokeCap = StrokeCap.round;
        for (var i = 0; i < 60; i++) {
          canvas.drawLine(
            at(i * pi / 30, s * .4),
            at(i * pi / 30, s * .435),
            dash,
          );
        }
        canvas.drawCircle(
          c,
          s * OrbitDigital.minuteOrbit,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = s * .006
            ..color = face,
        );
        canvas.drawCircle(c, s * .2, Paint()..color = face);
      case AnalogStyle.flowerCard:
        final s = size.width;
        final card = RRect.fromRectAndRadius(
          Rect.fromCenter(center: c, width: s * .9, height: s * .9),
          Radius.circular(s * .12),
        );
        canvas.drawRRect(
          card.shift(Offset(0, s * .015)),
          Paint()
            ..color = Colors.black.withValues(alpha: .1)
            ..maskFilter = MaskFilter.blur(BlurStyle.normal, s * .03),
        );
        canvas.drawRRect(card, Paint()..color = face);
        final petals = Path();
        for (var i = 0; i < 5; i++) {
          petals.addOval(
            Rect.fromCircle(
              center: at(i * 2 * pi / 5 + .3, s * .19),
              radius: s * .19,
            ),
          );
        }
        petals.addOval(Rect.fromCircle(center: c, radius: s * .2));
        canvas.drawPath(petals, Paint()..color = ticks);
        final mark = Paint()..color = face;
        for (var i = 0; i < 4; i++) {
          canvas.save();
          canvas.translate(c.dx, c.dy);
          canvas.rotate(i * pi / 2);
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromCenter(
                center: Offset(0, -s * .11),
                width: s * .065,
                height: s * .075,
              ),
              Radius.circular(s * .02),
            ),
            mark,
          );
          canvas.restore();
        }
      case AnalogStyle.sport:
        canvas.drawCircle(
          c,
          r,
          Paint()
            ..shader = RadialGradient(
              colors: [shade(.08), shade(-.04)],
            ).createShader(circle),
        );
        for (var i = 0; i < 12; i++) {
          final quarter = i % 3 == 0;
          canvas.drawLine(
            at(i * pi / 6, r * (quarter ? .7 : .76)),
            at(i * pi / 6, r * .92),
            line(r * (quarter ? .07 : .045))..strokeCap = StrokeCap.butt,
          );
        }
    }
  }

  /// Geometric faces share the same centered, independently exported hands.
  void _paintAbstract(Canvas canvas, Size size) {
    canvas.save();
    canvas.translate(size.width / 2, size.height / 2);
    canvas.scale(size.width * .44);
    final paint = Paint()..isAntiAlias = true;
    void disc(Offset center, double radius, Color color) => canvas.drawCircle(
      center,
      radius,
      paint
        ..style = PaintingStyle.fill
        ..color = color,
    );
    void arc(
      double radius,
      double start,
      double sweep,
      double width,
      Color color,
    ) => canvas.drawArc(
      Rect.fromCircle(center: Offset.zero, radius: radius),
      start,
      sweep,
      false,
      paint
        ..style = PaintingStyle.stroke
        ..strokeWidth = width
        ..strokeCap = StrokeCap.round
        ..color = color,
    );
    void box(Rect rect, Color color) => canvas.drawRect(
      rect,
      paint
        ..style = PaintingStyle.fill
        ..color = color,
    );
    Color soft(Color color, double alpha) =>
        color.withValues(alpha: color.a * alpha);
    disc(Offset.zero, 1, face);
    canvas.save();
    canvas.clipPath(Path()..addOval(const Rect.fromLTWH(-1, -1, 2, 2)));
    switch (style) {
      case AnalogStyle.bauhausPop:
        box(const Rect.fromLTWH(-1, 0, 1, 1), accent);
        disc(const Offset(.43, -.43), .34, ticks);
        box(const Rect.fromLTWH(-.67, -.72, .24, .52), soft(accent, .55));
      case AnalogStyle.ripple:
        for (var i = 0; i < 7; i++) {
          arc(
            .24 + i * .105,
            -.7 + i * .17,
            4.9,
            .025,
            soft(ticks, .2 + i * .11),
          );
        }
      case AnalogStyle.solarEclipse:
        disc(const Offset(.08, -.05), .78, ticks);
        disc(const Offset(-.13, -.23), .76, face);
        arc(.9, .15, 2.8, .012, soft(accent, .6));
      case AnalogStyle.memphis:
        for (var i = 0; i < 12; i++) {
          final a = i * pi / 6;
          final p = Offset(sin(a), -cos(a)) * .74;
          if (i.isEven) {
            disc(p, .065, ticks);
          } else {
            canvas.save();
            canvas.translate(p.dx, p.dy);
            canvas.rotate(a);
            box(const Rect.fromLTWH(-.055, -.055, .11, .11), accent);
            canvas.restore();
          }
        }
        arc(.5, .3, 1.1, .03, soft(accent, .6));
      case AnalogStyle.prism:
        for (var i = 0; i < 6; i++) {
          final a = i * pi / 3;
          final path = Path()
            ..moveTo(-.15, .1)
            ..lineTo(cos(a), sin(a))
            ..lineTo(cos(a + pi / 3), sin(a + pi / 3))
            ..close();
          canvas.drawPath(
            path,
            paint
              ..style = PaintingStyle.fill
              ..color = soft(i.isEven ? ticks : accent, .12 + i * .1),
          );
        }
      case AnalogStyle.ribbon:
        for (var i = 0; i < 3; i++) {
          final path = Path()
            ..moveTo(-1.1, -.55 + i * .4)
            ..cubicTo(-.2, -1.2 + i * .4, .1, .8 - i * .2, 1.1, -.3 + i * .3);
          canvas.drawPath(
            path,
            paint
              ..style = PaintingStyle.stroke
              ..strokeWidth = .15
              ..color = soft(i == 1 ? accent : ticks, .4 + i * .25),
          );
        }
      case AnalogStyle.terrazzo:
        // Fixed coordinates keep exported assets identical to their previews.
        for (var i = 0; i < 32; i++) {
          final a = i * 2.39996;
          final p = Offset(cos(a), sin(a)) * (.35 + (i % 5) * .13);
          canvas.save();
          canvas.translate(p.dx, p.dy);
          canvas.rotate(a);
          final color = soft(i % 3 == 0 ? accent : ticks, i.isEven ? .8 : .35);
          if (i % 3 == 0) {
            final chip = Path()
              ..moveTo(-.06, .04)
              ..lineTo(-.02, -.07)
              ..lineTo(.07, .02)
              ..close();
            canvas.drawPath(
              chip,
              paint
                ..style = PaintingStyle.fill
                ..color = color,
            );
          } else {
            canvas.drawOval(
              const Rect.fromLTWH(-.055, -.03, .11, .06),
              paint
                ..style = PaintingStyle.fill
                ..color = color,
            );
          }
          canvas.restore();
        }
      case AnalogStyle.contour:
        for (var ring = 0; ring < 7; ring++) {
          final path = Path();
          for (var i = 0; i <= 120; i++) {
            final a = i * 2 * pi / 120;
            final radius = .24 + ring * .105 + .045 * sin(3 * a + ring * .35);
            final p = Offset(cos(a), sin(a)) * radius;
            if (i == 0) {
              path.moveTo(p.dx, p.dy);
            } else {
              path.lineTo(p.dx, p.dy);
            }
          }
          canvas.drawPath(
            path,
            paint
              ..style = PaintingStyle.stroke
              ..strokeWidth = .012
              ..color = soft(ticks, .3 + ring * .09),
          );
        }
      case AnalogStyle.pixelSun:
        for (var x = -7; x <= 7; x++) {
          for (var y = -7; y <= 7; y++) {
            if (x * x + y * y > 45 || x * x + y * y < 13) continue;
            box(
              Rect.fromLTWH(x * .12 - .05, y * .12 - .05, .1, .1),
              soft(y < 0 ? ticks : accent, .4 + (7 - y.abs()) * .07),
            );
          }
        }
      case AnalogStyle.kineticTiles:
        for (var x = 0; x < 4; x++) {
          for (var y = 0; y < 4; y++) {
            canvas.save();
            canvas.translate(-.75 + x * .5, -.75 + y * .5);
            canvas.rotate((x + y) * pi / 2);
            canvas.drawArc(
              const Rect.fromLTWH(-.22, -.22, .44, .44),
              0,
              pi,
              true,
              paint
                ..style = PaintingStyle.fill
                ..color = soft((x + y).isEven ? ticks : accent, .65),
            );
            canvas.restore();
          }
        }
      case AnalogStyle.fanFold:
        for (var i = 0; i < 24; i++) {
          final a = i * pi / 12;
          final inner = Offset(cos(a), sin(a)) * .27;
          final outer = Offset(cos(a), sin(a)) * .84;
          final next = Offset(cos(a + pi / 12), sin(a + pi / 12)) * .84;
          final fold = Path()
            ..moveTo(inner.dx, inner.dy)
            ..lineTo(outer.dx, outer.dy)
            ..lineTo(next.dx, next.dy)
            ..close();
          canvas.drawPath(
            fold,
            paint
              ..style = PaintingStyle.fill
              ..color = soft(i < 12 ? ticks : accent, i.isEven ? .8 : .25),
          );
        }
      case AnalogStyle.liquidLoops:
        for (var i = 0; i < 3; i++) {
          canvas.save();
          canvas.rotate(i * pi / 3 + .2);
          final loop = Path()
            ..moveTo(0, -.82)
            ..cubicTo(.85, -.82, .6, -.1, .24, .14)
            ..cubicTo(-.2, .46, -.25, .85, -.55, .62)
            ..cubicTo(-.95, .26, -.62, -.8, 0, -.82)
            ..close();
          canvas.drawPath(
            loop,
            paint
              ..style = PaintingStyle.stroke
              ..strokeWidth = .055
              ..color = soft(i == 1 ? accent : ticks, .65 + i * .15),
          );
          canvas.restore();
        }
      case AnalogStyle.checkerWave:
        Offset wave(double x, double y) =>
            Offset(x + .09 * sin(y * 5), y + .06 * cos(x * 5));
        for (var row = 0; row < 10; row++) {
          for (var col = 0; col < 10; col++) {
            if ((row + col).isOdd) continue;
            final path = Path();
            final x = -1.2 + col * .24;
            final y = -1.2 + row * .24;
            for (final (edge, point) in [
              wave(x, y),
              wave(x + .24, y),
              wave(x + .24, y + .24),
              wave(x, y + .24),
            ].indexed) {
              if (edge == 0) {
                path.moveTo(point.dx, point.dy);
              } else {
                path.lineTo(point.dx, point.dy);
              }
            }
            path.close();
            canvas.drawPath(
              path,
              paint
                ..style = PaintingStyle.fill
                ..color = soft(ticks, .65),
            );
          }
        }
        disc(Offset.zero, .42, face);
        arc(.44, -.5, 2.5, .02, accent);
      case AnalogStyle.cyberReticle:
        arc(.84, 0, pi * 1.8, .02, ticks);
        arc(.62, pi * .5, pi * 1.25, .014, soft(accent, .75));
        arc(.36, -pi * .2, pi * .85, .018, ticks);
        canvas.drawLine(
          const Offset(-.9, 0),
          const Offset(-.42, 0),
          paint
            ..style = PaintingStyle.stroke
            ..strokeWidth = .014
            ..color = ticks,
        );
        canvas.drawLine(const Offset(.42, 0), const Offset(.9, 0), paint);
        canvas.drawLine(const Offset(0, -.9), const Offset(0, -.42), paint);
        canvas.drawLine(const Offset(0, .42), const Offset(0, .9), paint);
        for (var i = 0; i < 24; i++) {
          final a = i * pi / 12;
          final p1 = Offset(cos(a), sin(a)) * .84;
          final p2 = Offset(cos(a), sin(a)) * (i % 6 == 0 ? .76 : .80);
          canvas.drawLine(
            p1,
            p2,
            paint
              ..style = PaintingStyle.stroke
              ..strokeWidth = .012
              ..color = soft(accent, .8),
          );
        }
        disc(Offset.zero, .04, accent);
      case AnalogStyle.sunsetGrid:
        disc(const Offset(0, -.12), .48, accent);
        final sunMask = Paint()
          ..style = PaintingStyle.fill
          ..color = face;
        for (var y = -.04; y <= .36; y += .08) {
          canvas.drawRect(Rect.fromLTWH(-.6, y, 1.2, .035), sunMask);
        }
        final gridLine = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = .014
          ..color = soft(ticks, .75);
        canvas.drawLine(const Offset(-1, .28), const Offset(1, .28), gridLine);
        for (var i = 1; i <= 4; i++) {
          final y = .28 + i * .16;
          canvas.drawLine(
            Offset(-1, y),
            Offset(1, y),
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = .012
              ..color = soft(ticks, .3 + i * .15),
          );
        }
        for (var x = -1.2; x <= 1.2; x += .3) {
          canvas.drawLine(
            const Offset(0, .28),
            Offset(x * 1.4, 1.05),
            gridLine,
          );
        }
      case AnalogStyle.zenGarden:
        for (var i = 1; i <= 8; i++) {
          arc(.12 + i * .105, 0, 2 * pi, .012, soft(ticks, .2 + i * .09));
        }
        canvas.drawOval(
          const Rect.fromLTWH(.02, -.3, .34, .26),
          Paint()
            ..style = PaintingStyle.fill
            ..color = accent,
        );
        canvas.drawOval(
          const Rect.fromLTWH(-.36, .14, .26, .2),
          Paint()
            ..style = PaintingStyle.fill
            ..color = soft(ticks, .85),
        );
      case AnalogStyle.vortex:
        for (var arm = 0; arm < 8; arm++) {
          final baseAngle = arm * pi / 4;
          final path = Path();
          for (var t = 0; t <= 40; t++) {
            final theta = t * 0.1;
            final r = .08 * exp(0.55 * theta);
            final a = baseAngle + theta;
            final pt = Offset(cos(a), sin(a)) * r;
            if (t == 0) {
              path.moveTo(pt.dx, pt.dy);
            } else {
              path.lineTo(pt.dx, pt.dy);
            }
          }
          canvas.drawPath(
            path,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = .022
              ..strokeCap = StrokeCap.round
              ..color = soft(arm.isEven ? accent : ticks, .5 + (arm % 4) * .12),
          );
        }
        disc(Offset.zero, .1, accent);
      case AnalogStyle.circuitTrace:
        final trace = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = .018
          ..color = soft(ticks, .75);
        void wire(List<Offset> pts) {
          final p = Path()..moveTo(pts[0].dx, pts[0].dy);
          for (var i = 1; i < pts.length; i++) {
            p.lineTo(pts[i].dx, pts[i].dy);
          }
          canvas.drawPath(p, trace);
          disc(pts.first, .035, accent);
          disc(pts.first, .015, face);
          disc(pts.last, .035, accent);
          disc(pts.last, .015, face);
        }
        wire([
          const Offset(-.7, -.4),
          const Offset(-.3, -.4),
          const Offset(-.1, -.2),
          const Offset(-.1, .3),
        ]);
        wire([
          const Offset(.6, -.6),
          const Offset(.2, -.2),
          const Offset(.2, .4),
          const Offset(.5, .7),
        ]);
        wire([
          const Offset(-.6, .5),
          const Offset(-.2, .5),
          const Offset(.1, .2),
          const Offset(.6, .2),
        ]);
        wire([
          const Offset(-.4, -.7),
          const Offset(-.4, -.3),
          const Offset(.3, .4),
          const Offset(.3, .8),
        ]);
      case AnalogStyle.artDeco:
        for (var i = 1; i <= 6; i++) {
          final rad = i * .15;
          canvas.drawArc(
            Rect.fromCircle(center: const Offset(0, .9), radius: rad),
            pi,
            pi,
            false,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = .018
              ..color = soft(i.isEven ? accent : ticks, .35 + i * .1),
          );
        }
        for (var i = -5; i <= 5; i++) {
          final a = -pi / 2 + i * pi / 14;
          canvas.drawLine(
            const Offset(0, .9),
            const Offset(0, .9) + Offset(cos(a), sin(a)) * 1.8,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = .01
              ..color = soft(ticks, .4),
          );
        }
        void diamond(Offset center, double s, Color col) {
          final path = Path()
            ..moveTo(center.dx, center.dy - s)
            ..lineTo(center.dx + s * .7, center.dy)
            ..lineTo(center.dx, center.dy + s)
            ..lineTo(center.dx - s * .7, center.dy)
            ..close();
          canvas.drawPath(path, Paint()..style = PaintingStyle.fill..color = col);
        }
        diamond(const Offset(0, -.72), .08, accent);
        diamond(const Offset(-.72, 0), .08, accent);
        diamond(const Offset(.72, 0), .08, accent);
      case AnalogStyle.squirclePebble:
        for (var i = 6; i >= 1; i--) {
          final s = i * .145;
          canvas.save();
          canvas.rotate(i * pi / 16);
          final rrect = RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset.zero, width: s * 2, height: s * 1.8),
            Radius.circular(s * .55),
          );
          canvas.drawRRect(
            rrect,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = .02
              ..color = soft(i.isEven ? ticks : accent, .25 + i * .12),
          );
          canvas.restore();
        }
        disc(Offset.zero, .06, accent);
      case AnalogStyle.moireRings:
        final ringPaint = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = .01
          ..color = soft(ticks, .6);
        for (var i = 1; i <= 14; i++) {
          canvas.drawCircle(const Offset(-.18, 0), i * .065, ringPaint);
          canvas.drawCircle(
            const Offset(.18, 0),
            i * .065,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = .01
              ..color = soft(accent, .6),
          );
        }
        disc(const Offset(-.18, 0), .03, ticks);
        disc(const Offset(.18, 0), .03, accent);
      case AnalogStyle.brutalistPop:
        box(const Rect.fromLTWH(-.88, -.88, .6, .6), soft(accent, .35));
        for (var i = 0; i < 4; i++) {
          box(
            Rect.fromLTWH(-.8 + i * .18, .2 - i * .18, .24, .24),
            soft(ticks, .8),
          );
        }
        disc(const Offset(.44, -.4), .36, accent);
        canvas.drawRect(
          const Rect.fromLTWH(-.95, -.08, 1.9, .16),
          Paint()
            ..style = PaintingStyle.fill
            ..color = soft(face, .9),
        );
        canvas.drawRect(
          const Rect.fromLTWH(-.95, -.08, 1.9, .16),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = .02
            ..color = ticks,
        );
      case AnalogStyle.holoWarp:
        for (var i = 0; i < 7; i++) {
          final yOffset = -.6 + i * .2;
          final path = Path()
            ..moveTo(-1.1, yOffset - .15)
            ..cubicTo(
              -.5,
              yOffset + .35,
              .2,
              yOffset - .35,
              1.1,
              yOffset + .15,
            );
          canvas.drawPath(
            path,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = .035
              ..color = soft(i % 2 == 0 ? ticks : accent, .4 + i * .09),
          );
        }
        disc(const Offset(.15, -.1), .14, accent);
      default:
        break;
    }
    canvas.restore();
    for (var i = 0; i < 12; i++) {
      final a = i * pi / 6;
      disc(Offset(sin(a), -cos(a)) * .93, i % 3 == 0 ? .024 : .009, ticks);
    }
    canvas.restore();
  }

  /// Square board hung on a wall: soft drop shadow, bevelled edge, light falloff.
  void _paintPanel(Canvas canvas, Size size) {
    final w = size.width;
    final board = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: size.center(Offset.zero),
        width: w * .86,
        height: w * .92,
      ),
      Radius.circular(w * .012),
    );
    final hsl = HSLColor.fromColor(face);
    Color tone(double d) => hsl
        .withLightness((hsl.lightness + d).clamp(0, 1))
        .toColor()
        .withValues(alpha: face.a);
    canvas.drawRRect(
      board.shift(Offset(w * .012, w * .02)),
      Paint()
        ..color = Colors.black.withValues(alpha: .55 * face.a)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, w * .018),
    );
    canvas.drawRRect(board, Paint()..color = tone(-.25));
    final inner = board.deflate(w * .006);
    canvas.drawRRect(
      inner,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [tone(-.06), tone(0), tone(.05)],
          stops: const [0, .55, 1],
        ).createShader(inner.outerRect),
    );
    // Paper grain.
    final rnd = Random(7);
    final grain = Paint()..strokeWidth = max(1, w * .002);
    for (var i = 0; i < 900; i++) {
      grain.color = (rnd.nextBool() ? Colors.black : Colors.white).withValues(
        alpha: .035 * face.a,
      );
      canvas.drawCircle(
        Offset(
          inner.left + rnd.nextDouble() * inner.width,
          inner.top + rnd.nextDouble() * inner.height,
        ),
        w * .0025,
        grain,
      );
    }
    // Window light falling across the lower-right corner.
    canvas.save();
    canvas.clipRRect(inner);
    canvas.drawPath(
      Path()
        ..moveTo(inner.left + inner.width * .55, inner.bottom)
        ..lineTo(inner.right, inner.top + inner.height * .35)
        ..lineTo(inner.right, inner.bottom)
        ..close(),
      Paint()
        ..color = Colors.white.withValues(alpha: .28 * face.a)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, w * .05),
    );
    canvas.restore();
    canvas.drawRRect(
      inner,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * .004
        ..color = Colors.white.withValues(alpha: .5 * face.a),
    );
  }

  /// Glossy coloured dial with a white rim, 12/3/6/9 numerals and a glass sheen.
  void _paintCrimson(
    Canvas canvas,
    Offset c,
    double r,
    Color Function(double) shade,
    Offset Function(double, double) at,
    Paint Function(double, [double]) line,
  ) {
    final circle = Rect.fromCircle(center: c, radius: r);
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(.35, -.55),
          radius: 1.1,
          colors: [shade(.1), shade(-.02), shade(-.14)],
          stops: const [0, .5, 1],
        ).createShader(circle),
    );
    canvas.save();
    canvas.clipPath(Path()..addOval(circle));
    final sheen = Paint()..color = Colors.white.withValues(alpha: .07);
    for (final (offset, width) in [(-.05, .32), (.42, .12)]) {
      canvas.save();
      canvas.translate(c.dx, c.dy);
      canvas.rotate(pi / 4);
      canvas.drawRect(
        Rect.fromLTWH(r * offset, -r * 1.2, r * width, r * 2.4),
        sheen,
      );
      canvas.restore();
    }
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * .08
        ..color = Colors.black.withValues(alpha: .35)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * .04),
    );
    canvas.restore();
    canvas.drawCircle(
      c,
      r - max(rim, r * .018) / 2,
      line(max(rim, r * .018))..style = PaintingStyle.stroke,
    );
    for (var i = 0; i < 12; i++) {
      if (i % 3 == 0) {
        final text = TextPainter(
          text: TextSpan(
            text: '${i == 0 ? 12 : i}',
            style: TextStyle(color: ticks, fontSize: r * .12, height: 1),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        text.paint(
          canvas,
          at(i * pi / 6, r * .8) - Offset(text.width / 2, text.height / 2),
        );
      } else {
        canvas.drawLine(
          at(i * pi / 6, r * .78),
          at(i * pi / 6, r * .84),
          line(r * .022)..strokeCap = StrokeCap.butt,
        );
      }
    }
  }

  /// Vintage wall clock: dark metal frame, cream face, Roman numerals, glass.
  void _paintRoman(
    Canvas canvas,
    Offset c,
    double r,
    Color Function(double) shade,
    Offset Function(double, double) at,
    Paint Function(double, [double]) line,
  ) {
    final frame = r * .14;
    canvas.drawCircle(
      c + Offset(r * .04, r * .07),
      r,
      Paint()
        ..color = Colors.black.withValues(alpha: .45)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * .06),
    );
    final outer = Rect.fromCircle(center: c, radius: r);
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..shader = SweepGradient(
          colors: [
            ticks,
            Color.lerp(ticks, Colors.white, .25)!,
            ticks,
            Color.lerp(ticks, Colors.black, .3)!,
            ticks,
          ],
        ).createShader(outer),
    );
    // Worn metal speckle on the frame.
    final rnd = Random(3);
    final speck = Paint();
    for (var i = 0; i < 500; i++) {
      final a = rnd.nextDouble() * pi * 2;
      final d = r - rnd.nextDouble() * frame;
      speck.color = (rnd.nextBool() ? Colors.white : Colors.black).withValues(
        alpha: .12,
      );
      canvas.drawCircle(at(a, d), r * .004, speck);
    }
    final faceR = r - frame;
    final faceRect = Rect.fromCircle(center: c, radius: faceR);
    canvas.drawCircle(
      c,
      faceR,
      Paint()
        ..shader = RadialGradient(
          colors: [shade(.04), shade(-.06)],
        ).createShader(faceRect),
    );
    canvas.drawCircle(
      c,
      faceR,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * .03
        ..color = Colors.black.withValues(alpha: .4)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * .02),
    );
    final ink = Color.lerp(ticks, Colors.black, .6)!;
    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = max(1, r * .006)
      ..color = ink;
    canvas.drawCircle(c, faceR * .95, track);
    canvas.drawCircle(c, faceR * .9, track);
    for (var i = 0; i < 60; i++) {
      canvas.drawLine(
        at(i * pi / 30, faceR * .9),
        at(i * pi / 30, faceR * .95),
        Paint()
          ..color = ink
          ..strokeWidth = max(1, r * (i % 5 == 0 ? .012 : .005)),
      );
    }
    const numerals = [
      'XII', 'I', 'II', 'III', 'IV', 'V', //
      'VI', 'VII', 'VIII', 'IX', 'X', 'XI',
    ];
    for (var i = 0; i < 12; i++) {
      final text = TextPainter(
        text: TextSpan(
          text: numerals[i],
          style: TextStyle(
            color: ink,
            fontSize: faceR * .25,
            fontFamily: 'serif',
            fontWeight: FontWeight.w700,
            letterSpacing: -faceR * .012,
            height: 1,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      final p = at(i * pi / 6, faceR * .72);
      canvas.save();
      canvas.translate(p.dx, p.dy);
      canvas.rotate(i * pi / 6);
      // Tall, condensed numerals like the reference wall clock.
      canvas.scale(.72, 1);
      text.paint(canvas, Offset(-text.width / 2, -text.height / 2));
      canvas.restore();
    }
    canvas.save();
    canvas.clipPath(Path()..addOval(faceRect));
    canvas.drawPath(
      Path()..addOval(
        Rect.fromCircle(
          center: c + Offset(-faceR * .35, -faceR * .55),
          radius: faceR * .9,
        ),
      ),
      Paint()
        ..color = Colors.white.withValues(alpha: .12)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, faceR * .1),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _DialPainter old) =>
      old.style != style ||
      old.face != face ||
      old.ticks != ticks ||
      old.rim != rim ||
      old.accent != accent;
}

class _HandPainter extends CustomPainter {
  const _HandPainter(this.part, this.style, this.color, [this.cap]);
  final AnalogPart part;
  final AnalogStyle style;
  final Color color;

  /// Centre cap colour (Flower card).
  final Color? cap;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2;
    final short = style == AnalogStyle.numerals;
    var (length, tail, width) = switch (part) {
      AnalogPart.hour => (short ? .4 : .46, .0, .024),
      AnalogPart.minute => (short ? .58 : .68, .0, .018),
      _ => (short ? .66 : .76, .14, .01),
    };
    width *= switch (style) {
      AnalogStyle.sport => part == AnalogPart.second ? 1.4 : 2,
      AnalogStyle.minimal => .7,
      _ => 1,
    };
    // Measured from the reference concepts (fractions of the box radius).
    var ink = color;
    switch (style) {
      case AnalogStyle.flowerCard:
        final (len, w) = part == AnalogPart.hour ? (.36, .05) : (.6, .036);
        canvas.drawLine(
          c,
          c - Offset(0, r * len),
          Paint()
            ..color = color
            ..strokeWidth = r * w * 2
            ..strokeCap = StrokeCap.round,
        );
        if (part == AnalogPart.minute) {
          canvas.drawCircle(c, r * .1, Paint()..color = this.cap ?? color);
        }
        return;
      case AnalogStyle.woodPanel:
        (length, tail, width) = switch (part) {
          AnalogPart.hour => (.3, .0, .013),
          AnalogPart.minute => (.49, .0, .008),
          _ => (.5, .0, .005),
        };
      case AnalogStyle.crimsonGlass:
        (length, tail, width) = switch (part) {
          AnalogPart.hour => (.38, .0, .012),
          AnalogPart.minute => (.68, .0, .007),
          _ => (.57, .0, .006),
        };
      case AnalogStyle.romanWall:
        (length, tail, width) = switch (part) {
          AnalogPart.hour => (.46, .0, .013),
          AnalogPart.minute => (.66, .0, .011),
          _ => (.46, .0, .02),
        };
        _paintRomanHand(canvas, c, r, length, width);
        return;
      case AnalogStyle.luxuryGold:
        (length, width) = switch (part) {
          AnalogPart.hour => (.42, .042),
          AnalogPart.minute => (.62, .032),
          _ => (.7, .008),
        };
        if (part == AnalogPart.second) break;
        _paintRomanHand(canvas, c, r, length, width);
        // Dauphine ridge: lighter half catches the light.
        canvas.drawPath(
          Path()
            ..moveTo(c.dx, c.dy - r * length)
            ..lineTo(c.dx - r * width, c.dy - r * length * .12)
            ..lineTo(c.dx, c.dy)
            ..close(),
          Paint()..color = Colors.white.withValues(alpha: .35),
        );
        return;
      case AnalogStyle.orbit:
        final (radius, dot) = switch (part) {
          AnalogPart.hour => (.37, .05),
          AnalogPart.minute => (.55, .04),
          _ => (.72, .026),
        };
        canvas.drawCircle(
          c - Offset(0, r * radius),
          r * dot * 1.8,
          Paint()
            ..color = color.withValues(alpha: .35)
            ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * dot),
        );
        canvas.drawCircle(
          c - Offset(0, r * radius),
          r * dot,
          Paint()..color = color,
        );
        return;
      case AnalogStyle.neonGlow:
        canvas.drawLine(
          c + Offset(0, r * tail),
          c - Offset(0, r * length),
          Paint()
            ..color = color.withValues(alpha: .7)
            ..strokeWidth = r * width * 5
            ..strokeCap = StrokeCap.round
            ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * .03),
        );
        ink = Color.lerp(color, Colors.white, .55)!;
      case AnalogStyle.frostedGlass:
        width *= 1.25;
      default:
    }
    final paint = Paint()
      ..color = ink
      ..strokeWidth = r * width * 2
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(c + Offset(0, r * tail), c - Offset(0, r * length), paint);
    final cap = switch ((style, part)) {
      (AnalogStyle.crimsonGlass, AnalogPart.second) => 0.0,
      (AnalogStyle.crimsonGlass, AnalogPart.minute) => r * .045,
      (AnalogStyle.woodPanel, AnalogPart.hour) => r * .03,
      (AnalogStyle.woodPanel, _) => 0.0,
      (_, AnalogPart.second) => r * width * 3.5,
      _ => r * width * 2.2,
    };
    if (cap > 0) canvas.drawCircle(c, cap, Paint()..color = ink);
  }

  /// Slim tapered hand with a short counterweight and a soft cast shadow.
  void _paintRomanHand(
    Canvas canvas,
    Offset c,
    double r,
    double length,
    double width,
  ) {
    final half = r * width;
    final tip = r * length;
    final tail = r * .1;
    final hand = Path()
      ..moveTo(c.dx, c.dy - tip)
      ..lineTo(c.dx + half, c.dy - tip * .12)
      ..lineTo(c.dx + half * .7, c.dy + tail)
      ..lineTo(c.dx - half * .7, c.dy + tail)
      ..lineTo(c.dx - half, c.dy - tip * .12)
      ..close();
    canvas.drawPath(
      hand.shift(Offset(r * .012, r * .02)),
      Paint()
        ..color = Colors.black.withValues(alpha: .28)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * .01),
    );
    canvas.drawPath(hand, Paint()..color = color);
    canvas.drawCircle(c, r * .035, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _HandPainter old) =>
      old.part != part ||
      old.style != style ||
      old.color != color ||
      old.cap != cap;
}
