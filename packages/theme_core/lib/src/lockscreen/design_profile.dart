import 'dart:math' as math;

import '../values/rgba.dart';
import 'element_enums.dart';
import 'lock_element_spec.dart';

extension DesignKinds on ElementType {
  /// Shows live information: weather, battery, steps, calendar, music or
  /// notifications.
  bool get isInfo =>
      isWeatherText ||
      isHealth ||
      isMusic ||
      const {
        ElementType.batteryText,
        ElementType.batteryLevel,
        ElementType.notification,
        ElementType.missedCalls,
        ElementType.calendarGrid,
        ElementType.weatherIconClock,
        ElementType.progressBar,
      }.contains(this);

  /// Fills space with a shape, card or image rather than text.
  bool get isDecoration => isShape || isContainer || isPng;

  bool get _isAnalog => name.startsWith('analog');
}

/// What a lockscreen is made of: for judging how rich it is and for telling
/// whether two designs resemble each other. Hidden elements are ignored.
class DesignProfile {
  DesignProfile(Iterable<LockElementSpec> elements)
    : elements = [
        for (final e in elements)
          if (e.isVisible) e,
      ];

  /// Fewer visible elements than this reads as a bare lockscreen.
  static const minElements = 6;

  final List<LockElementSpec> elements;

  int get count => elements.length;
  bool get hasClock => elements.any((e) => e.type.isClock);
  bool get hasInfo => elements.any((e) => e.type.isInfo);
  bool get hasDecoration => elements.any((e) => e.type.isDecoration);

  /// How many different font sizes the texts and digital clocks use.
  int get fontSizes => {
    for (final e in elements)
      if (e.type.isText || (e.type.isClock && !e.type._isAnalog))
        e.fontSize.round(),
  }.length;

  /// Texts and digital clocks, which is what font sizes apply to.
  int get textCount => elements
      .where((e) => e.type.isText || (e.type.isClock && !e.type._isAnalog))
      .length;

  Set<String> get types => {for (final e in elements) e.type.name};
  Set<String> get clockTypes => {
    for (final e in elements)
      if (e.type.isClock) e.type.name,
  };

  LockElementSpec? get _mainClock =>
      elements.where((e) => e.type.isClock).firstOrNull;

  /// The first unlock control with its skin, e.g. `slideToUnlock/glass`.
  String? get unlock {
    final e = elements
        .where((e) => e.type.isUnlockControl || e.type.swipeUpUnlock)
        .firstOrNull;
    return e == null ? null : '${e.type.name}/${e.unlockSkin.name}';
  }

  /// Where the main clock sits, on a coarse grid of the screen.
  String? get clockCell {
    final c = _mainClock;
    return c == null ? null : '${(c.dx / 46).round()},${(c.dy / 100).round()}';
  }

  /// The main text color as a hue name, so near colors count as the same.
  String? get colorFamily {
    final c = _mainClock?.color;
    return c == null ? null : _family(c);
  }

  static String _family(Rgba c) {
    final r = c.r / 255, g = c.g / 255, b = c.b / 255;
    final hi = math.max(r, math.max(g, b)), lo = math.min(r, math.min(g, b));
    final delta = hi - lo;
    if (delta < .12) return hi > .5 ? 'light' : 'dark';
    var hue = hi == r
        ? ((g - b) / delta) % 6
        : hi == g
        ? (b - r) / delta + 2
        : (r - g) / delta + 4;
    hue *= 60;
    const names = ['red', 'yellow', 'green', 'cyan', 'blue', 'magenta'];
    return names[((hue + 30) % 360 ~/ 60)];
  }

  static double _jaccard(Set<String> a, Set<String> b) {
    if (a.isEmpty && b.isEmpty) return 1;
    return a.intersection(b).length / a.union(b).length;
  }

  /// 0 for nothing in common, 1 for the same design: the pieces used count
  /// most, then clock style, unlock control, clock position and color.
  double similarityTo(DesignProfile other) =>
      .4 * _jaccard(types, other.types) +
      .15 * _jaccard(clockTypes, other.clockTypes) +
      .15 * (unlock == other.unlock ? 1 : 0) +
      .15 * (clockCell == other.clockCell ? 1 : 0) +
      .15 * (colorFamily == other.colorFamily ? 1 : 0);

  /// What this design and [other] have in common, for a person to read.
  List<String> sharedWith(DesignProfile other) => [
    if (clockTypes.intersection(other.clockTypes).isNotEmpty)
      'clock ${clockTypes.intersection(other.clockTypes).join(', ')}',
    if (unlock != null && unlock == other.unlock) 'unlock $unlock',
    if (clockCell != null && clockCell == other.clockCell)
      'clock in the same place',
    if (colorFamily != null && colorFamily == other.colorFamily)
      '$colorFamily text',
    if (types.intersection(other.types).length > 4)
      '${types.intersection(other.types).length} element types',
  ];
}
