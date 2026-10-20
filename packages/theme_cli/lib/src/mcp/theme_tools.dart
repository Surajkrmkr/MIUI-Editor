import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:theme_core/theme_core.dart';

import '../batch_runner.dart';
import 'mcp_server.dart';
import 'library_tools.dart';
import 'design_tools.dart';
import 'widget_tools.dart';
import 'tool_args.dart';
import 'tool_context.dart';
import '../root_config.dart';

export 'tool_context.dart';

const _instructions =
    'Builds MIUI/HyperOS 3 themes from a JSON spec. Call get_spec_schema for '
    'the format. Pick a wallpaper with list_wallpapers and look at it with '
    'view_wallpaper (it also gives its dominant colors). Take design '
    'references only from the designer\'s AI preset folder, through '
    'list_references and get_reference; do not use the Preset folder '
    '(list_presets, get_preset) unless the designer names a preset. The '
    'editor\'s ready-made widgets (battery ring, calendar, music, bento '
    'layouts...) come from list_widgets and get_widget, and the saved looks '
    'for unlock controls, analog clocks, shortcuts and calendars from '
    'list_widget_styles and get_widget_style; their elements go straight '
    'into lockscreen.elements. The designer\'s curated lockscreens come '
    'from list_references and get_reference: study them first. '
    'validate_spec warns about a bare lockscreen, and check_uniqueness '
    'compares your design with earlier specs. Always start from '
    'get_base_spec, whose lockscreen is already aligned, and read its layout '
    'guide. While designing, check the layout with preview_lockscreen and '
    'the icons with preview_icons: both are much faster than build_theme, '
    'which you run once at the end. Then '
    'validate_spec until it reports ok and build_theme with preview on to '
    'get the lockscreen and home screen images back; look at them and '
    'adjust. Give week (and folder, the wallpaper folder) and the theme goes '
    'to THEMES/Week<week>, with the default lockscreen assets filled in; its '
    'spec and preview pictures go to Preset/<name>. '
    'Pick fonts with list_fonts: use the designer\'s fonts by their listed '
    'family (no fonts entry needed), favour ones few presets use, and pair '
    'a display font for the clock with a quieter one for the date and '
    'texts instead of Roboto everywhere. Other fonts need a .ttf/.otf: list '
    'it in the spec\'s fonts or pass fonts_dirs. Use build_batch for many '
    'specs; it skips themes that are already built.';

const _rulesNote =
    ' The designer keeps rules for themes: call get_rules before designing '
    'and follow them; validate_spec does not check most of them.';

McpServer themeMcpServer(ThemeToolContext ctx, {void Function(String)? log}) =>
    McpServer(
      name: 'theme-cli',
      version: '1.0.0',
      instructions: ctx.rulesFile == null
          ? _instructions
          : _instructions + _rulesNote,
      log: log,
      tools: themeTools(ctx),
    );

