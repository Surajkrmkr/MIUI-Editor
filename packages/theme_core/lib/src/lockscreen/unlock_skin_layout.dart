import 'dart:math';

import 'element_enums.dart';
import 'geometry.dart';
import 'lock_element_spec.dart';

enum UnlockSkinShape { circle, tile, pill }

/// Per-skin look of slide/drag unlock controls; also drives layout.
class UnlockSkinSpec {
  const UnlockSkinSpec(
    this.shape, {
    this.thumbWidth = 1,
    this.trails = 0,
    this.shadow = false,
    this.inset = false,
    this.chevrons = false,
    this.carved = false,
    this.glow = false,
    this.gloss = false,
    this.flow = false,
    this.groove = false,
    this.pad = .08,
  });

  final UnlockSkinShape shape;
  final double thumbWidth, pad;
  final int trails;
  final bool shadow, inset, chevrons, carved, glow, gloss, flow, groove;
}

const _slideSpecs = <UnlockSkin, UnlockSkinSpec>{
  UnlockSkin.ghostStack: UnlockSkinSpec(
    UnlockSkinShape.tile,
    trails: 2,
    pad: .1,
  ),
  UnlockSkin.insetTile: UnlockSkinSpec(
    UnlockSkinShape.tile,
    inset: true,
    pad: .1,
  ),
  UnlockSkin.neonOrbs: UnlockSkinSpec(
    UnlockSkinShape.circle,
    trails: 2,
    chevrons: true,
  ),
  UnlockSkin.outlineTile: UnlockSkinSpec(
    UnlockSkinShape.tile,
    shadow: true,
    pad: .12,
  ),
  UnlockSkin.cardStack: UnlockSkinSpec(
    UnlockSkinShape.tile,
    trails: 2,
    shadow: true,
    pad: .07,
  ),
  UnlockSkin.pillStack: UnlockSkinSpec(
    UnlockSkinShape.pill,
    thumbWidth: 1.6,
    trails: 2,
  ),
  UnlockSkin.carved: UnlockSkinSpec(
    UnlockSkinShape.tile,
    trails: 2,
    shadow: true,
    carved: true,
    pad: .1,
  ),
  UnlockSkin.neonLine: UnlockSkinSpec(
    UnlockSkinShape.circle,
    glow: true,
    chevrons: true,
    pad: .2,
  ),
  UnlockSkin.liquidGlass: UnlockSkinSpec(
    UnlockSkinShape.circle,
    gloss: true,
    pad: .1,
  ),
  UnlockSkin.gradientFlow: UnlockSkinSpec(
    UnlockSkinShape.pill,
    thumbWidth: 1.5,
    shadow: true,
    flow: true,
    pad: .1,
  ),
  UnlockSkin.groove: UnlockSkinSpec(
    UnlockSkinShape.circle,
    groove: true,
    shadow: true,
    pad: .2,
  ),
  UnlockSkin.dotTrail: UnlockSkinSpec(UnlockSkinShape.circle, pad: .14),
  UnlockSkin.zipper: UnlockSkinSpec(
    UnlockSkinShape.tile,
    thumbWidth: 1.25,
    pad: .12,
  ),
  UnlockSkin.rulerSlide: UnlockSkinSpec(
    UnlockSkinShape.tile,
    thumbWidth: .62,
    pad: .1,
  ),
  UnlockSkin.sunMoon: UnlockSkinSpec(UnlockSkinShape.circle, pad: .1),
  UnlockSkin.bracketTrack: UnlockSkinSpec(
    UnlockSkinShape.tile,
    thumbWidth: 1.3,
    pad: .14,
  ),
  UnlockSkin.stairSteps: UnlockSkinSpec(UnlockSkinShape.circle, pad: .18),
  UnlockSkin.ropeBead: UnlockSkinSpec(UnlockSkinShape.circle, pad: .12),
  UnlockSkin.slotPlate: UnlockSkinSpec(UnlockSkinShape.tile, pad: .14),
  UnlockSkin.waveTrack: UnlockSkinSpec(UnlockSkinShape.circle, pad: .2),
  UnlockSkin.pixelRun: UnlockSkinSpec(UnlockSkinShape.tile, pad: .14),
};

UnlockSkinSpec unlockSkinSpecOf(LockElementSpec el) =>
    _slideSpecs[el.unlockSkin] ??
    const UnlockSkinSpec(UnlockSkinShape.tile, pad: .1);

/// Geometry of a skinned unlock control in theme pixels (before `scale`),
/// shared by the editor preview and the MAML export.
class UnlockSkinLayout {
  const UnlockSkinLayout._({
    required this.width,
    required this.height,
    required this.thumbY,
    required this.thumbWidth,
    required this.thumbHeight,
    required this.thumbPaintWidth,
    required this.travel,
    required this.iconCenter,
    required this.iconSize,
    required this.textRect,
    this.target,
  });

