import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:miui_icon_generator/widgets/iphone_frame.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../providers/wallpaper_provider.dart';
import '../../icon_editor/widgets/icon_preview_on_phone.dart';
import '../../lockscreen/widgets/element_widget_preview.dart';

class ImageStack extends ConsumerStatefulWidget {
  const ImageStack({super.key, required this.isLockscreen});
  final bool isLockscreen;

  @override
  ConsumerState<ImageStack> createState() => _ImageStackState();
}

class _ImageStackState extends ConsumerState<ImageStack> {

  @override
  Widget build(BuildContext context) {
    final wallState = ref.watch(wallpaperProvider);
    if (wallState.paths.isEmpty) return const SizedBox.shrink();

    final screenContent = Container(
      height: AppConstants.screenHeight,
      width: AppConstants.screenWidth,
      decoration: BoxDecoration(
        image: DecorationImage(
          image: FileImage(File(wallState.paths[wallState.index])),
          fit: BoxFit.cover,
        ),
      ),
      child: widget.isLockscreen
          ? const ElementWidgetPreview()
          : const IconPreviewOnPhone(),
    );

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (!widget.isLockscreen && wallState.index > 0)
              _NavArrow(
                icon: Icons.chevron_left_rounded,
                onTap: () => ref
                    .read(wallpaperProvider.notifier)
                    .setIndex(wallState.index - 1),
              )
            else
              const SizedBox(width: 40),
            IPhoneFrame(
              child: screenContent,
            ),
            if (!widget.isLockscreen &&
                wallState.index < wallState.paths.length - 1)
              _NavArrow(
                icon: Icons.chevron_right_rounded,
                onTap: () => ref
                    .read(wallpaperProvider.notifier)
                    .setIndex(wallState.index + 1),
              )
            else
              const SizedBox(width: 40),
          ],
        ),
      ],
    );
  }
}

// ── Navigation Arrow ──────────────────────────────────────────────────────────

class _NavArrow extends StatelessWidget {
  const _NavArrow({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
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
    );
  }
}

// ── Lockscreen Bottom Bar ─────────────────────────────────────────────────────

// class _LockscreenBar extends StatelessWidget {
//   const _LockscreenBar({
//     required this.themeName,
//     required this.onScreenshot,
//   });

//   final String themeName;
//   final VoidCallback onScreenshot;

//   @override
//   Widget build(BuildContext context) {
//     final scheme = Theme.of(context).colorScheme;
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
//       decoration: BoxDecoration(
//         color: scheme.surfaceContainerLow,
//         borderRadius: BorderRadius.circular(14),
//         border: Border.all(color: scheme.outlineVariant.withAlpha(80)),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withAlpha(12),
//             blurRadius: 8,
//             offset: const Offset(0, 2),
//           ),
//         ],
//       ),
//       child: Row(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           if (themeName.isNotEmpty) ...[
//             Icon(Icons.palette_outlined,
//                 size: 13, color: scheme.onSurfaceVariant),
//             const SizedBox(width: 6),
//             Text(
//               themeName,
//               style: TextStyle(
//                 fontWeight: FontWeight.w600,
//                 fontSize: 12,
//                 color: scheme.onSurface,
//               ),
//             ),
//             const SizedBox(width: 12),
//             Container(width: 1, height: 16, color: scheme.outlineVariant),
//             const SizedBox(width: 12),
//           ],
//           FilledButton.icon(
//             icon: const Icon(Icons.photo_camera_outlined, size: 14),
//             label: const Text('Screenshot',
//                 style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
//             style: FilledButton.styleFrom(
//               padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//               minimumSize: Size.zero,
//               tapTargetSize: MaterialTapTargetSize.shrinkWrap,
//             ),
//             onPressed: onScreenshot,
//           ),
//         ],
//       ),
//     );
//   }
// }