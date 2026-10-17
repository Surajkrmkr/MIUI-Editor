import 'dart:math';
import 'package:flutter/material.dart';

/// Hand-drawn app glyphs used by shortcut sets, drawn in a unit square.
enum GlyphKind {
  bubble,
  lens,
  camera,
  note,
  compass,
  chrome,
  whatsapp,
  whatsappOutline,
  handset,
  gear,
  gearWrench,
  bulb,
  torch,
  gallery,
  clockFace,
  instagram,
  telegram,
  spotify,
  play,
  youtube,
  compassFlat,
  lensFlat,
  facebookF,
  tiktokNote,
  brush,
  flowerGear,
  noteSoft,
  galleryScene,
  playTik,
  gearSpokes,
  calculator,
  calculatorBody,
}

class GlyphPainter extends CustomPainter {
  const GlyphPainter(
    this.kind, {
    required this.ink,
    this.gradient,
    this.detail = Colors.white,
    this.gloss = false,
    this.colorful = false,
  });

  final GlyphKind kind;
  final Color ink;
  final Gradient? gradient;

  /// Secondary colour for inner parts (needle, handset inside a bubble, wrench).
  final Color detail;
  final bool gloss;

  /// Use the app's own colours (chrome segments) instead of [ink].
  final bool colorful;

