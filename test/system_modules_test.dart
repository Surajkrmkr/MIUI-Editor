import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show FontLoader;
import 'package:flutter_test/flutter_test.dart';
import 'package:theme_core/theme_core.dart';
import 'package:miui_icon_generator/theme_editor/core/utils/wallpaper_palette.dart';
import 'package:miui_icon_generator/theme_editor/presentation/features/icon_editor/utils/control_center_painter.dart';
import 'package:miui_icon_generator/theme_editor/domain/usecases/export_system_modules_usecase.dart';
import 'package:xml/xml.dart';

/// Loads the Material Icons font so glyph-based drawables render in tests.
Future<void> _loadMaterialIcons() async {
  // flutter_tester lives at <root>/bin/cache/artifacts/engine/<platform>/.
  final flutterRoot =
      Platform.environment['FLUTTER_ROOT'] ??
      File(
        Platform.resolvedExecutable,
      ).parent.parent.parent.parent.parent.parent.path;
  final font = File(
    '$flutterRoot/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
  );
  if (!font.existsSync()) return;
  final loader = FontLoader('MaterialIcons')
    ..addFont(Future.value(ByteData.sublistView(font.readAsBytesSync())));
  await loader.load();
}

const _accent = Color(0xff3d7bff);

Future<String> _wallpaper(String dir, List<Color> colors) async {
  final rec = ui.PictureRecorder();
  const r = Rect.fromLTWH(0, 0, 1200, 2600);
  Canvas(rec).drawRect(
    r,
    Paint()..shader = ui.Gradient.linear(r.topLeft, r.bottomRight, colors),
  );
  final img = await rec.endRecording().toImage(1200, 2600);
  final png = await img.toByteData(format: ui.ImageByteFormat.png);
  final f = File('$dir/wall.png')..writeAsBytesSync(png!.buffer.asUint8List());
  return f.path;
}

Map<String, Uint8List> _chunks(Uint8List png) {
  final out = <String, Uint8List>{};
  final order = <String>[];
  var i = 8;
  final bd = ByteData.sublistView(png);
  while (i < png.length) {
    final len = bd.getUint32(i);
    final type = String.fromCharCodes(png.sublist(i + 4, i + 8));
    order.add(type);
    out.putIfAbsent(type, () => png.sublist(i + 8, i + 8 + len));
    i += 12 + len;
  }
  out['_order'] = Uint8List.fromList(order.join(',').codeUnits);
  return out;
}

int _segments(List<int> divs, int size) {
  final e = {0, ...divs, size}.toList()..sort();
  var n = 0;
  for (var i = 1; i < e.length; i++) {
    if (e[i] > e[i - 1]) n++;
  }
  return n;
}

