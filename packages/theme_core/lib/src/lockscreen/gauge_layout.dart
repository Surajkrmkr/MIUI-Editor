import 'dart:math';

import '../values/rgba.dart';
import 'element_enums.dart';
import 'geometry.dart';
import 'lock_element_spec.dart';
import 'maml_dates.dart';

/// Sample readings for editor previews, matching the other info widgets.
class GaugeSample {
  const GaugeSample({
    required this.now,
    this.battery = 75,
    this.temperature = 24,
    this.aqi = 42,
    this.humidity = 65,
    this.steps = 6240,
    this.stepGoal = 10000,
    this.alarm = '07:30',
    this.azimuth = 45,
    this.notifications = 3,
  });

  final DateTime now;
  final int battery, temperature, aqi, humidity, steps, stepGoal;
  final int azimuth, notifications;
  final String alarm;
}

/// One gauge of a gauge set, in theme pixels (before `scale`).
class GaugeSlot {
  const GaugeSlot(this.source, this.center, this.diameter);

  final GaugeSource source;
  final Pt center;
  final double diameter;

  double get radius => diameter / 2;
}

/// Geometry, sample values and MAML expressions of a gauge set; shared by the
/// editor painter and the export so the PNG and the live parts line up.
class GaugeLayout {
  GaugeLayout.of(this.el) : items = GaugeSource.parse(el.gaugeItems);

  final LockElementSpec el;
  final List<GaugeSource> items;

  GaugeStyle get style => el.gaugeStyle;
  double get w => el.width;
  double get h => el.height;
  double get slotW => w / items.length;
  double get diameter => min(h * .92, slotW * .84);

  /// Room around the panel for glows in the exported PNG.
  double get exportInset => diameter * .25;

  List<GaugeSlot> get slots => [
    for (var i = 0; i < items.length; i++)
      GaugeSlot(items[i], Pt(slotW * (i + .5), h / 2), diameter),
  ];

  /// Ring line width.
  double get weight =>
      diameter *
      switch (style) {
        GaugeStyle.fullRing => .13,
        GaugeStyle.bezelBold => .16,
        GaugeStyle.glassDisc => .05,
        GaugeStyle.neonOrbit => .035,
        GaugeStyle.compassRose => .04,
        _ => .1,
      };

  /// Radius the progress arc runs on.
  double get ringRadius => diameter / 2 - weight / 2 - diameter * .02;

  /// Where the progress arc starts and how far it can sweep, in degrees
  /// clockwise from 3 o'clock.
  (double, double) get arc => switch (style) {
    GaugeStyle.openArc => (135, 270),
    GaugeStyle.halfDial => (180, 180),
    _ => (-90, 360),
  };

  /// Segments or ticks for the stepped styles.
  int get steps => switch (style) {
    GaugeStyle.segmentRing => 10,
    GaugeStyle.tickDial => 30,
    _ => 0,
  };

  Rgba get captionColor => el.strokeColor.a > 0
      ? el.strokeColor
      : el.color.withOpacity(el.color.opacity * .7);

  double get valueSize =>
      diameter * (style == GaugeStyle.halfDial ? .26 : .3) * el.fontSize / 9;
  double get captionSize => diameter * .13 * el.fontSize / 9;

  /// Value and caption centres for [slot].
  Pt valueAt(GaugeSlot s) => Pt(
    s.center.dx,
    s.center.dy + diameter * (style == GaugeStyle.halfDial ? .02 : -.05),
  );
  Pt captionAt(GaugeSlot s) => Pt(
    s.center.dx,
    s.center.dy + diameter * (style == GaugeStyle.halfDial ? .24 : .22),
  );

  // ── Preview values ────────────────────────────────────────────────────────

