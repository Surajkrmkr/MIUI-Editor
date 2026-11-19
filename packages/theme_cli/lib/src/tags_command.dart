import 'dart:convert';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:path/path.dart' as p;

import 'exit_codes.dart';
import 'root_config.dart';
import 'root_option.dart';
import 'sidecar_options.dart';
import 'tags.dart';

/// `theme tags <theme folder | week folder>...`: writes `1tags/<name>.txt`
/// next to built themes, with up to six catalog tags picked from each
/// lockscreen.
class TagsCommand extends Command<int> {
  TagsCommand(this._out, this._err, this._cwd) {
    argParser
      ..addOption(
        'week',
        valueHelp: 'n',
        help: 'Tag every theme in <root>/THEMES/Week<n>.',
      )
      ..addOption(
        'out',
        abbr: 'o',
        valueHelp: 'dir',
        help:
            'Folder for the .txt files. Default: $tagsFolderName/ next to the '
            'theme folders.',
      )
      ..addOption(
        'tags',
        valueHelp: 'a,b,c',
        help:
            'Use these tags instead of picking them (one theme only). Each '
            'must be in the catalog; at most $maxTags.',
      )
      ..addOption(
        'catalog',
        valueHelp: 'file',
        help: 'Tag catalog. Default: <project>/assets/tags/tags.json.',
      )
      ..addFlag(
        'force',
        abbr: 'f',
        defaultsTo: true,
        help: 'Overwrite existing tag files (--no-force keeps them).',
      )
      ..addFlag(
        'dry-run',
        negatable: false,
        help: 'Print the tags without writing files.',
      )
      ..addFlag('json', negatable: false, help: 'Print JSON instead of text.')
      ..addOption(
        'project',
        valueHelp: 'dir',
        help: 'Flutter project holding assets/tags/tags.json.',
      );
    addRootOption(argParser);
  }

  final StringSink _out, _err;
  final Directory _cwd;

  @override
  String get name => 'tags';

  @override
  String get description =>
      'Write <name>.txt tag files for built themes, picked from the '
      'lockscreen and the tag catalog.';

  @override
  String get invocation =>
      'theme tags <theme folder | week folder>... [--week <n> --root <dir>]';

  @override
  Future<int> run() async {
    final args = argResults!;
    final week = args['week'] as String?;
    final rest = [...args.rest];
    if (week != null) {
      if (!isSafeSegment(week)) {
        usageException('--week must be letters, digits, _ or -.');
      }
      final root = rootOf(args, _cwd);
      if (root == null) {
        usageException('--week needs --root (or \$THEME_ROOT).');
      }
      rest.add(root.weekDir(week));
    }
    if (rest.isEmpty) usageException('Give theme folders, or --week.');

    final workspaces = findWorkspaces(rest, _cwd);
    if (workspaces.isEmpty) {
      _err.writeln('No built themes (folders with theme.spec.json) found.');
      return ExitCodes.io;
    }

    final catalogOption = args['catalog'] as String?;
    final String? catalogPath;
    if (catalogOption != null) {
      catalogPath = p.absolute(_cwd.path, catalogOption);
    } else {
      final project = projectDirOf(args, _cwd, workspaces);
      catalogPath = project == null ? null : tagsCatalogPath(project);
    }
    if (catalogPath == null || !File(catalogPath).existsSync()) {
      _err.writeln(
        'Tag catalog not found${catalogPath == null ? '' : ' at $catalogPath'}. '
        'Run from the repo, or pass --catalog <tags.json>.',
      );
      return ExitCodes.io;
    }
    final TagCatalog catalog;
    try {
      catalog = TagCatalog.load(catalogPath);
    } on FormatException catch (e) {
      _err.writeln('Cannot read $catalogPath: ${e.message}');
      return ExitCodes.io;
    }

    List<String>? given;
    final tagsOption = args['tags'] as String?;
    if (tagsOption != null) {
      if (workspaces.length != 1) {
        usageException('--tags works with one theme at a time.');
      }
      try {
        given = normalizeTags(tagsOption.split(','), catalog);
      } on FormatException catch (e) {
        _err.writeln(e.message);
        return ExitCodes.invalid;
      }
    }

    final outOption = args['out'] as String?;
    final dryRun = args['dry-run'] as bool;
    final force = args['force'] as bool;
    final json = args['json'] as bool;
    final results = <Map<String, Object?>>[];
    var code = ExitCodes.ok;
    for (final ws in workspaces) {
      final dir = outOption != null
          ? p.absolute(_cwd.path, outOption)
          : p.join(p.dirname(ws), tagsFolderName);
      try {
        final input = TagInput.ofWorkspace(ws);
        final tags = given ?? suggestTags(input, catalog);
        final file = p.join(dir, '${input.title}.txt');
        final keep = !force && File(file).existsSync();
        if (!dryRun && !keep) writeTagsFile(dir, input.title, tags);
        results.add({
          'theme': input.title,
          'tags': tags,
          'file': file,
          if (keep) 'kept': true,
        });
        if (!json) {
          final note = dryRun
              ? ' (dry run)'
              : keep
              ? ' (kept existing)'
              : '';
          _out.writeln('${input.title}: ${tags.join(',')}$note');
        }
      } on Object catch (e) {
        code = ExitCodes.io;
        results.add({'workspace': ws, 'error': '$e'});
        _err.writeln('${p.basename(ws)}: $e');
      }
    }
    if (json) {
      _out.writeln(
        const JsonEncoder.withIndent('  ').convert({
          'command': 'tags',
          'ok': code == ExitCodes.ok,
          'results': results,
        }),
      );
    } else if (!dryRun) {
      final dirs = {
        for (final r in results)
          if (r['file'] != null) p.dirname(r['file'] as String),
      };
      for (final d in dirs) {
        _out.writeln('Tags written to $d');
      }
    }
    return code;
  }
}

/// Built theme folders among [args]: a folder holding `theme.spec.json`, or
/// a folder whose subfolders do (a week folder).
List<String> findWorkspaces(List<String> args, Directory cwd) {
  final found = <String>[];
  for (final a in args) {
    final path = p.normalize(p.absolute(cwd.path, a));
    if (File(p.join(path, 'theme.spec.json')).existsSync()) {
      found.add(path);
    } else if (Directory(path).existsSync()) {
      found.addAll(
        Directory(path)
            .listSync()
            .whereType<Directory>()
            .map((d) => d.path)
            .where((d) => File(p.join(d, 'theme.spec.json')).existsSync())
            .toList()
          ..sort(),
      );
    }
  }
  return found.toSet().toList();
}
