import 'dart:convert';

import 'package:json_schema/json_schema.dart';
import 'package:test/test.dart';
import 'package:theme_core/theme_core.dart';

Map<String, dynamic> _json(Object? o) =>
    jsonDecode(jsonEncode(o)) as Map<String, dynamic>;

void main() {
  final schema = JsonSchema.create(_json(themeSpecSchema()));

  Map<String, dynamic> spec({List<Object?>? elements}) => {
    'specVersion': 1,
    'meta': {'title': 'Neon'},
    'wallpaper': {'home': 'wall.png'},
    'icons': {'pack': 'u1'},
    'lockscreen': {
      'elements':
          elements ??
          [
            {'type': 'swipeUpUnlock'},
          ],
    },
  };

  bool accepts(Object? doc) => schema.validate(doc).isValid;

  String why(Object? doc) => schema
      .validate(doc)
      .errors
      .map((e) => '${e.instancePath}: ${e.message}')
      .join('; ');

  test(r'a spec may point at its schema with $schema', () {
    final doc = spec()..[r'$schema'] = 'theme.schema.json';
    expect(accepts(doc), isTrue, reason: why(doc));
    expect(ThemeSpec.parse(doc).issues, isEmpty);
  });

  test('a minimal spec conforms', () {
    expect(accepts(spec()), isTrue, reason: why(spec()));
  });

  test('every element type conforms with all of its fields written out', () {
    final elements = [
      for (final t in ElementType.values) LockElementSpec(type: t).toJson(),
    ];
    final doc = spec(elements: _json({'e': elements})['e']);
    expect(accepts(doc), isTrue, reason: why(doc));
  });

  test('every value of every enum field conforms', () {
    for (final entry in LockscreenSpec.enumKeys.entries) {
      for (final v in entry.value) {
        final doc = spec(
          elements: [
            {'type': 'hourClock', entry.key: v.name},
          ],
        );
        expect(
          accepts(doc),
          isTrue,
          reason: '${entry.key}=${v.name}: ${why(doc)}',
        );
      }
    }
    for (final shape in IconShape.values) {
      final doc = spec()..['icons'] = {'pack': 'u1', 'shape': shape.name};
      expect(accepts(doc), isTrue, reason: '$shape: ${why(doc)}');
    }
  });

  test('what the spec writes is what the schema accepts', () {
    final doc = _json(ThemeSpec.fromJson(spec()).toJson());
    expect(accepts(doc), isTrue, reason: why(doc));
  });

  test('colors, alignments and weights take every form the reader takes', () {
    final doc = spec(
      elements: [
        {'type': 'swipeUpUnlock'},
        {
          'type': 'hourClock',
          'color': '#FFF',
          'colorSecondary': '80FF00FF',
          'strokeColor': 4294967295,
          'align': [0.5, -0.25],
          'gradStartAlign': 'Alignment.topLeft',
          'fontWeight': 700,
        },
        {'type': 'minClock', 'fontWeight': 'FontWeight.w300'},
      ],
    );
    expect(accepts(doc), isTrue, reason: why(doc));
    expect(ThemeSpec.parse(doc).ok, isTrue);
  });

  group('rejects', () {
    final bad = <String, Map<String, dynamic> Function()>{
      'a typo in an element type': () => spec(
        elements: [
          {'type': 'hourClok'},
        ],
      ),
      'an unknown element key': () => spec(
        elements: [
          {'type': 'hourClock', 'colour': '#FFFFFF'},
        ],
      ),
      'a bad color': () => spec(
        elements: [
          {'type': 'hourClock', 'color': '#7C8CF'},
        ],
      ),
      'a bad alignment': () => spec(
        elements: [
          {'type': 'hourClock', 'align': 'middle'},
        ],
      ),
      'an element without a type': () => spec(elements: [{}]),
      'an unknown top-level key': () => spec()..['extras'] = 1,
      'a missing wallpaper': () => spec()..remove('wallpaper'),
      'a missing icon pack': () => spec()..['icons'] = <String, Object?>{},
      'a wrong specVersion': () => spec()..['specVersion'] = 2,
      'bgAlpha above 1': () => spec()..['lockscreen'] = {'bgAlpha': 1.5},
      'a font without a ref': () => spec()
        ..['fonts'] = [
          {'path': 'x.ttf'},
        ],
    };
    for (final entry in bad.entries) {
      test(entry.key, () => expect(accepts(entry.value()), isFalse));
    }
  });

  test('agrees with the reader on the structural cases above', () {
    for (final entry in {
      'a typo in an element type': spec(
        elements: [
          {'type': 'hourClok'},
        ],
      ),
      'a bad color': spec(
        elements: [
          {'type': 'hourClock', 'color': '#7C8CF'},
        ],
      ),
      'a missing wallpaper': spec()..remove('wallpaper'),
    }.entries) {
      expect(ThemeSpec.parse(entry.value).ok, isFalse, reason: entry.key);
    }
  });
}
