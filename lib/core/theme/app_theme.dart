import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';
import 'app_radius.dart';
import 'theme_extensions.dart';

/// AMOLED Purple theme system.
///
/// Dark (default): true AMOLED black + purple accent.
/// Light:          clean white surfaces + deeper purple accent.
///
/// All sub-apps should use [AppTheme.dark] / [AppTheme.light].
/// Widgets must read colors from [context.appColors] or [Theme.of(context)].
class AppTheme {
  AppTheme._();

  // ── Legacy palette aliases (kept for backward compat inside this file) ────
  // Prefer context.appColors in new/updated code.
  static const Color accent      = AppColors.purplePrimary;
  static const Color accentLight = AppColors.purplePrimaryLight;

  // Pro-workspace surface aliases (consumed by existing widgets during migration)
  static const Color proBackground = AppColors.darkBg0;
  static const Color proSidebar    = AppColors.darkSurface0;
  static const Color proInspector  = AppColors.darkSurface1;
  static const Color proCard       = AppColors.darkSurface2;
  static const Color proInput      = AppColors.darkBg1;

  // ── Dark theme ────────────────────────────────────────────────────────────

  static ThemeData dark() => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: const ColorScheme(
          brightness: Brightness.dark,
          primary:          AppColors.purplePrimary,
          onPrimary:        AppColors.darkTextPrimary,
          primaryContainer: AppColors.purplePressed,
          onPrimaryContainer: AppColors.purpleSelection,
          secondary:        AppColors.purpleSelection,
          onSecondary:      AppColors.darkBg0,
          secondaryContainer: AppColors.darkSurface1,
          onSecondaryContainer: AppColors.darkTextPrimary,
          tertiary:         AppColors.purpleHover,
          onTertiary:       AppColors.darkBg0,
          tertiaryContainer: AppColors.darkSurface2,
          onTertiaryContainer: AppColors.darkTextPrimary,
          error:            AppColors.errorDark,
          onError:          AppColors.darkBg0,
          errorContainer:   AppColors.darkSurface1,
          onErrorContainer: AppColors.errorDark,
          surface:          AppColors.darkSurface0,
          onSurface:        AppColors.darkTextPrimary,
          onSurfaceVariant: AppColors.darkTextSecondary,
          outline:          AppColors.darkBorder0,
          outlineVariant:   AppColors.darkBorder1,
          shadow:           AppColors.darkBg0,
          scrim:            AppColors.darkBg0,
          inverseSurface:   AppColors.lightSurface0,
          onInverseSurface: AppColors.lightTextPrimary,
          inversePrimary:   AppColors.purplePrimaryLight,
          surfaceContainerHighest: AppColors.darkSurface2,
          surfaceContainerHigh:    AppColors.darkSurface1,
          surfaceContainer:        AppColors.darkSurface0,
          surfaceContainerLow:     AppColors.darkBg1,
          surfaceContainerLowest:  AppColors.darkBg0,
          surfaceTint:      AppColors.purplePrimary,
        ),
        scaffoldBackgroundColor: AppColors.darkBg0,
        extensions: const [AppColorScheme.dark],

