import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:theme_core/theme_core.dart';

import 'mcp_server.dart';
import 'tool_context.dart';

/// The editor's own sets plus the designer's saved ones from
/// `<root>/WidgetStyles`. Files that can't be read are reported, not fatal.
({List<(WidgetStyleSet, bool)> sets, List<String> problems}) _styleSets(
  ThemeToolContext ctx,
) {
  final sets = <(WidgetStyleSet, bool)>[
    for (final s in WidgetLibrary.builtin.styleSets) (s, true),
  ];
  final problems = <String>[];
  final dir = ctx.root == null ? null : Directory(ctx.root!.widgetStylesDir);
  if (dir != null && dir.existsSync()) {
    final files =
        dir
            .listSync()
            .whereType<File>()
            .where((f) => p.extension(f.path).toLowerCase() == '.json')
            .toList()
          ..sort((a, b) => a.path.compareTo(b.path));
    for (final f in files) {
      try {
        if (f.lengthSync() > 20 * 1024 * 1024) {
          throw const FormatException('larger than 20 MB');
        }
        final set = WidgetStyleSet.fromEditorFile(
          jsonDecode(f.readAsStringSync()),
        );
        if (set == null) throw const FormatException('not a style set');
        sets.add((set, false));
      } on Object catch (e) {
        problems.add('${p.basename(f.path)}: $e');
      }
    }
  }
  return (sets: sets, problems: problems);
}

/// The user a call is for, as a profile name. Throws when it is missing or
/// unknown, so the agent has to ask the designer instead of guessing.
String requireUser(Map<String, dynamic> args) {
  final given = args['user'];
  if (given == null || (given is String && given.trim().isEmpty)) {
    throw ToolException(
      'user is required. Ask the designer which user this theme is for '
      'unless the request already names one; do not guess. '
      'Users: ${themeUsers.join(', ')}.',
    );
  }
  final user = themeUserOf(given);
  if (user == null) {
    throw ToolException(
      'Unknown user "$given". Users: ${themeUsers.join(', ')}. Ask the '
      'designer if it is unclear.',
    );
  }
  return user;
}

const userProp = {
  'type': 'string',
  'enum': themeUsers,
  'description':
      'The user the theme is built for. Use the one the designer named; if '
      'the request names none, ask the designer before calling this.',
};

bool _offScreen(Map<String, dynamic> e) =>
    ((e['dx'] as num?) ?? 0).abs() > 138 ||
    ((e['dy'] as num?) ?? 0).abs() > 300;

const _unlockTypes = {
  'swipeUpUnlock',
  'tapToUnlock',
  'slideToUnlock',
  'dragToUnlock',
};

Map<String, dynamic> _elementArg(Object? v) {
  try {
    final decoded = v is String ? jsonDecode(v) : v;
    if (decoded is Map) return Map<String, dynamic>.from(decoded);
  } on FormatException {
    // fall through
  }
  throw const ToolException(
    'element must be a JSON object, e.g. {"type":"slideToUnlock"}.',
  );
}

