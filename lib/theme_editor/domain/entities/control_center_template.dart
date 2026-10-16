/// Shape of the control-center toggle tiles.
enum CcTileShape { circle, squircle, roundedSquare, capsule }

/// Control center (`miui.systemui.plugin`) templates: each one defines the
/// tile effect, tile shape/size and card shape. Colours always come from the
/// wallpaper palette.
enum ControlCenterTemplate {
  frostedGlass(
    'Frosted Glass',
    shape: CcTileShape.circle,
    tileScale: .96,
    cardRoundness: 1,
  ),
  crystalJelly(
    'Crystal Jelly',
    shape: CcTileShape.squircle,
    tileScale: .86,
    cardRoundness: .82,
  ),
  candyGloss(
    'Candy Gloss',
    shape: CcTileShape.roundedSquare,
    tileScale: .84,
    cardRoundness: 1,
  ),
  bubblePill(
    'Bubble Pill',
    shape: CcTileShape.capsule,
    tileScale: .94,
    cardRoundness: 1,
  ),
  softClay(
    'Soft Clay',
    shape: CcTileShape.squircle,
    tileScale: .9,
    cardRoundness: .6,
  ),
  auroraGlass(
    'Aurora Glass',
    shape: CcTileShape.circle,
    tileScale: .9,
    cardRoundness: .7,
  ),
  neonRing(
    'Neon Ring',
    shape: CcTileShape.circle,
    tileScale: .84,
    cardRoundness: .55,
  ),
  miniDots(
    'Mini Dots',
    shape: CcTileShape.circle,
    tileScale: .66,
    cardRoundness: .45,
  );

  const ControlCenterTemplate(
    this.label, {
    required this.shape,
    required this.tileScale,
    required this.cardRoundness,
  });

  final String label;
  final CcTileShape shape;

  /// Visible tile size as a fraction of the 188px tile canvas.
  final double tileScale;

  /// Card corner roundness, 0 (square) … 1 (full pill).
  final double cardRoundness;
}
