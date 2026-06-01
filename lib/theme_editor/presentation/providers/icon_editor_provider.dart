import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/icon_effect.dart';
import '../../domain/entities/icon_shape.dart';
import '../../domain/entities/icon_texture.dart';
import 'user_profile_provider.dart';

class IconEditorState {
  const IconEditorState({
    this.margin = 4,
    this.padding = 9,
    this.radius = 10,
    this.borderWidth = 2,
    this.bgColor = const Color(0xFFFFC300),
    this.bgColor2 = const Color(0xFFFFC300),
    this.bgGradStart = Alignment.topLeft,
    this.bgGradEnd = Alignment.bottomRight,
    this.iconColor = Colors.white,
    this.borderColor = const Color(0x4DFFFFFF),
    this.accentColor = const Color(0xFFFFC300),
    this.bgColors = const [Color(0xFFFFC300)],
    this.randomColors = false,
    this.beforeVectorPath = '',
    this.afterVectorPath = '',
    this.iconAssetsPath = const [],
    this.isExporting = false,
    this.isExported = false,
    this.exportProgress = 0,
    this.shape = IconShape.squircle,
    this.effect = IconEffect.none,
    this.texture = IconTexture.none,
    this.effectIntensity = 0.6,
    this.effectBlur = 20.0,
    this.effectElevation = 4.0,
    this.textureScale = 1.0,
    this.textureOpacity = 0.3,
  });

  final double margin, padding, radius, borderWidth;
  final Color bgColor, bgColor2, iconColor, borderColor, accentColor;
  final AlignmentGeometry bgGradStart, bgGradEnd;
  final List<Color> bgColors;
  final bool randomColors;
  final String beforeVectorPath, afterVectorPath;
  final List<dynamic> iconAssetsPath;
  final bool isExporting, isExported;
  final int exportProgress;
  final IconShape shape;
  final IconEffect effect;
  final IconTexture texture;
  final double effectIntensity, effectBlur, effectElevation;
  final double textureScale, textureOpacity;

  IconEditorState copyWith({
    double? margin,
    double? padding,
    double? radius,
    double? borderWidth,
    Color? bgColor,
    Color? bgColor2,
    Color? iconColor,
    Color? borderColor,
    Color? accentColor,
    AlignmentGeometry? bgGradStart,
    AlignmentGeometry? bgGradEnd,
    List<Color>? bgColors,
    bool? randomColors,
    String? beforeVectorPath,
    String? afterVectorPath,
    List<dynamic>? iconAssetsPath,
    bool? isExporting,
    bool? isExported,
    int? exportProgress,
    IconShape? shape,
    IconEffect? effect,
    IconTexture? texture,
    double? effectIntensity,
    double? effectBlur,
    double? effectElevation,
    double? textureScale,
    double? textureOpacity,
  }) =>
      IconEditorState(
        margin: margin ?? this.margin,
        padding: padding ?? this.padding,
        radius: radius ?? this.radius,
        borderWidth: borderWidth ?? this.borderWidth,
        bgColor: bgColor ?? this.bgColor,
        bgColor2: bgColor2 ?? this.bgColor2,
        iconColor: iconColor ?? this.iconColor,
        borderColor: borderColor ?? this.borderColor,
        accentColor: accentColor ?? this.accentColor,
        bgGradStart: bgGradStart ?? this.bgGradStart,
        bgGradEnd: bgGradEnd ?? this.bgGradEnd,
        bgColors: bgColors ?? this.bgColors,
        randomColors: randomColors ?? this.randomColors,
        beforeVectorPath: beforeVectorPath ?? this.beforeVectorPath,
        afterVectorPath: afterVectorPath ?? this.afterVectorPath,
        iconAssetsPath: iconAssetsPath ?? this.iconAssetsPath,
        isExporting: isExporting ?? this.isExporting,
        isExported: isExported ?? this.isExported,
        exportProgress: exportProgress ?? this.exportProgress,
        shape: shape ?? this.shape,
        effect: effect ?? this.effect,
        texture: texture ?? this.texture,
        effectIntensity: effectIntensity ?? this.effectIntensity,
        effectBlur: effectBlur ?? this.effectBlur,
        effectElevation: effectElevation ?? this.effectElevation,
        textureScale: textureScale ?? this.textureScale,
        textureOpacity: textureOpacity ?? this.textureOpacity,
      );
}

class IconEditorNotifier extends Notifier<IconEditorState> {
  @override
  IconEditorState build() => const IconEditorState();

  void setMargin(double v) => state = state.copyWith(margin: v);
  void setPadding(double v) => state = state.copyWith(padding: v);
  void setRadius(double v) => state = state.copyWith(radius: v);
  void setBorderWidth(double v) => state = state.copyWith(borderWidth: v);
  void setBgColor(Color c) => state = state.copyWith(bgColor: c);
  void setBgColor2(Color c) => state = state.copyWith(bgColor2: c);
  void setIconColor(Color c) => state = state.copyWith(iconColor: c);
  void setBorderColor(Color c) => state = state.copyWith(borderColor: c);
  void setAccentColor(Color c) => state = state.copyWith(accentColor: c);
  void setBgGradStart(AlignmentGeometry a) =>
      state = state.copyWith(bgGradStart: a);
  void setBgGradEnd(AlignmentGeometry a) =>
      state = state.copyWith(bgGradEnd: a);
  void setBgColors(List<Color> c) => state = state.copyWith(bgColors: c);
  void setRandomColors(bool v) => state = state.copyWith(randomColors: v);
  void setBeforeVector(String p) => state = state.copyWith(beforeVectorPath: p);
  void setAfterVector(String p) => state = state.copyWith(afterVectorPath: p);
  void setIconAssetsPath(List<dynamic> p) =>
      state = state.copyWith(iconAssetsPath: p);
  void setIconShape(IconShape s) => state = state.copyWith(shape: s);
  void setIconEffect(IconEffect e) => state = state.copyWith(effect: e);
  void setIconTexture(IconTexture t) => state = state.copyWith(texture: t);
  void setEffectIntensity(double v) => state = state.copyWith(effectIntensity: v);
  void setEffectBlur(double v) => state = state.copyWith(effectBlur: v);
  void setEffectElevation(double v) => state = state.copyWith(effectElevation: v);
  void setTextureScale(double v) => state = state.copyWith(textureScale: v);
  void setTextureOpacity(double v) => state = state.copyWith(textureOpacity: v);

  Future<void> loadIconAssets() async {
    final profile = ref.read(activeUserProfileProvider);
    final iconFolder = profile?.iconFolder ?? 'u1';
    final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    final names = manifest
        .listAssets()
        .where((k) =>
            k.startsWith('assets/icons/$iconFolder/') && k.endsWith('.svg'))
        .map((k) => k.split('/').last.replaceAll('.svg', ''))
        .toList();
    setIconAssetsPath(names);
  }

  void setExporting(bool v) => state = state.copyWith(isExporting: v);
  void setExported(bool v) => state = state.copyWith(isExported: v);
  void setProgress(int v) => state = state.copyWith(exportProgress: v);
}

final iconEditorProvider =
    NotifierProvider<IconEditorNotifier, IconEditorState>(
        IconEditorNotifier.new);
