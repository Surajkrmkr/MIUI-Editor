import 'package:flutter/material.dart';

/// AMOLED Purple design tokens — all UI colors live here.
/// Widgets must NOT use Color(0xFF…) or Colors.* directly.
abstract final class AppColors {
  // ── Dark background ───────────────────────────────────────────────────────
  static const Color darkBg0 = Color(0xFF000000);      // true AMOLED black
  static const Color darkBg1 = Color(0xFF0D0B15);      // near-black, violet hint
  static const Color darkBg2 = Color(0xFF110E1A);      // input background

  // ── Dark surface ──────────────────────────────────────────────────────────
  static const Color darkSurface0 = Color(0xFF16111F); // dark purple surface
  static const Color darkSurface1 = Color(0xFF1F1A2D); // elevated purple surface
  static const Color darkSurface2 = Color(0xFF29253C); // overlay purple surface

  // ── Dark border ───────────────────────────────────────────────────────────
  static const Color darkBorder0 = Color(0xFF352F4A);  // purple-toned border
  static const Color darkBorder1 = Color(0xFF433D5A);  // elevated border

  // ── Dark text ─────────────────────────────────────────────────────────────
  static const Color darkTextPrimary   = Color(0xFFFFFFFF);
  static const Color darkTextSecondary = Color(0xFFA1A1AA);
  static const Color darkTextDisabled  = Color(0xFF71717A);

  // ── Light background ──────────────────────────────────────────────────────
  static const Color lightBg0 = Color(0xFFFFFFFF);
  static const Color lightBg1 = Color(0xFFFAFAFA);

  // ── Light surface ─────────────────────────────────────────────────────────
  static const Color lightSurface0 = Color(0xFFF4F4F5);
  static const Color lightSurface1 = Color(0xFFE4E4E7);

  // ── Light border ──────────────────────────────────────────────────────────
  static const Color lightBorder = Color(0xFFD4D4D8);

  // ── Light text ────────────────────────────────────────────────────────────
  static const Color lightTextPrimary   = Color(0xFF18181B);
  static const Color lightTextSecondary = Color(0xFF52525B);

  // ── Purple palette (shared) ───────────────────────────────────────────────
  static const Color purplePrimary   = Color(0xFF9B5CFF);
  static const Color purpleHover     = Color(0xFFB388FF);
  static const Color purplePressed   = Color(0xFF7C3AED);
  static const Color purpleSelection = Color(0xFFC084FC);
  static const Color purpleDark      = Color(0xFF6D28D9);

  // Light mode uses a slightly deeper purple for WCAG contrast on white
  static const Color purplePrimaryLight   = Color(0xFF7C3AED);
  static const Color purpleHoverLight     = Color(0xFF8B5CF6);
  static const Color purpleSelectionLight = Color(0xFFA78BFA);

  // ── Semantic ──────────────────────────────────────────────────────────────
  static const Color successDark   = Color(0xFF22C55E);
  static const Color warningDark   = Color(0xFFF59E0B);
  static const Color errorDark     = Color(0xFFEF4444);
  static const Color successLight  = Color(0xFF16A34A);
  static const Color warningLight  = Color(0xFFD97706);
  static const Color errorLight    = Color(0xFFDC2626);

  // ── Transparent helpers ───────────────────────────────────────────────────
  static const Color transparent = Colors.transparent;

  // ── Alpha overlay colors (theme-agnostic) ─────────────────────────────────
  static Color whiteAlpha(int alpha) => Color.fromARGB(alpha, 255, 255, 255);
  static Color blackAlpha(int alpha) => Color.fromARGB(alpha, 0, 0, 0);
  static Color purpleAlpha(int alpha) =>
      Color.fromARGB(alpha, 155, 92, 255); // purplePrimary RGB
}
