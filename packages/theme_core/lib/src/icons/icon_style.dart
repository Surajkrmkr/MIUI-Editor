import '../values/alignment2.dart';
import '../values/rgba.dart';
import 'control_center_template.dart';
import 'icon_effect.dart';
import 'icon_shape.dart';
import 'icon_texture.dart';

/// Everything that decides how the app icons and the system UI drawables look.
/// Pure-data twin of the icon editor's state, minus its export-progress flags.
class IconStyle {
  const IconStyle({
    this.margin = 4,
    this.padding = 9,
    this.radius = 10,
    this.borderWidth = 2,
    this.bgColor = _amber,
    this.bgColor2 = _amber,
    this.bgGradStart = Alignment2.topLeft,
    this.bgGradEnd = Alignment2.bottomRight,
    this.bgColors = const [_amber],
    this.randomColors = false,
    this.iconColor = const Rgba(0xFFFFFFFF),
    this.borderColor = const Rgba(0x4DFFFFFF),
    this.accent = _amber,
    this.shape = IconShape.squircle,
    this.effect = IconEffect.none,
    this.effectIntensity = 0.6,
    this.effectBlur = 20.0,
    this.effectElevation = 4.0,
    this.texture = IconTexture.none,
    this.textureScale = 1.0,
    this.textureOpacity = 0.3,
    this.ccTemplate = ControlCenterTemplate.frostedGlass,
  });

  static const _amber = Rgba(0xFFFFC300);

  final double margin, padding, radius, borderWidth;

  /// Gradient endpoints; used when [randomColors] is off.
  final Rgba bgColor, bgColor2;
  final Alignment2 bgGradStart, bgGradEnd;

  /// Palette each icon picks from when [randomColors] is on.
  final List<Rgba> bgColors;
  final bool randomColors;
  final Rgba iconColor, borderColor;

  /// Accent used for system UI colors.
  final Rgba accent;
  final IconShape shape;
  final IconEffect effect;
  final double effectIntensity, effectBlur, effectElevation;
  final IconTexture texture;
  final double textureScale, textureOpacity;
  final ControlCenterTemplate ccTemplate;
}
