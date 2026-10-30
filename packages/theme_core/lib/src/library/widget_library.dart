import 'dart:convert';

import '../lockscreen/element_enums.dart';
import 'theme_users.dart';
import 'widget_library.g.dart';

/// A named group of lockscreen elements from the editor's Widget Center, e.g.
/// "Battery Ring". [elements] are spec elements with defaults left out;
/// their offsets place the group around the middle of the screen.
class WidgetTemplate {
  const WidgetTemplate({
    required this.name,
    required this.description,
    required this.category,
    required this.elements,
  });

  factory WidgetTemplate.fromJson(Map<String, dynamic> j) => WidgetTemplate(
    name: j['name'] as String,
    description: j['description'] as String,
    category: j['category'] as String,
    elements: _uniqueNames([
      for (final e in j['elements'] as List)
        Map<String, dynamic>.from(e as Map),
    ]),
  );

  /// Gives repeated elements an `instanceId` (2, 3, ...), as the editor does
  /// when a widget is added, since every element needs its own name.
  static List<Map<String, dynamic>> _uniqueNames(
    List<Map<String, dynamic>> elements,
  ) {
    String nameOf(Map<String, dynamic> e) {
      final id = e['instanceId'] as String? ?? '';
      return id.isEmpty ? '${e['type']}' : '${e['type']}_$id';
    }

    final seen = <String>{};
    for (final e in elements) {
      if (seen.contains(nameOf(e))) {
        var suffix = 2;
        while (seen.contains('${e['type']}_$suffix')) {
          suffix++;
        }
        e['instanceId'] = '$suffix';
      }
      seen.add(nameOf(e));
    }
    return elements;
  }

  final String name, description, category;
  final List<Map<String, dynamic>> elements;
}

/// One saved look for an unlock control, analog clock, shortcut set or
/// calendar. [appearance] holds element fields to write over an element of
/// the same [type].
class WidgetStyle {
  const WidgetStyle({
    required this.id,
    required this.name,
    required this.type,
    required this.appearance,
  });

  final String id, name;
  final ElementType type;
  final Map<String, dynamic> appearance;

  /// [element] with this style applied, the way the editor does it: the look
  /// is replaced, position and anything else stay. Throws [FormatException]
  /// for an element of another type.
  Map<String, dynamic> applyTo(Map<String, dynamic> element) {
    if (element['type'] != type.name) {
      throw FormatException(
        'The style "$id" is for ${type.name}, not ${element['type']}.',
      );
    }
    return {
      ...element,
      // Styles saved before skins existed describe the classic look.
      if (element.containsKey('unlockSkin')) 'unlockSkin': 'classic',
      ...appearance,
    };
  }
}

class WidgetStyleSet {
  const WidgetStyleSet({
    required this.id,
    required this.name,
    required this.styles,
    this.skipped = 0,
    this.user,
  });

  factory WidgetStyleSet.fromJson(Map<String, dynamic> j) => WidgetStyleSet(
    id: j['id'] as String,
    name: j['name'] as String,
    user: themeUserOf(j['user']),
    styles: [
      for (final s in j['styles'] as List)
        WidgetStyle(
          id: (s as Map)['id'] as String,
          name: s['name'] as String,
          type: ElementType.values.byName(s['type'] as String),
          appearance: Map<String, dynamic>.from(s['appearance'] as Map),
        ),
    ],
  );

  /// Reads a style set saved by the editor (`miui-editor.widget-style-set`).
  /// Styles that need an icon image stored inside the file can't be offered
  /// and are counted in [skipped]. Null when [json] isn't a style set.
  static WidgetStyleSet? fromEditorFile(Object? json) {
    if (json is! Map ||
        json['format'] != 'miui-editor.widget-style-set' ||
        json['version'] != 1 ||
        json['styles'] is! List) {
      return null;
    }
    final types = ElementType.values.asNameMap();
    final styles = <WidgetStyle>[];
    var skipped = 0;
    for (final s in json['styles'] as List) {
      final appearance = s is Map ? s['appearance'] : null;
      final type = s is Map ? types[s['type']] : null;
      if (s is! Map ||
          appearance is! Map ||
          type == null ||
          s['id'] is! String ||
          s['name'] is! String ||
          appearance['unlockIcon'] == 'customPng') {
        skipped++;
        continue;
      }
      styles.add(
        WidgetStyle(
          id: s['id'] as String,
          name: s['name'] as String,
          type: type,
          appearance: Map<String, dynamic>.from(appearance),
        ),
      );
    }
    if (json['id'] is! String || json['name'] is! String) return null;
    return WidgetStyleSet(
      id: json['id'] as String,
      name: json['name'] as String,
      styles: styles,
      skipped: skipped,
      user: themeUserOf(json['user']),
    );
  }

  final String id, name;
  final List<WidgetStyle> styles;
  final int skipped;

  /// The profile (one of [themeUsers]) this set was made for; null for the
  /// built-in sets and for saved sets nobody has claimed yet.
  final String? user;
}

/// A clock layout (digits, date lines) made for one user; [elements] are
/// spec elements with defaults left out, ready for a lockscreen.
class ClockSetTemplate {
  const ClockSetTemplate({
    required this.id,
    required this.name,
    required this.elements,
    this.user,
  });

  factory ClockSetTemplate.fromJson(Map<String, dynamic> j) => ClockSetTemplate(
    id: j['id'] as String,
    name: j['name'] as String,
    user: themeUserOf(j['user']),
    elements: [
      for (final e in j['elements'] as List)
        Map<String, dynamic>.from(e as Map),
    ],
  );

  final String id, name;
  final String? user;
  final List<Map<String, dynamic>> elements;
}

/// The widget templates, style sets and clock sets that ship with the editor.
class WidgetLibrary {
  const WidgetLibrary._(
    this.widgets,
    this.styleSets,
    this.clockSets,
    this.weatherSets,
    this.batterySets,
  );

  static final WidgetLibrary builtin = () {
    final json = jsonDecode(widgetLibraryJson) as Map<String, dynamic>;
    return WidgetLibrary._(
      [
        for (final w in json['widgets'] as List)
          WidgetTemplate.fromJson(Map<String, dynamic>.from(w as Map)),
      ],
      [
        for (final s in json['styleSets'] as List)
          WidgetStyleSet.fromJson(Map<String, dynamic>.from(s as Map)),
      ],
      [
        for (final c in json['clockSets'] as List? ?? const [])
          ClockSetTemplate.fromJson(Map<String, dynamic>.from(c as Map)),
      ],
      [
        for (final c in json['weatherSets'] as List? ?? const [])
          ClockSetTemplate.fromJson(Map<String, dynamic>.from(c as Map)),
      ],
      [
        for (final c in json['batterySets'] as List? ?? const [])
          ClockSetTemplate.fromJson(Map<String, dynamic>.from(c as Map)),
      ],
    );
  }();

  final List<WidgetTemplate> widgets;
  final List<WidgetStyleSet> styleSets;
  final List<ClockSetTemplate> clockSets;

  /// Weather layouts (temperature, icon, city lines inside shapes).
  final List<ClockSetTemplate> weatherSets;

  /// Battery layouts (rings, bars, percentage text).
  final List<ClockSetTemplate> batterySets;
}
