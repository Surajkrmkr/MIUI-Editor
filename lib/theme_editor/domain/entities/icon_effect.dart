enum IconEffect {
  none,
  glass,
  neon,
  liquid,
  holographic,
  glitch,
  ember,
  ocean,
  cyberpunk,
  golden,
  frost;

  String get label => switch (this) {
        none => 'None',
        glass => 'Glass',
        neon => 'Neon',
        liquid => 'Liquid',
        holographic => 'Holo',
        glitch => 'Glitch',
        ember => 'Ember',
        ocean => 'Ocean',
        cyberpunk => 'Cyber',
        golden => 'Golden',
        frost => 'Frost',
      };
}