/// Warnings for a spec that does not name its user, or that wears a style
/// another user owns instead of one of its own.
List<SpecIssue> styleOwnerIssues(ThemeSpec spec, ThemeToolContext ctx) {
  const warning = IssueSeverity.warning;
  final user = themeUserOf(spec.meta.profile);
  if (user == null) {
    return [
      SpecIssue(
        code: 'meta.profile_missing',
        path: '/meta/profile',
        message: 'The spec does not say which user it is for.',
        hint:
            'Set meta.profile to one of ${themeUsers.join(', ')}; get_base_spec '
            'does it when given user.',
        severity: warning,
      ),
    ];
  }
  final sets = [for (final e in _styleSets(ctx).sets) e.$1];
  bool wears(Map<String, dynamic> element, WidgetStyle style) {
    if (style.appearance.length < 4) return false;
    final look = LockElementSpec.fromJson({
      'type': style.type.name,
      ...style.appearance,
    }).toJson();
    return style.appearance.keys.every(
      (k) => jsonEncode(element[k]) == jsonEncode(look[k]),
    );
  }

  final issues = <SpecIssue>[];
  final elements = spec.lockscreen.elements;
  for (var i = 0; i < elements.length; i++) {
    final e = elements[i];
    if (!e.isVisible) continue;
    final json = e.toJson();
    bool wornFrom(bool Function(WidgetStyleSet) pick) => sets.any(
      (s) =>
          pick(s) && s.styles.any((st) => st.type == e.type && wears(json, st)),
    );
    if (wornFrom((s) => s.user == user)) continue;
    final other = sets
        .where((s) => s.user != null && s.user != user)
        .where((s) => wornFrom((o) => identical(o, s)))
        .firstOrNull;
    if (other != null) {
      issues.add(
        SpecIssue(
          code: 'style.other_user',
          path: '/lockscreen/elements/$i',
          message:
              '"${e.name}" uses a style from ${other.user}\'s set '
              '"${other.name}", not $user\'s.',
          hint: 'Pick a style from list_widget_styles for $user.',
          severity: warning,
        ),
      );
    }
  }
  return issues;
}

/// `list_<kind>_sets` and `get_<kind>_set` for a family of per-user layouts.
List<McpTool> _infoSetTools({
  required String kind,
  required List<ClockSetTemplate> Function() sets,
  required String what,
}) => [
  McpTool(
    name: 'list_${kind}_sets',
    description:
        'Lists the ready-made $what that belong to one user. Use only these '
        'for that user, never another user\'s. Read one with get_${kind}_set.',
    inputSchema: const {
      'type': 'object',
      'properties': {'user': userProp},
      'required': ['user'],
    },
    readOnly: true,
    handler: (args, progress) async {
      final user = requireUser(args);
      final own = [
        for (final c in sets())
          if (c.user == user) c,
      ];
      return ToolResult(
        jsonEncode({
          'user': user,
          if (own.isEmpty)
            'note':
                '$user has no $kind sets. Design it yourself; do not use '
                'another user\'s.',
          '${kind}_sets': [
            for (final c in own)
              {
                'id': c.id,
                'name': c.name,
                'types': [for (final e in c.elements) e['type']],
              },
          ],
        }),
      );
    },
  ),
  McpTool(
    name: 'get_${kind}_set',
    description:
        'Reads a $kind set of list_${kind}_sets: its elements, ready to add '
        'to lockscreen.elements. Only fields that differ from the defaults '
        'are listed. Shape sizes are theme pixels, dx and dy are screen '
        'units from the centre. Move it with dx and dy, recolor it to suit '
        'the wallpaper and keep it clear of the status bar.',
    inputSchema: {
      'type': 'object',
      'properties': {
        'id': {'type': 'string', 'description': 'From list_${kind}_sets.'},
        'user': userProp,
      },
      'required': ['id', 'user'],
    },
    readOnly: true,
    handler: (args, progress) async {
      final id = args['id'];
      if (id is! String || id.isEmpty) {
        throw const ToolException('id is required.');
      }
      final user = requireUser(args);
      final found = sets().where((c) => c.id == id).firstOrNull;
      if (found == null) {
        throw ToolException('No $kind set "$id". See list_${kind}_sets.');
      }
      if (found.user != user) {
        throw ToolException(
          'The $kind set "$id" belongs to ${found.user ?? 'nobody'}, not '
          '$user. Pick one from list_${kind}_sets for $user.',
        );
      }
      return ToolResult(
        jsonEncode({
          'id': found.id,
          'name': found.name,
          'user': user,
          'elements': found.elements,
        }),
      );
    },
  ),
];

