import 'package:test/test.dart';
import 'package:theme_core/theme_core.dart';
import 'package:xml/xml.dart';

XmlElement? _group(XmlDocument d, String name) => d
    .findAllElements('Group')
    .where((g) => g.getAttribute('name') == name)
    .firstOrNull;

void main() {
  const builder = ManifestBuilder();

  test('builds a manifest without Flutter', () {
    final doc = builder.build(const [
      LockElementSpec(type: ElementType.hourClock, dx: 10, dy: -20),
    ], bgAlpha: .5);

    expect(doc.rootElement.name.local, 'Lockscreen');
    expect(_group(doc, 'hourClock')!.innerXml, contains('hour/hour_'));
    expect(_group(doc, 'bgAlpha')!.innerXml, contains('alpha="128"'));
  });

  test('hidden elements are skipped', () {
    final doc = builder.build(const [
      LockElementSpec(type: ElementType.hourClock, isVisible: false),
    ]);
    expect(_group(doc, 'hourClock')!.innerXml, isEmpty);
  });

  test('video wallpaper swaps Wallpaper for Video + ExternalCommands', () {
    final plain = builder.build(const []);
    expect(plain.findAllElements('Wallpaper'), isNotEmpty);
    expect(plain.findAllElements('Video'), isEmpty);

    final video = builder.build(const [
      LockElementSpec(type: ElementType.videoWallpaper),
    ]);
    expect(video.findAllElements('Wallpaper'), isEmpty);
    expect(video.findAllElements('Video'), isNotEmpty);
  });

  test('weather elements add the refresh binder commands', () {
    final doc = builder.build(const [
      LockElementSpec(type: ElementType.weatherTemp),
    ]);
    final refresh = doc
        .findAllElements('BinderCommand')
        .where((c) => c.getAttribute('name') == 'WeatherService');
    expect(refresh.length, 2);
  });

  test('output is well-formed for every element type', () {
    for (final t in ElementType.values) {
      final xml = builder.build([LockElementSpec(type: t)]).toXmlString();
      expect(() => XmlDocument.parse(xml), returnsNormally, reason: t.name);
    }
  });
}