        // AppBar
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.darkBg0,
          foregroundColor: AppColors.darkTextPrimary,
          elevation: 0,
          surfaceTintColor: AppColors.transparent,
          shadowColor: AppColors.transparent,
        ),

        // Card
        cardTheme: const CardThemeData(
          elevation: 0,
          color: AppColors.darkSurface0,
          surfaceTintColor: AppColors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.radiusLg,
            side: BorderSide(color: AppColors.darkBorder0),
          ),
        ),

        // Buttons
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.purplePrimary,
            foregroundColor: AppColors.darkTextPrimary,
            shape: const RoundedRectangleBorder(borderRadius: AppRadius.radiusMd),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.purplePrimary,
            foregroundColor: AppColors.darkTextPrimary,
            shape: const RoundedRectangleBorder(borderRadius: AppRadius.radiusMd),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.purplePrimary,
            side: const BorderSide(color: AppColors.darkBorder1),
            shape: const RoundedRectangleBorder(borderRadius: AppRadius.radiusMd),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: AppColors.purplePrimary,
            shape: const RoundedRectangleBorder(borderRadius: AppRadius.radiusMd),
          ),
        ),

        // Chip
        chipTheme: const ChipThemeData(
          checkmarkColor: AppColors.darkTextPrimary,
          selectedColor: AppColors.purplePrimary,
          backgroundColor: AppColors.darkSurface1,
          side: BorderSide.none,
          shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusSm),
          labelStyle: TextStyle(color: AppColors.darkTextPrimary),
        ),

        // Input
        inputDecorationTheme: const InputDecorationTheme(
          filled: true,
          fillColor: AppColors.darkBg1,
          hintStyle: TextStyle(color: AppColors.darkTextDisabled),
          labelStyle: TextStyle(color: AppColors.darkTextSecondary),
          border: OutlineInputBorder(
            borderRadius: AppRadius.radiusMd,
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: AppRadius.radiusMd,
            borderSide: BorderSide(color: AppColors.darkBorder0),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: AppRadius.radiusMd,
            borderSide: BorderSide(color: AppColors.purplePrimary, width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: AppRadius.radiusMd,
            borderSide: BorderSide(color: AppColors.errorDark),
          ),
        ),

        // Dialog
        dialogTheme: const DialogThemeData(
          backgroundColor: AppColors.darkSurface0,
          surfaceTintColor: AppColors.transparent,
          shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusXl),
        ),

        // ListTile
        listTileTheme: ListTileThemeData(
          selectedColor: AppColors.darkTextPrimary,
          selectedTileColor: AppColors.purplePrimary.withAlpha(30),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.radiusMd),
          iconColor: AppColors.darkTextSecondary,
          textColor: AppColors.darkTextPrimary,
        ),

        // Slider
        sliderTheme: const SliderThemeData(
          showValueIndicator: ShowValueIndicator.alwaysVisible,
          activeTrackColor: AppColors.purplePrimary,
          thumbColor: AppColors.purplePrimary,
          inactiveTrackColor: AppColors.darkBorder1,
          overlayColor: AppColors.purplePrimary,
          valueIndicatorColor: AppColors.purplePrimary,
        ),

        // FAB
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: AppColors.purplePrimary,
          foregroundColor: AppColors.darkTextPrimary,
        ),

        // SnackBar
        snackBarTheme: const SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.darkSurface1,
          contentTextStyle: TextStyle(color: AppColors.darkTextPrimary),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusMd),
        ),

        // Switch
        switchTheme: SwitchThemeData(
          thumbColor: WidgetStateProperty.resolveWith((s) =>
              s.contains(WidgetState.selected) ? AppColors.purplePrimary : AppColors.darkTextDisabled),
          trackColor: WidgetStateProperty.resolveWith((s) =>
              s.contains(WidgetState.selected)
                  ? AppColors.purplePrimary.withAlpha(80)
                  : AppColors.darkSurface2),
        ),

        // Checkbox
        checkboxTheme: CheckboxThemeData(
          fillColor: WidgetStateProperty.resolveWith((s) =>
              s.contains(WidgetState.selected) ? AppColors.purplePrimary : AppColors.transparent),
          checkColor: WidgetStateProperty.all(AppColors.darkTextPrimary),
          side: const BorderSide(color: AppColors.darkBorder1),
        ),

        // Divider
        dividerTheme: const DividerThemeData(
          color: AppColors.darkBorder0,
          thickness: 1,
          space: 1,
        ),

        // Tooltip
        tooltipTheme: TooltipThemeData(
          decoration: BoxDecoration(
            color: AppColors.darkSurface2,
            borderRadius: AppRadius.radiusSm,
            border: Border.all(color: AppColors.darkBorder0),
          ),
          textStyle: const TextStyle(color: AppColors.darkTextPrimary, fontSize: 11),
        ),

        // PopupMenu
        popupMenuTheme: const PopupMenuThemeData(
          color: AppColors.darkSurface1,
          surfaceTintColor: AppColors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.radiusMd,
            side: BorderSide(color: AppColors.darkBorder0),
          ),
          textStyle: TextStyle(color: AppColors.darkTextPrimary),
        ),

        // Tab
        tabBarTheme: const TabBarThemeData(
          labelColor: AppColors.purplePrimary,
          unselectedLabelColor: AppColors.darkTextSecondary,
          indicatorColor: AppColors.purplePrimary,
          dividerColor: AppColors.darkBorder0,
        ),

        // IconButton
        iconButtonTheme: IconButtonThemeData(
          style: IconButton.styleFrom(
            shape: const RoundedRectangleBorder(borderRadius: AppRadius.radiusMd),
            minimumSize: const Size(36, 36),
            padding: const EdgeInsets.all(6),
          ),
        ),

        // Icon
        iconTheme: const IconThemeData(color: AppColors.darkTextSecondary),
        primaryIconTheme: const IconThemeData(color: AppColors.purplePrimary),

        // Text
        textTheme: _buildTextTheme(AppColors.darkTextPrimary, AppColors.darkTextSecondary),

        // Progress
        progressIndicatorTheme: const ProgressIndicatorThemeData(
          color: AppColors.purplePrimary,
          linearTrackColor: AppColors.darkBorder0,
        ),

        // ScrollBar
        scrollbarTheme: ScrollbarThemeData(
          thumbColor: WidgetStateProperty.all(AppColors.darkBorder1),
          trackColor: WidgetStateProperty.all(AppColors.darkBg1),
          radius: const Radius.circular(AppRadius.xs),
        ),
      );

  // ── Light theme ───────────────────────────────────────────────────────────

  static ThemeData light() => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: const ColorScheme(
          brightness: Brightness.light,
          primary:          AppColors.purplePrimaryLight,
          onPrimary:        AppColors.lightBg0,
          primaryContainer: AppColors.purpleSelectionLight,
          onPrimaryContainer: AppColors.purplePressed,
          secondary:        AppColors.purpleHoverLight,
          onSecondary:      AppColors.lightBg0,
          secondaryContainer: AppColors.lightSurface0,
          onSecondaryContainer: AppColors.lightTextPrimary,
          tertiary:         AppColors.purpleSelectionLight,
          onTertiary:       AppColors.lightBg0,
          tertiaryContainer: AppColors.lightSurface1,
          onTertiaryContainer: AppColors.lightTextPrimary,
          error:            AppColors.errorLight,
          onError:          AppColors.lightBg0,
          errorContainer:   AppColors.lightSurface0,
          onErrorContainer: AppColors.errorLight,
          surface:          AppColors.lightSurface0,
          onSurface:        AppColors.lightTextPrimary,
          onSurfaceVariant: AppColors.lightTextSecondary,
          outline:          AppColors.lightBorder,
          outlineVariant:   AppColors.lightSurface1,
          shadow:           AppColors.lightTextSecondary,
          scrim:            AppColors.lightTextPrimary,
          inverseSurface:   AppColors.darkSurface0,
          onInverseSurface: AppColors.darkTextPrimary,
          inversePrimary:   AppColors.purplePrimary,
          surfaceContainerHighest: AppColors.lightSurface1,
          surfaceContainerHigh:    AppColors.lightSurface0,
          surfaceContainer:        AppColors.lightBg1,
          surfaceContainerLow:     AppColors.lightBg0,
          surfaceContainerLowest:  AppColors.lightBg0,
          surfaceTint:      AppColors.purplePrimaryLight,
        ),
        scaffoldBackgroundColor: AppColors.lightBg0,
        extensions: const [AppColorScheme.light],

        // AppBar
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.lightBg0,
          foregroundColor: AppColors.lightTextPrimary,
          elevation: 0,
          surfaceTintColor: AppColors.transparent,
          shadowColor: AppColors.transparent,
        ),

        // Card
        cardTheme: const CardThemeData(
          elevation: 0,
          color: AppColors.lightBg0,
          surfaceTintColor: AppColors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.radiusLg,
            side: BorderSide(color: AppColors.lightBorder),
          ),
        ),

        // Buttons
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.purplePrimaryLight,
            foregroundColor: AppColors.lightBg0,
            shape: const RoundedRectangleBorder(borderRadius: AppRadius.radiusMd),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.purplePrimaryLight,
            foregroundColor: AppColors.lightBg0,
            shape: const RoundedRectangleBorder(borderRadius: AppRadius.radiusMd),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.purplePrimaryLight,
            side: const BorderSide(color: AppColors.lightBorder),
            shape: const RoundedRectangleBorder(borderRadius: AppRadius.radiusMd),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: AppColors.purplePrimaryLight,
            shape: const RoundedRectangleBorder(borderRadius: AppRadius.radiusMd),
          ),
        ),

        // Chip
        chipTheme: const ChipThemeData(
          checkmarkColor: AppColors.lightBg0,
          selectedColor: AppColors.purplePrimaryLight,
          backgroundColor: AppColors.lightSurface0,
          side: BorderSide.none,
          shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusSm),
          labelStyle: TextStyle(color: AppColors.lightTextPrimary),
        ),

        // Input
        inputDecorationTheme: const InputDecorationTheme(
          filled: true,
          fillColor: AppColors.lightSurface0,
          hintStyle: TextStyle(color: AppColors.lightTextSecondary),
          labelStyle: TextStyle(color: AppColors.lightTextSecondary),
          border: OutlineInputBorder(
            borderRadius: AppRadius.radiusMd,
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: AppRadius.radiusMd,
            borderSide: BorderSide(color: AppColors.lightBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: AppRadius.radiusMd,
            borderSide: BorderSide(color: AppColors.purplePrimaryLight, width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: AppRadius.radiusMd,
            borderSide: BorderSide(color: AppColors.errorLight),
          ),
        ),

        // Dialog
        dialogTheme: const DialogThemeData(
          backgroundColor: AppColors.lightBg0,
          surfaceTintColor: AppColors.transparent,
          shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusXl),
        ),

        // ListTile
        listTileTheme: ListTileThemeData(
          selectedColor: AppColors.lightBg0,
          selectedTileColor: AppColors.purplePrimaryLight.withAlpha(20),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.radiusMd),
          iconColor: AppColors.lightTextSecondary,
          textColor: AppColors.lightTextPrimary,
        ),

        // Slider
        sliderTheme: const SliderThemeData(
          showValueIndicator: ShowValueIndicator.alwaysVisible,
          activeTrackColor: AppColors.purplePrimaryLight,
          thumbColor: AppColors.purplePrimaryLight,
          inactiveTrackColor: AppColors.lightSurface1,
          valueIndicatorColor: AppColors.purplePrimaryLight,
        ),

        // FAB
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: AppColors.purplePrimaryLight,
          foregroundColor: AppColors.lightBg0,
        ),

        // SnackBar
        snackBarTheme: const SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.lightTextPrimary,
          contentTextStyle: TextStyle(color: AppColors.lightBg0),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusMd),
        ),

        // Switch
        switchTheme: SwitchThemeData(
          thumbColor: WidgetStateProperty.resolveWith((s) =>
              s.contains(WidgetState.selected) ? AppColors.purplePrimaryLight : AppColors.lightTextSecondary),
          trackColor: WidgetStateProperty.resolveWith((s) =>
              s.contains(WidgetState.selected)
                  ? AppColors.purplePrimaryLight.withAlpha(60)
                  : AppColors.lightSurface1),
        ),

        // Checkbox
        checkboxTheme: CheckboxThemeData(
          fillColor: WidgetStateProperty.resolveWith((s) =>
              s.contains(WidgetState.selected) ? AppColors.purplePrimaryLight : AppColors.transparent),
          checkColor: WidgetStateProperty.all(AppColors.lightBg0),
          side: const BorderSide(color: AppColors.lightBorder),
        ),

        // Divider
        dividerTheme: const DividerThemeData(
          color: AppColors.lightBorder,
          thickness: 1,
          space: 1,
        ),

        // Tooltip
        tooltipTheme: const TooltipThemeData(
          decoration: BoxDecoration(
            color: AppColors.lightTextPrimary,
            borderRadius: AppRadius.radiusSm,
          ),
          textStyle: TextStyle(color: AppColors.lightBg0, fontSize: 11),
        ),

        // PopupMenu
        popupMenuTheme: const PopupMenuThemeData(
          color: AppColors.lightBg0,
          surfaceTintColor: AppColors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.radiusMd,
            side: BorderSide(color: AppColors.lightBorder),
          ),
          textStyle: TextStyle(color: AppColors.lightTextPrimary),
        ),

        // Tab
        tabBarTheme: const TabBarThemeData(
          labelColor: AppColors.purplePrimaryLight,
          unselectedLabelColor: AppColors.lightTextSecondary,
          indicatorColor: AppColors.purplePrimaryLight,
          dividerColor: AppColors.lightBorder,
        ),

        // IconButton
        iconButtonTheme: IconButtonThemeData(
          style: IconButton.styleFrom(
            shape: const RoundedRectangleBorder(borderRadius: AppRadius.radiusMd),
            minimumSize: const Size(36, 36),
            padding: const EdgeInsets.all(6),
          ),
        ),

        // Icon
        iconTheme: const IconThemeData(color: AppColors.lightTextSecondary),
        primaryIconTheme: const IconThemeData(color: AppColors.purplePrimaryLight),

        // Text
        textTheme: _buildTextTheme(AppColors.lightTextPrimary, AppColors.lightTextSecondary),

        // Progress
        progressIndicatorTheme: const ProgressIndicatorThemeData(
          color: AppColors.purplePrimaryLight,
          linearTrackColor: AppColors.lightSurface1,
        ),

        // ScrollBar
        scrollbarTheme: ScrollbarThemeData(
          thumbColor: WidgetStateProperty.all(AppColors.lightBorder),
          trackColor: WidgetStateProperty.all(AppColors.lightSurface0),
          radius: const Radius.circular(AppRadius.xs),
        ),
      );

  // ── Typography ────────────────────────────────────────────────────────────

  static TextTheme _buildTextTheme(Color primary, Color secondary) =>
      GoogleFonts.plusJakartaSansTextTheme(TextTheme(
        displayLarge:  TextStyle(color: primary, fontWeight: FontWeight.bold),
        displayMedium: TextStyle(color: primary, fontWeight: FontWeight.bold),
        displaySmall:  TextStyle(color: primary, fontWeight: FontWeight.bold),
        headlineLarge: TextStyle(color: primary, fontWeight: FontWeight.w600),
        headlineMedium: TextStyle(color: primary, fontWeight: FontWeight.w600),
        headlineSmall: TextStyle(color: primary, fontWeight: FontWeight.w600),
        titleLarge:    TextStyle(color: primary, fontWeight: FontWeight.w600),
        titleMedium:   TextStyle(color: primary, fontWeight: FontWeight.w500),
        titleSmall:    TextStyle(color: primary, fontWeight: FontWeight.w500),
        bodyLarge:     TextStyle(color: primary),
        bodyMedium:    TextStyle(color: primary),
        bodySmall:     TextStyle(color: secondary),
        labelLarge:    TextStyle(color: primary, fontWeight: FontWeight.w500),
        labelMedium:   TextStyle(color: secondary),
        labelSmall:    TextStyle(color: secondary),
      ));
}
