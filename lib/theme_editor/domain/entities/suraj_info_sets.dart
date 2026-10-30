import 'package:flutter/material.dart';

import 'builtin_widget_styles.dart' show ClockSetPreset;
import 'element_widget.dart';

// Suraj's weather and battery sets. Each is a handful of live text elements
// framed by geometry shapes. Positions (dx, dy) are lockscreen units from the
// centre of the 276.92 x 600 canvas; shape sizes are theme pixels, so the
// helpers below take lockscreen units and convert.

const _ratio = 2340 / 600;

/// Shapes a set draws carry this instanceId prefix, so applying another set
/// can tell them from shapes the designer added.
const weatherSetIdPrefix = 'wx';
const batterySetIdPrefix = 'bt';

const weatherSetElementTypes = <ElementType>{
  ElementType.weatherIconClock,
  ElementType.weatherTemp,
  ElementType.weatherDesc,
  ElementType.weatherCity,
  ElementType.weatherTemperatureRange,
  ElementType.weatherAqi,
  ElementType.weatherHumidity,
};

const batterySetElementTypes = <ElementType>{
  ElementType.batteryText,
  ElementType.batteryLevel,
};

/// Whether [e] belongs to a weather set (its text or its shapes).
bool isWeatherSetElement(LockElement e) =>
    weatherSetElementTypes.contains(e.type) ||
    (e.type.isShape && e.instanceId.startsWith(weatherSetIdPrefix));

/// Whether [e] belongs to a battery set (its text or its shapes).
bool isBatterySetElement(LockElement e) =>
    batterySetElementTypes.contains(e.type) ||
    (e.type.isShape && e.instanceId.startsWith(batterySetIdPrefix));

class _Build {
  _Build(this.prefix, this.shift);
  final String prefix;
  final double shift;
  final elements = <LockElement>[];
  var _n = 0;

  String get _id => '$prefix${++_n}';

  void rect(
    double dx,
    double dy,
    double w,
    double h, {
    double r = 0,
    Color fill = const Color(0x00000000),
    Color line = const Color(0x00000000),
    double lineW = 0,
  }) => elements.add(
    LockElement(
      type: ElementType.rectangleShape,
      instanceId: _id,
      dx: dx,
      dy: dy + shift,
      width: w * _ratio,
      height: h * _ratio,
      radius: r * _ratio,
      color: line,
      colorSecondary: fill,
      shapeStrokeWidth: lineW * _ratio,
    ),
  );

  void disc(
    double dx,
    double dy,
    double d, {
    Color fill = const Color(0x00000000),
    Color line = const Color(0x00000000),
    double lineW = 0,
  }) => elements.add(
    LockElement(
      type: ElementType.circleShape,
      instanceId: _id,
      dx: dx,
      dy: dy + shift,
      width: d * _ratio,
      height: d * _ratio,
      color: line,
      colorSecondary: fill,
      shapeStrokeWidth: lineW * _ratio,
    ),
  );

  /// A ring or part of one; [source] fills it live, none draws it whole.
  void arc(
    double dx,
    double dy,
    double d,
    double w, {
    required Color color,
    Color? track,
    double start = -90,
    double sweep = 360,
    ArcProgressSource source = ArcProgressSource.battery,
  }) => elements.add(
    LockElement(
      type: ElementType.arcShape,
      instanceId: _id,
      dx: dx,
      dy: dy + shift,
      width: d * _ratio,
      height: d * _ratio,
      shapeStrokeWidth: w * _ratio,
      startAngle: start,
      sweepAngle: sweep,
      progressSource: source,
      color: color,
      colorSecondary: track ?? color.withValues(alpha: .22),
    ),
  );

  /// A pill that fills left to right with [source].
  void bar(
    double dx,
    double dy,
    double w,
    double h, {
    required Color color,
    Color? track,
    ArcProgressSource source = ArcProgressSource.battery,
  }) => elements.add(
    LockElement(
      type: ElementType.rectangleShape,
      instanceId: _id,
      dx: dx,
      dy: dy + shift,
      width: w * _ratio,
      height: h * _ratio,
      radius: h / 2 * _ratio,
      shapeStrokeWidth: 0,
      progressSource: source,
      color: color,
      colorSecondary: track ?? color.withValues(alpha: .25),
    ),
  );

