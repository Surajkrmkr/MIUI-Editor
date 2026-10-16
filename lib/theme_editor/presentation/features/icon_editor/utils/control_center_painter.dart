import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../../../core/utils/wallpaper_palette.dart';
import '../../../../domain/entities/control_center_template.dart';

/// Tile states the control center ships drawables for.
enum TileState { enabled, disabled, restricted, unavailable }

/// Inputs a control center template is drawn from.
class CcStyle {
  const CcStyle({
    required this.template,
    required this.palette,
    this.tileScale = 1,
  });

  final ControlCenterTemplate template;
  final WallpaperPalette palette;

  /// User size multiplier on top of the template's own tile size.
  final double tileScale;

  double get cardRadius => (template.cardRoundness * 100).clamp(24, 100);
}

/// Draws control center tiles, cards and slider colours for every template.
/// Shared by the export use case and the editor preview so they match.
abstract final class ControlCenterPainter {
  static Color _w(double a) => Colors.white.withValues(alpha: a);
  static Color _k(double a) => Colors.black.withValues(alpha: a);
  static Color _mix(Color a, Color b, double t) => Color.lerp(a, b, t)!;

  static Color _deep(Color c) {
    final h = HSLColor.fromColor(c);
    return h.withLightness((h.lightness * .55).clamp(.16, .38)).toColor();
  }

  // ── Geometry ──────────────────────────────────────────────────────────────

  static Rect _tileRect(Rect r, CcStyle s) {
    final f = (s.template.tileScale * s.tileScale).clamp(.45, 1.0);
    if (s.template.shape == CcTileShape.capsule) {
      return Rect.fromCenter(
        center: r.center,
        width: r.width * f,
        height: r.height * f * .64,
      );
    }
    return Rect.fromCenter(
      center: r.center,
      width: r.width * f,
      height: r.height * f,
    );
  }

  static RRect _tileRRect(Rect t, CcTileShape shape) => switch (shape) {
    CcTileShape.circle || CcTileShape.capsule => RRect.fromRectAndRadius(
      t,
      Radius.circular(t.shortestSide / 2),
    ),
    CcTileShape.squircle => RRect.fromRectAndRadius(
      t,
      Radius.circular(t.shortestSide * .34),
    ),
    CcTileShape.roundedSquare => RRect.fromRectAndRadius(
      t,
      Radius.circular(t.shortestSide * .26),
    ),
  };

  /// Toggle tile on a square canvas (188px when exported).
  static void tile(Canvas c, Rect r, TileState state, CcStyle s) {
    final t = _tileRect(r, s);
    _paint(c, _tileRRect(t, s.template.shape), state, s, s.palette.primary);
  }

  /// Wi-Fi / mobile-data card (210px 9-patch when exported).
  static void card(
    Canvas c,
    Rect r,
    TileState state,
    CcStyle s, {
    double? radius,
  }) {
    final inset = r.width * .03;
    final rr = RRect.fromRectAndRadius(
      r.deflate(inset),
      Radius.circular(radius ?? s.cardRadius),
    );
    _paint(c, rr, state, s, s.palette.primary);
  }

  // ── Effects ───────────────────────────────────────────────────────────────

  static void _paint(
    Canvas c,
    RRect rr,
    TileState state,
    CcStyle s,
    Color tint,
  ) {
    final on = state == TileState.enabled;
    final b = rr.outerRect;
    final k = b.shortestSide / 160;
    final p = s.palette;
    final offAlpha = switch (state) {
      TileState.restricted => .6,
      TileState.unavailable => .45,
      _ => 1.0,
    };

    void fill(Color color) => c.drawRRect(rr, Paint()..color = color);
    void grad(List<Color> colors, {Offset? from, Offset? to}) => c.drawRRect(
      rr,
      Paint()
        ..shader = ui.Gradient.linear(
          from ?? b.topLeft,
          to ?? b.bottomRight,
          colors,
          [for (var i = 0; i < colors.length; i++) i / (colors.length - 1)],
        ),
    );
    void rim(Color color, double width) => c.drawRRect(
      rr.deflate(width / 2),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = width
        ..color = color,
    );
    void shadow(double blur, double dy, double alpha) => c.drawRRect(
      rr.shift(Offset(0, dy)),
      Paint()
        ..color = _k(alpha)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, blur),
    );
    void clipped(void Function() draw) {
      c.save();
      c.clipRRect(rr);
      draw();
      c.restore();
    }

