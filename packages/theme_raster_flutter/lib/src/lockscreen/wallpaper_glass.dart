import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'lock_element.dart';

/// Light falling across the glass surface, top-left to bottom-right.
const glassSheen = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [
    Color(0x59FFFFFF),
    Color(0x00FFFFFF),
    Color(0x00FFFFFF),
    Color(0x1FFFFFFF),
  ],
  stops: [0, .38, .7, 1],
);

/// The light rim just inside the glass edge.
const glassRimGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [
    Color(0xF2FFFFFF),
    Color(0x66FFFFFF),
    Color(0x26FFFFFF),
    Color(0x99FFFFFF),
  ],
  stops: [0, .35, .65, 1],
);

/// Paints light catching the inner edges of a shape that [drawShape] draws
/// opaque at a given offset: a soft shade inside every edge, hairline glints
/// along the top-left and fainter ones along the bottom-right.
void paintGlassEdgeLight(
  Canvas canvas,
  Rect bounds,
  double unit,
  void Function(Offset shift) drawShape,
) {
  // The outside of the shape, shifted and blurred, seen only inside it: it
  // lands along the edges facing away from [shift].
  void innerEdge(Offset shift, double sigma, Color color) {
    canvas.saveLayer(bounds, Paint());
    canvas.saveLayer(
      bounds,
      Paint()..imageFilter = ui.ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
    );
    canvas.drawRect(bounds, Paint()..color = color);
    canvas.saveLayer(bounds, Paint()..blendMode = BlendMode.dstOut);
    drawShape(shift);
    canvas
      ..restore()
      ..restore();
    canvas.saveLayer(bounds, Paint()..blendMode = BlendMode.dstIn);
    drawShape(Offset.zero);
    canvas
      ..restore()
      ..restore();
  }

  innerEdge(Offset.zero, unit * .8, const Color(0x61000000));
  innerEdge(Offset(unit * .3, unit * .35), unit * .12, const Color(0xF2FFFFFF));
  innerEdge(
    Offset(-unit * .25, -unit * .3),
    unit * .12,
    const Color(0x8CFFFFFF),
  );
}

/// A container drawn as wallpaper glass: the blurred background behind it,
/// tinted, with sheen, optional edge light, inner rim and drop shadow.
class WallpaperGlassBox extends StatelessWidget {
  const WallpaperGlassBox({super.key, required this.element});

  final LockElement element;