List<McpTool> themeTools(ThemeToolContext ctx) {
  const specSource = {
    'spec': {
      'type': 'string',
      'description':
          'The theme spec as JSON text (see get_spec_schema). Give this or '
          'path.',
    },
    'path': {
      'type': 'string',
      'description': 'Path to a spec .json file. Give this or spec.',
    },
    'base_dir': {
      'type': 'string',
      'description':
          'Folder that relative paths in the spec resolve against. Defaults '
          'to the spec file\'s folder, or the server\'s working folder for '
          'an inline spec.',
    },
    'week': _weekProp,
    'folder': _folderProp,
    'fonts_dirs': {
      'type': 'array',
      'items': {'type': 'string'},
      'description':
          'Folders holding font files named after the font family, e.g. '
          'Ground.ttf, for fonts the spec gives no path for.',
    },
  };

  Future<ToolResult> quick(Map<String, dynamic> args, BuildMode mode) async {
    final input = _SpecInput.of(args, ctx);
    final scratch = Directory.systemTemp.createTempSync('theme_quick');
    try {
      final specPath = input.inline == null
          ? input.path!
          : (File(
              p.join(scratch.path, 'spec.json'),
            )..writeAsStringSync(jsonEncode(input.inline))).path;
      final report = await ctx.exclusive(
        () => BatchRunner(ctx.sidecar).run(
          [specPath],
          BatchOptions(
            outDir: p.join(scratch.path, 'out'),
            prepare: _preparer(args, ctx),
            force: true,
            preview: true,
            mode: mode,
            checkDesign: true,
            similarDesigns: earlierDesigns(ctx),
            fontsDirs: argFontsDirs(args, ctx),
            assetsRoot: ctx.project,
            baseDir:
                input.baseDir ?? (input.inline == null ? null : ctx.cwd.path),
          ),
        ),
      );
      final e = report.entries.single;
      final built = e.status == BatchStatus.built;
      final shot = mode == BuildMode.lockscreen
          ? e.lockscreenPreview
          : e.preview;
      return ToolResult(
        jsonEncode({
          'ok': built,
          'mode': mode.name,
          if (report.sidecarError != null)
            'error': {'code': 'sidecar', 'message': report.sidecarError},
          // The files live in a scratch folder that is deleted below.
          ...(e.toJson()
            ..remove('workspace')
            ..remove('preview')
            ..remove('lockscreenPreview')
            ..remove('mtz')),
        }),
        images: [
          if (built && shot != null && File(shot).existsSync())
            ToolImage(File(shot).readAsBytesSync()),
        ],
        isError: !built,
      );
    } finally {
      scratch.deleteSync(recursive: true);
    }
  }

  return [
    McpTool(
      name: 'get_spec_schema',
      description:
          'The JSON Schema of a theme spec: every field, enum value and '
          'default. Read it before writing a spec.',
      inputSchema: const {
        'type': 'object',
        'properties': {
          'section': {
            'type': 'string',
            'enum': _schemaSections,
            'description':
                'Only this part of the schema, which is much shorter. '
                'Leave out for all of it.',
          },
        },
      },
      readOnly: true,
      handler: (args, progress) async =>
          ToolResult(jsonEncode(_schemaSection(args['section']))),
    ),
    McpTool(
      name: 'validate_spec',
      description:
          'Checks a theme spec without building it: structure, enum values, '
          'files on disk, fonts, and whether text is legible on the '
          'wallpaper. Returns every error and warning with its JSON path '
          'and a hint. Fast; call it until ok is true.',
      inputSchema: {
        'type': 'object',
        'properties': {
          ...specSource,
          'contrast': {
            'type': 'boolean',
            'description':
                'Decode the wallpaper to check text legibility. Default true.',
          },
        },
      },
      readOnly: true,
      handler: (args, progress) async {
        final input = _SpecInput.of(args, ctx);
        final options = ValidationOptions(
          baseDir: input.baseDir ?? ctx.cwd.path,
          assetsRoot: ctx.project,
          checkContrast: argBool(args, 'contrast') ?? true,
          checkDesign: true,
          similarDesigns: earlierDesigns(ctx),
          fontsDirs: argFontsDirs(args, ctx),
        );
        final prepare = _preparer(args, ctx);
        final ValidationReport report;
        if (input.inline != null) {
          final json =
              jsonDecode(jsonEncode(input.inline)) as Map<String, dynamic>;
          prepare(json, options.baseDir);
          report = const SpecValidator().validate(json, options);
        } else {
          final String text;
          try {
            text = File(input.path!).readAsStringSync();
          } on FileSystemException catch (e) {
            throw ToolException(
              'Cannot read ${input.path}: ${e.osError?.message ?? e.message}',
            );
          }
          final baseDir = input.baseDir ?? p.dirname(input.path!);
          final fileOptions = ValidationOptions(
            baseDir: baseDir,
            assetsRoot: options.assetsRoot,
            checkContrast: options.checkContrast,
            checkDesign: options.checkDesign,
            similarDesigns: options.similarDesigns,
            fontsDirs: options.fontsDirs,
          );
          Object? json;
          try {
            json = jsonDecode(text);
          } on FormatException {
            json = null;
          }
          if (json is Map<String, dynamic>) {
            prepare(json, baseDir);
            report = const SpecValidator().validate(json, fileOptions);
          } else {
            report = const SpecValidator().validateText(text, fileOptions);
          }
        }
        return ToolResult(jsonEncode(report.toJson()), isError: !report.ok);
      },
    ),
    McpTool(
      name: 'build_theme',
      description:
          'Validates and builds one theme into out_dir: <name>.mtz (the '
          'installable theme) and the <name>/ folder; its spec and preview '
          'pictures are saved to Preset/<name>/. With preview on, also '
          'returns two images, the lockscreen and the home screen, so you '
          'can check the result. Takes 5 to 20 seconds. If the spec is '
          'invalid nothing is built and the issues are returned.',
      inputSchema: {
        'type': 'object',
        'properties': {
          ...specSource,
          'out_dir': {'type': 'string', 'description': _outDirHelp},
          'preview': {
            'type': 'boolean',
            'description': 'Write and return preview images. Default true.',
          },
        },
      },
      handler: (args, progress) async {
        final preview = argBool(args, 'preview') ?? true;
        final input = _SpecInput.of(args, ctx);
        final out = _outDir(args, ctx, input);
        final temp = input.inline == null
            ? null
            : Directory.systemTemp.createTempSync('theme_mcp');
        try {
          final specPath = temp == null
              ? input.path!
              : (File(
                  p.join(temp.path, 'spec.json'),
                )..writeAsStringSync(jsonEncode(input.inline))).path;
          final report = await ctx.exclusive(
            () => BatchRunner(ctx.sidecar).run(
              [specPath],
              BatchOptions(
                outDir: out,
                prepare: _preparer(args, ctx),
                force: true,
                preview: preview,
                checkDesign: true,
                similarDesigns: earlierDesigns(ctx),
                fontsDirs: argFontsDirs(args, ctx),
                assetsRoot: ctx.project,
                baseDir: input.baseDir ?? (temp == null ? null : ctx.cwd.path),
                presetsDir: ctx.root?.presetsDir,
              ),
            ),
          );
          final e = report.entries.single;
          final built = e.status == BatchStatus.built;
          final images = <ToolImage>[
            if (built && preview)
              for (final path in [e.lockscreenPreview, e.preview])
                if (path != null && File(path).existsSync())
                  ToolImage(File(path).readAsBytesSync()),
          ];
          return ToolResult(
            jsonEncode({
              'ok': built,
              if (report.sidecarError != null)
                'error': {'code': 'sidecar', 'message': report.sidecarError},
              ...e.toJson(),
            }),
            images: images,
            isError: !built,
          );
        } finally {
          temp?.deleteSync(recursive: true);
        }
      },
    ),
    McpTool(
      name: 'preview_lockscreen',
      description:
          'Draws only the lockscreen of a spec and returns its picture: no '
          'icons, system UI or package, so it is much faster than '
          'build_theme. Use it to check and fix the layout, alignment and '
          'colors, then build once at the end. Shortcuts show the default '
          'app icons, not the theme\'s own.',
      inputSchema: {'type': 'object', 'properties': specSource},
      readOnly: true,
      handler: (args, progress) => quick(args, BuildMode.lockscreen),
    ),
    McpTool(
      name: 'preview_icons',
      description:
          'Draws only the wallpaper and app icons of a spec and returns the '
          'home screen picture: no lockscreen, system UI or package, so it '
          'is faster than build_theme. Use it to check the icon colors, '
          'shape and effects against the wallpaper.',
      inputSchema: {'type': 'object', 'properties': specSource},
      readOnly: true,
      handler: (args, progress) => quick(args, BuildMode.icons),
    ),
    McpTool(
      name: 'build_batch',
      description:
          'Builds many specs. paths are spec files or folders of .json files. '
          'Everything is validated first; themes already built and newer '
          'than their spec are skipped, so an interrupted run can simply be '
          'repeated. Slow (about 15 seconds a theme); progress is reported '
          'while it runs. Returns the counts and, for each spec, its '
          'status, errors and file paths.',
      inputSchema: {
        'type': 'object',
        'properties': {
          'paths': {
            'type': 'array',
            'items': {'type': 'string'},
            'minItems': 1,
            'description': 'Spec files and/or folders holding them.',
          },
          'out_dir': {'type': 'string', 'description': _outDirHelp},
          'week': _weekProp,
          'folder': _folderProp,
          'preview': {'type': 'boolean', 'description': 'Default false.'},
          'force': {
            'type': 'boolean',
            'description': 'Rebuild even if up to date. Default false.',
          },
          'chunk': {
            'type': 'integer',
            'minimum': 1,
            'description': 'Themes per render process. Default 20.',
          },
          'retries': {
            'type': 'integer',
            'minimum': 0,
            'description':
                'Extra attempts for a theme that crashes the renderer. '
                'Default 1.',
          },
          'fonts_dirs': specSource['fonts_dirs'],
        },
        'required': ['paths'],
      },
      handler: (args, progress) async {
        final paths = argStringList(args, 'paths');
        if (paths == null || paths.isEmpty) {
          throw const ToolException(
            'paths must list at least one file or folder.',
          );
        }
        final specs = discoverSpecs(paths, ctx.cwd);
        if (specs.isEmpty) {
          throw const ToolException('No .json spec files found in paths.');
        }
        final chunk = argInt(args, 'chunk') ?? 20;
        final retries = argInt(args, 'retries') ?? 1;
        if (chunk < 1) throw const ToolException('chunk must be 1 or more.');
        if (retries < 0) {
          throw const ToolException('retries must be 0 or more.');
        }
        final out = _outDir(args, ctx, null);
        var done = 0;
        final report = await ctx.exclusive(
          () => BatchRunner(ctx.sidecar).run(
            specs,
            BatchOptions(
              outDir: out,
              prepare: _preparer(args, ctx),
              chunkSize: chunk,
              retries: retries,
              force: argBool(args, 'force') ?? false,
              preview: argBool(args, 'preview') ?? false,
              fontsDirs: argFontsDirs(args, ctx),
              assetsRoot: ctx.project,
              presetsDir: ctx.root?.presetsDir,
            ),
            onEntry: (e) {
              done++;
              progress(
                done,
                specs.length,
                '${e.status.name}: ${e.name ?? p.basename(e.spec)}',
              );
            },
          ),
        );
        final json = report.toJson();
        // Built themes need no detail; keep the answer short for big batches.
        json['results'] = [
          for (final e in report.entries)
            if (e.status == BatchStatus.built ||
                e.status == BatchStatus.skipped)
              {'name': e.name, 'status': e.status.name, 'mtz': e.mtz}
            else
              e.toJson(),
        ];
        return ToolResult(jsonEncode(json), isError: json['ok'] != true);
      },
    ),
    McpTool(
      name: 'preview_theme',
      description:
          'Draws the home-screen image of a theme that was already built. '
          'Fast, no rendering process needed.',
      inputSchema: {
        'type': 'object',
        'properties': {
          'workspace': {
            'type': 'string',
            'description':
                'The <name>/ folder build_theme produced. Or give week and '
                'name instead.',
          },
          'week': _weekProp,
          'name': {
            'type': 'string',
            'description': 'Theme name inside THEMES/Week<week>.',
          },
          'width': {
            'type': 'integer',
            'minimum': 64,
            'maximum': 2160,
            'description': 'Image width in pixels. Default 540.',
          },
        },
      },
      readOnly: true,
      handler: (args, progress) async {
        final workspace = _workspaceOf(args, ctx);
        final width = argInt(args, 'width') ?? 540;
        if (width < 64 || width > 2160) {
          throw const ToolException('width must be from 64 to 2160.');
        }
        try {
          return ToolResult(
            jsonEncode({'ok': true, 'width': width}),
            images: [ToolImage(HomePreview.compose(workspace, width: width))],
          );
        } on AppException catch (e) {
          throw ToolException(e.message);
        }
      },
    ),
    ...libraryTools(ctx),
    ...widgetTools(ctx),
    ...designTools(ctx),
  ];
}