    /// Glossy cap over the top part of the shape.
    void gloss(double alpha, {double height = .5}) => clipped(() {
      final cap = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          b.left + b.width * .08,
          b.top + b.height * .05,
          b.width * .84,
          b.height * height,
        ),
        Radius.circular(b.shortestSide * .3),
      );
      c.drawRRect(
        cap,
        Paint()
          ..shader = ui.Gradient.linear(
            cap.outerRect.topCenter,
            cap.outerRect.bottomCenter,
            [_w(alpha), _w(0)],
          ),
      );
    });

    /// Soft inner shading: dark toward bottom-right, light toward top-left.
    void depth(double dark, double light) => clipped(() {
      final ring = Path()
        ..fillType = PathFillType.evenOdd
        ..addRect(b.inflate(40 * k))
        ..addRRect(rr.shift(Offset(-9 * k, -9 * k)));
      c.drawPath(
        ring,
        Paint()
          ..color = _k(dark)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, 10 * k),
      );
      final ring2 = Path()
        ..fillType = PathFillType.evenOdd
        ..addRect(b.inflate(40 * k))
        ..addRRect(rr.shift(Offset(8 * k, 8 * k)));
      c.drawPath(
        ring2,
        Paint()
          ..color = _w(light)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, 9 * k),
      );
    });

    void glitter(int count, double alpha) => clipped(() {
      final rnd = math.Random(7);
      for (var i = 0; i < count; i++) {
        final o = Offset(
          b.left + rnd.nextDouble() * b.width,
          b.top + rnd.nextDouble() * b.height,
        );
        c.drawCircle(
          o,
          (.8 + rnd.nextDouble() * 1.6) * k,
          Paint()..color = _w(alpha * rnd.nextDouble()),
        );
      }
    });

    final restColor = tint;
    switch (s.template) {
      case ControlCenterTemplate.frostedGlass:
        fill(on ? _w(.9) : _w(.16 * offAlpha));
        gloss(on ? .35 : .22);
        rim(_w(on ? .95 : .35 * offAlpha), 3 * k);

      case ControlCenterTemplate.crystalJelly:
        shadow(10 * k, 6 * k, on ? .28 : .18);
        if (on) {
          grad(
            [_mix(restColor, Colors.white, .2), restColor, _deep(restColor)],
            from: b.topLeft,
            to: b.bottomRight,
          );
        } else {
          grad([
            _w(.92 * offAlpha),
            _mix(p.light, Colors.white, .5).withValues(alpha: .85 * offAlpha),
          ]);
        }
        depth(on ? .32 : .12, on ? .35 : .6);
        glitter(on ? 70 : 40, on ? .85 : .7);
        gloss(.75, height: .38);
        rim(_w(.9), 5 * k);

      case ControlCenterTemplate.candyGloss:
        shadow(8 * k, 5 * k, .22);
        final candyOff = _mix(p.secondary, Colors.white, .45);
        grad(
          on
              ? [
                  _mix(restColor, Colors.white, .15),
                  restColor,
                  _deep(restColor),
                ]
              : [
                  _mix(candyOff, Colors.white, .3),
                  candyOff,
                  _mix(candyOff, Colors.black, .12),
                ].map((x) => x.withValues(alpha: offAlpha)).toList(),
        );
        depth(.25, .4);
        gloss(.8, height: .45);
        rim(_w(.95), 8 * k);

      case ControlCenterTemplate.bubblePill:
        if (on) {
          grad([restColor, _mix(restColor, p.secondary, .55)]);
        } else {
          fill(_k(.32 * offAlpha));
        }
        gloss(on ? .4 : .14, height: .45);
        rim(_w(on ? .55 : .18), 2.5 * k);

      case ControlCenterTemplate.softClay:
        shadow(12 * k, 8 * k, .3);
        fill(
          on
              ? restColor
              : _mix(p.light, p.secondary, .12).withValues(alpha: offAlpha),
        );
        depth(on ? .35 : .18, on ? .45 : .75);

      case ControlCenterTemplate.auroraGlass:
        fill(_w(on ? .16 : .08 * offAlpha));
        if (on) {
          grad([
            restColor.withValues(alpha: .85),
            p.secondary.withValues(alpha: .7),
          ]);
        }
        gloss(on ? .45 : .2, height: .42);
        rim(_w(on ? .85 : .3 * offAlpha), 3 * k);

      case ControlCenterTemplate.neonRing:
        fill(_k(on ? .5 : .38 * offAlpha));
        if (on) {
          clipped(() {
            c.drawRRect(
              rr,
              Paint()
                ..style = PaintingStyle.stroke
                ..strokeWidth = 22 * k
                ..color = restColor
                ..maskFilter = MaskFilter.blur(BlurStyle.normal, 8 * k),
            );
          });
          rim(_mix(restColor, Colors.white, .4), 5 * k);
        } else {
          rim(_w(.22 * offAlpha), 3 * k);
        }

      case ControlCenterTemplate.miniDots:
        fill(on ? restColor : _w(.2 * offAlpha));
        if (on) gloss(.3, height: .45);
    }
  }

  // ── Colours for theme_values.xml ─────────────────────────────────────────

  /// Icon, slider and card-text colours that pair with each template.
  static Map<String, Color> colors(CcStyle s) {
    final p = s.palette;
    final darkText = <String, Color>{
      'qs_card_primary_text_enabled_color': _k(.88),
      'qs_card_secondary_text_enabled_color': _k(.5),
    };
    final lightText = <String, Color>{
      'qs_card_primary_text_enabled_color': Colors.white,
      'qs_card_secondary_text_enabled_color': _w(.72),
    };
    Map<String, Color> set({
      required Color iconOn,
      required Color iconOff,
      required Color slider,
      required Color sliderBg,
      required Color sliderIcon,
      required Map<String, Color> text,
      Color? panel,
    }) {
      // Off tiles/cards that are drawn light need dark text.
      final lightOff = switch (s.template) {
        ControlCenterTemplate.crystalJelly ||
        ControlCenterTemplate.candyGloss ||
        ControlCenterTemplate.softClay => true,
        _ => false,
      };
      final offText = lightOff ? _deep(p.secondary) : Colors.white;
      // Long-press panels draw plain circles behind the same icon colours.
      final detailOn = iconOn.computeLuminance() > .6 ? p.primary : _w(.92);
      final detailOff = iconOff.computeLuminance() < .3 ? _w(.82) : _w(.14);
      return {
        'qs_detail_enabled_color': detailOn,
        'qs_detail_disabled_color': detailOff,
        'miui_volume_color_accent': slider,
        'vp_o3_volume_icon_normal': sliderIcon,
        'miui_volume_seekbar_bg_color_cc': sliderBg,
        'toggle_slider_detail_progress_background_color': sliderBg,
        'qs_icon_enabled_color': iconOn,
        // Stock per-tile accents (orange torch, red mute…) follow the template.
        for (final n in [
          'qs_mute_icon_enabled_color',
          'qs_miui_flashlight_icon_enabled_color',
          'qs_power_safer_icon_enabled_color',
          'qs_auto_brightness_icon_enabled_color',
          'qs_paper_mode_icon_enabled_color',
          'qs_miui_cellular_icon_enabled_color',
          'qs_quiet_mode_icon_enabled_color',
        ])
          n: iconOn,
        'qs_icon_disabled_color': iconOff,
        'qs_icon_unavailable_color': iconOff.withValues(alpha: .6),
        'toggle_slider_progress_color': slider,
        'toggle_slider_detail_progress_color': slider,
        'toggle_slider_progress_background_color': sliderBg,
        'toggle_slider_brightness_icon_color': sliderIcon,
        'toggle_slider_volume_icon_color': sliderIcon,
        'miuix_appcompat_sliding_button_bar_on_dark': p.primary,
        'qs_card_primary_text_disabled_color': offText,
        'qs_card_secondary_text_disabled_color': offText.withValues(alpha: .6),
        'qs_card_primary_text_unavailable_color': offText.withValues(alpha: .6),
        'qs_card_secondary_text_unavailable_color': offText.withValues(
          alpha: .6,
        ),
        if (panel != null) 'external_entry_background_color': panel,
        if (panel != null) 'secondary_panel_background_color': panel,
        ...text,
      };
    }

    return switch (s.template) {
      ControlCenterTemplate.frostedGlass => set(
        iconOn: p.primary,
        iconOff: Colors.white,
        slider: _w(.88),
        sliderBg: _w(.16),
        sliderIcon: _deep(p.primary),
        text: darkText,
        panel: _w(.14),
      ),
      ControlCenterTemplate.crystalJelly => set(
        iconOn: Colors.white,
        iconOff: _mix(p.dark, Colors.white, .25),
        slider: _mix(p.primary, Colors.white, .45),
        sliderBg: _k(.32),
        sliderIcon: Colors.white,
        text: lightText,
        panel: _k(.3),
      ),
      ControlCenterTemplate.candyGloss => set(
        iconOn: Colors.white,
        iconOff: _deep(p.secondary),
        slider: _mix(p.primary, Colors.white, .3),
        sliderBg: _k(.28),
        sliderIcon: Colors.white,
        text: lightText,
        panel: _k(.28),
      ),
      ControlCenterTemplate.bubblePill => set(
        iconOn: Colors.white,
        iconOff: Colors.white,
        slider: p.primary,
        sliderBg: _k(.32),
        sliderIcon: Colors.white,
        text: lightText,
      ),
      ControlCenterTemplate.softClay => set(
        iconOn: Colors.white,
        iconOff: _deep(p.secondary),
        slider: p.primary,
        sliderBg: _mix(p.light, Colors.black, .1).withValues(alpha: .8),
        sliderIcon: Colors.white,
        text: lightText,
        panel: p.light.withValues(alpha: .55),
      ),
      ControlCenterTemplate.auroraGlass => set(
        iconOn: Colors.white,
        iconOff: Colors.white,
        slider: _mix(p.primary, p.secondary, .4),
        sliderBg: _w(.12),
        sliderIcon: Colors.white,
        text: lightText,
        panel: _w(.1),
      ),
      ControlCenterTemplate.neonRing => set(
        iconOn: _mix(p.primary, Colors.white, .3),
        iconOff: _w(.75),
        slider: p.primary,
        sliderBg: _k(.45),
        sliderIcon: Colors.white,
        text: lightText,
        panel: _k(.4),
      ),
      ControlCenterTemplate.miniDots => set(
        iconOn: Colors.white,
        iconOff: Colors.white,
        slider: p.primary,
        sliderBg: _w(.16),
        sliderIcon: Colors.white,
        text: lightText,
      ),
    };
  }

  // ── Mini preview for the picker ───────────────────────────────────────────

  /// Small control-center mock-up drawn over the wallpaper (or its palette).
  static void preview(Canvas c, Size size, CcStyle s, {ui.Image? wallpaper}) {
    final r = Offset.zero & size;
    final p = s.palette;
    c.save();
    c.clipRRect(RRect.fromRectAndRadius(r, const Radius.circular(12)));
    if (wallpaper != null) {
      final src =
          Offset.zero &
          Size(wallpaper.width.toDouble(), wallpaper.height.toDouble());
      final fit = applyBoxFit(BoxFit.cover, src.size, size);
      c.drawImageRect(
        wallpaper,
        Alignment.center.inscribe(fit.source, src),
        r,
        Paint()..filterQuality = FilterQuality.medium,
      );
      c.drawRect(r, Paint()..color = _k(.25));
    } else {
      c.drawRect(
        r,
        Paint()
          ..shader = ui.Gradient.linear(r.topLeft, r.bottomRight, [
            p.dark,
            _deep(p.primary),
          ]),
      );
    }

    final colors = ControlCenterPainter.colors(s);
    final pad = size.width * .07;
    final gap = size.width * .045;
    final cardW = (size.width - pad * 2 - gap) / 2;
    final cardH = cardW * .44;
    final cardR = cardH / 2 * s.template.cardRoundness;
    for (var i = 0; i < 2; i++) {
      final cr = Rect.fromLTWH(pad + i * (cardW + gap), pad, cardW, cardH);
      card(
        c,
        cr,
        i == 0 ? TileState.enabled : TileState.disabled,
        s,
        radius: cardR,
      );
      _dot(
        c,
        Offset(cr.left + cardH * .55, cr.center.dy),
        cardH * .14,
        colors[i == 0 ? 'qs_icon_enabled_color' : 'qs_icon_disabled_color']!,
      );
    }

    final sliderTop = pad + cardH + gap;
    final sliderH = cardW * .85;
    final sliderW = (cardW - gap) / 2;
    final media = Rect.fromLTWH(pad, sliderTop, cardW, sliderH);
    c.drawRRect(
      RRect.fromRectAndRadius(media, Radius.circular(cardW * .16)),
      Paint()..color = colors['secondary_panel_background_color'] ?? _k(.3),
    );
    for (var i = 0; i < 2; i++) {
      final sr = Rect.fromLTWH(
        pad + cardW + gap + i * (sliderW + gap),
        sliderTop,
        sliderW,
        sliderH,
      );
      final rr = RRect.fromRectAndRadius(sr, Radius.circular(sliderW * .4));
      c.drawRRect(
        rr,
        Paint()..color = colors['toggle_slider_progress_background_color']!,
      );
      c.save();
      c.clipRRect(rr);
      c.drawRect(
        Rect.fromLTRB(
          sr.left,
          sr.top + sr.height * (i == 0 ? .35 : .55),
          sr.right,
          sr.bottom,
        ),
        Paint()..color = colors['toggle_slider_progress_color']!,
      );
      c.restore();
    }

    final cell = (size.width - pad * 2 - gap * 3) / 4;
    for (var row = 0; row < 2; row++) {
      for (var col = 0; col < 4; col++) {
        final i = row * 4 + col;
        final tr = Rect.fromLTWH(
          pad + col * (cell + gap),
          sliderTop + sliderH + gap + row * (cell + gap),
          cell,
          cell,
        );
        final on = i == 0 || i == 5;
        tile(c, tr, on ? TileState.enabled : TileState.disabled, s);
        _dot(
          c,
          tr.center,
          cell * .13,
          on
              ? colors['qs_icon_enabled_color']!
              : colors['qs_icon_disabled_color']!,
        );
      }
    }
    c.restore();
  }

  static void _dot(Canvas c, Offset o, double r, Color color) =>
      c.drawCircle(o, r, Paint()..color = color);
}