  void text(
    ElementType type,
    double dx,
    double dy,
    double size,
    Color color, {
    FontWeight weight = FontWeight.w600,
  }) => elements.add(
    LockElement(
      type: type,
      dx: dx,
      dy: dy + shift,
      fontSize: size,
      fontWeight: weight,
      color: color,
    ),
  );

  void icon(double dx, double dy, double scale) => elements.add(
    LockElement(
      type: ElementType.weatherIconClock,
      dx: dx,
      dy: dy + shift,
      scale: scale,
    ),
  );
}

ClockSetPreset _weather(
  String slug,
  String name,
  Color background,
  void Function(_Build b) design,
) {
  final b = _Build(weatherSetIdPrefix, 40);
  design(b);
  return ClockSetPreset(
    id: 'weather-set-suraj-$slug',
    name: name,
    user: 'suraj',
    background: background,
    elements: b.elements,
  );
}

ClockSetPreset _battery(
  String slug,
  String name,
  Color background,
  void Function(_Build b) design,
) {
  final b = _Build(batterySetIdPrefix, 140);
  design(b);
  return ClockSetPreset(
    id: 'battery-set-suraj-$slug',
    name: name,
    user: 'suraj',
    background: background,
    elements: b.elements,
  );
}

const _temp = ElementType.weatherTemp;
const _desc = ElementType.weatherDesc;
const _city = ElementType.weatherCity;
const _range = ElementType.weatherTemperatureRange;
const _aqi = ElementType.weatherAqi;
const _humid = ElementType.weatherHumidity;
const _pct = ElementType.batteryText;
const _white = Color(0xFFFFFFFF);

