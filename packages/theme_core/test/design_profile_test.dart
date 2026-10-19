import 'package:test/test.dart';
import 'package:theme_core/theme_core.dart';

LockElementSpec el(
  ElementType type, {
  double dx = 0,
  double dy = 0,
  Rgba color = const Rgba(0xFFFFFFFF),
  bool visible = true,
}) => LockElementSpec(
  type: type,
  dx: dx,
  dy: dy,
  color: color,
  isVisible: visible,
);

void main() {
  final a = DesignProfile([
    el(ElementType.hourClock, dy: -100),
    el(ElementType.minClock, dy: -100),
    el(ElementType.slideToUnlock),
    el(ElementType.weatherTemp),
  ]);

  test('the same design is fully similar', () {
    expect(a.similarityTo(a), closeTo(1, 1e-9));
  });

  test('a different design is far from it', () {
    final b = DesignProfile([
      el(
        ElementType.analogClock,
        dx: 90,
        dy: 150,
        color: const Rgba(0xFFFF2200),
      ),
      el(ElementType.tapToUnlock),
      el(ElementType.calendarGrid),
      el(ElementType.rectangleShape),
    ]);
    expect(a.similarityTo(b), lessThan(.25));
  });

  test('a design that only changes the color stays close', () {
    final c = DesignProfile([
      el(ElementType.hourClock, dy: -100, color: const Rgba(0xFFFFCC00)),
      el(ElementType.minClock, dy: -100),
      el(ElementType.slideToUnlock),
      el(ElementType.weatherTemp),
    ]);
    expect(a.similarityTo(c), greaterThan(.8));
    expect(a.sharedWith(c), contains('4 elements in the same place'));
  });

  test('the same pieces in other places are not the same design', () {
    final moved = DesignProfile([
      el(ElementType.hourClock, dx: 80, dy: 150),
      el(ElementType.minClock, dx: 80, dy: 200),
      el(ElementType.slideToUnlock, dy: -200),
      el(ElementType.weatherTemp, dx: -90, dy: -50),
    ]);
    expect(a.similarityTo(moved), lessThan(.55));
  });

  test('hidden elements are left out', () {
    final p = DesignProfile([
      el(ElementType.hourClock),
      el(ElementType.weatherTemp, visible: false),
    ]);
    expect(p.count, 1);
    expect(p.hasInfo, isFalse);
  });

  test('color families group near colors', () {
    DesignProfile one(int argb) =>
        DesignProfile([el(ElementType.hourClock, color: Rgba(argb))]);
    expect(one(0xFFFFFFFF).colorFamily, 'light');
    expect(one(0xFF101010).colorFamily, 'dark');
    expect(one(0xFFFF0000).colorFamily, 'red');
    expect(one(0xFF0000FF).colorFamily, 'blue');
    expect(one(0xFF00FF00).colorFamily, 'green');
  });
}
