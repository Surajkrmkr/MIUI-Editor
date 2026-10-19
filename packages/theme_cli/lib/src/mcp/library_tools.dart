import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:theme_core/theme_core.dart';

import 'mcp_server.dart';
import 'tool_args.dart';
import 'tool_context.dart';

const _imageExtensions = {'.jpg', '.jpeg', '.png', '.webp'};

/// Tools that look things up in the designer's folders: wallpapers and the
/// preset lockscreens that serve as references.
List<McpTool> libraryTools(ThemeToolContext ctx) => [
  McpTool(
    name: 'list_wallpapers',
    description:
        'Lists the wallpapers in Wall/<folder>. Without folder it lists the '
        'folders and how many wallpapers each holds. A wallpaper\'s name '
        'without its extension is the theme name the desktop editor uses.',
    inputSchema: const {
      'type': 'object',
      'properties': {
        'folder': {
          'type': 'string',
          'description': 'Wallpaper folder, e.g. 2.',
        },
      },
    },
    readOnly: true,
    handler: (args, progress) async {
      final root = requireRoot(ctx);
      final folder = argId(args, 'folder');
      if (folder == null) {
        final dir = Directory(root.wallDir);
        if (!dir.existsSync()) {
          throw ToolException('No wallpaper folder at ${root.wallDir}.');
        }
        final folders =
            [
              for (final d in dir.listSync().whereType<Directory>())
                {
                  'folder': p.basename(d.path),
                  'wallpapers': _wallpapers(d).length,
                },
            ]..sort(
              (a, b) =>
                  _natural(a['folder']! as String, b['folder']! as String),
            );
        return ToolResult(
          jsonEncode({'root': root.wallDir, 'folders': folders}),
        );
      }
      final dir = Directory(root.wallFolder(folder));
      if (!dir.existsSync()) {
        throw ToolException(
          'No wallpaper folder $folder (looked in ${dir.path}).',
        );
      }
      return ToolResult(
        jsonEncode({
          'folder': folder,
          'dir': dir.path,
          'wallpapers': [
            for (final f in _wallpapers(dir))
              {
                'name': p.basename(f.path),
                'theme_name': p.basenameWithoutExtension(f.path),
                'path': f.path,
                'bytes': f.lengthSync(),
              },
          ],
        }),
      );
    },
  ),
  McpTool(
    name: 'view_wallpaper',
    description:
        'Shows a wallpaper (scaled down) and tells its dominant colors and '
        'whether it is dark or light, so text and icon colors can be chosen '
        'to match and stay legible. Give folder and name, or a path.',
    inputSchema: const {
      'type': 'object',
      'properties': {
        'folder': {
          'type': 'string',
          'description': 'Wallpaper folder, e.g. 2.',
        },
        'name': {
          'type': 'string',
          'description':
              'File name from list_wallpapers; the extension may '
              'be left out.',
        },
        'path': {'type': 'string', 'description': 'Or an image file path.'},
        'max_width': {
          'type': 'integer',
          'minimum': 64,
          'maximum': 1080,
          'description': 'Width of the returned image. Default 540.',
        },
      },
    },
    readOnly: true,
    handler: (args, progress) async {
      final width = argInt(args, 'max_width') ?? 540;
      if (width < 64 || width > 1080) {
        throw const ToolException('max_width must be from 64 to 1080.');
      }
      final file = _wallpaperFile(args, ctx);
      final image = img.decodeImage(file.readAsBytesSync());
      if (image == null) throw ToolException('${file.path} is not an image.');

      final shown = image.width > width
          ? img.copyResize(
              image,
              width: width,
              interpolation: img.Interpolation.average,
            )
          : image;
      final palette = _palette(image);
      return ToolResult(
        jsonEncode({
          'path': file.path,
          'width': image.width,
          'height': image.height,
          'palette': palette.colors,
          'average_luminance': double.parse(
            palette.luminance.toStringAsFixed(2),
          ),
          'tone': palette.luminance < .35
              ? 'dark'
              : palette.luminance > .65
              ? 'light'
              : 'mid',
        }),
        images: [
          ToolImage(
            Uint8List.fromList(img.encodeJpg(shown, quality: 85)),
            mimeType: 'image/jpeg',
          ),
        ],
      );
    },
  ),
  McpTool(
    name: 'list_presets',
    description:
        'Lists saved presets, with their visible lockscreen element types. '
        'Presets may include a complete theme spec. Use only when the '
        'designer asks for a preset by name; design references come from '
        'list_references.',
    inputSchema: const {
      'type': 'object',
      'properties': {
        'query': {
          'type': 'string',
          'description': 'Only presets whose name contains this text.',
        },
        'min_elements': {
          'type': 'integer',
          'minimum': 0,
          'description':
              'Only presets with at least this many visible elements. Rich '
              'lockscreens have 6 or more.',
        },
        'sort': {
          'type': 'string',
          'enum': ['name', 'elements'],
          'description':
              'name (default), or elements to list the richest presets first.',
        },
        'limit': {
          'type': 'integer',
          'minimum': 1,
          'maximum': 300,
          'description': 'How many to return. Default 50.',
        },
      },
    },
    readOnly: true,
    handler: (args, progress) async {
      final root = requireRoot(ctx);
      final query = (args['query'] as String? ?? '').toLowerCase();
      final limit = argInt(args, 'limit') ?? 50;
      if (limit < 1 || limit > 300) {
        throw const ToolException('limit must be from 1 to 300.');
      }
      final minElements = argInt(args, 'min_elements') ?? 0;
      final sort = args['sort'] as String? ?? 'name';
      if (sort != 'name' && sort != 'elements') {
        throw const ToolException('sort must be name or elements.');
      }
      final dir = Directory(root.presetsDir);
      if (!dir.existsSync()) {
        throw ToolException('No preset folder at ${root.presetsDir}.');
      }
      final all =
          <({Directory dir, List<Map<String, dynamic>> elements})>[
              for (final d in dir.listSync().whereType<Directory>())
                if (p.basename(d.path).toLowerCase().contains(query) &&
                    File(p.join(d.path, 'preset.json')).existsSync())
                  (dir: d, elements: _presetElements(d)),
            ].where((e) => visibleCount(e.elements) >= minElements).toList()
            ..sort((a, b) {
              if (sort == 'elements') {
                final by = visibleCount(
                  b.elements,
                ).compareTo(visibleCount(a.elements));
                if (by != 0) return by;
              }
              return p.basename(a.dir.path).compareTo(p.basename(b.dir.path));
            });
      return ToolResult(
        jsonEncode({
          'total': all.length,
          'presets': [
            for (final e in all.take(limit))
              {
                'name': p.basename(e.dir.path),
                'visible_elements': visibleCount(e.elements),
                'elements': e.elements
                    .map((x) => '${x['type']}')
                    .toSet()
                    .toList(),
                'has_preview': File(
                  p.join(e.dir.path, 'preview.png'),
                ).existsSync(),
              },
          ],
        }),
      );
    },
  ),
  McpTool(
    name: 'get_preset',
    description:
        'Reads a preset, including its complete theme spec when available, '
        'lockscreen elements and preview. Adapt its wallpaper, icons, '
        'lockscreen and system-UI style to the requested theme. Fonts it '
        'lists need font files. Use only when the designer asks for a preset '
        'by name; design references come from get_reference.',
    inputSchema: const {
      'type': 'object',
      'properties': {
        'name': {'type': 'string', 'description': 'From list_presets.'},
        'image': {
          'type': 'boolean',
          'description': 'Return the preview image. Default true.',
        },
      },
      'required': ['name'],
    },
    readOnly: true,
    handler: (args, progress) async {
      final root = requireRoot(ctx);
      final name = args['name'];
      if (name is! String ||
          name.isEmpty ||
          name != p.basename(name) ||
          name == '..') {
        throw const ToolException(
          'name must be a preset name from list_presets.',
        );
      }
      final dir = Directory(p.join(root.presetsDir, name));
      if (!File(p.join(dir.path, 'preset.json')).existsSync()) {
        throw ToolException('No preset called "$name".');
      }
      final presetJson = jsonDecode(
        File(p.join(dir.path, 'preset.json')).readAsStringSync(),
      );
      final fullSpec =
          presetJson is Map && ThemeSpec.parse(presetJson).spec != null
          ? presetJson
          : null;
      final elements = _presetElements(dir);
      final unreadable = readyElements(elements, dir.path);
      final fonts = {
        for (final e in elements)
          if (e['font'] is String &&
              FontRef.parse(e['font'] as String).needsFile)
            e['font'] as String,
      }.toList();

      final preview = File(p.join(dir.path, 'preview.png'));
      final images = <ToolImage>[
        if ((argBool(args, 'image') ?? true) && preview.existsSync())
          ?scaledPicture(preview, 360),
      ];
      return ToolResult(
        jsonEncode({
          'name': name,
          if (fullSpec != null) 'spec': fullSpec,
          if (unreadable > 0)
            'note':
                '$unreadable alignment values in this preset were unreadable '
                'and are set to Alignment.center, as the editor does.',
          if (fonts.isNotEmpty) 'fonts_needed': fonts,
          'elements': elements,
        }),
        images: images,
      );
    },
  ),
  McpTool(
    name: 'get_rules',
    description:
        'The designer\'s rules for themes, from Rules.md in the root folder. '
        'Read them before designing and follow them; validate_spec does not '
        'check most of them.',
    inputSchema: const {
      'type': 'object',
      'properties': {
        'section': {
          'type': 'string',
          'description': 'Only the rules under this heading, e.g. Icons.',
        },
      },
    },
    readOnly: true,
    handler: (args, progress) async {
      final file = File(requireRoot(ctx).rulesFile);
      if (!file.existsSync()) {
        return ToolResult('There are no rules; ${file.path} does not exist.');
      }
      final text = file.readAsStringSync();
      final section = (args['section'] as String? ?? '').trim().toLowerCase();
      if (section.isEmpty) return ToolResult(text);
      final picked = _rulesSection(text, section);
      if (picked == null) {
        throw ToolException('No heading "$section" in the rules.');
      }
      return ToolResult(picked);
    },
  ),
];

