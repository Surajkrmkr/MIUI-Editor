import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';
import 'package:image/image.dart' as img;

/// Per-channel tolerance on mean RGBA, to absorb raster/AA differences across OSes.
const pngMeanTolerance = 2;

const moduleEntries = {
  'icons',
  'clock_2x4',
  'lockscreen',
  'miui.systemui.plugin',
  'com.android.systemui',
  'com.android.contacts',
  'com.android.mms',
  'com.android.settings',
};

Map<String, Object> describeFile(String name, Uint8List bytes) {
  final lower = name.toLowerCase();
  if (lower.endsWith('.png')) {
    final decoded = img.decodePng(bytes);
    if (decoded == null) {
      return {'kind': 'png-undecodable', 'bytes': bytes.length};
    }
    final rgba = decoded.getBytes(order: img.ChannelOrder.rgba);
    final sums = [0, 0, 0, 0];
    for (var i = 0; i < rgba.length; i++) {
      sums[i & 3] += rgba[i];
    }
    final n = decoded.width * decoded.height;
    return {
      'kind': 'png',
      'w': decoded.width,
      'h': decoded.height,
      'mean': [for (final s in sums) n == 0 ? 0 : (s / n).round()],
    };
  }
  final normalized = lower.endsWith('.xml')
      ? utf8.encode(utf8.decode(bytes).replaceAll('\r\n', '\n'))
      : bytes;
  return {
    'kind': lower.endsWith('.xml') ? 'xml' : 'bin',
    'bytes': normalized.length,
    'sha256': sha256.convert(normalized).toString(),
  };
}

Map<String, Object> snapshotMtz(String mtzPath) {
  final out = <String, Object>{};
  final root = ZipDecoder().decodeBytes(File(mtzPath).readAsBytesSync());
  for (final f in root.files.where((f) => f.isFile)) {
    final bytes = Uint8List.fromList(f.content as List<int>);
    if (moduleEntries.contains(f.name)) {
      final inner = ZipDecoder().decodeBytes(bytes);
      for (final e in inner.files.where((e) => e.isFile)) {
        final eb = Uint8List.fromList(e.content as List<int>);
        out['${f.name}!/${e.name}'] = describeFile(e.name, eb);
      }
    } else {
      out[f.name] = describeFile(f.name, bytes);
    }
  }
  return Map.fromEntries(
    out.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
  );
}

List<String> diffSnapshots(
  Map<String, Object> golden,
  Map<String, Object> actual,
) {
  final problems = <String>[];
  for (final k in golden.keys.where((k) => !actual.containsKey(k))) {
    problems.add('missing: $k');
  }
  for (final k in actual.keys.where((k) => !golden.containsKey(k))) {
    problems.add('unexpected: $k');
  }
  for (final k in golden.keys.where(actual.containsKey)) {
    final g = Map<String, Object?>.from(golden[k]! as Map);
    final a = Map<String, Object?>.from(actual[k]! as Map);
    if (g['kind'] == 'png' && a['kind'] == 'png') {
      if (g['w'] != a['w'] || g['h'] != a['h']) {
        problems.add(
          'size changed: $k ${g['w']}x${g['h']} -> ${a['w']}x${a['h']}',
        );
        continue;
      }
      final gm = (g['mean']! as List).cast<int>();
      final am = (a['mean']! as List).cast<int>();
      for (var i = 0; i < 4; i++) {
        if ((gm[i] - am[i]).abs() > pngMeanTolerance) {
          problems.add('pixels changed: $k mean $gm -> $am');
          break;
        }
      }
    } else if (jsonEncode(g) != jsonEncode(a)) {
      problems.add('content changed: $k');
    }
  }
  return problems;
}
