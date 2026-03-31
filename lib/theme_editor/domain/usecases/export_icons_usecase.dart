import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/constants/path_constants.dart';
import '../../core/errors/failures.dart';
import '../../domain/entities/user_profile.dart';
import '../../presentation/providers/icon_editor_provider.dart';

/// Renders every SVG icon directly via [dart:ui] Canvas — no widget tree,
/// no ScreenshotController. Composites gradient background + SVG + overlays
/// and writes PNG to both drawable-xhdpi and drawable-xxhdpi.
/// Also writes transform_config.xml.
///
/// Reports progress via [onProgress] so the UI can show a live counter.
class ExportIconsUseCase {
  const ExportIconsUseCase();

  static const double _pixelRatio = 4.0;
  static const int _canvasSize = 180; // 45 logical × 4

  Future<Failure?> call({
    required BuildContext context,
    required IconEditorState editorState,
    required UserProfile profile,
    required String themePath,
    required List<String> iconNames,
    required void Function(int done, int total) onProgress,
  }) async {
    try {
      final xhdpiDir = PathConstants.iconsXhdpi(themePath);
      final xxhdpiDir = PathConstants.iconsXxhdpi(themePath);
      await Directory(xhdpiDir).create(recursive: true);
      await Directory(xxhdpiDir).create(recursive: true);

      // Pre-load overlay images ONCE instead of per-icon.
      final beforePath = PathConstants.p(
          '${PathConstants.lockscreenAdvance(themePath)}beforeVector.png');
      final afterPath = PathConstants.p(
          '${PathConstants.lockscreenAdvance(themePath)}afterVector.png');

      final ui.Image? beforeImage = File(beforePath).existsSync()
          ? await _loadUiImage(File(beforePath).readAsBytesSync())
          : null;
      final ui.Image? afterImage = File(afterPath).existsSync()
          ? await _loadUiImage(File(afterPath).readAsBytesSync())
          : null;

      final colors = editorState.randomColors
          ? editorState.bgColors
          : [editorState.bgColor, editorState.bgColor2];

      final allIconNames = [...iconNames, ...extraIconList];
      int done = 0;
      for (final name in allIconNames) {
        final bytes = await _renderIcon(
          name: name,
          profile: profile,
          state: editorState,
          colors: colors,
          beforeImage: beforeImage,
          afterImage: afterImage,
        );

        // Write both resolution folders in parallel.
        await Future.wait([
          File(PathConstants.p('$xhdpiDir$name.png')).writeAsBytes(bytes),
          File(PathConstants.p('$xxhdpiDir$name.png')).writeAsBytes(bytes),
        ]);

        done++;
        onProgress(done, allIconNames.length);
      }

      beforeImage?.dispose();
      afterImage?.dispose();

      await File(PathConstants.p(
              '${themePath}icons${PathConstants.sep}transform_config.xml'))
          .writeAsString(_transformConfigXml);

      return null;
    } catch (e) {
      return ExportFailure(e.toString());
    }
  }

  // ── Low-level rendering ────────────────────────────────────────────────────

  static Future<ui.Image> _loadUiImage(Uint8List bytes) async {
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    return frame.image;
  }

  static Future<Uint8List> _renderIcon({
    required String name,
    required UserProfile profile,
    required IconEditorState state,
    required List<Color> colors,
    required ui.Image? beforeImage,
    required ui.Image? afterImage,
  }) async {
    const double p = _pixelRatio;
    final double size = _canvasSize.toDouble();

    final bool isIconMask = name == 'icon_mask';
    final double margin = (isIconMask ? 10.0 : state.margin) * p;
    final double clipRadius = (isIconMask ? 200.0 : 0.0) * p;
    final double bgRadius = state.radius * p;
    final double padding = state.padding * p;
    final double borderWidth = state.borderWidth * p;

    // Physical-pixel inner rect after margin.
    final innerRect = ui.Rect.fromLTWH(
      margin,
      margin,
      size - margin * 2,
      size - margin * 2,
    );

    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder, ui.Rect.fromLTWH(0, 0, size, size));

    // Clip everything to the inner rounded rect.
    canvas.clipRRect(
      ui.RRect.fromRectAndRadius(
          innerRect, ui.Radius.circular(clipRadius)),
    );

    // 1 ── Before-vector overlay
    if (beforeImage != null) {
      canvas.drawImageRect(
        beforeImage,
        ui.Rect.fromLTWH(0, 0, beforeImage.width.toDouble(),
            beforeImage.height.toDouble()),
        innerRect,
        ui.Paint(),
      );
    }

