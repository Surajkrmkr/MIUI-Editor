import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:theme_core/theme_core.dart' show IconTexture;
import '../icons/icon_visual_utils.dart';
import 'lock_element.dart';

/// Paints the element's icon texture over [child], masked to the
/// child's own pixels so nothing spills outside the glyphs or container.
class SurfaceFx extends StatefulWidget {
  const SurfaceFx({super.key, required this.element, required this.child});

  final LockElement element;
  final Widget child;

  @override
  State<SurfaceFx> createState() => _SurfaceFxState();
}

class _SurfaceFxState extends State<SurfaceFx> {
  static const _pixelRatio = 4.0;
  static const _maxSide = 4096.0;

  ui.Image? _image;
  double _imageRatio = 1;
  Object? _imageKey;

  // A shader mask always renders its child in its own layer, so srcATop only
  // sees the child's pixels and never the wallpaper behind it.
  Shader _shader(Rect bounds) {
    final el = widget.element;
    final key = (
      bounds.width,
      bounds.height,
      el.surfaceTexture,
      el.textureScale,
      el.textureOpacity,
    );
    if (_image == null || _imageKey != key) {
      _imageRatio = math.min(
        _pixelRatio,
        _maxSide / math.max(1.0, math.max(bounds.width, bounds.height)),
      );
      _image = _render(el, bounds.size, _imageRatio);
      _imageKey = key;
    }
    return ImageShader(
      _image!,
      TileMode.clamp,
      TileMode.clamp,
      Matrix4.diagonal3Values(1 / _imageRatio, 1 / _imageRatio, 1).storage,
    );
  }

  static ui.Image _render(LockElement el, Size size, double ratio) {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder)..scale(ratio);
    final rect = Offset.zero & size;
    IconVisualUtils.applyTexture(
      canvas,
      Path()..addRect(rect),
      el.surfaceTexture,
      rect,
      scale: el.textureScale,
      opacity: el.textureOpacity,
    );
    final picture = recorder.endRecording();
    final image = picture.toImageSync(
      math.max(1, (size.width * ratio).ceil()),
      math.max(1, (size.height * ratio).ceil()),
    );
    picture.dispose();
    return image;
  }

  @override
  void dispose() {
    _image?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.element.surfaceTexture == IconTexture.none) return widget.child;
    return ShaderMask(
      blendMode: BlendMode.srcATop,
      shaderCallback: _shader,
      child: widget.child,
    );
  }
}