/// The lines under the Markdown heading named [heading], up to the next
/// heading of the same or a higher level; null when there is none.
String? _rulesSection(String text, String heading) {
  final lines = text.split('\n');
  final level = RegExp(r'^(#+)\s*(.*?)\s*$');
  int? depth;
  final out = <String>[];
  for (final line in lines) {
    final m = level.firstMatch(line);
    if (depth == null) {
      if (m != null && m[2]!.toLowerCase() == heading) {
        depth = m[1]!.length;
        out.add(line);
      }
    } else if (m != null && m[1]!.length <= depth) {
      break;
    } else {
      out.add(line);
    }
  }
  return depth == null ? null : out.join('\n').trim();
}

List<File> _wallpapers(Directory dir) =>
    dir
        .listSync()
        .whereType<File>()
        .where(
          (f) => _imageExtensions.contains(p.extension(f.path).toLowerCase()),
        )
        .toList()
      ..sort((a, b) => _natural(p.basename(a.path), p.basename(b.path)));

File _wallpaperFile(Map<String, dynamic> args, ThemeToolContext ctx) {
  final path = argPath(args, 'path', ctx);
  if (path != null) {
    final f = File(path);
    if (!f.existsSync()) throw ToolException('No such file: $path');
    return f;
  }
  final root = requireRoot(ctx);
  final folder = argId(args, 'folder');
  final name = args['name'];
  if (folder == null ||
      name is! String ||
      name.isEmpty ||
      name != p.basename(name)) {
    throw const ToolException('Give folder and name, or a path.');
  }
  final dir = Directory(root.wallFolder(folder));
  final match = _wallpapers(dir)
      .where(
        (f) =>
            p.basename(f.path) == name ||
            p.basenameWithoutExtension(f.path) == name,
      )
      .firstOrNull;
  if (match == null) {
    throw ToolException(
      'No wallpaper "$name" in ${dir.path}; see list_wallpapers.',
    );
  }
  return match;
}

