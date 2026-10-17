import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:theme_core/theme_core.dart';
import 'package:theme_core/lockscreen_layout.dart' as core;
import '../../adapters.dart';
import '../lock_element.dart';
import '../lock_element_spec_bridge.dart';

export 'package:theme_core/lockscreen_layout.dart'
    show UnlockSkinShape, UnlockSkinSpec;

typedef _Spec = core.UnlockSkinSpec;
typedef _Shape = core.UnlockSkinShape;

_Spec _specOf(LockElement el) => core.unlockSkinSpecOf(el.toSpec());

/// Geometry of a skinned unlock control in theme pixels (before `scale`),
/// shared by the editor preview and the MAML export; the math lives in
/// theme_core, this adds Flutter types for the painters.
class UnlockSkinLayout {
  UnlockSkinLayout.of(LockElement el)
    : this._(core.UnlockSkinLayout.of(el.toSpec()));

  UnlockSkinLayout._(core.UnlockSkinLayout c)
    : width = c.width,
      height = c.height,
      thumbY = c.thumbY,
      thumbWidth = c.thumbWidth,
      thumbHeight = c.thumbHeight,
      thumbPaintWidth = c.thumbPaintWidth,
      travel = c.travel,
      iconCenter = c.iconCenter.toOffset(),
      iconSize = c.iconSize,
      textRect = c.textRect.toRect(),
      target = c.target?.toRect();

  final double width, height;
  final double thumbY, thumbWidth, thumbHeight, thumbPaintWidth, travel;
  final Offset iconCenter;
  final double iconSize;
  final Rect textRect;
  final Rect? target;
}

/// Renders skin parts; `k` converts theme pixels to logical pixels.
class UnlockSkinArt {
  const UnlockSkinArt._();

  static Widget track(LockElement el, double k) {
    final l = UnlockSkinLayout.of(el);
    return SizedBox(
      width: l.width * k,
      height: l.height * k,
      child: CustomPaint(painter: _TrackPainter(el, k)),
    );
  }

  static Widget thumb(LockElement el, double k) {
    final l = UnlockSkinLayout.of(el);
    if (el.unlockSkin == UnlockSkin.meet) {
      return SizedBox.square(
        dimension: l.thumbWidth * k,
        child: _image(
          el.effectiveUnlockIcon == UnlockIcon.customPng
              ? el.unlockIconPath
              : '',
          const _HandPainter(Color(0xFFF2C6A2), Color(0xFFFFFFFF), false),
        ),
      );
    }
    return SizedBox(
      width: l.thumbPaintWidth * k,
      height: l.thumbHeight * k,
      child: CustomPaint(painter: _ThumbPainter(el, k)),
    );
  }

  static Widget target(LockElement el, double k) {
    final l = UnlockSkinLayout.of(el);
    return SizedBox.square(
      dimension: l.target!.width * k,
      child: _image(
        el.unlockTargetPath,
        const _HandPainter(Color(0xFFA9653F), null, true),
      ),
    );
  }

  /// PNG parts written to `unlock/<name><suffix>.png` on export.
  static Map<String, Widget> exportParts(LockElement el) {
    const k = 1 / 3;
    return {
      '_track': track(el, k),
      if (el.type != ElementType.tapToUnlock) '_thumb': thumb(el, k),
      if (el.unlockSkin == UnlockSkin.meet) '_target': target(el, k),
    };
  }

  static Widget _image(String path, CustomPainter fallback) =>
      path.isNotEmpty && File(path).existsSync()
      ? Image.memory(
          File(path).readAsBytesSync(),
          fit: BoxFit.contain,
          gaplessPlayback: true,
          errorBuilder: (_, error, stackTrace) =>
              CustomPaint(painter: fallback),
        )
      : CustomPaint(painter: fallback);
}

/// Editor preview of a skinned unlock control.
class UnlockSkinView extends StatelessWidget {
  const UnlockSkinView({super.key, required this.element});
  final LockElement element;

