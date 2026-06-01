import 'icon_texture.dart';

class IconTextureModel {
  final IconTexture type;
  final double scale;
  final double opacity;

  const IconTextureModel({
    required this.type,
    this.scale = 1.0,
    this.opacity = 0.3,
  });

  IconTextureModel copyWith({
    IconTexture? type,
    double? scale,
    double? opacity,
  }) {
    return IconTextureModel(
      type: type ?? this.type,
      scale: scale ?? this.scale,
      opacity: opacity ?? this.opacity,
    );
  }
}