  @override
  void paint(Canvas canvas, Size size) {
    final u = size.width;
    final bounds = Offset.zero & size;
    final c = bounds.center;
    Offset p(double x, double y) => Offset(x * u, y * u);
    Offset dir(double deg, double r) =>
        c + Offset(cos(deg * pi / 180), sin(deg * pi / 180)) * r * u;
    Offset unit(double deg) => Offset(cos(deg * pi / 180), sin(deg * pi / 180));
    final paint = Paint()
      ..color = ink
      ..isAntiAlias = true
      ..shader = gradient?.createShader(bounds);
    Paint stroke(double w, [Paint? base]) => Paint()
      ..color = (base ?? paint).color
      ..shader = (base ?? paint).shader
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * u
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    void glossOver(Path shape) {
      if (!gloss) return;
      canvas.save();
      canvas.clipPath(shape);
      canvas.drawRect(
        Rect.fromLTWH(0, 0, u, u * .5),
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white.withValues(alpha: .55),
              Colors.white.withValues(alpha: 0),
            ],
          ).createShader(Rect.fromLTWH(0, 0, u, u * .5)),
      );
      canvas.drawRect(
        Rect.fromLTWH(0, u * .6, u, u * .4),
        Paint()..color = Colors.black.withValues(alpha: .08),
      );
      canvas.restore();
    }

    Path handsetPath(double w) {
      final out = Path();
      final line = Path()
        ..moveTo(.27 * u, .17 * u)
        ..cubicTo(.08 * u, .32 * u, .42 * u, .92 * u, .83 * u, .74 * u);
      for (final metric in line.computeMetrics()) {
        for (var d = 0.0; d <= metric.length; d += u * .01) {
          final t = metric.getTangentForOffset(d)!;
          out.addOval(Rect.fromCircle(center: t.position, radius: w * u / 2));
        }
      }
      return out;
    }

    switch (kind) {
      case GlyphKind.bubble:
        final shape = Path()
          ..addOval(Rect.fromLTRB(.06 * u, .14 * u, .94 * u, .76 * u))
          ..moveTo(.26 * u, .64 * u)
          ..quadraticBezierTo(.25 * u, .86 * u, .12 * u, .92 * u)
          ..quadraticBezierTo(.38 * u, .9 * u, .48 * u, .74 * u)
          ..close();
        canvas.drawPath(shape, paint);
        glossOver(shape);
      case GlyphKind.lens:
        canvas.drawCircle(
          c,
          .46 * u,
          Paint()
            ..shader = const RadialGradient(
              colors: [Color(0xFF3A3D4A), Color(0xFF0B0C12)],
            ).createShader(bounds),
        );
        canvas.drawCircle(
          c,
          .35 * u,
          Paint()
            ..shader = const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFFFFFFF), Color(0xFF9EA3B5)],
            ).createShader(bounds),
        );
        canvas.drawCircle(c, .27 * u, Paint()..color = const Color(0xFF15182A));
        canvas.drawCircle(
          c,
          .2 * u,
          Paint()
            ..shader = RadialGradient(
              center: const Alignment(-.3, -.3),
              colors: [
                Color.lerp(detail, Colors.white, .35)!,
                detail,
                const Color(0xFF15182A),
              ],
              stops: const [0, .55, 1],
            ).createShader(Rect.fromCircle(center: c, radius: .2 * u)),
        );
        canvas.drawCircle(
          p(.43, .42),
          .06 * u,
          Paint()..color = Colors.white.withValues(alpha: .9),
        );
      case GlyphKind.camera:
        final body = Path()
          ..fillType = PathFillType.evenOdd
          ..addRRect(
            RRect.fromLTRBR(
              .08 * u,
              .3 * u,
              .92 * u,
              .84 * u,
              Radius.circular(.12 * u),
            ),
          )
          ..addRRect(
            RRect.fromLTRBR(
              .32 * u,
              .18 * u,
              .62 * u,
              .34 * u,
              Radius.circular(.05 * u),
            ),
          )
          ..addOval(Rect.fromCircle(center: p(.5, .57), radius: .19 * u));
        canvas.drawPath(body, paint);
        canvas.drawCircle(p(.5, .57), .1 * u, paint);
      case GlyphKind.note:
        final note = Path()
          ..addOval(
            Rect.fromCenter(
              center: p(.27, .78),
              width: .3 * u,
              height: .22 * u,
            ),
          )
          ..addOval(
            Rect.fromCenter(center: p(.73, .7), width: .3 * u, height: .22 * u),
          )
          ..addRect(Rect.fromLTRB(.35 * u, .25 * u, .42 * u, .78 * u))
          ..addRect(Rect.fromLTRB(.81 * u, .14 * u, .88 * u, .7 * u))
          ..addPolygon([
            p(.35, .22),
            p(.88, .08),
            p(.88, .22),
            p(.35, .36),
          ], true);
        canvas.drawPath(note, paint);
        glossOver(note);
      case GlyphKind.compass:
        canvas.drawCircle(c, .46 * u, paint);
        final tick = Paint()
          ..color = Colors.white
          ..strokeWidth = .018 * u
          ..strokeCap = StrokeCap.round;
        for (var i = 0; i < 48; i++) {
          final major = i % 4 == 0;
          canvas.drawLine(
            dir(i * 7.5, .4),
            dir(i * 7.5, major ? .31 : .35),
            tick,
          );
        }
        final a = dir(-45, .32), b = dir(135, .32);
        final side = Offset(.06 * u, .06 * u);
        canvas.drawPath(
          Path()..addPolygon([a, c + side, c - side], true),
          Paint()..color = detail,
        );
        canvas.drawPath(
          Path()..addPolygon([b, c + side, c - side], true),
          Paint()..color = Colors.white,
        );
      case GlyphKind.chrome:
        final outer = .45 * u;
        const inner = .23;
        final disc = Path()..addOval(Rect.fromCircle(center: c, radius: outer));
        canvas.drawPath(disc, paint);
        // Each segment edge is a line tangent to the inner ring.
        const tangents = [-90.0, 30.0, 150.0];
        canvas.save();
        canvas.clipPath(disc);
        if (colorful) {
          const colors = [
            Color(0xFFF4B400),
            Color(0xFF0F9D58),
            Color(0xFFDB4437),
          ];
          for (var i = 0; i < 3; i++) {
            final t0 = tangents[i], t1 = tangents[(i + 1) % 3];
            final a = dir(t0, inner), b = dir(t1, inner);
            canvas.drawPath(
              Path()..addPolygon([
                a,
                a + unit(t0 + 90) * 2 * u,
                c + unit(t0 + 120) * 3 * u,
                b + unit(t1 + 90) * 2 * u,
                b,
              ], true),
              Paint()..color = colors[i],
            );
          }
        } else {
          final sep = Paint()
            ..color = detail
            ..strokeWidth = .05 * u;
          for (final deg in tangents) {
            final start = dir(deg, inner);
            canvas.drawLine(start, start + unit(deg + 90) * u, sep);
          }
        }
        canvas.restore();
        canvas.drawCircle(
          c,
          inner * u,
          Paint()..color = colorful ? Colors.white : detail,
        );
        canvas.drawCircle(
          c,
          .17 * u,
          colorful ? (Paint()..color = const Color(0xFF4285F4)) : paint,
        );
      case GlyphKind.whatsapp:
        final shape = Path()
          ..addOval(Rect.fromCircle(center: p(.52, .47), radius: .4 * u))
          ..addPolygon([p(.1, .92), p(.18, .62), p(.38, .82)], true);
        canvas.drawPath(shape, paint);
        glossOver(shape);
        canvas.save();
        canvas.translate(.27 * u, .22 * u);
        canvas.scale(.5);
        canvas.drawPath(handsetPath(.17), Paint()..color = detail);
        canvas.restore();
      case GlyphKind.whatsappOutline:
        final ring = Path()
          ..moveTo(.2 * u, .7 * u)
          ..arcTo(
            Rect.fromCircle(center: p(.52, .47), radius: .38 * u),
            2.45,
            5.6,
            false,
          )
          ..lineTo(.12 * u, .9 * u)
          ..close();
        canvas.drawPath(ring, stroke(.07));
        canvas.save();
        canvas.translate(.29 * u, .24 * u);
        canvas.scale(.46);
        canvas.drawPath(handsetPath(.18), paint);
        canvas.restore();
      case GlyphKind.handset:
        final shape = handsetPath(.17);
        canvas.drawPath(shape, paint);
        glossOver(shape);
      case GlyphKind.gear:
      case GlyphKind.gearWrench:
        final gear = Path()..fillType = PathFillType.evenOdd;
        final teeth = Path()
          ..addOval(Rect.fromCircle(center: c, radius: .34 * u));
        for (var i = 0; i < 8; i++) {
          final angle = i * pi / 4;
          final m = Matrix4.identity()
            ..setTranslationRaw(c.dx, c.dy, 0)
            ..rotateZ(angle);
          teeth.addPath(
            Path()..addRRect(
              RRect.fromLTRBR(
                -.08 * u,
                -.46 * u,
                .08 * u,
                -.26 * u,
                Radius.circular(.03 * u),
              ),
            ),
            Offset.zero,
            matrix4: m.storage,
          );
        }
        gear.addPath(teeth, Offset.zero);
        if (kind == GlyphKind.gear) {
          gear.addOval(Rect.fromCircle(center: c, radius: .2 * u));
          canvas.drawPath(gear, paint);
          canvas.drawCircle(c, .11 * u, paint);
        } else {
          canvas.drawPath(gear, paint);
          canvas.save();
          canvas.translate(c.dx, c.dy);
          final wrench = Paint()..color = detail;
          canvas.drawRRect(
            RRect.fromLTRBR(
              -.07 * u,
              -.12 * u,
              .07 * u,
              .42 * u,
              Radius.circular(.07 * u),
            ),
            wrench,
          );
          canvas.drawCircle(Offset(0, -.18 * u), .17 * u, wrench);
          canvas.drawRect(
            Rect.fromLTRB(-.06 * u, -.4 * u, .06 * u, -.18 * u),
            paint,
          );
          canvas.restore();
        }
      case GlyphKind.bulb:
        final line = stroke(.065);
        canvas.drawArc(
          Rect.fromCircle(center: p(.5, .44), radius: .19 * u),
          pi * .75,
          pi * 1.5,
          false,
          line,
        );
        canvas.drawLine(p(.37, .58), p(.42, .7), line);
        canvas.drawLine(p(.63, .58), p(.58, .7), line);
        canvas.drawRRect(
          RRect.fromLTRBR(
            .4 * u,
            .72 * u,
            .6 * u,
            .78 * u,
            Radius.circular(.02 * u),
          ),
          paint,
        );
        canvas.drawRRect(
          RRect.fromLTRBR(
            .43 * u,
            .81 * u,
            .57 * u,
            .87 * u,
            Radius.circular(.02 * u),
          ),
          paint,
        );
        canvas.drawCircle(p(.5, .44), .05 * u, paint);
        canvas.drawLine(p(.5, .48), p(.5, .66), stroke(.04));
        for (final (from, to) in [
          (p(.5, .08), p(.5, .14)),
          (p(.22, .18), p(.27, .23)),
          (p(.78, .18), p(.73, .23)),
          (p(.12, .44), p(.18, .44)),
          (p(.88, .44), p(.82, .44)),
        ]) {
          canvas.drawLine(from, to, stroke(.05));
        }
      case GlyphKind.torch:
        canvas.drawRRect(
          RRect.fromLTRBR(
            .33 * u,
            .3 * u,
            .67 * u,
            .37 * u,
            Radius.circular(.02 * u),
          ),
          paint,
        );
        canvas.drawPath(
          Path()..addPolygon([
            p(.34, .37),
            p(.66, .37),
            p(.6, .5),
            p(.4, .5),
          ], true),
          paint,
        );
        canvas.drawRRect(
          RRect.fromLTRBR(
            .41 * u,
            .5 * u,
            .59 * u,
            .9 * u,
            Radius.circular(.03 * u),
          ),
          paint,
        );
        canvas.drawCircle(p(.5, .64), .03 * u, Paint()..color = detail);
        final ray = Paint()
          ..color = detail
          ..strokeWidth = .045 * u
          ..strokeCap = StrokeCap.round;
        canvas.drawLine(p(.5, .1), p(.5, .2), ray);
        canvas.drawLine(p(.33, .14), p(.39, .22), ray);
        canvas.drawLine(p(.67, .14), p(.61, .22), ray);
      case GlyphKind.gallery:
        final frame = RRect.fromLTRBR(
          .1 * u,
          .16 * u,
          .9 * u,
          .84 * u,
          Radius.circular(.12 * u),
        );
        final shape = Path()
          ..fillType = PathFillType.evenOdd
          ..addRRect(frame)
          ..addRRect(frame.deflate(.07 * u));
        final scene = Path()
          ..addOval(Rect.fromCircle(center: p(.66, .36), radius: .08 * u))
          ..addPolygon([
            p(.17, .77),
            p(.4, .47),
            p(.55, .63),
            p(.66, .52),
            p(.83, .77),
          ], true);
        canvas.drawPath(shape, paint);
        canvas.drawPath(scene, paint);
        glossOver(Path()..addRRect(frame));
      case GlyphKind.clockFace:
        canvas.drawCircle(c, .4 * u, stroke(.08));
        canvas.drawLine(c, p(.5, .26), stroke(.07));
        canvas.drawLine(c, p(.68, .6), stroke(.07));
      case GlyphKind.instagram:
        canvas.drawRRect(
          RRect.fromLTRBR(
            .14 * u,
            .14 * u,
            .86 * u,
            .86 * u,
            Radius.circular(.24 * u),
          ),
          stroke(.08),
        );
        canvas.drawCircle(c, .17 * u, stroke(.08));
        canvas.drawCircle(p(.69, .31), .05 * u, paint);
      case GlyphKind.telegram:
        final plane = Path()
          ..addPolygon([
            p(.08, .48),
            p(.9, .14),
            p(.76, .86),
            p(.5, .68),
            p(.38, .82),
            p(.36, .6),
          ], true);
        canvas.drawPath(plane, paint);
        canvas.drawLine(
          p(.36, .6),
          p(.78, .26),
          Paint()
            ..color = detail
            ..strokeWidth = .04 * u
            ..strokeCap = StrokeCap.round,
        );
      case GlyphKind.spotify:
        canvas.drawCircle(c, .44 * u, paint);
        final arc = Paint()
          ..color = detail
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round;
        for (final (y, w, span) in [
          (.36, .075, .3),
          (.5, .065, .26),
          (.63, .055, .21),
        ]) {
          canvas.drawPath(
            Path()
              ..moveTo((.5 - span) * u, y * u)
              ..quadraticBezierTo(
                .5 * u,
                (y - .1) * u,
                (.5 + span) * u,
                (y + .03) * u,
              ),
            arc..strokeWidth = w * u,
          );
        }
      case GlyphKind.play:
        final cone = Path()
          ..moveTo(.24 * u, .2 * u)
          ..quadraticBezierTo(.2 * u, .5 * u, .24 * u, .8 * u)
          ..lineTo(.86 * u, .52 * u)
          ..close();
        canvas.drawPath(cone, paint);
        glossOver(cone);
      case GlyphKind.youtube:
        final box = RRect.fromLTRBR(
          .08 * u,
          .2 * u,
          .92 * u,
          .8 * u,
          Radius.circular(.16 * u),
        );
        canvas.drawRRect(box, paint);
        canvas.drawPath(
          Path()..addPolygon([p(.42, .36), p(.66, .5), p(.42, .64)], true),
          Paint()..color = detail,
        );
      case GlyphKind.compassFlat:
        canvas.drawCircle(c, .38 * u, stroke(.07));
        final side = Offset(.07 * u, .07 * u);
        canvas.drawPath(
          Path()..addPolygon([
            dir(-45, .27),
            c + side,
            dir(135, .27),
            c - side,
          ], true),
          paint,
        );
        canvas.drawCircle(c, .04 * u, Paint()..color = detail);
      case GlyphKind.facebookF:
        canvas.drawPath(
          Path()
            ..moveTo(.6 * u, 1.2 * u)
            ..lineTo(.6 * u, .44 * u)
            ..quadraticBezierTo(.6 * u, .2 * u, .84 * u, .2 * u)
            ..lineTo(.92 * u, .2 * u),
          stroke(.17)..strokeCap = StrokeCap.butt,
        );
        canvas.drawRect(Rect.fromLTRB(.4 * u, .5 * u, .86 * u, .64 * u), paint);
      case GlyphKind.tiktokNote:
      case GlyphKind.noteSoft:
        Path note(Offset o) => Path()
          ..addRRect(
            RRect.fromLTRBR(
              .47 * u + o.dx,
              .14 * u + o.dy,
              .58 * u + o.dx,
              .66 * u + o.dy,
              Radius.circular(.02 * u),
            ),
          )
          ..addOval(Rect.fromCircle(center: p(.37, .66) + o, radius: .15 * u))
          ..addPath(
            Path()
              ..moveTo(.53 * u + o.dx, .14 * u + o.dy)
              ..quadraticBezierTo(
                .6 * u + o.dx,
                .34 * u + o.dy,
                .82 * u + o.dx,
                .34 * u + o.dy,
              )
              ..lineTo(.82 * u + o.dx, .46 * u + o.dy)
              ..quadraticBezierTo(
                .64 * u + o.dx,
                .46 * u + o.dy,
                .53 * u + o.dx,
                .36 * u + o.dy,
              )
              ..close(),
            Offset.zero,
          );
        final hole = Path()
          ..addOval(Rect.fromCircle(center: p(.37, .66), radius: .06 * u));
        if (kind == GlyphKind.tiktokNote) {
          canvas.drawPath(
            note(Offset(-.03 * u, -.02 * u)),
            Paint()..color = const Color(0xFF25F4EE),
          );
          canvas.drawPath(
            note(Offset(.03 * u, .02 * u)),
            Paint()..color = const Color(0xFFFE2C55),
          );
        }
        canvas.drawPath(
          Path.combine(PathOperation.difference, note(Offset.zero), hole),
          paint,
        );
      case GlyphKind.galleryScene:
        canvas.drawCircle(p(.74, .2), .09 * u, Paint()..color = detail);
        final hills = Path()
          ..moveTo(.1 * u, .82 * u)
          ..lineTo(.34 * u, .4 * u)
          ..quadraticBezierTo(.4 * u, .3 * u, .46 * u, .4 * u)
          ..lineTo(.6 * u, .64 * u)
          ..lineTo(.68 * u, .52 * u)
          ..quadraticBezierTo(.74 * u, .44 * u, .8 * u, .52 * u)
          ..lineTo(.92 * u, .82 * u)
          ..quadraticBezierTo(.92 * u, .86 * u, .86 * u, .86 * u)
          ..lineTo(.16 * u, .86 * u)
          ..quadraticBezierTo(.08 * u, .86 * u, .1 * u, .82 * u)
          ..close();
        canvas.drawPath(hills, paint);
      case GlyphKind.playTik:
        Path play(Offset o) => Path()
          ..moveTo(.32 * u + o.dx, .2 * u + o.dy)
          ..quadraticBezierTo(
            .28 * u + o.dx,
            .5 * u + o.dy,
            .32 * u + o.dx,
            .8 * u + o.dy,
          )
          ..quadraticBezierTo(
            .36 * u + o.dx,
            .84 * u + o.dy,
            .42 * u + o.dx,
            .8 * u + o.dy,
          )
          ..lineTo(.8 * u + o.dx, .56 * u + o.dy)
          ..quadraticBezierTo(
            .86 * u + o.dx,
            .5 * u + o.dy,
            .8 * u + o.dx,
            .44 * u + o.dy,
          )
          ..lineTo(.42 * u + o.dx, .2 * u + o.dy)
          ..quadraticBezierTo(
            .36 * u + o.dx,
            .16 * u + o.dy,
            .32 * u + o.dx,
            .2 * u + o.dy,
          )
          ..close();
        canvas.drawPath(
          play(Offset(-.03 * u, -.02 * u)),
          Paint()..color = const Color(0xFF25F4EE),
        );
        canvas.drawPath(
          play(Offset(.03 * u, .02 * u)),
          Paint()..color = const Color(0xFFFE2C55),
        );
        canvas.drawPath(play(Offset.zero), paint);
      case GlyphKind.gearSpokes:
        final teeth = Paint()..color = ink;
        for (var i = 0; i < 24; i++) {
          canvas.save();
          canvas.translate(c.dx, c.dy);
          canvas.rotate(i * pi / 12);
          canvas.drawRRect(
            RRect.fromLTRBR(
              -.035 * u,
              -.47 * u,
              .035 * u,
              -.36 * u,
              Radius.circular(.015 * u),
            ),
            teeth,
          );
          canvas.restore();
        }
        canvas.drawCircle(c, .37 * u, stroke(.07));
        final spoke = stroke(.05);
        for (final deg in [-90.0, 30.0, 150.0]) {
          canvas.drawLine(c, dir(deg, .34), spoke);
        }
        canvas.drawCircle(c, .08 * u, paint);
        canvas.drawCircle(c, .035 * u, Paint()..color = detail);
      case GlyphKind.calculator:
      case GlyphKind.calculatorBody:
        final body = kind == GlyphKind.calculatorBody;
        if (body) {
          canvas.drawRRect(
            RRect.fromLTRBR(
              .1 * u,
              .08 * u,
              .9 * u,
              .92 * u,
              Radius.circular(.14 * u),
            ),
            paint,
          );
        }
        canvas.drawRRect(
          RRect.fromLTRBR(
            .2 * u,
            (body ? .17 : .14) * u,
            .8 * u,
            (body ? .4 : .42) * u,
            Radius.circular(.06 * u),
          ),
          body ? (Paint()..color = const Color(0xFF555558)) : paint,
        );
        final key = Paint()..color = detail;
        for (final (row, y) in [(0, .58), (1, .76)]) {
          for (var i = 0; i < 4; i++) {
            if (row == 1 && i >= 2) continue;
            canvas.drawCircle(p(.28 + i * .148, y), .062 * u, key);
          }
        }
        canvas.drawRRect(
          RRect.fromLTRBR(
            .52 * u,
            .7 * u,
            .8 * u,
            .82 * u,
            Radius.circular(.06 * u),
          ),
          Paint()
            ..color = body ? const Color(0xFFE8A13A) : const Color(0xFFEBC23F),
        );
      case GlyphKind.brush:
        canvas.drawRRect(
          RRect.fromLTRBR(
            .28 * u,
            .12 * u,
            .72 * u,
            .46 * u,
            Radius.circular(.05 * u),
          ),
          paint,
        );
        final metal = Paint()..color = detail;
        canvas.drawRRect(
          RRect.fromLTRBR(
            .24 * u,
            .46 * u,
            .76 * u,
            .58 * u,
            Radius.circular(.03 * u),
          ),
          metal,
        );
        canvas.drawRRect(
          RRect.fromLTRBR(
            .43 * u,
            .56 * u,
            .57 * u,
            .9 * u,
            Radius.circular(.06 * u),
          ),
          metal,
        );
      case GlyphKind.flowerGear:
        final flower = Path()
          ..addOval(Rect.fromCircle(center: c, radius: .3 * u));
        for (var i = 0; i < 8; i++) {
          flower.addOval(
            Rect.fromCircle(center: dir(i * 45.0, .3), radius: .13 * u),
          );
        }
        canvas.drawPath(flower, paint);
        canvas.drawCircle(c, .17 * u, Paint()..color = detail);
        final hub = Paint()
          ..color = const Color(0xFF3B2F63)
          ..strokeWidth = .045 * u
          ..strokeCap = StrokeCap.round;
        for (final deg in [-90.0, 30.0, 150.0]) {
          canvas.drawLine(c, dir(deg, .13), hub);
        }
        canvas.drawCircle(c, .06 * u, hub);
      case GlyphKind.lensFlat:
        canvas.drawCircle(c, .38 * u, paint);
        canvas.drawCircle(c, .22 * u, Paint()..color = detail);
        canvas.drawCircle(p(.44, .44), .06 * u, paint);
    }
  }

  @override
  bool shouldRepaint(covariant GlyphPainter old) =>
      old.kind != kind ||
      old.ink != ink ||
      old.gradient != gradient ||
      old.detail != detail ||
      old.gloss != gloss ||
      old.colorful != colorful;
}
