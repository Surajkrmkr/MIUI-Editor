import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import '../../domain/entities/element_widget.dart';

class SVGGenerator {
  static const double ratio = 2340 / 600;

  static String generateHeader(double width, double height) {
    return '<?xml version="1.0" encoding="UTF-8" standalone="no"?>\n'
        '<svg width="$width" height="$height" viewBox="0 0 $width $height" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink">\n';
  }

  static String generateFooter() {
    return '</svg>';
  }

  static String wrapInLayer(String content, String layerId) {
    return '  <g id="$layerId">\n$content  </g>\n';
  }

  static String generateProfessionalSVG({
    required double width,
    required double height,
    required List<LockElement> elements,
    Map<ElementType, String>? imagePaths,
  }) {
    final buffer = StringBuffer();
    buffer.write(generateHeader(width, height));

    // 1. Background Layer
    final bgContent = elements
        .where((e) => e.type == ElementType.swipeUpUnlock) // Or actual bg
        .map((e) => generateElement(e, width, height, imgPath: imagePaths?[e.type]))
        .join();
    buffer.write(wrapInLayer(bgContent, 'Background'));

    // 2. Shape Layer
    final shapeContent = elements
        .where((e) => e.type.isContainer)
        .map((e) => generateElement(e, width, height))
        .join();
    buffer.write(wrapInLayer(shapeContent, 'Shape'));

    // 3. Texture Layer
    buffer.write(wrapInLayer('', 'Texture')); // Placeholder for Phase 4

    // 4. Effects Layer
    buffer.write(wrapInLayer('', 'Effects')); // Placeholder for Phase 4

    // 5. Icon/Content Layer
    final iconContent = elements
        .where((e) => !e.type.isContainer && e.type != ElementType.swipeUpUnlock)
        .map((e) => generateElement(e, width, height, imgPath: imagePaths?[e.type]))
        .join();
    buffer.write(wrapInLayer(iconContent, 'Icon'));

    // 6. Highlights Layer
    buffer.write(wrapInLayer('', 'Highlights')); // Placeholder for Phase 4

    buffer.write(generateFooter());
    return buffer.toString();
  }


  static String generateElement(LockElement el, double width, double height,
      {String? imgPath}) {
    if (el.type == ElementType.swipeUpUnlock) return '';

    final buffer = StringBuffer();
    final dx = el.dx * ratio;
    final dy = el.dy * ratio;
    final angle = el.angle;
    final scale = el.scale;

    buffer.writeln(
        '    <g id="element_${el.type.name}" transform="translate($dx, $dy) rotate($angle, ${width / 2}, ${height / 2}) scale($scale)">');

    if (el.type.isClock || el.type.isText) {
      _addText(buffer, el, width, height);
    } else if (el.type.isContainer) {
      _addContainer(buffer, el, width, height);
    } else {
      _addImage(buffer, el, width, height, imgPath);
    }

    buffer.writeln('    </g>');
    return buffer.toString();
  }

  static void _addText(
      StringBuffer buffer, LockElement el, double canvasW, double canvasH) {
    final color = _toHex(el.color);
    final fontSize = el.fontSize * ratio;
    final fontWeight = _toFontWeight(el.fontWeight);
    final fontFamily = el.font;

    String textAnchor = 'middle';
    double x = canvasW / 2;
    double y = canvasH / 2;

    final align = el.align as Alignment;
    x = canvasW / 2 + (align.x * canvasW / 2);
    y = canvasH / 2 + (align.y * canvasH / 2);

    if (align.x < -0.1) {
      textAnchor = 'start';
    } else if (align.x > 0.1) {
      textAnchor = 'end';
    }

    final text = el.type.isClock ? _getClockText(el.type, el.isShort) : el.text;

    buffer.writeln(
        '      <text x="$x" y="$y" fill="$color" font-family="$fontFamily" font-size="$fontSize" font-weight="$fontWeight" text-anchor="$textAnchor" alignment-baseline="middle">$text</text>');
  }

  static void _addContainer(
      StringBuffer buffer, LockElement el, double canvasW, double canvasH) {
    final color = _toHex(el.color);
    final borderColor = _toHex(el.borderColor);
    final borderWidth = el.borderWidth * ratio;
    final radius = el.radius * ratio;
    final w = el.width * ratio;
    final h = el.height * ratio;

    final align = el.align as Alignment;
    final x = (canvasW - w) / 2 + (align.x * (canvasW - w) / 2);
    final y = (canvasH - h) / 2 + (align.y * (canvasH - h) / 2);

    buffer.writeln(
        '      <rect x="$x" y="$y" width="$w" height="$h" rx="$radius" ry="$radius" fill="$color" stroke="$borderColor" stroke-width="$borderWidth" />');
  }

  static void _addImage(StringBuffer buffer, LockElement el, double canvasW,
      double canvasH, String? imgPath) {
    final w = el.width * ratio;
    final h = el.height * ratio;
    final align = el.align as Alignment;
    final x = (canvasW - w) / 2 + (align.x * (canvasW - w) / 2);
    final y = (canvasH - h) / 2 + (align.y * (canvasH - h) / 2);

    if (imgPath != null && File(imgPath).existsSync()) {
      final bytes = File(imgPath).readAsBytesSync();
      final base64Image = base64Encode(bytes);
      buffer.writeln(
          '      <image xlink:href="data:image/png;base64,$base64Image" x="$x" y="$y" width="$w" height="$h" />');
    } else {
      buffer.writeln('      <!-- Placeholder for ${el.type.name} -->');
      buffer.writeln(
          '      <rect x="$x" y="$y" width="$w" height="$h" fill="#cccccc" opacity="0.3" rx="${10 * ratio}" />');
    }
  }

  static String _toHex(Color c) {
    return '#${c.toARGB32().toRadixString(16).padLeft(8, '0').substring(2)}';
  }

  static String _toFontWeight(FontWeight fw) {
    final weights = {
      FontWeight.w100: '100',
      FontWeight.w200: '200',
      FontWeight.w300: '300',
      FontWeight.w400: '400',
      FontWeight.w500: '500',
      FontWeight.w600: '600',
      FontWeight.w700: '700',
      FontWeight.w800: '800',
      FontWeight.w900: '900',
    };
    return weights[fw] ?? '400';
  }

  static String _getClockText(ElementType type, bool isShort) {
    return switch (type) {
      ElementType.hourClock => '02',
      ElementType.minClock => '36',
      ElementType.dotClock => ':',
      ElementType.amPmClock => 'AM',
      ElementType.weekClock => isShort ? 'Wed' : 'Wednesday',
      ElementType.monthClock => isShort ? 'Feb' : 'February',
      ElementType.dateClock => '08',
      ElementType.weatherIconClock => 'Cloudy',
      _ => '',
    };
  }
}