/// Tools that tell the agent what the desktop editor's Widget Center offers.
List<McpTool> widgetTools(ThemeToolContext ctx) => [
  McpTool(
    name: 'list_users',
    description:
        'Lists the users themes are built for, with how many saved style '
        'sets each has. Every design starts by knowing the user: when the '
        'designer\'s request does not name one, show this list and ask which '
        'user the theme is for before designing.',
    inputSchema: const {
      'type': 'object',
      'properties': {
        'user': {
          'type': 'string',
          'description': 'Only this user, to see how many sets they have.',
        },
      },
    },
    readOnly: true,
    handler: (args, progress) async {
      final only = args['user'] == null ? null : requireUser(args);
      final sets = _styleSets(ctx).sets;
      return ToolResult(
        jsonEncode({
          'users': [
            for (final u in themeUsers)
              if (only == null || u == only)
                {
                  'user': u,
                  'style_sets': sets.where((s) => s.$1.user == u).length,
                  'clock_sets': WidgetLibrary.builtin.clockSets
                      .where((c) => c.user == u)
                      .length,
                  'weather_sets': WidgetLibrary.builtin.weatherSets
                      .where((c) => c.user == u)
                      .length,
                  'battery_sets': WidgetLibrary.builtin.batterySets
                      .where((c) => c.user == u)
                      .length,
                },
          ],
        }),
      );
    },
  ),
  McpTool(
    name: 'list_clock_sets',
    description:
        'Lists the ready-made clock layouts (hour, minute, date lines with '
        'fonts, colors, textures) that belong to one user. Use only these '
        'for that user, never another user\'s. Read one with get_clock_set.',
    inputSchema: const {
      'type': 'object',
      'properties': {'user': userProp},
      'required': ['user'],
    },
    readOnly: true,
    handler: (args, progress) async {
      final user = requireUser(args);
      final own = [
        for (final c in WidgetLibrary.builtin.clockSets)
          if (c.user == user) c,
      ];
      return ToolResult(
        jsonEncode({
          'user': user,
          if (own.isEmpty)
            'note':
                '$user has no clock sets. Design the clock yourself; do not '
                'use another user\'s.',
          'clock_sets': [
            for (final c in own)
              {
                'id': c.id,
                'name': c.name,
                'types': [for (final e in c.elements) e['type']],
              },
          ],
        }),
      );
    },
  ),
  McpTool(
    name: 'get_clock_set',
    description:
        'Reads a clock set of list_clock_sets: its elements, ready to add to '
        'lockscreen.elements. Only fields that differ from the defaults are '
        'listed. Its fonts are Google or catalog fonts that need font files '
        '(see list_fonts): swap in a listed font if the file is missing. '
        'Move it with dx and dy, recolor it to suit the wallpaper, and keep '
        'it clear of the status bar.',
    inputSchema: const {
      'type': 'object',
      'properties': {
        'id': {'type': 'string', 'description': 'From list_clock_sets.'},
        'user': userProp,
      },
      'required': ['id', 'user'],
    },
    readOnly: true,
    handler: (args, progress) async {
      final id = args['id'];
      if (id is! String || id.isEmpty) {
        throw const ToolException('id is required.');
      }
      final user = requireUser(args);
      final found = WidgetLibrary.builtin.clockSets
          .where((c) => c.id == id)
          .firstOrNull;
      if (found == null) {
        throw ToolException('No clock set "$id". See list_clock_sets.');
      }
      if (found.user != user) {
        throw ToolException(
          'The clock set "$id" belongs to ${found.user ?? 'nobody'}, not '
          '$user. Pick one from list_clock_sets for $user.',
        );
      }
      final fonts = {
        for (final e in found.elements)
          if (e['font'] is String &&
              FontRef.parse(e['font'] as String).needsFile)
            e['font'] as String,
      }.toList();
      return ToolResult(
        jsonEncode({
          'id': found.id,
          'name': found.name,
          'user': user,
          if (fonts.isNotEmpty) 'fonts_needed': fonts,
          'elements': found.elements,
        }),
      );
    },
  ),
  ..._infoSetTools(
    kind: 'weather',
    sets: () => WidgetLibrary.builtin.weatherSets,
    what:
        'weather layouts (icon, temperature, description, city, humidity '
        'and AQI texts framed by geometry shapes)',
  ),
  ..._infoSetTools(
    kind: 'battery',
    sets: () => WidgetLibrary.builtin.batterySets,
    what:
        'battery layouts (live rings, gauges and bars drawn with arc and '
        'rectangle shapes, plus the percentage text)',
  ),
  McpTool(
    name: 'list_widgets',
    description:
        'Lists the ready-made widgets of the editor\'s Widget Center '
        '(battery ring, calendar, floating music, shortcut dock, bento '
        'layouts...), grouped by category, with the element types each '
        'uses. Read one with get_widget.',
    inputSchema: const {
      'type': 'object',
      'properties': {
        'category': {
          'type': 'string',
          'description': 'Only this category, e.g. Music.',
        },
      },
    },
    readOnly: true,
    handler: (args, progress) async {
      final category = (args['category'] as String? ?? '').toLowerCase();
      final byCategory = <String, List<Map<String, dynamic>>>{};
      for (final w in WidgetLibrary.builtin.widgets) {
        if (category.isNotEmpty && w.category.toLowerCase() != category) {
          continue;
        }
        byCategory.putIfAbsent(w.category, () => []).add({
          'name': w.name,
          'description': w.description,
          'elements': w.elements.length,
          'types': {for (final e in w.elements) e['type']}.toList(),
        });
      }
      return ToolResult(
        jsonEncode({
          'categories': [
            for (final e in byCategory.entries)
              {'category': e.key, 'widgets': e.value},
          ],
        }),
      );
    },
  ),
  McpTool(
    name: 'get_widget',
    description:
        'Reads a widget: its elements, ready to add to a spec\'s '
        'lockscreen.elements. Only fields that differ from the defaults are '
        'listed. Repeated elements already have their instanceId. A widget '
        'may have no unlock control, which every lockscreen needs; add one '
        '(see list_widget_styles). dx and dy place the widget on the screen; change them to '
        'move it, and change colors and fonts to suit the wallpaper. A "path" '
        'names a folder of images in the lockscreen assets.',
    inputSchema: const {
      'type': 'object',
      'properties': {
        'name': {'type': 'string', 'description': 'From list_widgets.'},
      },
      'required': ['name'],
    },
    readOnly: true,
    handler: (args, progress) async {
      final name = args['name'];
      if (name is! String || name.isEmpty) {
        throw const ToolException('name is required.');
      }
      final matches = WidgetLibrary.builtin.widgets
          .where((w) => w.name.toLowerCase() == name.toLowerCase())
          .toList();
      if (matches.isEmpty) {
        throw ToolException(
          'No widget called "$name". Known: '
          '${WidgetLibrary.builtin.widgets.map((w) => w.name).join(', ')}.',
        );
      }
      final w = matches.first;
      return ToolResult(
        jsonEncode({
          'name': w.name,
          'category': w.category,
          'description': w.description,
          if (!w.elements.any((e) => _unlockTypes.contains(e['type'])))
            'note':
                'No unlock control in this widget; the lockscreen still '
                'needs one.',
          if (w.elements.any(_offScreen))
            'warning':
                'Some positions are outside the screen (dx -138 to 138, dy '
                '-300 to 300 are visible), so use them only as a guide to '
                'the arrangement: re-place the elements and check with '
                'preview_lockscreen.',
          'elements': w.elements,
        }),
      );
    },
  ),
  McpTool(
    name: 'list_widget_styles',
    description:
        'Lists the saved looks for unlock controls (tapToUnlock, '
        'slideToUnlock, dragToUnlock), analog clocks, shortcut sets and '
        'calendar grids, for one user: only the style sets that user owns '
        '(the editor\'s sets dealt to them and any they saved in '
        'WidgetStyles/). Pick styles from these only, never from another '
        'user. If there is none for a type, leave that widget with its '
        'default look. Apply one with get_widget_style.',
    inputSchema: const {
      'type': 'object',
      'properties': {
        'user': userProp,
        'type': {
          'type': 'string',
          'description': 'Only styles for this element type, e.g. analogClock.',
        },
        'set': {
          'type': 'string',
          'description': 'Only this style set (its id from an earlier call).',
        },
      },
      'required': ['user'],
    },
    readOnly: true,
    handler: (args, progress) async {
      final user = requireUser(args);
      final type = args['type'] as String?;
      final only = args['set'] as String?;
      final loaded = _styleSets(ctx);
      bool offers(WidgetStyleSet s) =>
          s.styles.any((st) => type == null || st.type.name == type);
      final own = [
        for (final e in loaded.sets)
          if (e.$1.user == user) e,
      ];
      final offered = own.any((e) => offers(e.$1));
      final forType = type == null ? '' : ' with $type styles';
      return ToolResult(
        jsonEncode({
          'user': user,
          if (!offered)
            'note':
                '$user has no style sets$forType. Do not use another '
                'user\'s styles; leave this widget with its default look.',
          'sets': [
            for (final (set, builtin) in own)
              if (offers(set) && (only == null || set.id == only))
                {
                  'id': set.id,
                  'name': set.name,
                  'builtin': builtin,
                  if (set.user != null) 'user': set.user,
                  if (set.skipped > 0)
                    'left_out': '${set.skipped} styles that need an icon image',
                  'styles': [
                    for (final s in set.styles)
                      if (type == null || s.type.name == type)
                        {'id': s.id, 'name': s.name, 'type': s.type.name},
                  ],
                },
          ],
          if (loaded.problems.isNotEmpty) 'unreadable': loaded.problems,
        }),
      );
    },
  ),
  McpTool(
    name: 'get_widget_style',
    description:
        'Reads a style from list_widget_styles. Gives its appearance (the '
        'element fields it sets). With element, gives that element with the '
        'style applied: position and other fields stay, the look is '
        'replaced.',
    inputSchema: const {
      'type': 'object',
      'properties': {
        'id': {'type': 'string', 'description': 'The style id.'},
        'set': {
          'type': 'string',
          'description': 'The style set id, if the style id appears in two.',
        },
        'element': {
          'type': 'string',
          'description':
              'An element of the style\'s type as JSON text, e.g. '
              '{"type":"analogClock","dx":120}.',
        },
        'user': userProp,
      },
      'required': ['id', 'user'],
    },
    readOnly: true,
    handler: (args, progress) async {
      final id = args['id'];
      if (id is! String || id.isEmpty) {
        throw const ToolException('id is required.');
      }
      final user = requireUser(args);
      final only = args['set'] as String?;
      final found = [
        for (final (set, _) in _styleSets(ctx).sets)
          if (only == null || set.id == only)
            for (final s in set.styles)
              if (s.id == id) (set, s),
      ];
      if (found.isEmpty) {
        throw ToolException('No style "$id". See list_widget_styles.');
      }
      if (found.length > 1) {
        throw ToolException(
          'The style "$id" is in several sets '
          '(${found.map((f) => f.$1.id).join(', ')}); give set.',
        );
      }
      final (set, style) = found.single;
      if (set.user != user) {
        throw ToolException(
          'The style "$id" belongs to ${set.user ?? 'nobody'}, not $user. '
          'Pick one from list_widget_styles for $user.',
        );
      }
      final Map<String, dynamic>? applied;
      if (args['element'] == null) {
        applied = null;
      } else {
        try {
          applied = style.applyTo(_elementArg(args['element']));
        } on FormatException catch (e) {
          throw ToolException(e.message);
        }
      }
      return ToolResult(
        jsonEncode({
          'id': style.id,
          'name': style.name,
          'set': set.id,
          'type': style.type.name,
          'appearance': style.appearance,
          if (applied != null) 'element': applied,
        }),
      );
    },
  ),
];
