import 'package:test/test.dart';
import 'package:theme_core/theme_core.dart';

void main() {
  group('Rgba', () {
    test('parses #RGB, #RRGGBB and #AARRGGBB with or without #', () {
      expect(Rgba.fromHex('#fc0'), const Rgba(0xFFFFCC00));
      expect(Rgba.fromHex('3d7bff'), const Rgba(0xFF3D7BFF));
      expect(Rgba.fromHex('#803D7BFF'), const Rgba(0x803D7BFF));
    });

    test('rejects malformed hex', () {
      expect(Rgba.tryParseHex('#12'), isNull);
      expect(Rgba.tryParseHex('#GGGGGG'), isNull);
      expect(() => Rgba.fromHex('nope'), throwsFormatException);
    });

    test('tryParse accepts the legacy int and hex strings only', () {
      expect(Rgba.tryParse(0xFF112233), const Rgba(0xFF112233));
      expect(Rgba.tryParse('#112233'), const Rgba(0xFF112233));
      expect(Rgba.tryParse(-1), isNull);
      expect(Rgba.tryParse(1.5), isNull);
      expect(Rgba.tryParse(null), isNull);
    });

    test('formats upper-case hex', () {
      const c = Rgba(0x803D7BFF);
      expect(c.toHex(), '#3D7BFF');
      expect(c.toHex(withAlpha: true), '#803D7BFF');
      expect(c.toMamlHex(), '#FF3D7BFF');
    });

    test('channel getters and alpha helpers', () {
      const c = Rgba.fromARGB(0x80, 1, 2, 3);
      expect([c.a, c.r, c.g, c.b], [0x80, 1, 2, 3]);
      expect(c.withAlpha(0xFF).a, 0xFF);
      expect(c.withOpacity(0).a, 0);
      expect(c.withOpacity(2).a, 255);
    });

    test('contrast ratio matches the WCAG extremes', () {
      const black = Rgba(0xFF000000), white = Rgba(0xFFFFFFFF);
      expect(black.contrastWith(white), closeTo(21, 1e-9));
      expect(white.contrastWith(white), closeTo(1, 1e-9));
      expect(black.luminance, 0);
      expect(white.luminance, closeTo(1, 1e-9));
    });
  });

  group('Alignment2', () {
    test('parses the legacy names used in preset JSON', () {
      expect(Alignment2.tryParse('Alignment.topLeft'), Alignment2.topLeft);
      expect(
        Alignment2.tryParse('Alignment.bottomRight'),
        Alignment2.bottomRight,
      );
      expect(Alignment2.tryParse('Alignment.nowhere'), isNull);
    });

    test('parses [x, y] lists', () {
      expect(Alignment2.tryParse([-1, 0.5]), const Alignment2(-1, 0.5));
      expect(Alignment2.tryParse([1]), isNull);
      expect(Alignment2.tryParse(['a', 'b']), isNull);
    });

    test('round-trips grid positions through the legacy string', () {
      for (final a in [
        Alignment2.topLeft,
        Alignment2.topCenter,
        Alignment2.topRight,
        Alignment2.centerLeft,
        Alignment2.center,
        Alignment2.centerRight,
        Alignment2.bottomLeft,
        Alignment2.bottomCenter,
        Alignment2.bottomRight,
      ]) {
        expect(Alignment2.tryParse(a.toLegacyString()), a);
      }
    });

    test('off-grid positions fall back to center in legacy form', () {
      expect(const Alignment2(0.3, 0.3).toLegacyString(), 'Alignment.center');
    });
  });
}