  static int _monthDays(DateTime d) => DateTime(d.year, d.month + 1, 0).day;
  static int _yearDays(DateTime d) =>
      DateTime(d.year + 1).difference(DateTime(d.year)).inDays;
  static int _dayOfYear(DateTime d) =>
      DateTime(d.year, d.month, d.day).difference(DateTime(d.year)).inDays + 1;
  static int _weekLeft(DateTime d) => 7 - d.weekday;
  static const _dirs = ['N', 'NE', 'E', 'SE', 'S', 'SW', 'W', 'NW'];
  static const _days = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];

  static double fraction(GaugeSource s, GaugeSample x) {
    final now = x.now;
    final secs = now.hour * 3600 + now.minute * 60 + now.second;
    final f = switch (s) {
      GaugeSource.battery => x.battery / 100,
      GaugeSource.todayLeft => 1 - secs / 86400,
      GaugeSource.hoursLeft => (86400 - secs) / 86400,
      GaugeSource.weekLeft => _weekLeft(now) / 7,
      GaugeSource.monthLeft =>
        (_monthDays(now) - now.day) / _monthDays(now),
      GaugeSource.yearLeft =>
        (_yearDays(now) - _dayOfYear(now)) / _yearDays(now),
      GaugeSource.date => now.day / _monthDays(now),
      GaugeSource.temperature => (x.temperature + 10) / 55,
      GaugeSource.aqi => x.aqi / 300,
      GaugeSource.humidity => x.humidity / 100,
      GaugeSource.steps => x.stepGoal > 0 ? x.steps / x.stepGoal : 0,
      GaugeSource.alarm => x.alarm.isEmpty ? 0 : 1,
      GaugeSource.compass => x.azimuth / 360,
      GaugeSource.notifications => x.notifications / 10,
      GaugeSource.seconds => now.second / 60,
    };
    return f.clamp(0.0, 1.0).toDouble();
  }

  static String value(GaugeSource s, GaugeSample x) {
    final now = x.now;
    return switch (s) {
      GaugeSource.battery => '${x.battery}',
      GaugeSource.todayLeft =>
        '${((1 - (now.hour * 3600 + now.minute * 60 + now.second) / 86400) * 100).floor()}%',
      GaugeSource.hoursLeft =>
        '${(1440 - now.hour * 60 - now.minute) ~/ 60}h',
      GaugeSource.weekLeft => '${_weekLeft(now)}',
      GaugeSource.monthLeft => '${_monthDays(now) - now.day}',
      GaugeSource.yearLeft => '${_yearDays(now) - _dayOfYear(now)}',
      GaugeSource.date => '${now.day}',
      GaugeSource.temperature => '${x.temperature}°',
      GaugeSource.aqi => '${x.aqi}',
      GaugeSource.humidity => '${x.humidity}%',
      GaugeSource.steps => '${(x.steps / 1000).toStringAsFixed(1)}k',
      GaugeSource.alarm => x.alarm.isEmpty ? '--' : x.alarm,
      GaugeSource.compass => '${x.azimuth}°',
      GaugeSource.notifications => '${x.notifications}',
      GaugeSource.seconds => now.second.toString().padLeft(2, '0'),
    };
  }

  static String caption(GaugeSource s, GaugeSample x) => switch (s) {
    GaugeSource.date => _days[x.now.weekday - 1],
    GaugeSource.compass => _dirs[((x.azimuth + 22.5) % 360 ~/ 45)],
    _ => s.caption,
  };

  // ── MAML ──────────────────────────────────────────────────────────────────

  static const _secs = '(#hour24*3600+#minute*60+#second)';

  /// Live 0–1 fraction for [s].
  static String fractionExp(GaugeSource s) {
    final f = switch (s) {
      GaugeSource.battery => '#battery_level/100',
      GaugeSource.todayLeft || GaugeSource.hoursLeft => '(1-$_secs/86400)',
      GaugeSource.weekLeft => '${MamlDates.weekDaysLeft}/7',
      GaugeSource.monthLeft =>
        '(${MamlDates.monthDays}-#date)/${MamlDates.monthDays}',
      GaugeSource.yearLeft =>
        '(${MamlDates.yearDays}-${MamlDates.dayOfYear})/${MamlDates.yearDays}',
      GaugeSource.date => '#date/${MamlDates.monthDays}',
      GaugeSource.temperature => '(#weather_temperature+10)/55',
      GaugeSource.aqi => '#weather_aqi/300',
      GaugeSource.humidity => '#weather_humidity/100',
      GaugeSource.steps => ArcProgressSource.steps.mamlFraction!,
      GaugeSource.alarm => 'ifelse(strIsEmpty(@next_alarm_time),0,1)',
      GaugeSource.compass => '#gauge_azimuth/360',
      GaugeSource.notifications => '#hasnotifications/10',
      GaugeSource.seconds => '#second/60',
    };
    return 'min(1,max(0,$f))';
  }

  /// `format`/`paras` for numeric values, or a `textExp` for text ones.
  static ({String? format, String? paras, String? textExp}) valueExp(
    GaugeSource s,
  ) => switch (s) {
    GaugeSource.battery => (format: '%d', paras: '#battery_level', textExp: null),
    GaugeSource.todayLeft => (
      format: '%d%%',
      paras: 'int((1-$_secs/86400)*100)',
      textExp: null,
    ),
    GaugeSource.hoursLeft => (
      format: '%dh',
      paras: 'int((1440-#hour24*60-#minute)/60)',
      textExp: null,
    ),
    GaugeSource.weekLeft => (
      format: '%d',
      paras: MamlDates.weekDaysLeft,
      textExp: null,
    ),
    GaugeSource.monthLeft => (
      format: '%d',
      paras: '${MamlDates.monthDays}-#date',
      textExp: null,
    ),
    GaugeSource.yearLeft => (
      format: '%d',
      paras: '${MamlDates.yearDays}-${MamlDates.dayOfYear}',
      textExp: null,
    ),
    GaugeSource.date => (format: '%d', paras: '#date', textExp: null),
    GaugeSource.temperature => (
      format: null,
      paras: null,
      textExp: "ifelse(#hasweather,#weather_temperature+'°','--')",
    ),
    GaugeSource.aqi => (
      format: null,
      paras: null,
      textExp: "ifelse(#hasweather,#weather_aqi+'','--')",
    ),
    GaugeSource.humidity => (
      format: null,
      paras: null,
      textExp: "ifelse(#hasweather,#weather_humidity+'%','--')",
    ),
    GaugeSource.steps => (
      format: '%.1fk',
      paras: 'int(@MiSteps_steps)/1000',
      textExp: null,
    ),
    GaugeSource.alarm => (
      format: null,
      paras: null,
      textExp: "ifelse(strIsEmpty(@next_alarm_time),'--',@next_alarm_time)",
    ),
    GaugeSource.compass => (
      format: '%d°',
      paras: 'int(#gauge_azimuth)',
      textExp: null,
    ),
    GaugeSource.notifications => (
      format: '%d',
      paras: '#hasnotifications',
      textExp: null,
    ),
    GaugeSource.seconds => (format: '%02d', paras: '#second', textExp: null),
  };

  /// `textExp` for the caption; constant captions are plain text.
  static String captionExp(GaugeSource s) => switch (s) {
    GaugeSource.date =>
      "substr('SUNMONTUEWEDTHUFRISAT',(#day_of_week-1)*3,3)",
    GaugeSource.compass =>
      "substr('N NEE SES SWW NW',int(((#gauge_azimuth+22.5)%360)/45)*2,2)",
    _ => "'${s.caption}'",
  };

  bool get usesWeather => items.any(
    (s) =>
        s == GaugeSource.temperature ||
        s == GaugeSource.aqi ||
        s == GaugeSource.humidity,
  );
  bool get usesSteps => items.contains(GaugeSource.steps);
  bool get usesCompass => items.contains(GaugeSource.compass);
}