/// The spec a call refers to: inline JSON or a file.
class _SpecInput {
  _SpecInput({this.inline, this.path, this.baseDir});

  final Object? inline;
  final String? path;
  final String? baseDir;

  factory _SpecInput.of(Map<String, dynamic> args, ThemeToolContext ctx) {
    final hasSpec = args['spec'] != null, hasPath = args['path'] != null;
    if (hasSpec == hasPath) {
      throw const ToolException('Give exactly one of spec or path.');
    }
    // Hosts differ in how they pass JSON: as text, or already decoded.
    var inline = args['spec'];
    if (inline is String) {
      try {
        inline = jsonDecode(inline);
      } on FormatException catch (e) {
        throw ToolException('spec is not valid JSON: ${e.message}');
      }
    }
    if (hasSpec && inline is! Map) {
      throw const ToolException('spec must be a JSON object.');
    }
    return _SpecInput(
      inline: inline,
      path: argPath(args, 'path', ctx),
      baseDir: argPath(args, 'base_dir', ctx),
    );
  }
}

const _weekProp = {
  'type': 'string',
  'description':
      'Week number, e.g. 3: the theme goes to THEMES/Week3 and the spec\'s '
      'workspace.week is set to it.',
};

const _folderProp = {
  'type': 'string',
  'description':
      'Wallpaper folder, e.g. 2 for Wall/2. A relative wallpaper name in the '
      'spec is looked up there, and workspace.folder is set to it.',
};