  @override
  Widget build(BuildContext context) {
    const k = 1 / lockscreenScreenRatio;
    final el = element;
    final l = UnlockSkinLayout.of(el);
    final tap = el.type == ElementType.tapToUnlock;
    final meet = el.unlockSkin == UnlockSkin.meet;
    final icon = meet ? null : _icon(el, l.iconSize * k);
    Widget placeIcon(Offset c) => Positioned(
      left: (c.dx - l.iconSize / 2) * k,
      top: (c.dy - l.iconSize / 2) * k,
      width: l.iconSize * k,
      height: l.iconSize * k,
      child: icon!,
    );
    return SizedBox(
      width: l.width * k,
      height: l.height * k,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          UnlockSkinArt.track(el, k),
          if (l.target case final t?)
            Positioned.fromRect(
              rect: Rect.fromLTWH(
                t.left * k,
                t.top * k,
                t.width * k,
                t.height * k,
              ),
              child: UnlockSkinArt.target(el, k),
            ),
          if (el.unlockText.isNotEmpty)
            Positioned.fromRect(
              rect: Rect.fromLTRB(
                l.textRect.left * k,
                l.textRect.top * k,
                l.textRect.right * k,
                l.textRect.bottom * k,
              ),
              child: Center(
                child: Text(
                  el.unlockText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: el.unlockTextFontSize,
                    color: el.color,
                    fontWeight: el.fontWeight,
                    letterSpacing: el.unlockTextFontSize * .12,
                    height: 1,
                  ),
                ),
              ),
            ),
          if (tap) ...[
            if (icon != null) placeIcon(l.iconCenter),
          ] else
            Positioned(
              left: 0,
              top: l.thumbY * k,
              child: SizedBox(
                width: l.thumbPaintWidth * k,
                height: l.thumbHeight * k,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    UnlockSkinArt.thumb(el, k),
                    if (icon != null) placeIcon(l.iconCenter),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  static Widget? _icon(LockElement el, double size) {
    final kind = el.effectiveUnlockIcon;
    if (kind == UnlockIcon.none) return null;
    if (kind == UnlockIcon.customPng) {
      return el.unlockIconPath.isNotEmpty &&
              File(el.unlockIconPath).existsSync()
          ? Image.memory(
              File(el.unlockIconPath).readAsBytesSync(),
              fit: BoxFit.contain,
              gaplessPlayback: true,
              errorBuilder: (_, error, stackTrace) =>
                  const Icon(Icons.broken_image_outlined),
            )
          : const Icon(Icons.image_outlined);
    }
    return FittedBox(
      child: Icon(kind.icon, color: el.color, size: size),
    );
  }
}

Color _alpha(Color c, double opacity) =>
    c.withValues(alpha: (c.a * opacity).clamp(0, 1));

Color _lighten(Color c, double amount) {
  final hsl = HSLColor.fromColor(c);
  return hsl.withLightness((hsl.lightness + amount).clamp(0, 1)).toColor();
}

class _TrackPainter extends CustomPainter {
  _TrackPainter(this.el, this.k);
  final LockElement el;
  final double k;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final bgOpacity = el.unlockBackgroundOpacity.clamp(0, 1).toDouble();
    final base = _alpha(el.colorSecondary, bgOpacity);
    final blend = _alpha(
      Color.lerp(el.colorSecondary, el.unlockAccent, .45)!,
      bgOpacity,
    );
    final fill = Paint()
      ..shader = LinearGradient(
        colors: [base, blend],
      ).createShader(Offset.zero & size);
    final border = el.borderWidth * k;

    switch (el.unlockSkin) {
      case UnlockSkin.waveNotch:
        final path = Path()
          ..moveTo(w, 0)
          ..cubicTo(w, h * .16, w * .62, h * .2, w * .32, h * .3)
          ..cubicTo(w * .02, h * .4, w * .02, h * .6, w * .32, h * .7)
          ..cubicTo(w * .62, h * .8, w, h * .84, w, h)
          ..close();
        canvas.drawPath(path, fill);
        if (border > 0) {
          canvas.drawPath(
            path,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = border
              ..color = el.borderColor,
          );
        }
        return;
      case UnlockSkin.glowOrb:
      case UnlockSkin.ringButton:
        final l = UnlockSkinLayout.of(el);
        final c = l.iconCenter * k;
        final hasText = el.unlockText.isNotEmpty;
        final r = min(w, hasText ? h * .7 : h) * .31;
        final glow = el.unlockSkin == UnlockSkin.glowOrb;
        for (var i = 3; i >= 1; i--) {
          final ringR = r * (1 + i * (glow ? .16 : .1));
          if (ringR > min(w / 2, hasText ? h * .38 : h / 2)) continue;
          canvas.drawCircle(
            c,
            ringR,
            Paint()
              ..style = glow ? PaintingStyle.fill : PaintingStyle.stroke
              ..strokeWidth = r * .04
              ..color = _alpha(el.unlockAccent, (glow ? .18 : .4) / i),
          );
        }
        final orb = Rect.fromCircle(center: c, radius: r);
        canvas.drawCircle(
          c,
          r,
          Paint()
            ..shader =
                (glow
                        ? RadialGradient(
                            center: const Alignment(-.3, -.4),
                            colors: [
                              _alpha(_lighten(el.unlockAccent, .18), bgOpacity),
                              base,
                            ],
                          )
                        : LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [base, blend],
                          ))
                    .createShader(orb),
        );
        if (border > 0 || !glow) {
          canvas.drawCircle(
            c,
            r,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = max(border, r * .04)
              ..color = el.borderColor,
          );
        }
        return;
      default:
    }

    final radius = Radius.circular(
      min(el.effectiveUnlockCornerRadius * k, h / 2),
    );
    final fx = _specOf(el);
    final rrect = RRect.fromRectAndRadius(
      (Offset.zero & size).deflate(fx.glow ? h * .1 : 0),
      radius,
    );
    canvas.drawRRect(
      rrect,
      fx.flow
          ? (Paint()
              ..shader = LinearGradient(
                colors: [
                  base,
                  _alpha(el.unlockAccent, bgOpacity),
                  _alpha(el.borderColor, bgOpacity),
                ],
              ).createShader(Offset.zero & size))
          : fill,
    );
    if (fx.flow) {
      canvas.save();
      canvas.clipRRect(rrect);
      canvas.translate(w * .62, h / 2);
      canvas.rotate(.5);
      canvas.drawRect(
        Rect.fromCenter(center: Offset.zero, width: h * .5, height: h * 4),
        Paint()
          ..color = Colors.white.withValues(alpha: .16)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, h * .12),
      );
      canvas.restore();
    }
    if (fx.glow) {
      for (final (blur, width, alpha) in [
        (h * .06, h * .05, .7),
        (0.0, h * .016, 1.0),
      ]) {
        canvas.drawRRect(
          rrect,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = width
            ..maskFilter = blur == 0
                ? null
                : MaskFilter.blur(BlurStyle.normal, blur)
            ..shader = LinearGradient(
              colors: [
                for (final c in [el.unlockAccent, el.borderColor])
                  (blur == 0 ? Color.lerp(c, Colors.white, .45)! : c)
                      .withValues(alpha: alpha),
              ],
            ).createShader(Offset.zero & size),
        );
      }
    }
    if (fx.gloss) {
      canvas.save();
      canvas.clipRRect(rrect);
      canvas.drawRect(
        Rect.fromLTWH(0, 0, w, h * .5),
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white.withValues(alpha: .28),
              Colors.white.withValues(alpha: 0),
            ],
          ).createShader(Rect.fromLTWH(0, 0, w, h * .5)),
      );
      canvas.restore();
      canvas.drawRRect(
        rrect.deflate(h * .01),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = h * .02
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white.withValues(alpha: .7),
              Colors.white.withValues(alpha: .05),
              Colors.white.withValues(alpha: .3),
            ],
          ).createShader(Offset.zero & size),
      );
    }
    if (fx.groove) {
      final y = h / 2;
      final groove = RRect.fromLTRBR(
        h * .5,
        y - h * .05,
        w - h * .5,
        y + h * .05,
        Radius.circular(h * .05),
      );
      canvas.drawRRect(
        groove,
        Paint()..color = Colors.black.withValues(alpha: .45),
      );
      canvas.drawRRect(
        groove.shift(Offset(0, h * .02)),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = h * .01
          ..color = Colors.white.withValues(alpha: .12),
      );
      canvas.drawCircle(
        Offset(w - h / 2, y),
        h * .26,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = h * .025
          ..color = _alpha(el.unlockAccent, .8),
      );
    }

    if (el.unlockSkin == UnlockSkin.gradientPill) {
      final iconBox = min(h, w * .4);
      canvas.drawCircle(
        Offset(iconBox / 2, h / 2),
        iconBox * .36,
        Paint()..color = _alpha(el.color, .16),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, w, h / 2), radius),
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white.withValues(alpha: .14),
              Colors.white.withValues(alpha: 0),
            ],
          ).createShader(Rect.fromLTWH(0, 0, w, h / 2)),
      );
    }

    final spec = _specOf(el);
    if (spec.carved) {
      canvas.save();
      canvas.clipRRect(rrect);
      final ring = Path()
        ..fillType = PathFillType.evenOdd
        ..addRect(Rect.fromLTWH(-h, -h, w + h * 2, h * 3))
        ..addRRect(rrect.shift(Offset(0, h * .04)));
      canvas.drawPath(
        ring,
        Paint()
          ..color = Colors.black.withValues(alpha: .55)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, h * .06),
      );
      canvas.restore();
    }
    if (border > 0) {
      canvas.drawRRect(
        rrect.deflate(border / 2),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = border
          ..shader = LinearGradient(
            colors: [
              el.borderColor,
              el.unlockSkin == UnlockSkin.neonOrbs
                  ? el.unlockAccent
                  : el.borderColor,
            ],
          ).createShader(Offset.zero & size),
      );
    }
    if (spec.chevrons) {
      final chevron = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = h * .035
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;
      for (var i = 0; i < 4; i++) {
        final x = w - h * 1.0 + i * h * .14;
        chevron.color = _alpha(el.color, .3 + i * .23);
        canvas.drawPath(
          Path()
            ..moveTo(x, h * .42)
            ..lineTo(x + h * .07, h * .5)
            ..lineTo(x, h * .58),
          chevron,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _TrackPainter old) => old.el != el || old.k != k;
}

class _ThumbPainter extends CustomPainter {
  _ThumbPainter(this.el, this.k);
  final LockElement el;
  final double k;

  @override
  void paint(Canvas canvas, Size size) {
    final spec = _specOf(el);
    final h = size.height;
    final pad = h * spec.pad;
    final thumbW = h * spec.thumbWidth;
    final step = h * .16;
    final opacity = el.unlockThumbOpacity.clamp(0, 1).toDouble();

    RRect shape(int i) {
      final rect = Rect.fromLTWH(
        i * step + pad,
        pad,
        thumbW - pad * 2,
        h - pad * 2,
      );
      return RRect.fromRectAndRadius(
        rect,
        Radius.circular(switch (spec.shape) {
          _Shape.circle || _Shape.pill => rect.shortestSide / 2,
          _Shape.tile => min(
            rect.shortestSide * .24,
            max(0, el.effectiveUnlockCornerRadius * k - pad),
          ),
        }),
      );
    }

    for (var i = spec.trails; i >= 1; i--) {
      final r = shape(i);
      final color = _alpha(
        Color.lerp(el.unlockAccent, el.colorSecondary, .22 * i)!,
        opacity * (1 - .3 * i),
      );
      if (spec.shadow) {
        canvas.drawShadow(Path()..addRRect(r), Colors.black, h * .04, false);
      }
      canvas.drawRRect(r, Paint()..color = color);
    }

    final front = shape(0);
    if (spec.glow) {
      final o = front.outerRect;
      canvas.drawCircle(
        o.center,
        o.width / 2,
        Paint()
          ..color = _alpha(el.unlockAccent, .8 * opacity)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, h * .07),
      );
      canvas.drawCircle(
        o.center,
        o.width / 2,
        Paint()..color = _alpha(el.colorSecondary, opacity),
      );
      canvas.drawCircle(
        o.center,
        o.width / 2 - h * .01,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = h * .025
          ..color = Color.lerp(el.unlockAccent, Colors.white, .4)!,
      );
      return;
    }
    if (spec.gloss || spec.groove) {
      final o = front.outerRect;
      if (spec.shadow) {
        canvas.drawShadow(Path()..addOval(o), Colors.black, h * .05, false);
      }
      canvas.drawOval(
        o,
        Paint()
          ..shader =
              (spec.groove
                      ? SweepGradient(
                          colors: [
                            _lighten(el.unlockAccent, .25),
                            _lighten(el.unlockAccent, -.15),
                            _lighten(el.unlockAccent, .25),
                            _lighten(el.unlockAccent, -.15),
                            _lighten(el.unlockAccent, .25),
                          ],
                        )
                      : RadialGradient(
                          center: const Alignment(-.3, -.4),
                          colors: [
                            _alpha(_lighten(el.unlockAccent, .3), opacity),
                            _alpha(el.unlockAccent, opacity),
                            _alpha(_lighten(el.unlockAccent, -.15), opacity),
                          ],
                          stops: const [0, .6, 1],
                        ))
                  .createShader(o),
      );
      if (spec.gloss) {
        canvas.drawOval(
          Rect.fromLTWH(
            o.left + o.width * .2,
            o.top + o.height * .08,
            o.width * .6,
            o.height * .32,
          ),
          Paint()
            ..shader = LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.white.withValues(alpha: .75),
                Colors.white.withValues(alpha: 0),
              ],
            ).createShader(o),
        );
      } else {
        canvas.drawCircle(
          o.center,
          o.width * .18,
          Paint()..color = _lighten(el.unlockAccent, -.2),
        );
      }
      return;
    }
    if (spec.shadow) {
      canvas.drawShadow(Path()..addRRect(front), Colors.black, h * .06, false);
    }
    canvas.drawRRect(
      front,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: spec.flow
              ? [
                  Colors.white.withValues(alpha: opacity),
                  Color.lerp(
                    Colors.white,
                    el.unlockAccent,
                    .25,
                  )!.withValues(alpha: opacity),
                ]
              : [
                  _alpha(
                    _lighten(el.unlockAccent, spec.inset ? -.05 : .12),
                    opacity,
                  ),
                  _alpha(el.unlockAccent, opacity),
                ],
        ).createShader(front.outerRect),
    );
    if (spec.inset) {
      canvas.save();
      canvas.clipRRect(front);
      canvas.drawPath(
        Path()
          ..fillType = PathFillType.evenOdd
          ..addRect(front.outerRect.inflate(h))
          ..addRRect(front.shift(Offset(h * .02, h * .03))),
        Paint()
          ..color = Colors.black.withValues(alpha: .45)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, h * .05),
      );
      canvas.restore();
    }
    if (spec.carved) {
      canvas.drawRRect(
        front.deflate(h * .01),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = h * .015
          ..color = Colors.white.withValues(alpha: .25),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ThumbPainter old) => old.el != el || old.k != k;
}

