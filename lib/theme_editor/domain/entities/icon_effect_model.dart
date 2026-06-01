import 'package:flutter/material.dart';
import 'icon_effect.dart';

class IconEffectModel {
  final IconEffect type;
  final double intensity;
  final Color? primaryColor;
  final double blur;
  final double elevation;

  const IconEffectModel({
    required this.type,
    this.intensity = 0.5,
    this.primaryColor,
    this.blur = 10.0,
    this.elevation = 4.0,
  });

  IconEffectModel copyWith({
    IconEffect? type,
    double? intensity,
    Color? primaryColor,
    double? blur,
    double? elevation,
  }) {
    return IconEffectModel(
      type: type ?? this.type,
      intensity: intensity ?? this.intensity,
      primaryColor: primaryColor ?? this.primaryColor,
      blur: blur ?? this.blur,
      elevation: elevation ?? this.elevation,
    );
  }
}
