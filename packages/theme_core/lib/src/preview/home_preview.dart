import 'dart:io';
import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;

import '../errors/app_exception.dart';

/// Mock home screen drawn from a built theme folder: the wallpaper with the
/// theme's app icons on a launcher grid and dock. No Flutter needed.
abstract final class HomePreview {
  static const _w = 1080, _h = 2340, _icon = 180;
  static const _cols = 4, _rows = 5;

  // Common apps first so previews of different themes are comparable.
  static const _preferred = [
    'com.android.settings',
    'com.android.camera',
    'com.android.chrome',
    'com.android.calendar',
    'com.android.deskclock',
    'com.android.calculator2',
    'com.android.fileexplorer',
    'com.android.thememanager',
    'com.android.vending',
    'com.google.android.apps.maps',
    'com.vanced.android.youtube',
    'com.facebook.katana',
    'com.whatsapp',
    'org.telegram.messenger',
    'com.instagram.android',
    'com.spotify.music',
    'com.miui.gallery',
    'com.miui.player',
    'com.xiaomi.scanner',
    'com.android.soundrecorder',
  ];
  static const _dock = [
    'com.android.contacts.activities.TwelveKeyDialer',
    'com.android.mms',
    'com.android.chrome',
    'com.android.camera',
  ];

  /// PNG of [workspace]'s home screen, [width] px wide.
  static Uint8List compose(String workspace, {int width = 540}) {
    final wallpaper = _decode(
      p.join(workspace, 'wallpaper', 'default_wallpaper.jpg'),
    );
    if (wallpaper == null) {
      throw AppException(
        'No wallpaper in $workspace/wallpaper; build the theme first.',
      );
    }
    final iconDir = p.join(workspace, 'icons', 'res', 'drawable-xxhdpi');
    final available = <String>{
      if (Directory(iconDir).existsSync())
        for (final f in Directory(iconDir).listSync())
          if (f is File && f.path.endsWith('.png'))
            p.basenameWithoutExtension(f.path),
    };
    if (available.isEmpty) {
      throw AppException('No icons in $iconDir; build the theme first.');
    }

    final canvas = _cover(wallpaper, _w, _h);

    final dock = _dock.where(available.contains).toList();
    final rest = [
      ..._preferred.where((n) => available.contains(n) && !dock.contains(n)),
      for (final n in available.toList()..sort())
        if (_isApp(n) && !dock.contains(n) && !_preferred.contains(n)) n,
    ];

    const cellW = (_w - 120) ~/ _cols;
    for (var i = 0; i < _cols * _rows && i < rest.length; i++) {
      final x = 60 + (i % _cols) * cellW + (cellW - _icon) ~/ 2;
      final y = 330 + (i ~/ _cols) * 330;
      _paste(canvas, p.join(iconDir, '${rest[i]}.png'), x, y);
    }

    if (dock.isNotEmpty) {
      const top = 2020, bar = 250;
      img.fillRect(
        canvas,
        x1: 40,
        y1: top,
        x2: _w - 40,
        y2: top + bar,
        color: img.ColorRgba8(255, 255, 255, 60),
        radius: 80,
      );
      for (var i = 0; i < dock.length; i++) {
        final x = 60 + i * cellW + (cellW - _icon) ~/ 2;
        _paste(
          canvas,
          p.join(iconDir, '${dock[i]}.png'),
          x,
          top + (bar - _icon) ~/ 2,
        );
      }
    }

    final out = width == _w
        ? canvas
        : img.copyResize(
            canvas,
            width: width,
            interpolation: img.Interpolation.average,
          );
    return img.encodePng(out);
  }

  // Skips the system resources that share the icon folder.
  static bool _isApp(String name) =>
      !name.startsWith('icon_') &&
      !name.startsWith('status_bar') &&
      !name.contains('.providers.');

  static img.Image? _decode(String path) {
    final f = File(path);
    return f.existsSync() ? img.decodeImage(f.readAsBytesSync()) : null;
  }

  static void _paste(img.Image canvas, String path, int x, int y) {
    final icon = _decode(path);
    if (icon == null) return;
    final fitted = icon.width == _icon
        ? icon
        : img.copyResize(icon, width: _icon, height: _icon);
    img.compositeImage(canvas, fitted, dstX: x, dstY: y);
  }

  static img.Image _cover(img.Image src, int w, int h) {
    final scale = w / src.width > h / src.height
        ? w / src.width
        : h / src.height;
    final scaled = img.copyResize(
      src,
      width: (src.width * scale).ceil(),
      height: (src.height * scale).ceil(),
      interpolation: img.Interpolation.linear,
    );
    return img.copyCrop(
      scaled,
      x: (scaled.width - w) ~/ 2,
      y: (scaled.height - h) ~/ 2,
      width: w,
      height: h,
    );
  }
}
