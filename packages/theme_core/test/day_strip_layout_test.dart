import 'package:test/test.dart';
import 'package:theme_core/lockscreen_layout.dart';
import 'package:theme_core/theme_core.dart';
import 'package:xml/xml.dart';

void main() {
  test('today is the middle slot for every day count', () {
    for (final count in [3, 5, 7]) {
      final slots = DayStripLayout.of(
        LockElementSpec(type: ElementType.dayStrip, dayStripCount: count),
      ).slots;
      expect(slots, hasLength(count));
      expect(slots[count ~/ 2].isToday, isTrue);
      expect(slots.first.offset, -(count ~/ 2));
    }
  });

  test('stored day counts snap to 3, 5 or 7', () {
    expect(dayStripCountOf(null), 3);
    expect(dayStripCountOf(4), 3);
    expect(dayStripCountOf(6), 5);
    expect(dayStripCountOf(12), 7);
  });

  test('every style keeps its slots inside the element', () {
    for (final style in DayStripStyle.values) {
      for (final count in [3, 5, 7]) {
        final l = DayStripLayout.of(
          LockElementSpec(
            type: ElementType.dayStrip,
            dayStripStyle: style,
            dayStripCount: count,
            width: 600,
            height: 200,
          ),
        );
        for (final s in l.slots) {
          expect(s.box.left, greaterThanOrEqualTo(-.01), reason: '$style');
          expect(s.box.right, lessThanOrEqualTo(600.01), reason: '$style');
          expect(s.box.top, greaterThanOrEqualTo(-.01), reason: '$style');
          expect(s.box.bottom, lessThanOrEqualTo(200.01), reason: '$style');
        }
      }
    }
  });

  test('MAML labels follow the device weekday', () {
    final l = DayStripLayout.of(
      const LockElementSpec(type: ElementType.dayStrip),
    );
    // A Wednesday: MAML #day_of_week is 4, Dart weekday is 3.
    final wed = DateTime(2026, 5, 27);
    for (final o in [-1, 0, 1]) {
      final exp = l.labelExp(o);
      final idx = (4 - 1 + o + 70) % 7;
      expect(exp, contains("substr('SUNMONTUEWEDTHUFRISAT'"));
      expect(
        'SUNMONTUEWEDTHUFRISAT'.substring(idx * 3, idx * 3 + 3),
        l.labelFor(wed.add(Duration(days: o))),
      );
    }
  });

  test('exports the strip panel and one live label per day', () {
    final doc = const ManifestBuilder().build(const [
      LockElementSpec(
        type: ElementType.dayStrip,
        dayStripStyle: DayStripStyle.calendarTear,
        dayStripCount: 5,
      ),
    ]);
    final xml = doc.toXmlString();
    expect(xml, contains('calendar/dayStrip_strip.png'));
    expect(
      doc.findAllElements('Text').where(
        (t) => t.getAttribute('textExp')?.contains('#day_of_week') ?? false,
      ),
      hasLength(5),
    );
    expect(
      doc.findAllElements('DateTime').where(
        (t) => t.getAttribute('value')?.contains('86400000') ?? false,
      ),
      hasLength(5),
    );
    expect(XmlDocument.parse(xml), isNotNull);
  });
}
