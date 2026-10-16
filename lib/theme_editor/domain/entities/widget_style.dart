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
            }.contains(entry.key) &&
            value is! int) {
          throw FormatException(
            'Colors must be integer ARGB values: ${entry.key}',
          );
        }
      } else if (entry.key == 'unlockInline') {
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
      type == ElementType.tapToUnlock || type == ElementType.slideToUnlock;

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
  };
  static final properties = Set<String>.unmodifiable({
    ...numericBounds.keys,
    'unlockIcon',
    'unlockIconPath',
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
    return LockElement.fromJson({...element.toJson(), ...appearance});
  }
}

class WidgetStyleSet {
  WidgetStyleSet({
    required this.id,
    required this.name,
    required List<WidgetStyle> styles,
  }) : styles = List.unmodifiable(styles) {
    if (!RegExp(r'^[a-zA-Z0-9][a-zA-Z0-9._-]{0,79}$').hasMatch(id) ||
        name.trim().isEmpty ||
        name.length > 120) {
      throw const FormatException('Invalid style set ID or name');
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
}