  @override
  Widget build(BuildContext context) {
    final el = element;
    final radius = BorderRadius.circular(el.radius);
    final tint = el.glassTint.clamp(0.0, 1.0);
    final shadow = el.glassShadow;
    return SizedBox(
      width: el.width,
      height: el.height,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          if (shadow.color.a > 0)
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: radius,
                  boxShadow: [shadow],
                ),
              ),
            ),
          Positioned.fill(
            child: GlassBackdropFill(
              blur: el.glassBlur,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: radius,
                  color: const Color(0xFFFFFFFF),
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: radius,
                gradient: LinearGradient(
                  begin: el.gradStartAlign as Alignment,
                  end: el.gradEndAlign as Alignment,
                  colors: [
                    for (final c in [el.color, el.colorSecondary])
                      c.withValues(alpha: c.a * tint),
                  ],
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: radius,
                gradient: glassSheen,
              ),
            ),
          ),
          Positioned.fill(
            child: CustomPaint(
              painter: _GlassBoxEdgesPainter(
                radius: el.radius,
                rim: el.glassRim,
                edgeLight: el.glassEdgeLight,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GlassBoxEdgesPainter extends CustomPainter {
  const _GlassBoxEdgesPainter({
    required this.radius,
    required this.rim,
    required this.edgeLight,
  });

  final double radius, rim;
  final bool edgeLight;

  @override
  void paint(Canvas canvas, Size size) {
    final box = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(radius),
    );
    if (edgeLight) {
      final solid = Paint()..color = const Color(0xFFFFFFFF);
      paintGlassEdgeLight(
        canvas,
        (Offset.zero & size).inflate(size.longestSide),
        1,
        (shift) => canvas.drawRRect(box.shift(shift), solid),
      );
    }
    if (rim > 0) {
      canvas.drawRRect(
        box.deflate(rim / 2),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = rim
          ..shader = glassRimGradient.createShader(Offset.zero & size),
      );
    }
  }

  @override
  bool shouldRepaint(_GlassBoxEdgesPainter oldDelegate) =>
      radius != oldDelegate.radius ||
      rim != oldDelegate.rim ||
      edgeLight != oldDelegate.edgeLight;
}

/// Marks the lockscreen screen box and supplies the background layers
/// (bottom first, each cover-fitted) that wallpaper glass glyphs refract.
class WallpaperGlassScope extends StatefulWidget {
  const WallpaperGlassScope({
    super.key,
    this.layers = const [],
    this.images,
    required this.child,
  });

  /// Resolved asynchronously; ignored when [images] is given.
  final List<ImageProvider> layers;

  /// Already decoded layers, for one-shot captures that cannot wait.
  final List<ui.Image>? images;
  final Widget child;

  /// Decodes [paths] that exist, bottom layer first.
  static Future<List<ui.Image>> decode(Iterable<String?> paths) async {
    final images = <ui.Image>[];
    for (final path in paths) {
      if (path == null || !File(path).existsSync()) continue;
      final codec = await ui.instantiateImageCodec(
        await File(path).readAsBytes(),
      );
      images.add((await codec.getNextFrame()).image);
      codec.dispose();
    }
    return images;
  }

  @override
  State<WallpaperGlassScope> createState() => _WallpaperGlassScopeState();
}

class _WallpaperGlassScopeState extends State<WallpaperGlassScope> {
  final _streams = <ImageStream>[];
  final _listeners = <ImageStreamListener>[];
  List<ui.Image?> _resolved = const [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _resolve();
  }

  @override
  void didUpdateWidget(WallpaperGlassScope oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!listEquals(oldWidget.layers, widget.layers)) _resolve();
  }

  void _resolve() {
    _stop();
    if (widget.images != null) return;
    _resolved = List.filled(widget.layers.length, null);
    final config = createLocalImageConfiguration(context);
    for (final (index, provider) in widget.layers.indexed) {
      final stream = provider.resolve(config);
      final listener = ImageStreamListener((info, _) {
        if (mounted) setState(() => _resolved[index] = info.image);
      }, onError: (_, _) {});
      stream.addListener(listener);
      _streams.add(stream);
      _listeners.add(listener);
    }
  }

  void _stop() {
    for (final (index, stream) in _streams.indexed) {
      stream.removeListener(_listeners[index]);
    }
    _streams.clear();
    _listeners.clear();
  }

  @override
  void dispose() {
    _stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _GlassImages(
    images: widget.images ?? [for (final image in _resolved) ?image],
    child: _GlassScreen(child: widget.child),
  );
}

class _GlassImages extends InheritedWidget {
  const _GlassImages({required this.images, required super.child});

  final List<ui.Image> images;

  @override
  bool updateShouldNotify(_GlassImages oldWidget) =>
      !listEquals(images, oldWidget.images);
}

class _GlassScreen extends SingleChildRenderObjectWidget {
  const _GlassScreen({super.child});

  @override
  RenderObject createRenderObject(BuildContext context) => _RenderGlassScreen();
}

class _RenderGlassScreen extends RenderProxyBox {}

/// Paints the scope's background, blurred and in screen space, wherever
/// [child] paints; the child's own colours only shape the mask.
class GlassBackdropFill extends SingleChildRenderObjectWidget {
  const GlassBackdropFill({super.key, required this.blur, super.child});

  /// Blur sigma in screen (canvas) units.
  final double blur;

  List<ui.Image> _images(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_GlassImages>()?.images ??
      const [];

  @override
  RenderObject createRenderObject(BuildContext context) =>
      RenderGlassBackdropFill(blur, _images(context));

  @override
  void updateRenderObject(
    BuildContext context,
    RenderGlassBackdropFill renderObject,
  ) => renderObject
    ..blur = blur
    ..images = _images(context);
}

class RenderGlassBackdropFill extends RenderProxyBox {
  RenderGlassBackdropFill(this._blur, this._images);

  double _blur;
  set blur(double value) {
    if (value == _blur) return;
    _blur = value;
    markNeedsPaint();
  }

  List<ui.Image> _images;
  set images(List<ui.Image> value) {
    if (listEquals(value, _images)) return;
    _images = value;
    markNeedsPaint();
  }

  _RenderGlassScreen? get _screen {
    for (var node = parent; node != null; node = node.parent) {
      if (node is _RenderGlassScreen) return node;
    }
    return null;
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final screen = _screen;
    if (child == null || screen == null || _images.isEmpty) return;
    final toLocal = Matrix4.tryInvert(getTransformTo(screen));
    if (toLocal == null) return;
    // Glyphs overflow their line box at height 1, like _GlyphShaderMask.
    final bounds = (offset & size).inflate(size.longestSide);
    final canvas = context.canvas
      ..saveLayer(bounds, Paint())
      ..save()
      ..clipRect(bounds);
    context.paintChild(child!, offset);
    canvas
      ..saveLayer(bounds, Paint()..blendMode = BlendMode.srcIn)
      ..translate(offset.dx, offset.dy)
      ..transform(toLocal.storage);
    final screenRect = Offset.zero & screen.size;
    final paint = Paint()
      ..filterQuality = FilterQuality.medium
      ..imageFilter = _blur > 0
          ? ui.ImageFilter.blur(
              sigmaX: _blur,
              sigmaY: _blur,
              tileMode: TileMode.clamp,
            )
          : null;
    for (final image in _images) {
      final source =
          Offset.zero & Size(image.width.toDouble(), image.height.toDouble());
      final fitted = applyBoxFit(BoxFit.cover, source.size, screenRect.size);
      canvas.drawImageRect(
        image,
        Alignment.center.inscribe(fitted.source, source),
        Alignment.center.inscribe(fitted.destination, screenRect),
        paint,
      );
    }
    canvas
      ..restore()
      ..restore()
      ..restore();
  }
}
