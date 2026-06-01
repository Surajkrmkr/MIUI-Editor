import 'package:flutter/material.dart';
import 'icon_effect.dart';
import 'icon_effect_model.dart';
import 'icon_texture.dart';
import 'icon_texture_model.dart';

class ThemePreset {
  final String id;
  final String name;
  final String description;
  final Color primaryColor;
  final IconEffectModel effect;
  final IconTextureModel texture;

  const ThemePreset({
    required this.id,
    required this.name,
    required this.description,
    required this.primaryColor,
    required this.effect,
    required this.texture,
  });
}

final List<ThemePreset> kThemePresets = [
  ThemePreset(
    id: 'hyperos',
    name: 'HyperOS',
    description: 'Modern, clean, vibrant design.',
    primaryColor: const Color(0xFFFFC300),
    effect: const IconEffectModel(type: IconEffect.holographic, intensity: 0.6),
    texture: const IconTextureModel(type: IconTexture.frostedGlass, opacity: 0.1),
  ),
  ThemePreset(
    id: 'ios',
    name: 'iOS Style',
    description: 'The classic glassmorphism feel.',
    primaryColor: const Color(0xFF007AFF),
    effect: const IconEffectModel(type: IconEffect.glass, blur: 20, intensity: 0.8),
    texture: const IconTextureModel(type: IconTexture.none),
  ),
  ThemePreset(
    id: 'neon',
    name: 'Cyber Neon',
    description: 'High contrast glow for night modes.',
    primaryColor: const Color(0xFF00FF00),
    effect: const IconEffectModel(type: IconEffect.neon, intensity: 1.0),
    texture: const IconTextureModel(type: IconTexture.none),
  ),
  ThemePreset(
    id: 'leather',
    name: 'Premium Leather',
    description: 'Sophisticated tactile feel.',
    primaryColor: const Color(0xFF3E2723),
    effect: const IconEffectModel(type: IconEffect.glass, intensity: 0.4),
    texture: const IconTextureModel(type: IconTexture.leather, opacity: 0.6),
  ),
];
