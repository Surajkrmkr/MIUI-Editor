import 'package:flutter/material.dart';

abstract final class ThemeDefaults {
  // Color seeds for a dark desktop app
  static const Color primarySeed = Color(0xFF6750A4);
  static const Color surfaceDark = Color(0xFF1C1B1F);
  static const Color surfaceVariantDark = Color(0xFF2B2930);

  // Standard padding / spacing
  static const double paddingXs = 4;
  static const double paddingSm = 8;
  static const double paddingMd = 16;
  static const double paddingLg = 24;
  static const double paddingXl = 32;

  static const double radiusSm = 8;
  static const double radiusMd = 12;
  static const double radiusLg = 16;

  static const double sidebarWidth = 220;
  static const double panelWidth = 320;
}
