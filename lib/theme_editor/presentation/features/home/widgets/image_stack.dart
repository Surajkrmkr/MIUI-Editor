import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:screenshot/screenshot.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/path_constants.dart';
import '../../../providers/wallpaper_provider.dart';
import '../../../providers/service_providers.dart';
import '../../icon_editor/widgets/icon_preview_on_phone.dart';
import '../../lockscreen/widgets/element_widget_preview.dart';

class ImageStack extends ConsumerStatefulWidget {
  const ImageStack({super.key, required this.isLockscreen});
  final bool isLockscreen;

  @override
  ConsumerState<ImageStack> createState() => _ImageStackState();
}

class _ImageStackState extends ConsumerState<ImageStack> {
  final _screenshotCtrl = ScreenshotController();

  @override
  Widget build(BuildContext context) {
    final wallState = ref.watch(wallpaperProvider);
    if (wallState.paths.isEmpty) return const SizedBox.shrink();

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          children: [
            if (!widget.isLockscreen && wallState.index > 0)
              IconButton(
                icon: const Icon(Icons.navigate_before),
                onPressed: () =>
                    ref.read(wallpaperProvider.notifier).setIndex(wallState.index - 1),
              )
            else
              const SizedBox(width: 48),
            Screenshot(
              controller: _screenshotCtrl,
              child: Container(
                height: AppConstants.screenHeight,
                width: AppConstants.screenWidth,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  image: DecorationImage(
                    image: FileImage(File(wallState.paths[wallState.index])),
                    fit: BoxFit.cover,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(51),
                      blurRadius: 9,
                      offset: const Offset(5, 5),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: widget.isLockscreen
                      ? const ElementWidgetPreview()
                      : const IconPreviewOnPhone(),
                ),
              ),
            ),
            if (!widget.isLockscreen &&
                wallState.index < wallState.paths.length - 1)
              IconButton(
                icon: const Icon(Icons.navigate_next),
                onPressed: () =>
                    ref.read(wallpaperProvider.notifier).setIndex(wallState.index + 1),
              )
            else
              const SizedBox(width: 48),
          ],
        ),
        if (widget.isLockscreen) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                wallState.currentThemeName ?? '',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 12),
              FilledButton.icon(
                icon: const Icon(Icons.send, size: 16),
                label: const Text('Screenshot'),
                onPressed: () => _takeScreenshot(wallState),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Future<void> _takeScreenshot(WallpaperState ws) async {
    final bytes = await _screenshotCtrl.capture();
    if (bytes == null || ws.weekNum == null || ws.currentThemeName == null) return;
    final path = PathConstants.p(
        '${PathConstants.themesBase}Week${ws.weekNum}\\${ws.currentThemeName}.png');
    await ref.read(fileServiceProvider).writeBytes(path, bytes);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Screenshot saved ✅')),
      );
    }
  }
}
