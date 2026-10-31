import 'package:theme_core/theme_core.dart' show themeUsers;

import 'element_widget.dart';

class WidgetStyle {
  WidgetStyle({
    required this.id,
    required this.name,
    required this.type,
    required Map<String, dynamic> appearance,
  }) : appearance = Map.unmodifiable(appearance) {
    if (!RegExp(r'^[a-zA-Z0-9][a-zA-Z0-9._-]{0,79}$').hasMatch(id) ||
        name.trim().isEmpty ||
        name.length > 120) {
      throw const FormatException('Invalid widget style ID or name');
    }
    if (!supports(type)) {
      throw FormatException('Unsupported style widget: ${type.name}');
    }
    for (final entry in appearance.entries) {
      if (!properties.contains(entry.key)) {
        throw FormatException('Unsupported appearance property: ${entry.key}');
      }
      if (numericBounds[entry.key] case final bounds?) {
        final value = entry.value;
        if (value is! num ||
            !value.isFinite ||
            value < bounds.$1 ||
            value > bounds.$2) {
          throw FormatException('Invalid style value: ${entry.key}');
        }
        if (const {
              'color',
              'colorSecondary',
              'borderColor',
              'unlockAccent',
              'strokeColor',
            }.contains(entry.key) &&
            value is! int) {
          throw FormatException(
            'Colors must be integer ARGB values: ${entry.key}',
          );
        }
      } else if (_flags.contains(entry.key)) {
        if (entry.value is! bool) {
          throw const FormatException('Invalid unlock layout');
        }
      } else if (entry.value is! String ||
          (entry.value as String).length > 4096) {
        throw FormatException('Invalid style value: ${entry.key}');
      }
    }
    if (appearance['unlockIcon'] case final String icon) {
      if (!UnlockIcon.values.any((value) => value.name == icon)) {
        throw const FormatException('Unknown unlock icon');
      }
    }
    if (appearance['calendarStyle'] case final String style) {
      if (!CalendarStyle.values.any((value) => value.name == style)) {
        throw const FormatException('Unknown calendar style');
      }
    }
    if (appearance['dayStripStyle'] case final String style) {
      if (!DayStripStyle.values.any((value) => value.name == style)) {
        throw const FormatException('Unknown day strip style');
      }
    }
    if (appearance['tickerStyle'] case final String style) {
      if (!TickerStyle.values.any((value) => value.name == style)) {
        throw const FormatException('Unknown ticker style');
      }
    }
    if (appearance['gaugeStyle'] case final String style) {
      if (!GaugeStyle.values.any((value) => value.name == style)) {
        throw const FormatException('Unknown gauge style');
      }
    }
    if (appearance['shortcutStyle'] case final String style) {
      if (!ShortcutStyle.values.any((value) => value.name == style)) {
        throw const FormatException('Unknown shortcut style');
      }
    }
    if (appearance['analogStyle'] case final String style) {
      if (!AnalogStyle.values.any((value) => value.name == style)) {
        throw const FormatException('Unknown analog style');
      }
    }
    if (appearance['unlockSkin'] case final String skin) {
      if (!UnlockSkin.values.any((value) => value.name == skin)) {
        throw const FormatException('Unknown unlock skin');
      }
    }
    if (appearance['fontWeight'] case final String weight) {
      if (!RegExp(r'^FontWeight\.w[1-9]00$').hasMatch(weight)) {
        throw const FormatException('Invalid font weight');
      }
    }
  }

  final String id, name;
  final ElementType type;
  final Map<String, dynamic> appearance;

  static bool supports(ElementType type) =>
      type == ElementType.tapToUnlock ||
      type == ElementType.slideToUnlock ||
      type == ElementType.dragToUnlock ||
      type == ElementType.analogClock ||
      const {
        ElementType.hourClock,
        ElementType.minClock,
        ElementType.secClock,
        ElementType.dotClock,
        ElementType.dotClock2,
        ElementType.weekClock,
        ElementType.monthClock,
        ElementType.dateClock,
        ElementType.dateTimeText1,
        ElementType.dateTimeText2,
        ElementType.dateTimeText3,
      }.contains(type) ||
      type == ElementType.shortcutSet ||
      type == ElementType.calendarGrid ||
      type == ElementType.dayStrip ||
      type == ElementType.countdownTicker ||
      type == ElementType.gaugeSet;

  static const numericBounds = <String, (double, double)>{
    'width': (48, 1080),
    'height': (48, 1600),
    'radius': (0, 540),
    'angle': (0, 360),
    'color': (0, 4294967295),
    'colorSecondary': (0, 4294967295),
    'fontSize': (4, 80),
    'unlockIconScale': (.2, 1),
    'unlockCornerRadius': (0, 540),
    'unlockBackgroundOpacity': (0, 1),
    'unlockThumbOpacity': (0, 1),
    'borderWidth': (0, 40),
    'borderColor': (0, 4294967295),
    'unlockAccent': (0, 4294967295),
    'strokeColor': (0, 4294967295),
    'calendarRows': (1, 6),
  };
  static const _flags = {
    'unlockInline',
    'calendarShowMonth',
    'calendarShowWeekdays',
  };
  static final properties = Set<String>.unmodifiable({
    ...numericBounds.keys,
    ..._flags,
    'calendarStyle',
    'dayStripStyle',
    'tickerStyle',
    'gaugeStyle',
    'unlockIcon',
    'unlockIconPath',
    'unlockTargetPath',
    'unlockSkin',
    'analogStyle',
    'shortcutStyle',
    'shortcutApps',
    'unlockText',
    'fontWeight',
    'unlockInline',
  });

  factory WidgetStyle.capture({
    required String id,
    required String name,
    required LockElement element,
  }) {
    final json = element.toJson();
    return WidgetStyle(
      id: id,
      name: name,
      type: element.type,
      appearance: {
        for (final key in properties)
          if (json[key] != null) key: json[key],
        'unlockCornerRadius': element.effectiveUnlockCornerRadius,
      },
    );
  }

  LockElement applyTo(LockElement element) {
    if (element.type != type) {
      throw const FormatException('Style does not match the selected widget');
    }
    return LockElement.fromJson({
      ...element.toJson(),
      // Styles saved before skins existed describe the classic look.
      'unlockSkin': UnlockSkin.classic.name,
      ...appearance,
    });
  }
}

class WidgetStyleSet {
  WidgetStyleSet({
    required this.id,
    required this.name,
    required List<WidgetStyle> styles,
    this.user,
  }) : styles = List.unmodifiable(styles) {
    if (!RegExp(r'^[a-zA-Z0-9][a-zA-Z0-9._-]{0,79}$').hasMatch(id) ||
        name.trim().isEmpty ||
        name.length > 120) {
      throw const FormatException('Invalid style set ID or name');
    }
    if (user != null && !themeUsers.contains(user)) {
      throw const FormatException('Unknown style set user');
    }
    if (styles.isEmpty ||
        styles.length > 256 ||
        styles.map((style) => style.id).toSet().length != styles.length) {
      throw const FormatException(
        'A style set needs 1-256 uniquely identified styles',
      );
    }
  }
  final String id, name;
  final List<WidgetStyle> styles;

  /// The profile name this set belongs to; null means shared by everyone.
  final String? user;

  WidgetStyleSet copyWith({String? user, List<WidgetStyle>? styles}) =>
      WidgetStyleSet(
        id: id,
        name: name,
        styles: styles ?? this.styles,
        user: user ?? this.user,
      );
}
