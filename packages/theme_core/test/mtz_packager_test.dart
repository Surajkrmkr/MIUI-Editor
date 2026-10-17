import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:test/test.dart';
import 'package:theme_core/theme_core.dart';
import 'package:xml/xml.dart';

void main() {
  late Directory tmp;
  late ThemeLayout layout;
  late File wallpaper;

  setUp(() {
    tmp = Directory.systemTemp.createTempSync('mtz_test');
    layout = ThemeLayout('${tmp.path}/Week1/Neon');
    Directory(layout.root).createSync(recursive: true);
    wallpaper = File('${tmp.path}/wall.jpg')..writeAsBytesSync([1, 2, 3]);
  });

  tearDown(() => tmp.deleteSync(recursive: true));

  Future<void> writeBase({String title = 'Neon', String uiVersion = '17'}) =>
      const ThemeBaseWriter().write(
        layout: layout,
        title: title,
        designer: 'Suraj',
        authorTag: 'Sj',
        wallpaperSourcePath: wallpaper.path,
        uiVersion: uiVersion,
      );

  void writeFile(String path, [List<int> bytes = const [0]]) => File(path)
    ..createSync(recursive: true)
    ..writeAsBytesSync(bytes);

  void writeCompleteSystemModules() {
    for (final m in ThemeModules.system) {
      writeFile('${layout.module(m)}/theme_values.xml');
    }
    writeFile(
      '${layout.moduleDrawables('miui.systemui.plugin')}/qs_background_enabled.png',
    );
    writeFile(
      '${layout.moduleDrawables('com.android.systemui')}/notification_item_bg.9.png',
    );
    writeFile(
      '${layout.moduleDrawables('com.android.mms')}/miuix_appcompat_action_button_main_new.png',
    );
    writeFile(
      '${layout.moduleDrawables('com.android.settings')}/ic_wifi_settings.png',
    );
  }

  Archive open(String mtz) =>
      ZipDecoder().decodeBytes(File(mtz).readAsBytesSync());

  test(
    'ThemeBaseWriter writes wallpapers, clock, description and plugin config',
    () async {
      await writeBase();

      expect(File(layout.defaultWallpaper).readAsBytesSync(), [1, 2, 3]);
      expect(File(layout.defaultLockWallpaper).readAsBytesSync(), [1, 2, 3]);
      expect(File(layout.clockManifest).existsSync(), isTrue);
      expect(File(layout.pluginConfigXml).existsSync(), isTrue);
      final desc = File(layout.descriptionXml).readAsStringSync();
      expect(desc, contains('<uiVersion>17</uiVersion>'));
      expect(desc, contains('<designer>Suraj</designer>'));
    },
  );

  test('description fields are XML-escaped', () async {
    await writeBase(title: 'Rock & <Roll>');
    final doc = XmlDocument.parse(
      File(layout.descriptionXml).readAsStringSync(),
    );
    expect(doc.findAllElements('title').single.innerText, 'Rock & <Roll>');
  });

  test('pack puts base files flat and each module in a nested zip', () async {
    await writeBase();
    writeFile('${layout.iconsXxhdpi}/a.png', [9, 9]);
    writeFile('${layout.lockscreenAdvance}/manifest.xml', [7]);
    writeCompleteSystemModules();

    final (mtz, failure) = await const MtzPackager().pack(
      layout: layout,
      name: 'Neon',
    );
    expect(failure, isNull, reason: failure?.toString());
    expect(mtz, layout.mtzFile('Neon'));

    final root = open(mtz!);
    final names = root.files.where((f) => f.isFile).map((f) => f.name).toSet();
    expect(
      names,
      containsAll([
        'description.xml',
        'plugin_config.xml',
        'wallpaper/default_wallpaper.jpg',
        'wallpaper/default_lock_wallpaper.jpg',
        ...ThemeModules.packed,
      ]),
    );

    final icons = ZipDecoder().decodeBytes(
      Uint8List.fromList(root.findFile('icons')!.content as List<int>),
    );
    expect(
      icons.files.where((f) => f.isFile).map((f) => f.name),
      contains('res/drawable-xxhdpi/a.png'),
    );
    expect(Directory(layout.tempDir).existsSync(), isFalse);
  });

  test('descriptionXml replaces the file inside the archive only', () async {
    await writeBase();
    final (mtz, _) = await const MtzPackager().pack(
      layout: layout,
      name: 'Neon_V1',
      descriptionXml: '<MIUI-Theme><uiVersion>15</uiVersion></MIUI-Theme>',
    );

    final inside = String.fromCharCodes(
      open(mtz!).findFile('description.xml')!.content as List<int>,
    );
    expect(inside, contains('<uiVersion>15</uiVersion>'));
    expect(
      File(layout.descriptionXml).readAsStringSync(),
      contains('<uiVersion>17</uiVersion>'),
    );
  });

  test('refuses to pack half-generated system modules', () async {
    await writeBase();
    writeFile('${layout.module('com.android.mms')}/theme_values.xml');

    final (mtz, failure) = await const MtzPackager().pack(
      layout: layout,
      name: 'Neon',
    );
    expect(mtz, isNull);
    expect(failure, isA<ExportFailure>());
    expect(File(layout.mtzFile('Neon')).existsSync(), isFalse);
  });

  test('missingOutputs lists nothing for a complete theme', () {
    writeCompleteSystemModules();
    expect(ThemeModules.missingOutputs(layout), isEmpty);
  });
}
