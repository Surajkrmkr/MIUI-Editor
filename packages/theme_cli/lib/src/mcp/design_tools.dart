import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:theme_core/theme_core.dart';

import 'library_tools.dart';
import 'mcp_server.dart';
import 'tool_args.dart';
import 'tool_context.dart';
import 'widget_tools.dart' show requireUser, userProp;

const _imageExtensions = {'.png', '.jpg', '.jpeg', '.webp'};

/// A curated lockscreen: its picture, and its elements when they were saved
/// with it.
class _Reference {
  _Reference(this.name, this.image, this.elementsFile);

  final String name;
  final File image;
  final File? elementsFile;
}

List<_Reference> _references(Directory dir) {
  if (!dir.existsSync()) return [];
  final found = <_Reference>[];
  for (final entity in dir.listSync()) {
    final name = p.basenameWithoutExtension(entity.path);
    if (entity is File &&
        _imageExtensions.contains(p.extension(entity.path).toLowerCase())) {
      final json = File(p.join(dir.path, '$name.json'));
      found.add(_Reference(name, entity, json.existsSync() ? json : null));
    } else if (entity is Directory) {
      final preset = File(p.join(entity.path, 'preset.json'));
      final preview = File(p.join(entity.path, 'preview.png'));
      if (preview.existsSync()) {
        found.add(
          _Reference(
            p.basename(entity.path),
            preview,
            preset.existsSync() ? preset : null,
          ),
        );
      }
    }
  }
  return found..sort((a, b) => a.name.compareTo(b.name));
}

/// The elements in a preset file (a list) or a spec file.
List<Map<String, dynamic>>? _elementsIn(File file) {
  try {
    final json = jsonDecode(file.readAsStringSync());
    final lockscreen = json is Map ? json['lockscreen'] : null;
    final list = json is List
        ? json
        : lockscreen is Map
        ? lockscreen['elements']
        : null;
    if (list is! List) return null;
    return [
      for (final e in list)
        if (e is Map) Map<String, dynamic>.from(e),
    ];
  } on Object {
    return null;
  }
}

/// The lockscreen of a spec as a design, or null when it can't be read.
DesignProfile? _designOf(Object? json) {
  final spec = ThemeSpec.parse(json).spec;
  return spec == null ? null : DesignProfile(spec.lockscreen.elements);
}

const _maxEarlierSpecs = 5000;

final _designCache =
    <String, ({int modified, int size, NamedDesign? design})>{};

/// Every readable spec under [dir], at any depth, as a design; unchanged
/// files are not parsed again.
List<({String path, NamedDesign design})> readEarlierDesigns(String dir) {
  final root = Directory(dir);
  if (!root.existsSync()) return [];
  final found = <({String path, NamedDesign design})>[];
  var seen = 0;
  for (final f in root.listSync(recursive: true).whereType<File>()) {
    if (p.extension(f.path).toLowerCase() != '.json') continue;
    if (++seen > _maxEarlierSpecs) break;
    final stat = f.statSync();
    final modified = stat.modified.millisecondsSinceEpoch;
    var cached = _designCache[f.path];
    if (cached == null ||
        cached.modified != modified ||
        cached.size != stat.size) {
      NamedDesign? design;
      try {
        final spec = ThemeSpec.parse(jsonDecode(f.readAsStringSync())).spec;
        if (spec != null) {
          design = NamedDesign(
            spec.meta.title,
            DesignProfile(spec.lockscreen.elements),
          );
        }
      } on Object {
        design = null;
      }
      cached = (modified: modified, size: stat.size, design: design);
      _designCache[f.path] = cached;
    }
    if (cached.design != null) {
      found.add((path: f.path, design: cached.design!));
    }
  }
  return found;
}

/// The designs of the specs already made, for the validator to compare with;
/// empty without a root folder.
List<NamedDesign> earlierDesigns(ThemeToolContext ctx) => ctx.root == null
    ? const []
    : [for (final e in readEarlierDesigns(ctx.root!.specsDir)) e.design];

Map<String, Object?> _summary(DesignProfile d) => {
  'visible_elements': d.count,
  'clocks': d.clockTypes.toList(),
  'unlock': d.unlock,
  'clock_position': d.clockCell,
  'text_color': d.colorFamily,
};