const _outDirHelp =
    'Folder that receives the build; a relative one is inside the root '
    'folder. Leave it out and give week instead to build into '
    'THEMES/Week<week>, which is what you want.';

/// The week and folder arguments, then the root's defaults, for a spec.
void Function(Map<String, dynamic>, String) _preparer(
  Map<String, dynamic> args,
  ThemeToolContext ctx,
) =>
    specPreparer(
      root: ctx.root,
      week: argId(args, 'week'),
      folder: argId(args, 'folder'),
    ) ??
    (spec, baseDir) {};

ThemeRoot _rootOf(ThemeToolContext ctx) =>
    ctx.root ??
    (throw const ToolException(
      'This needs the root folder (the one with Wall, THEMES, Sample2 and '
      'Preset). Start the server with --root or set THEME_ROOT.',
    ));

/// out_dir, else THEMES/Week<week> from the week argument or the spec's own
/// workspace.week.
String _outDir(
  Map<String, dynamic> args,
  ThemeToolContext ctx,
  _SpecInput? input,
) {
  final explicit = argPath(args, 'out_dir', ctx);
  if (explicit != null) return explicit;
  final week = argId(args, 'week') ?? _weekOfSpec(input);
  if (week == null) {
    throw const ToolException(
      'Give out_dir, or week to build into THEMES/Week<week>.',
    );
  }
  try {
    return _rootOf(ctx).weekDir(week);
  } on ArgumentError {
    throw ToolException('workspace.week "$week" is not a usable folder name.');
  }
}