final surajWeatherSets = <ClockSetPreset>[
  _weather('sun-disc', 'Sun disc', const Color(0xFF1B2A4A), (b) {
    b.disc(
      0,
      0,
      104,
      fill: const Color(0x1FFFFFFF),
      line: const Color(0x55FFFFFF),
      lineW: 1.2,
    );
    b.icon(0, -8, 1.55);
    b.text(_temp, 0, 78, 30, _white, weight: FontWeight.w700);
    b.text(_desc, 0, 100, 11, const Color(0xE6FFFFFF));
    b.text(_city, 0, 116, 9, const Color(0xAAFFFFFF), weight: FontWeight.w500);
  }),
  _weather('glass-pill', 'Glass pill', const Color(0xFF30415C), (b) {
    b.rect(
      0,
      0,
      214,
      56,
      r: 28,
      fill: const Color(0x24FFFFFF),
      line: const Color(0x40FFFFFF),
      lineW: 1,
    );
    b.icon(-76, 0, 1);
    b.text(_temp, -6, -7, 24, _white, weight: FontWeight.w700);
    b.text(_desc, -6, 12, 9, const Color(0xCCFFFFFF));
    b.rect(46, 0, 1, 26, fill: const Color(0x40FFFFFF));
    b.text(_humid, 74, 0, 15, _white);
  }),
  _weather('stacked-mono', 'Stacked mono', const Color(0xFF111111), (b) {
    b.text(_desc, 0, -50, 11, const Color(0xCCFFFFFF), weight: FontWeight.w500);
    b.text(_temp, 0, 0, 66, _white, weight: FontWeight.w200);
    b.rect(0, 46, 120, 1.2, fill: const Color(0x80FFFFFF));
    b.text(_city, -46, 62, 10, _white, weight: FontWeight.w700);
    b.text(_range, 46, 62, 10, const Color(0xBBFFFFFF));
  }),
  _weather('thermometer', 'Thermometer', const Color(0xFF0E2A33), (b) {
    b.text(_temp, -58, -18, 40, _white, weight: FontWeight.w700);
    b.text(_desc, -58, 14, 11, const Color(0xCCFFFFFF));
    b.text(
      _range,
      62,
      -18,
      14,
      const Color(0xFFFFC857),
      weight: FontWeight.w700,
    );
    b.text(_humid, 62, 4, 13, const Color(0xFF7FDBFF));
    b.rect(0, 44, 200, 10, r: 5, fill: const Color(0x33FFFFFF));
    b.rect(-36, 44, 128, 10, r: 5, fill: const Color(0xFFFFC857));
    b.disc(28, 44, 18, fill: _white, line: const Color(0xFFFFC857), lineW: 2.5);
  }),
  _weather('ticket-card', 'Ticket card', const Color(0xFF3A2E24), (b) {
    b.rect(0, 0, 210, 90, r: 16, fill: const Color(0xFFFAF3E6));
    b.text(
      _temp,
      -56,
      -8,
      34,
      const Color(0xFF2B2118),
      weight: FontWeight.w800,
    );
    b.text(_desc, -56, 22, 10, const Color(0xFF8A7560));
    b.rect(8, 0, 1.2, 60, fill: const Color(0x33000000));
    b.text(
      _city,
      58,
      -18,
      11,
      const Color(0xFF2B2118),
      weight: FontWeight.w700,
    );
    b.text(_range, 58, 0, 10, const Color(0xFF8A7560));
    b.text(
      _humid,
      58,
      18,
      12,
      const Color(0xFFD2553A),
      weight: FontWeight.w700,
    );
  }),
  _weather('orbit', 'Orbit', const Color(0xFF14122E), (b) {
    b.arc(
      0,
      0,
      124,
      3,
      color: const Color(0xFFFFC857),
      start: -60,
      sweep: 300,
      source: ArcProgressSource.none,
    );
    b.arc(
      0,
      0,
      104,
      2,
      color: const Color(0x88FFFFFF),
      start: 120,
      sweep: 200,
      source: ArcProgressSource.none,
    );
    b.icon(0, -2, 1.25);
    b.text(_temp, 0, 76, 22, _white, weight: FontWeight.w700);
    b.text(_desc, 0, 96, 10, const Color(0xCCFFFFFF));
  }),
  _weather('sunset-banner', 'Sunset banner', const Color(0xFF1A1033), (b) {
    b.rect(0, 0, 214, 72, r: 20, fill: const Color(0xFF2A1B4D));
    b.disc(74, 0, 44, fill: const Color(0xFFFF8A4C));
    b.disc(74, 0, 62, line: const Color(0x66FFB86B), lineW: 1.5);
    b.text(_temp, -48, -9, 30, _white, weight: FontWeight.w800);
    b.text(_desc, -48, 17, 10, const Color(0xCCFFD9A8));
  }),
  _weather('compact-strip', 'Compact strip', const Color(0xFF1F2A3A), (b) {
    b.rect(0, 0, 222, 44, r: 22, fill: const Color(0x2EFFFFFF));
    b.icon(-86, 0, .75);
    b.text(_temp, -40, 0, 16, _white, weight: FontWeight.w700);
    b.rect(-8, 0, 1, 20, fill: const Color(0x55FFFFFF));
    b.text(_humid, 22, 0, 14, _white);
    b.rect(46, 0, 1, 20, fill: const Color(0x55FFFFFF));
    b.text(_aqi, 78, 0, 11, const Color(0xFFB9F27C));
  }),
  _weather('big-city', 'Big city', const Color(0xFF241B16), (b) {
    b.text(_city, 0, -48, 12, const Color(0xFFFF9F43), weight: FontWeight.w700);
    b.text(_temp, 0, 0, 78, _white, weight: FontWeight.w900);
    b.rect(0, 50, 46, 4, r: 2, fill: const Color(0xFFFF9F43));
    b.text(_desc, 0, 68, 12, const Color(0xCCFFFFFF), weight: FontWeight.w500);
  }),
  _weather('bubbles', 'Bubbles', const Color(0xFF12263A), (b) {
    b.disc(
      -20,
      0,
      86,
      fill: const Color(0x33FFFFFF),
      line: const Color(0x66FFFFFF),
      lineW: 1,
    );
    b.text(_temp, -20, -4, 26, _white, weight: FontWeight.w800);
    b.text(_desc, -20, 16, 9, const Color(0xCCFFFFFF));
    b.disc(44, -30, 46, fill: const Color(0xFF5CC8FF));
    b.text(
      _humid,
      44,
      -30,
      12,
      const Color(0xFF0B1B2B),
      weight: FontWeight.w700,
    );
    b.disc(44, 22, 46, fill: const Color(0xFFB9F27C));
    b.text(_aqi, 44, 22, 9.5, const Color(0xFF0B1B2B), weight: FontWeight.w700);
  }),
  _weather('neon-outline', 'Neon outline', const Color(0xFF0B0B1A), (b) {
    b.rect(0, 0, 222, 94, r: 26, line: const Color(0x334DF3FF), lineW: 5);
    b.rect(0, 0, 214, 86, r: 22, line: const Color(0xFF4DF3FF), lineW: 2);
    b.text(
      _temp,
      -42,
      -6,
      32,
      const Color(0xFF4DF3FF),
      weight: FontWeight.w300,
    );
    b.text(_desc, -42, 20, 10, const Color(0xAA4DF3FF));
    b.text(
      _humid,
      58,
      -12,
      16,
      const Color(0xFFFF4DDA),
      weight: FontWeight.w700,
    );
    b.text(_aqi, 58, 12, 10, const Color(0xFFFF4DDA));
  }),
  _weather('tile-grid', 'Tile grid', const Color(0xFF202638), (b) {
    const tile = Color(0x26FFFFFF);
    b.rect(-34, -34, 62, 62, r: 16, fill: tile);
    b.rect(34, -34, 62, 62, r: 16, fill: const Color(0xFFFFC857));
    b.rect(-34, 34, 62, 62, r: 16, fill: tile);
    b.rect(34, 34, 62, 62, r: 16, fill: tile);
    b.icon(-34, -34, .9);
    b.text(
      _temp,
      34,
      -34,
      17,
      const Color(0xFF2B2118),
      weight: FontWeight.w800,
    );
    b.text(_humid, -34, 34, 15, _white);
    b.text(_aqi, 34, 34, 10, const Color(0xFFB9F27C));
  }),
];

