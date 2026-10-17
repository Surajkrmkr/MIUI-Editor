import 'dart:typed_data';

import 'package:archive/archive.dart' show getCrc32;

/// Stretch/padding metadata for an Android 9-patch.
class NinePatchSpec {
  const NinePatchSpec({
    required this.xDivs,
    required this.yDivs,
    this.padding = const [0, 0, 0, 0],
    this.outlineRadius = 0,
    this.outlineAlpha = 0xff,
  });

  /// Pairs of [start, end) stretch ranges in image pixels.
  final List<int> xDivs;
  final List<int> yDivs;

  /// Content padding: left, right, top, bottom.
  final List<int> padding;
  final double outlineRadius;
  final int outlineAlpha;

  /// Stretch a single centre row/column; content inset by [pad] on all sides.
  factory NinePatchSpec.centre(
    int w,
    int h, {
    int pad = 0,
    double radius = 0,
    int alpha = 0xff,
  }) => NinePatchSpec(
    xDivs: [w ~/ 2 - 1, w ~/ 2 + 1],
    yDivs: [h ~/ 2 - 1, h ~/ 2 + 1],
    padding: [pad, pad, pad, pad],
    outlineRadius: radius,
    outlineAlpha: alpha,
  );
}

/// Turns a plain PNG into a *compiled* 9-patch (what `aapt` produces and what
/// MIUI theme modules ship): the PNG gets `npOl` + `npTc` chunks after `IHDR`
/// instead of the 1px black guide border of source 9-patches.
abstract final class NinePatchPng {
  static const _noColor = 0x00000001;

  static Uint8List compile(Uint8List png, NinePatchSpec spec) {
    if (png.length < 33 ||
        String.fromCharCodes(png.sublist(12, 16)) != 'IHDR') {
      throw const FormatException('Not a PNG with a leading IHDR chunk');
    }
    final ihdrEnd = 8 + 12 + _u32(png, 8);
    final w = _u32(png, 16), h = _u32(png, 20);
    final out = BytesBuilder(copy: false)
      ..add(png.sublist(0, ihdrEnd))
      ..add(_chunk('npOl', _outline(spec)))
      ..add(_chunk('npTc', _patch(spec, w, h)))
      ..add(png.sublist(ihdrEnd));
    return out.toBytes();
  }

  /// Non-empty segments between 0, the divs and [size] (zero-width skipped).
  static int _segments(List<int> divs, int size) {
    final edges = {0, ...divs, size}.toList()..sort();
    var n = 0;
    for (var i = 1; i < edges.length; i++) {
      if (edges[i] > edges[i - 1]) n++;
    }
    return n;
  }

  static int _u32(Uint8List b, int o) =>
      (b[o] << 24) | (b[o + 1] << 16) | (b[o + 2] << 8) | b[o + 3];

  static Uint8List _chunk(String type, Uint8List data) {
    final typeBytes = Uint8List.fromList(type.codeUnits);
    final crcInput = Uint8List(4 + data.length)
      ..setAll(0, typeBytes)
      ..setAll(4, data);
    final b = ByteData(12 + data.length)
      ..setUint32(0, data.length)
      ..setUint32(8 + data.length, getCrc32(crcInput));
    final bytes = b.buffer.asUint8List()
      ..setAll(4, typeBytes)
      ..setAll(8, data);
    return bytes;
  }

  static Uint8List _outline(NinePatchSpec s) {
    final b = ByteData(24)
      ..setFloat32(16, s.outlineRadius)
      ..setUint8(20, s.outlineAlpha & 0xff);
    return b.buffer.asUint8List();
  }

  /// Serialized `Res_png_9patch`. Offsets are little-endian (aapt quirk);
  /// divs, padding and colors are big-endian.
  static Uint8List _patch(NinePatchSpec s, int w, int h) {
    final regions = _segments(s.xDivs, w) * _segments(s.yDivs, h);
    const xOff = 32;
    final yOff = xOff + s.xDivs.length * 4;
    final cOff = yOff + s.yDivs.length * 4;
    final b = ByteData(cOff + regions * 4)
      ..setUint8(0, 0)
      ..setUint8(1, s.xDivs.length)
      ..setUint8(2, s.yDivs.length)
      ..setUint8(3, regions)
      ..setUint32(4, xOff, Endian.little)
      ..setUint32(8, yOff, Endian.little)
      ..setInt32(12, s.padding[0])
      ..setInt32(16, s.padding[1])
      ..setInt32(20, s.padding[2])
      ..setInt32(24, s.padding[3])
      ..setUint32(28, cOff, Endian.little);
    for (var i = 0; i < s.xDivs.length; i++) {
      b.setInt32(xOff + i * 4, s.xDivs[i]);
    }
    for (var i = 0; i < s.yDivs.length; i++) {
      b.setInt32(yOff + i * 4, s.yDivs[i]);
    }
    for (var i = 0; i < regions; i++) {
      b.setUint32(cOff + i * 4, _noColor);
    }
    return b.buffer.asUint8List();
  }
}
