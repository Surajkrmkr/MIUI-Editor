import 'package:test/test.dart';
import 'package:theme_core/theme_core.dart';

void main() {
  final json = baseSpec(title: 'Neon', wallpaper: 'w.jpg', week: '3');

  test('the base spec is a valid spec', () {
    final r = ThemeSpec.parse(json);
    expect(
      r.issues.where((i) => i.severity == IssueSeverity.error),
      isEmpty,
      reason: r.issues.join('\n'),
    );
    expect(r.spec!.meta.title, 'Neon');
    expect(r.spec!.wallpaper.home, 'w.jpg');
    expect(r.spec!.workspace?.week, '3');
  });

  test('the base lockscreen passes every design check', () {
    final d = DesignProfile(ThemeSpec.parse(json).spec!.lockscreen.elements);
    expect(d.count, greaterThanOrEqualTo(DesignProfile.minElements));
    expect(d.hasClock, isTrue);
    expect(d.hasInfo, isTrue);
    expect(d.hasDecoration, isTrue);
    expect(d.fontSizes, greaterThan(1));
    expect(d.unlock, isNotNull);
    expect(d.hasSwipeUp, isTrue);
  });

  test('everything sits on the screen with a margin', () {
    for (final e in ThemeSpec.parse(json).spec!.lockscreen.elements) {
      expect(e.dx.abs(), lessThanOrEqualTo(138 - 12), reason: e.name);
      expect(e.dy.abs(), lessThanOrEqualTo(300), reason: e.name);
    }
  });

  test('element names are unique', () {
    final names = [
      for (final e in ThemeSpec.parse(json).spec!.lockscreen.elements) e.name,
    ];
    expect(names.toSet().length, names.length);
  });

  test('a new list every call, so edits do not leak', () {
    baseElements().first['dx'] = 999;
    expect(baseElements().first['dx'], -40);
  });

  test('the guide gives the canvas size and the unit rule', () {
    expect(baseLayoutGuide, contains('277'));
    expect(baseLayoutGuide, contains('3.9'));
  });
}