/// Default flat hand used by the "meet" drag skin; points right unless mirrored.
class _HandPainter extends CustomPainter {
  const _HandPainter(this.skin, this.cuff, this.mirror);
  final Color skin;
  final Color? cuff;
  final bool mirror;

  @override
  void paint(Canvas canvas, Size size) {
    final u = size.width;
    if (mirror) {
      canvas.translate(u, 0);
      canvas.scale(-1, 1);
    }
    final shade = Color.lerp(skin, Colors.black, .18)!;
    final fill = Paint()..color = skin;
    RRect capsule(double l, double t, double r, double b) => RRect.fromLTRBR(
      l * u,
      t * u,
      r * u,
      b * u,
      Radius.circular((b - t) * u / 2),
    );

    // Fingers, bottom to top so upper ones overlap.
    final fingers = [
      capsule(.38, .6, .78, .68),
      capsule(.38, .53, .86, .61),
      capsule(.38, .46, .9, .54),
      capsule(.38, .39, .88, .47),
    ];
    for (final f in fingers) {
      canvas.drawRRect(f, fill);
      canvas.drawLine(
        Offset(f.left + f.width * .35, f.bottom - u * .005),
        Offset(f.right - f.height / 2, f.bottom - u * .005),
        Paint()
          ..color = shade
          ..strokeWidth = u * .008
          ..strokeCap = StrokeCap.round,
      );
    }
    canvas.drawRRect(
      RRect.fromLTRBR(
        .04 * u,
        .37 * u,
        .5 * u,
        .69 * u,
        Radius.circular(u * .1),
      ),
      fill,
    );
    canvas.save();
    canvas.translate(.42 * u, .4 * u);
    canvas.rotate(-.55);
    canvas.drawRRect(
      RRect.fromLTRBR(0, -.04 * u, .22 * u, .04 * u, Radius.circular(.04 * u)),
      fill,
    );
    canvas.restore();
    if (cuff case final c?) {
      canvas.drawRect(
        Rect.fromLTWH(0, .35 * u, .05 * u, .36 * u),
        Paint()..color = c,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _HandPainter old) =>
      old.skin != skin || old.cuff != cuff || old.mirror != mirror;
}
