import 'element_enums.dart';
import 'lock_element_spec.dart';

enum AnalogPart {
  dial(null),
  hour('#hour12*30+#minute*0.5'),
  minute('#minute*6+#second*0.1'),
  second('#time_sys%60000*0.006');

  const AnalogPart(this.angleExpression);

  /// MAML rotation expression (degrees clockwise from 12 o'clock).
  final String? angleExpression;

  double angleAt(DateTime t) => switch (this) {
    AnalogPart.dial => 0,
    AnalogPart.hour => (t.hour % 12) * 30 + t.minute * .5,
    AnalogPart.minute => t.minute * 6 + t.second * .1,
    AnalogPart.second => t.second * 6.0,
  };
}

extension AnalogClockType on ElementType {
  bool get isAnalog =>
      this == ElementType.analogClockBg ||
      this == ElementType.analogHourHand ||
      this == ElementType.analogMinHand ||
      this == ElementType.analogSecHand ||
      this == ElementType.analogClock;

  /// Parts drawn by this element, bottom to top.
  List<AnalogPart> get analogParts => switch (this) {
    ElementType.analogClockBg => const [AnalogPart.dial],
    ElementType.analogHourHand => const [AnalogPart.hour],
    ElementType.analogMinHand => const [AnalogPart.minute],
    ElementType.analogSecHand => const [AnalogPart.second],
    _ => AnalogPart.values,
  };
}

/// Rotating parts drawn for [el], bottom to top.
List<AnalogPart> analogPartsOfSpec(LockElementSpec el) =>
    el.type != ElementType.analogClock
    ? el.type.analogParts
    : switch (el.analogStyle) {
        AnalogStyle.orbitDigital => const [AnalogPart.dial],
        AnalogStyle.flowerCard => const [
          AnalogPart.dial,
          AnalogPart.hour,
          AnalogPart.minute,
        ],
        _ => AnalogPart.values,
      };

/// File suffix of an exported analog part.
String analogPartSuffix(LockElementSpec el, AnalogPart part) =>
    el.type == ElementType.analogClock ? '_${part.name}' : '';

/// Geometry of the Orbit digital face as fractions of the clock size.
abstract final class OrbitDigital {
  static const minuteOrbit = .3, minuteBubble = .068, minuteText = .07;
  static const secondOrbit = .445, secondBubble = .04, secondText = .034;
  static const secondStem = .39;
  static const hourText = .2, dayText = .05, dayY = -.12;
  static const dateText = .055, dateY = .115;
}
