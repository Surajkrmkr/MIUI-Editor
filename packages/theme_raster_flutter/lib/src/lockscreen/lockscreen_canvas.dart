import 'dart:math';

import 'package:flutter/material.dart';
import 'package:theme_core/theme_core.dart';

import 'lock_element.dart';
import 'lock_element_view.dart';
import 'wallpaper_glass.dart';

/// Places [child] the way the lockscreen canvas does: scaled and rotated about
/// the middle of a full-screen box, then aligned inside it. The caller sets
/// the element's `dx`/`dy` offset.
class LockElementFrame extends StatelessWidget {
  const LockElementFrame({
    super.key,
    required this.element,
    required this.child,
  });

  final LockElement element;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final frame = Transform.scale(
      scale: element.scale,
      child: Transform.rotate(
        angle: -element.angle * pi / 180,
        child: SizedBox(
          height: lockscreenViewHeight,
          width: lockscreenViewWidth,
          child: Align(alignment: element.align, child: child),
        ),
      ),
    );
    final perspective = element.perspectiveMatrix;
    if (perspective == null) return frame;
    // The caller offsets this box by dx/dy; pivot on the screen centre so
    // every tilted clock element shares one surface.
    return Transform(
      transform: perspective,
      alignment: Alignment.center,
      origin: Offset(-element.dx, -element.dy),
      child: frame,
    );
  }
}

/// The lockscreen as a still picture: wallpaper, dimming and every visible
/// element, [lockscreenViewWidth] x [lockscreenViewHeight] logical pixels.
class LockscreenCanvas extends StatelessWidget {
  const LockscreenCanvas({
    super.key,
    required this.elements,
    this.wallpaper,
    this.bgImage,
    this.dimming = 0,
    this.resolveImage = noLockscreenImages,
  });

  final List<LockElement> elements;
  final ImageProvider? wallpaper;

  /// The theme's `bg.png`, drawn over the wallpaper; a transparent one lets
  /// the wallpaper show.
  final ImageProvider? bgImage;

  /// Black overlay opacity, 0 to 1.
  final double dimming;
  final LockscreenImageResolver resolveImage;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: lockscreenViewWidth,
    height: lockscreenViewHeight,
    child: ClipRect(
      child: WallpaperGlassScope(
        layers: [?wallpaper, ?bgImage],
        child: Stack(
          children: [
            if (wallpaper != null)
              Image(
                image: wallpaper!,
                gaplessPlayback: true,
                fit: BoxFit.cover,
                width: lockscreenViewWidth,
                height: lockscreenViewHeight,
              ),
            if (bgImage != null)
              Image(
                image: bgImage!,
                gaplessPlayback: true,
                fit: BoxFit.cover,
                width: lockscreenViewWidth,
                height: lockscreenViewHeight,
              ),
            if (dimming > 0)
              ColoredBox(
                color: Colors.black.withAlpha((dimming * 255).round()),
                child: const SizedBox.expand(),
              ),
            for (final el in elements.where((el) => el.isVisible))
              Positioned(
                left: el.dx,
                top: el.dy,
                child: LockElementFrame(
                  element: el,
                  child: LockElementView(
                    key: ValueKey(el.name),
                    element: el,
                    resolveImage: resolveImage,
                  ),
                ),
              ),
          ],
        ),
      ),
    ),
  );
}
