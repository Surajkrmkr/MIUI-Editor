import 'package:test/test.dart';
import 'package:theme_core/lockscreen_layout.dart';
import 'package:theme_core/theme_core.dart';
import 'package:xml/xml.dart';

void main() {
  final wed = GaugeSample(now: DateTime(2026, 5, 27, 18, 0, 30));

  test('slot lists parse in order, drop unknowns and cap at six', () {
    expect(GaugeSource.parse('aqi, battery,nope'), [
      GaugeSource.aqi,
      GaugeSource.battery,
    ]);
    expect(GaugeSource.parse(''), GaugeSource.defaults);
    expect(GaugeSource.parse(List.filled(9, 'date').join(',')), hasLength(6));
  });

  test('gauges share the width and stay inside the element', () {
    final l = GaugeLayout.of(
      const LockElementSpec(
        type: ElementType.gaugeSet,
        gaugeItems: 'battery,aqi,date,compass',
        width: 1000,
        height: 260,
      ),
    );
    expect(l.slots, hasLength(4));
    for (final s in l.slots) {
      expect(s.center.dx - s.radius, greaterThanOrEqualTo(0));
      expect(s.center.dx + s.radius, lessThanOrEqualTo(1000));
      expect(s.diameter, lessThanOrEqualTo(260));
    }
  });

  test('sample values read like the lockscreen', () {
    expect(GaugeLayout.value(GaugeSource.monthLeft, wed), '4');
    expect(GaugeLayout.value(GaugeSource.yearLeft, wed), '${365 - 147}');
    expect(GaugeLayout.value(GaugeSource.weekLeft, wed), '4');
    expect(GaugeLayout.value(GaugeSource.hoursLeft, wed), '6h');
    expect(GaugeLayout.value(GaugeSource.todayLeft, wed), '24%');
    expect(GaugeLayout.caption(GaugeSource.date, wed), 'WED');
    expect(GaugeLayout.caption(GaugeSource.compass, wed), 'NE');
    for (final s in GaugeSource.values) {
      expect(GaugeLayout.fraction(s, wed), inInclusiveRange(0, 1));
    }
  });

  test('MAML week maths matches Dart for every weekday', () {
    for (var dow = 1; dow <= 7; dow++) {
      // MAML: 1 = Sunday; Dart: 7 = Sunday.
      final dartWeekday = dow == 1 ? 7 : dow - 1;
      expect((7 - ((dow + 5) % 7 + 1)), 7 - dartWeekday);
    }
  });

  test('exports panel, live parts and only the binders it needs', () {
    XmlDocument build(String items, GaugeStyle style) =>
        const ManifestBuilder().build([
          LockElementSpec(
            type: ElementType.gaugeSet,
            gaugeItems: items,
            gaugeStyle: style,
          ),
        ]);
    final doc = build('battery,compass,steps', GaugeStyle.openArc);
    final xml = doc.toXmlString();
    expect(xml, contains('calendar/gaugeSet_gauges.png'));
    expect(doc.findAllElements('Arc'), hasLength(3));
    expect(doc.findAllElements('SensorBinder'), hasLength(1));
    expect(xml, contains('MiSteps'));

    final plain = build('battery,date', GaugeStyle.segmentRing);
    expect(plain.findAllElements('SensorBinder'), isEmpty);
    expect(plain.findAllElements('Array'), hasLength(2));
    for (final style in GaugeStyle.values) {
      expect(
        () => XmlDocument.parse(
          build(GaugeSource.values.map((s) => s.name).join(','), style)
              .toXmlString(),
        ),
        returnsNormally,
        reason: '$style',
      );
    }
  });
}
