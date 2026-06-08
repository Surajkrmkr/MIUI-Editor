import 'package:flutter/material.dart';
import '../core/theme/app_radius.dart';
import '../core/theme/theme_extensions.dart';

/// Rounded-square icon action button — consistent across every module.
///
/// [isActive] applies a primary-tinted background and foreground,
/// useful for toggle toolbar buttons.
class AppIconButton extends StatelessWidget {
  const AppIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.tooltip,
    this.isActive = false,
    this.iconSize = 20.0,
    this.buttonSize = 36.0,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final bool isActive;
  final double iconSize;
  final double buttonSize;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      icon: Icon(icon, size: iconSize),
      style: IconButton.styleFrom(
        foregroundColor: isActive ? colors.primary : colors.textSecondary,
        backgroundColor:
            isActive ? colors.primary.withAlpha(20) : Colors.transparent,
        minimumSize: Size(buttonSize, buttonSize),
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.radiusMd),
        padding: EdgeInsets.zero,
      ),
    );
  }
}

/// Standard leading navigation widget.
///
/// Default shows a back arrow. Use [AppBackButton.close] for modal/sheet
/// dismissal (shows ✕ instead).
class AppBackButton extends StatelessWidget {
  const AppBackButton({
    super.key,
    this.onPressed,
    this.tooltip = 'Back',
    this.icon = Icons.arrow_back_rounded,
  });

  const AppBackButton.close({
    super.key,
    this.onPressed,
    this.tooltip = 'Close',
    this.icon = Icons.close_rounded,
  });

  final VoidCallback? onPressed;
  final String tooltip;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return AppIconButton(
      icon: icon,
      tooltip: tooltip,
      onPressed: onPressed ?? () => Navigator.maybePop(context),
    );
  }
}
