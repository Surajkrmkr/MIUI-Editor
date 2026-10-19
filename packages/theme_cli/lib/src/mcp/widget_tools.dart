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

/// Tools that tell the agent what the desktop editor's Widget Center offers.
List<McpTool> widgetTools(ThemeToolContext ctx) => [
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
        'calendar grids: the editor\'s built-in sets and, when a root folder '
        'is set, the designer\'s own from WidgetStyles/. Apply one with '
        'get_widget_style.',
    inputSchema: const {
      'type': 'object',
      'properties': {
        'type': {
          'type': 'string',
          'description': 'Only styles for this element type, e.g. analogClock.',
        },
        'set': {
          'type': 'string',
          'description': 'Only this style set (its id from an earlier call).',
        },
      },
    },
    readOnly: true,
    handler: (args, progress) async {
      final type = args['type'] as String?;
      final only = args['set'] as String?;
      final loaded = _styleSets(ctx);
      return ToolResult(
        jsonEncode({
          'sets': [
            for (final (set, builtin) in loaded.sets)
              if (only == null || set.id == only)
                {
                  'id': set.id,
                  'name': set.name,
                  'builtin': builtin,
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
      },
      'required': ['id'],
    },
    readOnly: true,
    handler: (args, progress) async {
      final id = args['id'];
      if (id is! String || id.isEmpty) {
        throw const ToolException('id is required.');
      }
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
