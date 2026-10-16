import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:miui_icon_generator/theme_editor/domain/entities/icon_effect.dart';
import 'package:miui_icon_generator/theme_editor/domain/entities/icon_shape.dart';
import 'package:miui_icon_generator/theme_editor/domain/entities/icon_texture.dart';
import 'package:miui_icon_generator/theme_editor/presentation/features/icon_editor/utils/icon_shape_utils.dart';
import 'package:miui_icon_generator/theme_editor/presentation/features/icon_editor/utils/icon_visual_utils.dart';

/// Preview cell, picker thumbnail and export sizes used by the app.
const _sizes = [32.0, 37.0, 172.0];
const _base = Color(0xFF6C5CE7);

void _paintIcon(
  Canvas canvas,
  Rect rect,
  IconShape shape, {
  IconEffect effect = IconEffect.none,
  IconTexture texture = IconTexture.none,
  double radius = 10,
  double px = 1,
}) {
  final path = IconShapeUtils.path(shape, rect, radius: radius, seed: 7);
  canvas.drawPath(path, Paint()..color = _base);
  IconVisualUtils.applyTexture(canvas, path, texture, rect, opacity: .6);
  IconVisualUtils.applyEffect(
    canvas,
    path,
    effect,
    rect,
    _base,
    intensity: .8,
    blur: 20 * px,
    elevation: 4 * px,
  );
}

Future<void> _sheet(
  String file,
  List<IconShape> rows,
  int cols,
  void Function(Canvas, Rect, IconShape, int col) cell,
) async {
  const c = 72.0, pad = 6.0;
  final rec = ui.PictureRecorder();
  final canvas = Canvas(rec);
  canvas.drawRect(
    Rect.fromLTWH(0, 0, cols * c, rows.length * c),
    Paint()..color = const Color(0xFF1D1D24),
  );
  for (var r = 0; r < rows.length; r++) {
    for (var col = 0; col < cols; col++) {
      final rect = Rect.fromLTWH(
        col * c + pad,
        r * c + pad,
        c - pad * 2,
        c - pad * 2,
      );
      canvas.save();
      cell(canvas, rect, rows[r], col);
      canvas.restore();
    }
  }
  final img = await rec.endRecording().toImage(
    (cols * c).toInt(),
    (rows.length * c).toInt(),
  );
  final png = await img.toByteData(format: ui.ImageByteFormat.png);
  final out = File('build/visual_check/$file')..createSync(recursive: true);
  out.writeAsBytesSync(png!.buffer.asUint8List());
}

void main() {
  test(
    'every shape builds a closed, in-bounds path at every size and radius',
    () {
      for (final shape in IconShape.values) {
        for (final s in _sizes) {
          for (final radius in [0.0, 10.0, 20.0]) {
            final rect = Rect.fromLTWH(3, 3, s, s);
            final path = IconShapeUtils.path(
              shape,
              rect,
              radius: radius,
              seed: 3,
            );
            final b = path.getBounds();
            expect(b.isEmpty, isFalse, reason: '$shape @ $s r$radius is empty');
            expect(
              rect.inflate(.5).contains(b.topLeft) &&
                  rect.inflate(.5).contains(b.bottomRight),
              isTrue,
              reason: '$shape @ $s r$radius overflows: $b',
            );
            expect(
              b.width,
              greaterThan(s * .6),
              reason: '$shape @ $s too narrow',
            );
            expect(
              path.contains(rect.center),
              isTrue,
              reason: '$shape centre not filled',
            );
          }
        }
      }
    },
  );

  testWidgets('every shape × effect × texture paints without throwing', (
    tester,
  ) async {
    await tester.runAsync(() async {
      for (final s in _sizes) {
        final px = s / 37;
        final rec = ui.PictureRecorder();
        final canvas = Canvas(rec);
        final rect = Rect.fromLTWH(0, 0, s, s);
        for (final shape in IconShape.values) {
          for (final effect in IconEffect.values) {
            _paintIcon(canvas, rect, shape, effect: effect, px: px);
          }
          for (final texture in IconTexture.values) {
            _paintIcon(canvas, rect, shape, texture: texture, px: px);
          }
        }
        final img = await rec.endRecording().toImage(s.ceil(), s.ceil());
        expect(img.width, s.ceil());
      }
    });
  });

  testWidgets('writes visual contact sheets to build/visual_check', (
    tester,
  ) async {
    await tester.runAsync(() async {
      const shapes = IconShape.values;
      await _sheet('shapes_radius.png', shapes, 3, (c, r, shape, col) {
        _paintIcon(c, r, shape, radius: [0.0, 10.0, 20.0][col]);
      });
      await _sheet('effects.png', shapes, IconEffect.values.length, (
        c,
        r,
        shape,
        col,
      ) {
        _paintIcon(
          c,
          r,
          shape,
          effect: IconEffect.values[col],
          px: r.width / 37,
        );
      });
      await _sheet('textures.png', shapes, IconTexture.values.length, (
        c,
        r,
        shape,
        col,
      ) {
        _paintIcon(c, r, shape, texture: IconTexture.values[col]);
      });
    });
  });
}