String? _weekOfSpec(_SpecInput? input) {
  if (input == null) return null;
  Object? json = input.inline;
  if (json == null) {
    try {
      json = jsonDecode(File(input.path!).readAsStringSync());
    } on Object {
      return null;
    }
  }
  final workspace = json is Map ? json['workspace'] : null;
  final week = workspace is Map ? workspace['week'] : null;
  return week == null ? null : '$week';
}

String _workspaceOf(Map<String, dynamic> args, ThemeToolContext ctx) {
  final explicit = argPath(args, 'workspace', ctx);
  if (explicit != null) return explicit;
  final week = argId(args, 'week');
  final name = args['name'];
  if (week == null ||
      name is! String ||
      name.isEmpty ||
      name != p.basename(name) ||
      name == '..') {
    throw const ToolException('Give workspace, or week and name.');
  }
  return p.join(_rootOf(ctx).weekDir(week), name);
}

const _schemaSections = [
  'meta',
  'workspace',
  'wallpaper',
  'icons',
  'systemUi',
  'lockscreen',
  'element',
  'fonts',
  'output',
];

/// The whole spec schema, or one section of it with the shared definitions
/// it points at.
Map<String, Object?> _schemaSection(Object? section) {
  final schema = themeSpecSchema();
  if (section == null) return schema;
  if (section is! String || !_schemaSections.contains(section)) {
    throw ToolException(
      'section must be one of ${_schemaSections.join(', ')}.',
    );
  }
  final defs = schema[r'$defs']! as Map<String, Object?>;
  final part = section == 'element'
      ? defs['element']
      : (schema['properties']! as Map<String, Object?>)[section];
  return {
    r'$schema': schema[r'$schema'],
    'section': section,
    'schema': part,
    r'$defs': {
      'color': defs['color'],
      'alignment': defs['alignment'],
      if (section == 'lockscreen' || section == 'element')
        'element': defs['element'],
    },
  };
}
