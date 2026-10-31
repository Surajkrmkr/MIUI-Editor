import 'package:test/test.dart';
import 'package:theme_core/lockscreen_layout.dart';
import 'package:theme_core/theme_core.dart';
import 'package:xml/xml.dart';

TickerLayout _layout(TickerSource source, {int count = 9}) => TickerLayout.of(
  LockElementSpec(
    type: ElementType.countdownTicker,
    tickerSource: source,
    tickerCount: count,
    width: 1000,
    height: 200,
  ),
);

void main() {
  final may27 = DateTime(2026, 5, 27, 10, 30, 5);

  test('stored lengths snap to odd 5–11', () {
    expect(tickerCountOf(null), 9);
    expect(tickerCountOf(4), 5);
    expect(tickerCountOf(8), 7);
    expect(tickerCountOf(30), 11);
  });

  test('current value sits in the middle slot', () {
    for (final count in [5, 7, 9, 11]) {
      final slots = _layout(TickerSource.seconds, count: count).slots;
      expect(slots, hasLength(count));
      expect(slots[count ~/ 2].isCurrent, isTrue);
      expect(slots[count ~/ 2].center.dx, closeTo(500, .01));
    }
  });

  test('seconds count up and wrap within 0–59', () {
    final l = _layout(TickerSource.seconds);
    expect(l.current(may27), 5);
    expect(l.valueAt(may27, 1), 6);
    expect(l.valueAt(may27, -4), 1);
    expect(l.valueAt(may27, -6), 59);
    expect(l.format(5), '05');
  });

  test('days left in month and year, hidden past the ends', () {
    final month = _layout(TickerSource.monthDaysLeft);
    expect(month.current(may27), 4);
    expect(month.valueAt(may27, -4), 0);
    expect(month.valueAt(may27, -5), isNull);

    final year = _layout(TickerSource.yearDaysLeft);
    expect(year.current(may27), 365 - 147);
    expect(year.current(DateTime(2028, 12, 31)), 0);
    expect(year.current(DateTime(2028, 1, 1)), 365);
  });

  test('MAML vars use 0-based months and each element gets its own names', () {
    final xml = _layout(TickerSource.yearDaysLeft).varsXml;
    expect(xml, contains('eq(#month,4),120'));
    expect(xml, contains("name='ticker_countdownTicker_v'"));
    expect(
      _layout(TickerSource.seconds).valueExp(-1),
      '((#ticker_countdownTicker_v+599)%60)',
    );
  });

  test('exports the panel, the vars and one live number per slot', () {
    final doc = const ManifestBuilder().build(const [
      LockElementSpec(
        type: ElementType.countdownTicker,
        tickerStyle: TickerStyle.progressTrack,
        tickerSource: TickerSource.monthDaysLeft,
        tickerCount: 7,
      ),
    ]);
    expect(doc.toXmlString(), contains('calendar/countdownTicker_ticker.png'));
    expect(
      doc.findAllElements('Text').where(
        (t) => t.getAttribute('paras')?.contains('ticker_') ?? false,
      ),
      hasLength(7),
    );
    expect(
      doc.findAllElements('Rectangle').where(
        (r) => r.getAttribute('w')?.contains('ticker_') ?? false,
      ),
      hasLength(1),
    );
  });
}