    // 2 ── Gradient background (skipped for icon_border — transparent inside)
    if (!_skipBg(name)) {
      final gradStart = state.bgGradStart as Alignment;
      final gradEnd = state.bgGradEnd as Alignment;
      final startOffset = Offset(
        innerRect.left + (gradStart.x + 1) / 2 * innerRect.width,
        innerRect.top + (gradStart.y + 1) / 2 * innerRect.height,
      );
      final endOffset = Offset(
        innerRect.left + (gradEnd.x + 1) / 2 * innerRect.width,
        innerRect.top + (gradEnd.y + 1) / 2 * innerRect.height,
      );
      final effectiveColors =
          colors.length > 1 ? colors : [colors.first, colors.first];

      canvas.drawRRect(
        ui.RRect.fromRectAndRadius(innerRect, ui.Radius.circular(bgRadius)),
        ui.Paint()
          ..shader =
              ui.Gradient.linear(startOffset, endOffset, effectiveColors),
      );
    }

    // 3 ── Border stroke (drawn on top of the fill)
    if (borderWidth > 0) {
      canvas.drawRRect(
        ui.RRect.fromRectAndRadius(
          innerRect.deflate(borderWidth / 2),
          ui.Radius.circular(bgRadius),
        ),
        ui.Paint()
          ..style = ui.PaintingStyle.stroke
          ..strokeWidth = borderWidth
          ..color = state.borderColor,
      );
    }

    // 4 ── SVG icon
    // Skipped for bg-only icons (folder/pattern) and border-only icon.
    // icon_mask draws SVG but with a smaller margin (handled above via isIconMask).
    if (!_skipSvg(name)) {
      final svgArea = innerRect.deflate(padding + borderWidth);
      final loader =
          SvgAssetLoader('assets/icons/${profile.iconFolder}/$name.svg');
      final pictureInfo = await vg.loadPicture(loader, null);

      final scaleX = svgArea.width / pictureInfo.size.width;
      final scaleY = svgArea.height / pictureInfo.size.height;

      // saveLayer applies the tint (srcIn) to the entire SVG picture.
      canvas.save();
      canvas.translate(svgArea.left, svgArea.top);
      canvas.scale(scaleX, scaleY);
      canvas.saveLayer(
        ui.Rect.fromLTWH(
            0, 0, pictureInfo.size.width, pictureInfo.size.height),
        ui.Paint()
          ..colorFilter =
              ui.ColorFilter.mode(state.iconColor, ui.BlendMode.srcIn),
      );
      canvas.drawPicture(pictureInfo.picture);
      canvas.restore(); // saveLayer
      canvas.restore(); // translate + scale

      pictureInfo.picture.dispose();
    }

    // 5 ── After-vector overlay
    if (afterImage != null) {
      canvas.drawImageRect(
        afterImage,
        ui.Rect.fromLTWH(0, 0, afterImage.width.toDouble(),
            afterImage.height.toDouble()),
        innerRect,
        ui.Paint(),
      );
    }

    final picture = recorder.endRecording();
    final image = await picture.toImage(_canvasSize, _canvasSize);
    picture.dispose();

    final byteData =
        await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();

    return byteData!.buffer.asUint8List();
  }

  /// Extra icons appended to every export run (after the user's SVG icons).
  static const extraIconList = [
    'icon_folder',
    'icon_folder_light',
    'icon_mask',
    'icon_pattern',
    'icon_border',
  ];

  // bg-only: draw gradient background but skip the SVG step.
  static const _bgOnlyIcons = {
    'icon_folder',
    'icon_folder_light',
    'icon_pattern',
    'icon_mask'
  };
  // border-only: transparent inside — skip both BG fill and SVG.
  static const _borderOnlyIcon = 'icon_border';
  static bool _skipSvg(String name) =>
      _bgOnlyIcons.contains(name) || name == _borderOnlyIcon;
  static bool _skipBg(String name) => name == _borderOnlyIcon;

  // ── Transform config ───────────────────────────────────────────────────────
  static const String _transformConfigXml =
      '''<?xml version="1.0" encoding="UTF-8"?>
<IconTransform>
    <PointsMapping>
        <Point fromX="0" fromY="0" toX="22" toY="22"/>
        <Point fromX="0" fromY="90" toX="22" toY="68"/>
        <Point fromX="90" fromY="90" toX="68" toY="68"/>
        <Point fromX="90" fromY="0" toX="68" toY="22"/>
    </PointsMapping>
</IconTransform>''';
}
