enum IconEffect {
  none,
  liquidGlass,
  glass,
  clay,
  softUi,
  gloss,
  aurora,
  holographic,
  chrome,
  gold,
  neon,
  bevel,
  spotlight;

  String get label => switch (this) {
    none => 'None',
    liquidGlass => 'Liquid Glass',
    glass => 'Frosted',
    clay => 'Clay',
    softUi => 'Soft UI',
    gloss => 'Gloss',
    aurora => 'Aurora',
    holographic => 'Holo',
    chrome => 'Chrome',
    gold => 'Gold',
    neon => 'Neon',
    bevel => 'Bevel',
    spotlight => 'Spotlight',
  };
}
