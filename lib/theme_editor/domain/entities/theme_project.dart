import 'package:flutter/material.dart';

/// The root domain entity — everything the user is editing.
class ThemeProject {
  const ThemeProject({
    required this.name,
    required this.author,
    required this.version,
    required this.projectPath,
    required this.iconSet,
    required this.colorEntries,
    required this.fonts,
    required this.lockscreen,
  });

  final String name;
  final String author;
  final String version;
  final String projectPath;
  final IconSetEntity iconSet;
  final List<ColorEntry> colorEntries;
  final List<FontEntry> fonts;
  final LockscreenEntity lockscreen;

  ThemeProject copyWith({
    String? name,
    String? author,
    String? version,
    String? projectPath,
    IconSetEntity? iconSet,
    List<ColorEntry>? colorEntries,
    List<FontEntry>? fonts,
    LockscreenEntity? lockscreen,
  }) =>
      ThemeProject(
        name: name ?? this.name,
        author: author ?? this.author,
        version: version ?? this.version,
        projectPath: projectPath ?? this.projectPath,
        iconSet: iconSet ?? this.iconSet,
        colorEntries: colorEntries ?? this.colorEntries,
        fonts: fonts ?? this.fonts,
        lockscreen: lockscreen ?? this.lockscreen,
      );
}

// ─── Icon ────────────────────────────────────────────────────────────────────

class IconSetEntity {
  const IconSetEntity({
    required this.variant,
    required this.icons,
  });

  final IconVariant variant;
  final List<IconEntry> icons;

  IconSetEntity copyWith({IconVariant? variant, List<IconEntry>? icons}) =>
      IconSetEntity(
        variant: variant ?? this.variant,
        icons: icons ?? this.icons,
      );
}

enum IconVariant { u1, u2, u3, u4 }

class IconEntry {
  const IconEntry({
    required this.packageName,
    required this.componentName,
    required this.drawableName,
    this.customImagePath,
  });

  final String packageName;
  final String componentName;
  final String drawableName;
  final String? customImagePath;

  bool get isCustomized => customImagePath != null;

  IconEntry copyWith({
    String? packageName,
    String? componentName,
    String? drawableName,
    String? customImagePath,
  }) =>
      IconEntry(
        packageName: packageName ?? this.packageName,
        componentName: componentName ?? this.componentName,
        drawableName: drawableName ?? this.drawableName,
        customImagePath: customImagePath ?? this.customImagePath,
      );
}

// ─── Color ───────────────────────────────────────────────────────────────────

class ColorEntry {
  const ColorEntry({required this.name, required this.color});

  final String name;
  final Color color;

  ColorEntry copyWith({String? name, Color? color}) =>
      ColorEntry(name: name ?? this.name, color: color ?? this.color);

  @override
  bool operator ==(Object other) =>
      other is ColorEntry && other.name == name && other.color == color;

  @override
  int get hashCode => Object.hash(name, color);
}

// ─── Font ────────────────────────────────────────────────────────────────────

class FontEntry {
  const FontEntry({
    required this.name,
    required this.path,
    this.isDownloaded = false,
  });

  final String name;
  final String path;
  final bool isDownloaded;

  FontEntry copyWith({String? name, String? path, bool? isDownloaded}) =>
      FontEntry(
        name: name ?? this.name,
        path: path ?? this.path,
        isDownloaded: isDownloaded ?? this.isDownloaded,
      );
}

// ─── Lockscreen ──────────────────────────────────────────────────────────────

class LockscreenEntity {
  const LockscreenEntity({
    this.wallpaperPath,
    required this.clockStyle,
    required this.weatherIconVariant,
  });

  final String? wallpaperPath;
  final ClockStyle clockStyle;
  final String weatherIconVariant;

  LockscreenEntity copyWith({
    String? wallpaperPath,
    ClockStyle? clockStyle,
    String? weatherIconVariant,
  }) =>
      LockscreenEntity(
        wallpaperPath: wallpaperPath ?? this.wallpaperPath,
        clockStyle: clockStyle ?? this.clockStyle,
        weatherIconVariant: weatherIconVariant ?? this.weatherIconVariant,
      );
}

enum ClockStyle { digital, analog, minimal }
