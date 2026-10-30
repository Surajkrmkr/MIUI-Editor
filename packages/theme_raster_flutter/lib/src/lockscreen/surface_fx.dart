import 'package:flutter/material.dart';
import 'package:theme_core/theme_core.dart' show IconTexture;
import '../icons/icon_visual_utils.dart';
import 'lock_element.dart';

/// Paints the element's icon texture over [child], masked to the
/// child's own pixels so nothing spills outside the glyphs or container.
class SurfaceFx extends StatelessWidget {
  const SurfaceFx({super.key, required this.element, required this.child});

  final LockElement element;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final el = element;
    if (el.surfaceTexture == IconTexture.none) return child;
    // The no-op colour filter forces an isolated layer, so srcATop below only
    // sees the child and not whatever is painted behind it.
    return ColorFiltered(
      colorFilter: const ColorFilter.mode(Colors.transparent, BlendMode.dst),
      child: CustomPaint(foregroundPainter: _FxPainter(el), child: child),
    );
  }
}

class _FxPainter extends CustomPainter {
  _FxPainter(this.el);
  final LockElement el;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    if (rect.isEmpty) return;
    final path = Path()..addRect(rect);
    canvas.saveLayer(rect, Paint()..blendMode = BlendMode.srcATop);
    IconVisualUtils.applyTexture(
      canvas,
      path,
      el.surfaceTexture,
      rect,
      scale: el.textureScale,
      opacity: el.textureOpacity,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_FxPainter old) => old.el != el;
}
