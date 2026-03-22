import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class IconEditorState {
  const IconEditorState({
    this.margin = 4,
    this.padding = 9,
    this.radius = 10,
    this.borderWidth = 2,
    this.bgColor = Colors.pinkAccent,
    this.bgColor2 = Colors.pinkAccent,
    this.bgGradStart = Alignment.topLeft,
    this.bgGradEnd = Alignment.bottomRight,
    this.iconColor = Colors.white,
    this.borderColor = const Color(0x4DFFFFFF),
    this.accentColor = Colors.pinkAccent,
    this.bgColors = const [Colors.pinkAccent],
    this.randomColors = false,
    this.beforeVectorPath = '',
    this.afterVectorPath = '',
    this.iconAssetsPath = const [],
    this.isExporting = false,
    this.isExported = false,
    this.exportProgress = 0,
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

  Future<void> loadIconAssets() async {
    final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    final names = manifest
        .listAssets()
        .where((k) => k.startsWith('assets/icons/u1/') && k.endsWith('.svg'))
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
