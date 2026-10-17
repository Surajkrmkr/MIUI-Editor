import 'package:test/test.dart';
import 'package:theme_core/theme_core.dart';

SpecParseResult _parseWith(List<Map<String, dynamic>> elements) =>
    ThemeSpec.parse({
      'specVersion': 1,
      'meta': {'title': 'T', 'designer': 'D', 'authorTag': 'Sj'},
      'wallpaper': {'home': 'w.jpg'},
      'icons': {'pack': 'u7'},
      'lockscreen': {'elements': elements},
    });

void main() {
  final lib = WidgetLibrary.builtin;

  test('ships the editor widget templates and four style sets', () {
    expect(lib.widgets.length, greaterThan(10));
    expect(lib.widgets.map((w) => w.name), contains('Battery Ring'));
    expect(lib.styleSets.map((s) => s.id), [
      'builtin-unlock',
      'builtin-analog',
      'builtin-shortcuts',
      'builtin-calendar',
    ]);
    for (final set in lib.styleSets) {
      expect(set.styles, isNotEmpty);
      expect({for (final s in set.styles) s.id}.length, set.styles.length);
    }
  });

  test('every widget template is valid spec elements', () {
    for (final w in lib.widgets) {
      final r = _parseWith(w.elements);
      expect(
        r.issues.where((i) => i.severity == IssueSeverity.error),
        isEmpty,
        reason: w.name,
      );
      expect(r.spec!.lockscreen.elements.length, w.elements.length);
      expect(
        r.issues.where((i) => i.code == 'lockscreen.duplicate_element'),
        isEmpty,
        reason: w.name,
      );
    }
  });

  test('every style applies to a bare element of its type', () {
    for (final set in lib.styleSets) {
      for (final style in set.styles) {
        final element = style.applyTo({'type': style.type.name});
        final r = _parseWith([element]);
        expect(
          r.issues.where((i) => i.severity == IssueSeverity.error),
          isEmpty,
          reason: '${set.id}/${style.id}',
        );
      }
    }
  });

  test('applying a style keeps the position and replaces the look', () {
    final style = lib.styleSets.first.styles.first;
    final out = style.applyTo({
      'type': style.type.name,
      'offsetX': 12.0,
      'unlockSkin': 'ring',
    });
    expect(out['offsetX'], 12.0);
    expect(out['unlockSkin'], style.appearance['unlockSkin'] ?? 'classic');
  });

  test('a style refuses another element type', () {
    final style = lib.styleSets.first.styles.first;
    expect(
      () => style.applyTo({'type': 'hourClock'}),
      throwsA(isA<FormatException>()),
    );
  });

  group('style set files saved by the editor', () {
    Map<String, dynamic> file(List<Map<String, dynamic>> styles) => {
      'format': 'miui-editor.widget-style-set',
      'version': 1,
      'id': 'mine',
      'name': 'Mine',
      'styles': styles,
    };

    test('are read, leaving out styles that carry an icon image', () {
      final set = WidgetStyleSet.fromEditorFile(
        file([
          {
            'id': 'a',
            'name': 'A',
            'type': 'tapToUnlock',
            'appearance': {'color': '#FFFFFF'},
          },
          {
            'id': 'b',
            'name': 'B',
            'type': 'tapToUnlock',
            'appearance': {'unlockIcon': 'customPng'},
            'iconPng': 'AAAA',
          },
          {'id': 'c', 'name': 'C', 'type': 'nope', 'appearance': {}},
        ]),
      )!;
      expect(set.styles.map((s) => s.id), ['a']);
      expect(set.skipped, 2);
    });

    test('other json is not a style set', () {
      expect(WidgetStyleSet.fromEditorFile({'format': 'other'}), isNull);
      expect(WidgetStyleSet.fromEditorFile([1]), isNull);
    });
  });
}