void main() {
  test('NinePatchPng matches the aapt npTc layout of the reference theme', () {
    // 1x1 transparent PNG.
    final png = Uint8List.fromList([
      0x89,
      0x50,
      0x4e,
      0x47,
      0x0d,
      0x0a,
      0x1a,
      0x0a,
      0,
      0,
      0,
      13,
      0x49,
      0x48,
      0x44,
      0x52, //
      0, 0, 4, 0x38, 0, 0, 7, 0x80, 8, 6, 0, 0, 0, 0x5c, 0x72, 0xa8, 0x66, //
      0, 0, 0, 0, 0x49, 0x45, 0x4e, 0x44, 0xae, 0x42, 0x60, 0x82,
    ]);
    final out = NinePatchPng.compile(
      png,
      const NinePatchSpec(xDivs: [0, 1080], yDivs: [0, 24, 1897, 1920]),
    );
    final c = _chunks(out);
    expect(String.fromCharCodes(c['_order']!), startsWith('IHDR,npOl,npTc'));
    final np = c['npTc']!;
    // Same header bytes as the reference miuix_appcompat_window_bg_light.9.png.
    expect(np.sublist(0, 4), [0, 2, 4, 3]);
    expect(np.sublist(4, 12), [0x20, 0, 0, 0, 0x28, 0, 0, 0]);
    expect(np.sublist(28, 32), [0x38, 0, 0, 0]);
    expect(np.length, 68);
  });

  for (final dark in [false, true]) {
    testWidgets('generates valid ${dark ? 'dark' : 'light'} system modules', (
      tester,
    ) async {
      await tester.runAsync(() async {
        await _loadMaterialIcons();
        final root = Directory(
          'build/visual_check/system_modules/${dark ? 'dark' : 'light'}',
        );
        if (root.existsSync()) root.deleteSync(recursive: true);
        root.createSync(recursive: true);
        final wall = await _wallpaper(
          root.path,
          dark
              ? const [Color(0xff0b1026), Color(0xff2a1b4d)]
              : const [Color(0xfffde2ea), Color(0xffd9e4ff)],
        );

        final failure = await const ExportSystemModulesUseCase().call(
          accent: _accent,
          layout: ThemeLayout(root.path),
          wallpaperSourcePath: wall,
          style: const IconStyle(
            shape: IconShape.cookie7,
            effect: IconEffect.liquidGlass,
            texture: IconTexture.grain,
            bgColor: Rgba(0xff3d7bff),
            bgColor2: Rgba(0xff8a5cff),
          ),
          iconFolder: 'u10',
        );
        expect(failure, isNull, reason: failure?.toString());

        for (final m in ExportSystemModulesUseCase.modules) {
          expect(
            Directory('${root.path}/$m/nightmode').existsSync(),
            isFalse,
            reason: '$m has dark-mode output',
          );
          {
            final dir = Directory('${root.path}/$m');
            final values = File(
              '${dir.path}/theme_values.xml',
            ).readAsStringSync();
            XmlDocument.parse(values);
            XmlDocument.parse(
              File('${dir.path}/theme_fallback.xml').readAsStringSync(),
            );
            expect(
              values.toLowerCase(),
              isNot(contains('f97c76')),
              reason: '$m kept ref accent',
            );
            expect(values, contains('3d7bff'), reason: '$m missing accent');
            expect(
              values.contains('DarkTemplate'),
              isFalse,
              reason:
                  '$m should stay light for a ${dark ? 'dark' : 'light'} wallpaper',
            );

            final pngs = Directory(
              '${dir.path}/res/drawable-xxhdpi',
            ).listSync().whereType<File>();
            expect(pngs, isNotEmpty, reason: m);
            for (final f in pngs) {
              final bytes = f.readAsBytesSync();
              final codec = await ui.instantiateImageCodec(bytes);
              final frame = (await codec.getNextFrame()).image;
              if (!f.path.endsWith('.9.png')) continue;
              final c = _chunks(bytes);
              expect(
                String.fromCharCodes(c['_order']!),
                startsWith('IHDR,npOl,npTc'),
                reason: f.path,
              );
              final np = ByteData.sublistView(c['npTc']!);
              final nx = np.getUint8(1),
                  ny = np.getUint8(2),
                  nc = np.getUint8(3);
              final xs = [for (var i = 0; i < nx; i++) np.getInt32(32 + i * 4)];
              final ys = [
                for (var i = 0; i < ny; i++) np.getInt32(32 + nx * 4 + i * 4),
              ];
              expect(
                xs.every((v) => v >= 0 && v <= frame.width),
                isTrue,
                reason: f.path,
              );
              expect(
                ys.every((v) => v >= 0 && v <= frame.height),
                isTrue,
                reason: f.path,
              );
              expect(
                nc,
                _segments(xs, frame.width) * _segments(ys, frame.height),
                reason: f.path,
              );
            }
          }
        }
      });
    });
  }

  test('control center templates override plugin colors', () {
    const xml =
        '<color name="qs_icon_enabled_color" >#fff97c76</color>\n'
        '<color name="qs_icon_enabled_color_dark" >#fff97c76</color>';
    final out = ExportSystemModulesUseCase.withColors(xml, {
      'qs_icon_enabled_color': const Color(0x80112233),
    });
    expect(out, contains('"qs_icon_enabled_color" >#80112233<'));
    expect(out, contains('"qs_icon_enabled_color_dark" >#fff97c76<'));
  });

  testWidgets('renders every control center template', (tester) async {
    await tester.runAsync(() async {
      const cell = Size(200, 248);
      const t = ControlCenterTemplate.values;
      final rec = ui.PictureRecorder();
      final c = Canvas(rec);
      final palettes = [
        WallpaperPalette.fromSeed(
          const Color(0xff0f9d8f),
          const Color(0xff4b8dff),
        ),
        WallpaperPalette.fromSeed(
          const Color(0xffe0455a),
          const Color(0xfff2b33d),
        ),
      ];
      for (var row = 0; row < palettes.length; row++) {
        for (var i = 0; i < t.length; i++) {
          final s = CcStyle(template: t[i], palette: palettes[row]);
          c.save();
          c.translate(i * (cell.width + 10), row * (cell.height + 10));
          ControlCenterPainter.preview(c, cell, s);
          c.restore();
          expect(ControlCenterPainter.colors(s), isNotEmpty);
        }
      }
      final img = await rec.endRecording().toImage(
        (t.length * (cell.width + 10)).round(),
        (palettes.length * (cell.height + 10)).round(),
      );
      final png = await img.toByteData(format: ui.ImageByteFormat.png);
      await Directory('build/visual_check').create(recursive: true);
      File(
        'build/visual_check/cc_templates.png',
      ).writeAsBytesSync(png!.buffer.asUint8List());
    });
  });
}