/// Makes preset elements fit for a spec: old unreadable alignments become the
/// center, as the editor reads them, and images stored beside the preset get
/// absolute paths. Returns how many alignments were unreadable.
int readyElements(List<Map<String, dynamic>> elements, String dir) {
  var unreadable = 0;
  for (final e in elements) {
    for (final key in LockscreenSpec.alignKeys) {
      final v = e[key];
      if (v != null && Alignment2.tryParse(v) == null) {
        e[key] = 'Alignment.center';
        unreadable++;
      }
    }
    for (final key in ['unlockIconPath', 'unlockTargetPath']) {
      final v = e[key];
      if (v is String && v.isNotEmpty && !p.isAbsolute(v)) {
        e[key] = p.join(dir, v);
      }
    }
  }
  return unreadable;
}

/// [file] as a JPEG at most [width] wide; null when it isn't an image.
ToolImage? scaledPicture(File file, int width) {
  final decoded = img.decodeImage(file.readAsBytesSync());
  if (decoded == null) return null;
  final small = decoded.width > width
      ? img.copyResize(
          decoded,
          width: width,
          interpolation: img.Interpolation.average,
        )
      : decoded;
  return ToolImage(
    Uint8List.fromList(img.encodeJpg(small, quality: 85)),
    mimeType: 'image/jpeg',
  );
}

