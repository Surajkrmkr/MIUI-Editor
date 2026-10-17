import 'dart:typed_data';

import 'package:image/image.dart' as img;

import '../lockscreen/element_enums.dart';
import '../lockscreen/lock_element_spec.dart';
import '../values/rgba.dart';

/// Phone screen the lockscreen layout targets, in theme pixels.
const _screenW = 1080.0, _screenH = 2340.0;

/// Average wallpaper color near a lockscreen element, as it will look on the
/// phone (cover-fitted and darkened by the overlay). A rough estimate: the
/// region size is fixed because text extents aren't known without rendering.
class WallpaperSampler {
  WallpaperSampler(this._image, {required this.overlayAlpha});

  /// Returns null when the bytes aren't a decodable image.
  static WallpaperSampler? decode(
    Uint8List bytes, {
    required double overlayAlpha,
  }) {
    final image = img.decodeImage(bytes);
    return image == null
        ? null
        : WallpaperSampler(image, overlayAlpha: overlayAlpha);
  }

  final img.Image _image;
  final double overlayAlpha;

  /// Average color of the region centred on [element].
  Rgba around(LockElementSpec element) {
    const regionW = _screenW * .4, regionH = _screenH * .08;
    final cx = _screenW / 2 + element.dx * lockscreenScreenRatio;
    final cy = _screenH / 2 + element.dy * lockscreenScreenRatio;

    const screenAspect = _screenW / _screenH;
    final imageAspect = _image.width / _image.height;
    final visW = imageAspect > screenAspect
        ? _image.height * screenAspect
        : _image.width.toDouble();
    final visH = imageAspect > screenAspect
        ? _image.height.toDouble()
        : _image.width / screenAspect;
    final x0 = (_image.width - visW) / 2, y0 = (_image.height - visH) / 2;

    var r = 0.0, g = 0.0, b = 0.0, n = 0;
    const steps = 8;
    for (var i = 0; i < steps; i++) {
      for (var j = 0; j < steps; j++) {
        final sx = cx + (i / (steps - 1) - .5) * regionW;
        final sy = cy + (j / (steps - 1) - .5) * regionH;
        final px = (x0 + (sx / _screenW).clamp(0.0, 1.0) * visW)
            .clamp(0, _image.width - 1)
            .toInt();
        final py = (y0 + (sy / _screenH).clamp(0.0, 1.0) * visH)
            .clamp(0, _image.height - 1)
            .toInt();
        final p = _image.getPixel(px, py);
        r += p.rNormalized;
        g += p.gNormalized;
        b += p.bNormalized;
        n++;
      }
    }
    final dim = 1 - overlayAlpha.clamp(0.0, 1.0);
    int ch(double sum) => (sum / n * 255 * dim).round().clamp(0, 255);
    return Rgba.rgb(ch(r), ch(g), ch(b));
  }
}

/// [foreground] as seen over [background] (alpha composited).
Rgba compositeOver(Rgba foreground, Rgba background) {
  final a = foreground.opacity;
  int mix(int f, int b) => (f * a + b * (1 - a)).round();
  return Rgba.rgb(
    mix(foreground.r, background.r),
    mix(foreground.g, background.g),
    mix(foreground.b, background.b),
  );
}

/// Whether the element's text should be checked against the wallpaper.
bool isLegibilityChecked(LockElementSpec e) =>
    e.isVisible &&
    (e.type.isText || e.type.isClock) &&
    e.color.a > 0 &&
    // An outline keeps text readable on any background.
    !(e.strokeWidth > 0 && e.strokeColor.a > 0);

double textContrast(Rgba text, Rgba background) =>
    compositeOver(text, background).contrastWith(background);