  factory UnlockSkinLayout.of(LockElementSpec el) {
    final w = el.width, h = el.unlockHeight;
    final hasText = el.unlockText.isNotEmpty;
    final iconScale = el.unlockIconScale.clamp(.2, 1).toDouble();
    if (el.type == ElementType.tapToUnlock) {
      final Pt center;
      final double size;
      final Rect2 text;
      switch (el.unlockSkin) {
        case UnlockSkin.waveNotch:
          center = Pt(w * .6, hasText ? h * .44 : h / 2);
          size = min(w * .6, h * .3) * iconScale;
          text = Rect2.fromLTRB(w * .3, h * .56, w * .95, h * .68);
        case UnlockSkin.gradientPill:
          center = Pt(min(h, w * .4) / 2, h / 2);
          size = min(h, w * .4) * .7 * iconScale;
          text = Rect2.fromLTRB(min(h, w * .4), 0, w - h * .3, h);
        case UnlockSkin.hexBadge ||
            UnlockSkin.gemDiamond ||
            UnlockSkin.radarPulse ||
            UnlockSkin.dialKnob ||
            UnlockSkin.sealScallop:
          final area = hasText ? h * .78 : h;
          center = Pt(w / 2, area / 2);
          size = min(w, area) * .62 * iconScale;
          text = Rect2.fromLTRB(w * .05, h * .8, w * .95, h * .98);
        case UnlockSkin.shieldCrest:
          final area = hasText ? h * .8 : h;
          center = Pt(w / 2, area * .44);
          size = min(w, area) * .55 * iconScale;
          text = Rect2.fromLTRB(w * .12, h * .8, w * .88, h * .98);
        case UnlockSkin.ticketPunch:
          center = Pt(w * .86, h / 2);
          size = min(w * .3, h * .8) * iconScale;
          text = Rect2.fromLTRB(w * .06, h * .18, w * .66, h * .82);
        case UnlockSkin.keycap:
          center = Pt(w / 2, hasText ? h * .3 : h * .42);
          size = min(w, h * .72) * .62 * iconScale;
          text = Rect2.fromLTRB(w * .08, h * .52, w * .92, h * .74);
        case UnlockSkin.domeRay:
          final r = min(w / 2 * .9, h * .66);
          center = Pt(w / 2, h * .92 - r * (hasText ? .6 : .5));
          size = r * .9 * iconScale;
          text = Rect2.fromLTRB(w * .25, h * .92 - r * .32, w * .75, h * .9);
        case UnlockSkin.speechBubble:
          center = Pt(w / 2, hasText ? h * .3 : h * .4);
          size = min(w, h * .7) * .62 * iconScale;
          text = Rect2.fromLTRB(w * .08, h * .46, w * .92, h * .7);
        default:
          final d = min(w, hasText ? h * .7 : h) * .62;
          center = Pt(w / 2, hasText ? h * .38 : h / 2);
          size = d * iconScale;
          text = Rect2.fromLTRB(w * .05, h * .76, w * .95, h * .96);
      }
      return UnlockSkinLayout._(
        width: w,
        height: h,
        thumbY: 0,
        thumbWidth: 0,
        thumbHeight: 0,
        thumbPaintWidth: 0,
        travel: 0,
        iconCenter: center,
        iconSize: size,
        textRect: text,
      );
    }
    if (el.unlockSkin == UnlockSkin.meet) {
      final s = h * .74;
      return UnlockSkinLayout._(
        width: w,
        height: h,
        thumbY: 0,
        thumbWidth: s,
        thumbHeight: s,
        thumbPaintWidth: s,
        travel: max(0, w - s * 1.82),
        iconCenter: Pt(s / 2, s / 2),
        iconSize: s,
        textRect: Rect2.fromLTRB(h * .3, s, w - h * .3, h),
        target: Rect2.fromLTWH(w - s, 0, s, s),
      );
    }
    final spec = unlockSkinSpecOf(el);
    final thumbW = h * spec.thumbWidth;
    final paintW = thumbW + spec.trails * h * .16;
    return UnlockSkinLayout._(
      width: w,
      height: h,
      thumbY: 0,
      thumbWidth: thumbW,
      thumbHeight: h,
      thumbPaintWidth: paintW,
      travel: max(0, w - paintW),
      iconCenter: Pt(thumbW / 2, h / 2),
      iconSize: min(thumbW, h) * (1 - spec.pad * 2) * iconScale,
      textRect: Rect2.fromLTRB(
        paintW + h * .12,
        0,
        w - h * (spec.chevrons ? 1.1 : .25),
        h,
      ),
    );
  }

  final double width, height;
  final double thumbY, thumbWidth, thumbHeight, thumbPaintWidth, travel;
  final Pt iconCenter;
  final double iconSize;
  final Rect2 textRect;
  final Rect2? target;
}