final surajBatterySets = <ClockSetPreset>[
  _battery('twin-rings', 'Twin rings', const Color(0xFF0E1A2B), (b) {
    b.arc(0, 0, 120, 9, color: const Color(0xFF4DF3A8));
    b.arc(
      0,
      0,
      92,
      9,
      color: const Color(0xFFFFC857),
      source: ArcProgressSource.steps,
    );
    b.text(_pct, 0, 0, 20, _white, weight: FontWeight.w800);
  }),
  _battery('half-gauge', 'Half gauge', const Color(0xFF2B1620), (b) {
    b.arc(
      0,
      37,
      150,
      10,
      color: const Color(0xFFFF6B6B),
      track: const Color(0x33FFFFFF),
      start: 180,
      sweep: 180,
    );
    b.text(_pct, 0, 18, 26, _white, weight: FontWeight.w800);
  }),
  _battery('pill-meter', 'Pill meter', const Color(0xFF10231F), (b) {
    b.text(_pct, 0, -16, 30, _white, weight: FontWeight.w800);
    b.bar(
      0,
      18,
      200,
      20,
      color: const Color(0xFF7CFFB2),
      track: const Color(0x30FFFFFF),
    );
  }),
  _battery('battery-glyph', 'Battery glyph', const Color(0xFF1A1A24), (b) {
    b.rect(0, 0, 120, 56, r: 14, line: _white, lineW: 2.5);
    b.rect(66, 0, 8, 22, r: 4, fill: _white);
    b.bar(
      0,
      0,
      108,
      44,
      color: const Color(0xFF7CFFB2),
      track: const Color(0x1AFFFFFF),
    );
    b.text(_pct, 0, 48, 14, const Color(0xE6FFFFFF), weight: FontWeight.w700);
  }),
  _battery('speedometer', 'Speedometer', const Color(0xFF1E1410), (b) {
    b.arc(
      0,
      0,
      140,
      9,
      color: const Color(0xFFFF9F43),
      track: const Color(0x2EFFFFFF),
      start: 135,
      sweep: 270,
    );
    b.arc(
      0,
      0,
      112,
      2,
      color: const Color(0x55FFFFFF),
      start: 135,
      sweep: 270,
      source: ArcProgressSource.none,
    );
    b.text(_pct, 0, -2, 30, _white, weight: FontWeight.w800);
  }),
  _battery('dot-orbit', 'Dot orbit', const Color(0xFF17142B), (b) {
    b.arc(0, 0, 112, 3, color: _white, track: const Color(0x30FFFFFF));
    b.disc(0, 0, 78, fill: const Color(0x26FFFFFF));
    for (final (x, y) in const [
      (0.0, -56.0),
      (56.0, 0.0),
      (0.0, 56.0),
      (-56.0, 0.0),
    ]) {
      b.disc(x, y, 6, fill: const Color(0xCCFFFFFF));
    }
    b.text(_pct, 0, 0, 22, _white, weight: FontWeight.w700);
  }),
  _battery('brackets', 'Brackets', const Color(0xFF14152B), (b) {
    b.arc(
      0,
      0,
      130,
      6,
      color: const Color(0xFF8E7DFF),
      track: const Color(0x26FFFFFF),
      start: 120,
      sweep: 120,
    );
    b.arc(
      0,
      0,
      130,
      6,
      color: const Color(0xFFFF7AC8),
      track: const Color(0x26FFFFFF),
      start: -60,
      sweep: 120,
    );
    b.text(_pct, 0, 0, 28, _white, weight: FontWeight.w800);
  }),
  _battery('big-number', 'Big number', const Color(0xFF111111), (b) {
    b.text(_pct, 0, -8, 64, _white, weight: FontWeight.w900);
    b.bar(0, 40, 140, 5, color: _white, track: const Color(0x40FFFFFF));
  }),
  _battery('thick-donut', 'Thick donut', const Color(0xFF1E1633), (b) {
    b.arc(
      0,
      0,
      124,
      34,
      color: const Color(0xFFFF5A8A),
      track: const Color(0x26FFFFFF),
    );
    b.disc(0, 0, 70, fill: const Color(0xFF1E1633));
    b.text(_pct, 0, 0, 18, _white, weight: FontWeight.w800);
  }),
  _battery('activity-rings', 'Activity rings', const Color(0xFF000000), (b) {
    b.arc(0, 0, 132, 10, color: const Color(0xFFFF375F));
    b.arc(
      0,
      0,
      108,
      10,
      color: const Color(0xFFA8FF3E),
      source: ArcProgressSource.steps,
    );
    b.arc(
      0,
      0,
      84,
      10,
      color: const Color(0xFF2DD4FF),
      source: ArcProgressSource.hour,
    );
    b.text(_pct, 0, 0, 15, _white, weight: FontWeight.w800);
  }),
  _battery('stack-bars', 'Stack bars', const Color(0xFF111A24), (b) {
    b.text(_pct, 0, -52, 16, _white, weight: FontWeight.w800);
    b.bar(0, -22, 180, 8, color: const Color(0xFF7CFFB2));
    b.bar(
      0,
      0,
      180,
      8,
      color: const Color(0xFFFFC857),
      source: ArcProgressSource.steps,
    );
    b.bar(
      0,
      22,
      180,
      8,
      color: const Color(0xFF8EC5FF),
      source: ArcProgressSource.hour,
    );
  }),
  _battery('glass-card', 'Glass card', const Color(0xFF2A3345), (b) {
    b.rect(
      0,
      0,
      206,
      64,
      r: 22,
      fill: const Color(0x26FFFFFF),
      line: const Color(0x40FFFFFF),
      lineW: 1,
    );
    b.arc(-70, 0, 46, 6, color: _white, track: const Color(0x40FFFFFF));
    b.text(_pct, 22, -9, 22, _white, weight: FontWeight.w800);
    b.bar(22, 14, 104, 6, color: const Color(0xFF7CFFB2));
  }),
];