/// Tools that help the agent make lockscreens that are good and different:
/// curated pictures to study and a check against earlier designs.
List<McpTool> designTools(ThemeToolContext ctx) => [
  McpTool(
    name: 'get_base_spec',
    description:
        'The starting point for every theme: a complete spec whose lockscreen '
        'is already aligned (clock, weekday, weather card, unlock control, '
        'nothing overlapping or off screen). It shows only where things fit '
        'and how big they are; it is not a design to ship. Change the clock '
        'arrangement and position, the card content, the unlock control and '
        'the colors, using the layout guide for positions. validate_spec '
        'warns when a theme is still this layout. Also returns the guide: the '
        'canvas size and which fields use which units.',
    inputSchema: const {
      'type': 'object',
      'properties': {
        'title': {'type': 'string', 'description': 'The theme name.'},
        'wallpaper': {
          'type': 'string',
          'description':
              'Wallpaper file name from list_wallpapers, or a path. '
              'Default is a placeholder to replace.',
        },
        'week': {'type': 'string', 'description': 'Week number, e.g. 3.'},
        'folder': {
          'type': 'string',
          'description': 'Wallpaper folder, e.g. 2 for Wall/2.',
        },
        'user': userProp,
      },
      'required': ['title', 'user'],
    },
    readOnly: true,
    handler: (args, progress) async {
      final user = requireUser(args);
      final title = args['title'];
      if (title is! String || title.trim().isEmpty) {
        throw const ToolException('title is required.');
      }
      final wallpaper = args['wallpaper'];
      if (wallpaper != null && (wallpaper is! String || wallpaper.isEmpty)) {
        throw const ToolException('wallpaper must be a file name or path.');
      }
      return ToolResult(
        jsonEncode({
          'spec': baseSpec(
            title: title.trim(),
            wallpaper: wallpaper as String?,
            week: argId(args, 'week'),
            folder: argId(args, 'folder'),
            user: user,
          ),
          'layout_guide': baseLayoutGuide.trim(),
          'next':
              'This is the same layout every theme starts from, so do not '
              'ship it. Make your own design: change the clock arrangement '
              'and position, what the card shows, the unlock control and the '
              'colors, and keep elements inside the margins. After each '
              'move, preview_lockscreen. validate_spec warns when the '
              'result is still this layout or too close to an earlier theme.',
        }),
      );
    },
  ),
  McpTool(
    name: 'list_references',
    description:
        'Lists the designer\'s curated lockscreens (the AI preset folder): '
        'the designs to aim for. Study several with get_reference before '
        'designing.',
    inputSchema: const {
      'type': 'object',
      'properties': {
        'query': {
          'type': 'string',
          'description': 'Only references whose name contains this text.',
        },
      },
    },
    readOnly: true,
    handler: (args, progress) async {
      final dir = Directory(requireRoot(ctx).referencesDir);
      final query = (args['query'] as String? ?? '').toLowerCase();
      final all = [
        for (final r in _references(dir))
          if (r.name.toLowerCase().contains(query)) r,
      ];
      return ToolResult(
        jsonEncode({
          'dir': dir.path,
          'total': all.length,
          if (all.isEmpty)
            'note':
                'The AI preset folder has no pictures yet. Tell the designer '
                'to add some; do not use the Preset folder instead.',
          'references': [
            for (final r in all)
              {'name': r.name, 'has_elements': r.elementsFile != null},
          ],
        }),
      );
    },
  ),
  McpTool(
    name: 'get_reference',
    description:
        'Shows a curated lockscreen. Look at the picture: its layout, '
        'spacing, clock style and widgets are what to build toward, using '
        'list_widgets, list_widget_styles and the spec\'s elements. When the '
        'reference has elements they are returned, ready to use. Do not copy '
        'it exactly.',
    inputSchema: const {
      'type': 'object',
      'properties': {
        'name': {'type': 'string', 'description': 'From list_references.'},
        'max_width': {
          'type': 'integer',
          'minimum': 128,
          'maximum': 1080,
          'description': 'Width of the returned picture. Default 480.',
        },
      },
      'required': ['name'],
    },
    readOnly: true,
    handler: (args, progress) async {
      final name = args['name'];
      if (name is! String ||
          name.isEmpty ||
          name != p.basename(name) ||
          name == '..') {
        throw const ToolException(
          'name must be a reference name from list_references.',
        );
      }
      final width = argInt(args, 'max_width') ?? 480;
      if (width < 128 || width > 1080) {
        throw const ToolException('max_width must be from 128 to 1080.');
      }
      final ref = _references(
        Directory(requireRoot(ctx).referencesDir),
      ).where((r) => r.name == name).firstOrNull;
      if (ref == null) throw ToolException('No reference called "$name".');

      final picture = scaledPicture(ref.image, width);
      if (picture == null) {
        throw ToolException('${ref.image.path} is not an image.');
      }
      final elements = ref.elementsFile == null
          ? null
          : _elementsIn(ref.elementsFile!);
      final unreadable = elements == null
          ? 0
          : readyElements(elements, p.dirname(ref.elementsFile!.path));
      return ToolResult(
        jsonEncode({
          'name': name,
          if (elements == null)
            'note':
                'Only the picture was saved. Recreate the look from widgets '
                'and styles.',
          if (unreadable > 0)
            'unreadable_alignments': '$unreadable set to Alignment.center',
          'elements': ?elements,
        }),
        images: [picture],
      );
    },
  ),
  McpTool(
    name: 'check_uniqueness',
    description:
        'Compares a spec\'s lockscreen with the specs already made (the '
        'THEMES/specs folder) and returns the closest ones with what they '
        'share: clock style, unlock control, clock position, text color and '
        'element types. If it says too_similar, change the design.',
    inputSchema: const {
      'type': 'object',
      'properties': {
        'spec': {
          'type': 'string',
          'description': 'The theme spec as JSON text. Give this or path.',
        },
        'path': {
          'type': 'string',
          'description': 'Path to a spec .json file. Give this or spec.',
        },
        'specs_dir': {
          'type': 'string',
          'description':
              'Folder of earlier specs to compare with. Defaults to '
              'THEMES/specs in the root.',
        },
        'threshold': {
          'type': 'number',
          'minimum': 0.1,
          'maximum': 1,
          'description':
              'Similarity from which a design counts as too similar. '
              'Default 0.7.',
        },
      },
    },
    readOnly: true,
    handler: (args, progress) async {
      final path = argPath(args, 'path', ctx);
      final inline = args['spec'];
      if ((path == null) == (inline == null)) {
        throw const ToolException('Give spec or path, not both.');
      }
      final Object? json;
      try {
        json = jsonDecode(
          path != null
              ? File(path).readAsStringSync()
              : inline is String
              ? inline
              : jsonEncode(inline),
        );
      } on FormatException catch (e) {
        throw ToolException('The spec is not valid JSON: ${e.message}');
      } on FileSystemException catch (e) {
        throw ToolException('Cannot read $path: ${e.message}');
      }
      final mine = _designOf(json);
      if (mine == null) {
        throw const ToolException(
          'The spec has errors; fix them with validate_spec first.',
        );
      }
      final title = ThemeSpec.parse(json).spec!.meta.title;
      final threshold = (args['threshold'] as num?)?.toDouble() ?? .7;
      final dir = Directory(
        argPath(args, 'specs_dir', ctx) ?? requireRoot(ctx).specsDir,
      );
      if (!dir.existsSync()) {
        return ToolResult(
          jsonEncode({
            'verdict': 'distinct',
            'note': 'No earlier specs in ${dir.path}, so nothing to compare.',
            'design': _summary(mine),
          }),
        );
      }

      final scored = <({String name, double score, List<String> shared})>[];
      for (final earlier in readEarlierDesigns(dir.path)) {
        if (path != null && p.equals(earlier.path, path)) continue;
        if (earlier.design.title == title) continue;
        scored.add((
          name: earlier.design.title,
          score: mine.similarityTo(earlier.design.design),
          shared: mine.sharedWith(earlier.design.design),
        ));
      }
      scored.sort((a, b) => b.score.compareTo(a.score));
      final worst = scored.isEmpty ? 0.0 : scored.first.score;
      return ToolResult(
        jsonEncode({
          'verdict': worst >= threshold ? 'too_similar' : 'distinct',
          'compared_with': scored.length,
          'threshold': threshold,
          'design': _summary(mine),
          'closest': [
            for (final s in scored.take(3))
              {
                'name': s.name,
                'similarity': double.parse(s.score.toStringAsFixed(2)),
                'shares': s.shared,
              },
          ],
        }),
      );
    },
  ),
];
