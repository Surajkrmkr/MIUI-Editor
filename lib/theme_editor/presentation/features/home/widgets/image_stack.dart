import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:miui_icon_generator/widgets/iphone_frame.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../providers/wallpaper_provider.dart';
import '../../icon_editor/widgets/icon_preview_on_phone.dart';
import '../../lockscreen/widgets/element_widget_preview.dart';

class ImageStack extends ConsumerStatefulWidget {
  const ImageStack({
    super.key,
    required this.isLockscreen,
    this.isHomeScreen = false,
  });
  final bool isLockscreen;
  final bool isHomeScreen;

  @override
  ConsumerState<ImageStack> createState() => _ImageStackState();
}

class _ImageStackState extends ConsumerState<ImageStack> {
  @override
  Widget build(BuildContext context) {
    final wallState = ref.watch(wallpaperProvider);
    if (wallState.paths.isEmpty) return const SizedBox.shrink();
    final backgroundPath = widget.isHomeScreen && wallState.homeWallpaperEnabled
        ? wallState.homeWallpaperPath ?? wallState.currentPath!
        : wallState.currentPath!;

    final screenContent = Container(
      height: AppConstants.screenHeight,
      width: AppConstants.screenWidth,
      decoration: BoxDecoration(
        image: DecorationImage(
          image: FileImage(File(backgroundPath)),
          fit: BoxFit.cover,
        ),
      ),
      child: widget.isLockscreen
          ? const ElementWidgetPreview()
          : const IconPreviewOnPhone(),
    );

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (wallState.index > 0)
                _NavArrow(
                  icon: Icons.chevron_left_rounded,
                  tooltip: 'Previous theme',
                  onTap: () => ref
                      .read(wallpaperProvider.notifier)
                      .setIndex(wallState.index - 1),
                )
              else
                const SizedBox(width: 48),
              const SizedBox(width: 20),
              IPhoneFrame(child: screenContent),
              const SizedBox(width: 20),
              if (wallState.index < wallState.paths.length - 1)
                _NavArrow(
                  icon: Icons.chevron_right_rounded,
                  tooltip: 'Next theme',
                  onTap: () => ref
                      .read(wallpaperProvider.notifier)
                      .setIndex(wallState.index + 1),
                )
              else
                const SizedBox(width: 48),
            ],
          ),
        ],
      ),
    );
  }
}

class _NavArrow extends StatelessWidget {
  const _NavArrow({
    required this.icon,
    required this.onTap,
    required this.tooltip,
  });
  final IconData icon;
  final VoidCallback onTap;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHigh,
            shape: BoxShape.circle,
            border: Border.all(color: scheme.outlineVariant, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(20),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(icon, size: 22, color: scheme.onSurface),
        ),
      ),
    );
  }
}
