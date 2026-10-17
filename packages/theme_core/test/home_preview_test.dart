import 'dart:io';
import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:theme_core/theme_core.dart';

void main() {
  late Directory ws;

  setUp(() => ws = Directory.systemTemp.createTempSync('home_preview_test'));
  tearDown(() => ws.deleteSync(recursive: true));

  void solid(String rel, int w, int h, img.Color c) {
    File(p.join(ws.path, rel))
      ..createSync(recursive: true)
      ..writeAsBytesSync(
        img.encodePng(img.Image(width: w, height: h)..clear(c)),
      );
  }

  void workspace(List<String> icons) {
    solid(
      'wallpaper/default_wallpaper.jpg',
      270,
      585,
      img.ColorRgb8(0, 0, 255),
    );
    for (final n in icons) {
      solid(
        'icons/res/drawable-xxhdpi/$n.png',
        180,
        180,
        img.ColorRgb8(255, 0, 0),
      );
    }
  }

  img.Image decode(List<int> bytes) =>
      img.decodePng(Uint8List.fromList(bytes))!;

  test('output keeps the 1080x2340 aspect at the requested width', () {
    workspace(['com.android.settings']);
    final im = decode(HomePreview.compose(ws.path));
    expect((im.width, im.height), (540, 1170));
  });

  test('icons land on the grid and the wallpaper fills the rest', () {
    workspace(['com.android.settings', 'com.android.mms']);
    final im = decode(HomePreview.compose(ws.path, width: 1080));

    // First grid cell: settings icon centre.
    expect(im.getPixel(180, 420).r, 255);
    expect(im.getPixel(180, 420).b, 0);
    // Empty area keeps the wallpaper colour.
    expect(im.getPixel(900, 1500).b, 255);
    // Dock bar is tinted translucent white over the wallpaper, mms icon on top.
    expect(im.getPixel(90 + 90, 2020 + 35 + 90).r, 255);
    expect(im.getPixel(900, 2040).r, greaterThan(0));
  });

  test('app icons are not drawn twice or taken from system resources', () {
    workspace(['com.android.mms', 'status_bar_toggle_data_on', 'icon_mask']);
    final im = decode(HomePreview.compose(ws.path, width: 1080));
    // mms is in the dock only; the first grid cell stays wallpaper.
    expect(im.getPixel(180, 420).b, 255);
  });

  test('a folder that was never built explains itself', () {
    expect(
      () => HomePreview.compose(ws.path),
      throwsA(
        isA<AppException>().having(
          (e) => e.message,
          'message',
          contains('wallpaper'),
        ),
      ),
    );
    solid('wallpaper/default_wallpaper.jpg', 10, 10, img.ColorRgb8(0, 0, 0));
    expect(
      () => HomePreview.compose(ws.path),
      throwsA(
        isA<AppException>().having(
          (e) => e.message,
          'message',
          contains('icons'),
        ),
      ),
    );
  });
}
