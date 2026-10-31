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
        ElementType.dayStrip,
        ElementType.countdownTicker,
        ElementType.gaugeSet,
        ElementType.weatherIconClock,
        ElementType.progressBar,
      }.contains(this);

  /// Fills space with a shape, card or image rather than text.
  bool get isDecoration => isShape || isContainer || isPng;

  bool get _isAnalog => name.startsWith('analog');
}

/// An earlier theme's lockscreen, to compare a new design against.
class NamedDesign {
  const NamedDesign(this.title, this.design);

  final String title;
  final DesignProfile design;
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

  /// Similarity from which two themes count as the same design.
  static const sameDesign = .5;

  /// Similarity to the starter layout from which a theme never left it.
  static const starterLayout = .35;

  final List<LockElementSpec> elements;

  int get count => elements.length;
  bool get hasClock => elements.any((e) => e.type.isClock);

  /// Live information other than music, which the designer keeps out of the
  /// required widget.
  bool get hasInfo => elements.any((e) => e.type.isInfo && !e.type.isMusic);
  bool get hasSwipeUp => elements.any((e) => e.type.swipeUpUnlock);
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

  /// The first visible unlock control with its skin, e.g.
  /// `slideToUnlock/glass`; swipe-up counts only when nothing else does.
  String? get unlock {
    final e =
        elements.where((e) => e.type.isUnlockControl).firstOrNull ??
        elements.where((e) => e.type.swipeUpUnlock).firstOrNull;
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

  Map<String, LockElementSpec> get _firstOfType => {
    for (final e in elements.reversed) e.type.name: e,
  };

  /// The element types both designs use that sit within [tolerance] units of
  /// each other, which is what makes two lockscreens look alike.
  Set<String> _samePlace(DesignProfile other, {double tolerance = 25}) {
    final mine = _firstOfType, theirs = other._firstOfType;
    return {
      for (final t in mine.keys)
        if (theirs[t] case final o?
            when (mine[t]!.dx - o.dx).abs() <= tolerance &&
                (mine[t]!.dy - o.dy).abs() <= tolerance)
          t,
    };
  }

  /// 0 for nothing in common, 1 for the same design: where the shared
  /// elements sit counts most, then which pieces are used, the unlock
  /// control, the clock style and the text color.
  double similarityTo(DesignProfile other) {
    final union = types.union(other.types);
    final place = union.isEmpty ? 1 : _samePlace(other).length / union.length;
    return .5 * place +
        .2 * _jaccard(types, other.types) +
        .1 * (unlock == other.unlock ? 1 : 0) +
        .1 * _jaccard(clockTypes, other.clockTypes) +
        .1 * (colorFamily == other.colorFamily ? 1 : 0);
  }

  /// What this design and [other] have in common, for a person to read.
  List<String> sharedWith(DesignProfile other) => [
    if (clockTypes.intersection(other.clockTypes).isNotEmpty)
      'clock ${clockTypes.intersection(other.clockTypes).join(', ')}',
    if (unlock != null && unlock == other.unlock) 'unlock $unlock',
    if (_samePlace(other).length >= 3)
      '${_samePlace(other).length} elements in the same place',
    if (colorFamily != null && colorFamily == other.colorFamily)
      '$colorFamily text',
    if (types.intersection(other.types).length > 4)
      '${types.intersection(other.types).length} element types',
  ];
}
