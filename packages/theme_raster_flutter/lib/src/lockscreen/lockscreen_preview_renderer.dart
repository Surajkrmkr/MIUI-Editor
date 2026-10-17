import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:path/path.dart' as p;
import 'package:screenshot/screenshot.dart';
import 'package:theme_core/theme_core.dart';

import 'lock_element_spec_bridge.dart';
import 'lockscreen_canvas.dart';
import 'lockscreen_clock.dart';

/// The time previews show: a classic 10:09 so every spec's image is the same
/// from run to run.
final _previewTime = DateTime(2026, 1, 15, 10, 9, 30);

/// Draws the lockscreen as the editor's canvas shows it, from a built theme
/// folder, so previews and the app agree.
class LockscreenPreviewRenderer {
  const LockscreenPreviewRenderer();

  /// Writes a PNG of [elements] over the theme's lock wallpaper to [outPath].
  ///
  /// Sample text and numbers stand in for live data, and the clock shows a
  /// fixed time.
  Future<Failure?> render({
    required BuildContext context,
    required ThemeLayout layout,
    required List<LockElementSpec> elements,
    required double bgAlpha,
    required String outPath,
    double pixelRatio = 2,
  }) async {
    final realClock = lockscreenNow;
    lockscreenNow = () => _previewTime;
    try {
      final wallpaper = _wallpaper(layout);
      final canvas = LockscreenCanvas(
        elements: [for (final e in elements) e.toLockElement()],
        wallpaper: wallpaper == null ? null : FileImage(File(wallpaper)),
        dimming: bgAlpha,
        resolveImage: (relative) =>
            File(p.join(layout.lockscreenAdvance, '$relative.png')),
      );
      final bytes = await ScreenshotController().captureFromWidget(
        // No inherited widgets exist in the capture pipeline.
        Directionality(
          textDirection: TextDirection.ltr,
          child: DefaultTextStyle(
            style: const TextStyle(fontFamily: 'Roboto'),
            child: canvas,
          ),
        ),
        context: context,
        pixelRatio: pixelRatio,
        // Image and SVG loads finish while this waits.
        delay: const Duration(milliseconds: 400),
      );
      await File(outPath).parent.create(recursive: true);
      await File(outPath).writeAsBytes(bytes);
      return null;
    } catch (e) {
      return ExportFailure('Lockscreen preview failed: $e');
    } finally {
      lockscreenNow = realClock;
    }
  }

  // The same pick the editor makes: the exported bg.png, else the wallpapers.
  static String? _wallpaper(ThemeLayout layout) {
    for (final path in [
      p.join(layout.lockscreenAdvance, 'bg.png'),
      layout.defaultLockWallpaper,
      layout.defaultWallpaper,
    ]) {
      if (File(path).existsSync()) return path;
    }
    return null;
  }
}
