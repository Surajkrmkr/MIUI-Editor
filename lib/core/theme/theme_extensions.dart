import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Custom color slots exposed via ThemeExtension.
/// Usage: `context.appColors.primary`
@immutable
class AppColorScheme extends ThemeExtension<AppColorScheme> {
  const AppColorScheme({
    required this.bg,
    required this.bgSubtle,
    required this.surface,
    required this.surfaceElevated,
    required this.surfaceOverlay,
    required this.border,
    required this.borderSubtle,
    required this.primary,
    required this.primaryHover,
    required this.primaryPressed,
    required this.primarySelection,
    required this.onPrimary,
    required this.textPrimary,
    required this.textSecondary,
    required this.textDisabled,
    required this.success,
    required this.warning,
    required this.error,
  });

  final Color bg;
  final Color bgSubtle;
  final Color surface;
  final Color surfaceElevated;
  final Color surfaceOverlay;
  final Color border;
  final Color borderSubtle;
  final Color primary;
  final Color primaryHover;
  final Color primaryPressed;
  final Color primarySelection;
  final Color onPrimary;
  final Color textPrimary;
  final Color textSecondary;
  final Color textDisabled;
  final Color success;
  final Color warning;
  final Color error;

  // ── Dark ──────────────────────────────────────────────────────────────────
  static const AppColorScheme dark = AppColorScheme(
    bg:               AppColors.darkBg0,
    bgSubtle:         AppColors.darkBg1,
    surface:          AppColors.darkSurface0,
    surfaceElevated:  AppColors.darkSurface1,
    surfaceOverlay:   AppColors.darkSurface2,
    border:           AppColors.darkBorder0,
    borderSubtle:     AppColors.darkBorder1,
    primary:          AppColors.purplePrimary,
    primaryHover:     AppColors.purpleHover,
    primaryPressed:   AppColors.purplePressed,
    primarySelection: AppColors.purpleSelection,
    onPrimary:        AppColors.darkTextPrimary,
    textPrimary:      AppColors.darkTextPrimary,
    textSecondary:    AppColors.darkTextSecondary,
    textDisabled:     AppColors.darkTextDisabled,
    success:          AppColors.successDark,
    warning:          AppColors.warningDark,
    error:            AppColors.errorDark,
  );

  // ── Light ─────────────────────────────────────────────────────────────────
  static const AppColorScheme light = AppColorScheme(
    bg:               AppColors.lightBg0,
    bgSubtle:         AppColors.lightBg1,
    surface:          AppColors.lightSurface0,
    surfaceElevated:  AppColors.lightSurface1,
    surfaceOverlay:   AppColors.lightSurface1,
    border:           AppColors.lightBorder,
    borderSubtle:     AppColors.lightBorder,
    primary:          AppColors.purplePrimaryLight,
    primaryHover:     AppColors.purpleHoverLight,
    primaryPressed:   AppColors.purplePressed,
    primarySelection: AppColors.purpleSelectionLight,
    onPrimary:        AppColors.lightBg0,
    textPrimary:      AppColors.lightTextPrimary,
    textSecondary:    AppColors.lightTextSecondary,
    textDisabled:     AppColors.lightTextSecondary,
    success:          AppColors.successLight,
    warning:          AppColors.warningLight,
    error:            AppColors.errorLight,
  );

  @override
  AppColorScheme copyWith({
    Color? bg,
    Color? bgSubtle,
    Color? surface,
    Color? surfaceElevated,
    Color? surfaceOverlay,
    Color? border,
    Color? borderSubtle,
    Color? primary,
    Color? primaryHover,
    Color? primaryPressed,
    Color? primarySelection,
    Color? onPrimary,
    Color? textPrimary,
    Color? textSecondary,
    Color? textDisabled,
    Color? success,
    Color? warning,
    Color? error,
  }) =>
      AppColorScheme(
        bg:               bg               ?? this.bg,
        bgSubtle:         bgSubtle         ?? this.bgSubtle,
        surface:          surface          ?? this.surface,
        surfaceElevated:  surfaceElevated  ?? this.surfaceElevated,
        surfaceOverlay:   surfaceOverlay   ?? this.surfaceOverlay,
        border:           border           ?? this.border,
        borderSubtle:     borderSubtle     ?? this.borderSubtle,
        primary:          primary          ?? this.primary,
        primaryHover:     primaryHover     ?? this.primaryHover,
        primaryPressed:   primaryPressed   ?? this.primaryPressed,
        primarySelection: primarySelection ?? this.primarySelection,
        onPrimary:        onPrimary        ?? this.onPrimary,
        textPrimary:      textPrimary      ?? this.textPrimary,
        textSecondary:    textSecondary    ?? this.textSecondary,
        textDisabled:     textDisabled     ?? this.textDisabled,
        success:          success          ?? this.success,
        warning:          warning          ?? this.warning,
        error:            error            ?? this.error,
      );

  @override
  AppColorScheme lerp(AppColorScheme? other, double t) {
    if (other == null) return this;
    return AppColorScheme(
      bg:               Color.lerp(bg,               other.bg,               t)!,
      bgSubtle:         Color.lerp(bgSubtle,         other.bgSubtle,         t)!,
      surface:          Color.lerp(surface,          other.surface,          t)!,
      surfaceElevated:  Color.lerp(surfaceElevated,  other.surfaceElevated,  t)!,
      surfaceOverlay:   Color.lerp(surfaceOverlay,   other.surfaceOverlay,   t)!,
      border:           Color.lerp(border,           other.border,           t)!,
      borderSubtle:     Color.lerp(borderSubtle,     other.borderSubtle,     t)!,
      primary:          Color.lerp(primary,          other.primary,          t)!,
      primaryHover:     Color.lerp(primaryHover,     other.primaryHover,     t)!,
      primaryPressed:   Color.lerp(primaryPressed,   other.primaryPressed,   t)!,
      primarySelection: Color.lerp(primarySelection, other.primarySelection, t)!,
      onPrimary:        Color.lerp(onPrimary,        other.onPrimary,        t)!,
      textPrimary:      Color.lerp(textPrimary,      other.textPrimary,      t)!,
      textSecondary:    Color.lerp(textSecondary,    other.textSecondary,    t)!,
      textDisabled:     Color.lerp(textDisabled,     other.textDisabled,     t)!,
      success:          Color.lerp(success,          other.success,          t)!,
      warning:          Color.lerp(warning,          other.warning,          t)!,
      error:            Color.lerp(error,            other.error,            t)!,
    );
  }
}

/// Convenience extension — `context.appColors`.
extension AppColorSchemeX on BuildContext {
  AppColorScheme get appColors =>
      Theme.of(this).extension<AppColorScheme>() ?? AppColorScheme.dark;

  bool get isDark => Theme.of(this).brightness == Brightness.dark;
}