List<Map<String, dynamic>> _presetElements(Directory dir) {
  try {
    final json = jsonDecode(
      File(p.join(dir.path, 'preset.json')).readAsStringSync(),
    );
    final lockscreen = json is Map ? json['lockscreen'] : null;
    final elements = json is List
        ? json
        : lockscreen is Map
        ? lockscreen['elements']
        : null;
    return [
      if (elements is List)
        for (final e in elements)
          if (e is Map) Map<String, dynamic>.from(e),
    ];
  } on Object {
    return [];
  }
}

/// How many of preset [elements] are shown.
int visibleCount(List<Map<String, dynamic>> elements) =>
    elements.where((e) => e['isVisible'] != false).length;

/// Orders "2" before "10" and "a2" before "a10".
int _natural(String a, String b) {
  final x = int.tryParse(a), y = int.tryParse(b);
  if (x != null && y != null) return x.compareTo(y);
  return a.toLowerCase().compareTo(b.toLowerCase());
}

class _Palette {
  _Palette(this.colors, this.luminance);

  final List<Map<String, Object>> colors;
  final double luminance;
}

/// The few colors that cover the most of the picture, and its brightness.
_Palette _palette(img.Image source) {
  final small = source.width > 64
      ? img.copyResize(
          source,
          width: 64,
          interpolation: img.Interpolation.average,
        )
      : source;
  final buckets = <int, List<num>>{}; // key -> [count, sumR, sumG, sumB]
  var luma = 0.0;
  for (final px in small) {
    final r = px.r.toInt(), g = px.g.toInt(), b = px.b.toInt();
    luma += .2126 * r + .7152 * g + .0722 * b;
    final b4 = buckets.putIfAbsent(
      (r >> 4) << 8 | (g >> 4) << 4 | (b >> 4),
      () => [0, 0, 0, 0],
    );
    b4[0]++;
    b4[1] += r;
    b4[2] += g;
    b4[3] += b;
  }
  final total = small.width * small.height;

  final picks = <List<num>>[]; // [count, r, g, b]
  final sorted = buckets.values.toList()..sort((a, b) => b[0].compareTo(a[0]));
  for (final b in sorted) {
    final r = b[1] / b[0], g = b[2] / b[0], bl = b[3] / b[0];
    List<num>? near;
    for (final pick in picks) {
      final d =
          (pick[1] - r).abs() + (pick[2] - g).abs() + (pick[3] - bl).abs();
      if (d < 90) {
        near = pick;
        break;
      }
    }
    if (near != null) {
      near[0] += b[0];
    } else if (picks.length < 6) {
      picks.add([b[0], r, g, bl]);
    }
  }
  picks.sort((a, b) => b[0].compareTo(a[0]));
  String hex(num v) =>
      v.round().clamp(0, 255).toRadixString(16).padLeft(2, '0');
  return _Palette([
    for (final c in picks)
      {
        'color': '#${hex(c[1])}${hex(c[2])}${hex(c[3])}'.toUpperCase(),
        'share': double.parse((c[0] / total).toStringAsFixed(2)),
      },
  ], luma / total / 255);
}
