import 'dart:io';

import 'package:args/args.dart';
import 'package:path/path.dart' as p;

import 'sidecar.dart';

/// Options every command that renders themes takes.
void addSidecarOptions(ArgParser parser) => parser
  ..addFlag(
    'verbose',
    abbr: 'v',
    negatable: false,
    help: 'Forward the render process output to stderr.',
  )
  ..addOption(
    'project',
    valueHelp: 'dir',
    help:
        'Flutter project that holds assets/ and $sidecarEntry. Defaults to '
        '\$THEME_PROJECT, then the nearest parent of cwd or the specs.',
  )
  ..addOption(
    'flutter',
    valueHelp: 'path',
    help: 'flutter executable. Defaults to \$FLUTTER, then "flutter".',
  );

/// The Flutter project folder, or null when none can be found.
String? projectDirOf(ArgResults args, Directory cwd, List<String> specPaths) {
  final explicit =
      args['project'] as String? ?? Platform.environment['THEME_PROJECT'];
  if (explicit != null && explicit.isNotEmpty) {
    return p.normalize(p.absolute(cwd.path, explicit));
  }
  final script = Platform.script;
  return findProject([
    cwd.path,
    ...specPaths.map(p.dirname),
    // Lets an agent start the tool from any folder.
    if (script.scheme == 'file') p.dirname(script.toFilePath()),
  ]);
}

/// The Flutter render process for [project], or null without a project.
Sidecar? flutterSidecarOf(ArgResults args, String? project, StringSink err) {
  if (project == null) return null;
  return FlutterSidecar(
    projectDir: project,
    flutter:
        args['flutter'] as String? ??
        Platform.environment['FLUTTER'] ??
        'flutter',
    onOutput: args['verbose'] as bool ? err.writeln : null,
  );
}

/// What to tell the user when no project folder was found.
const noProjectMessage =
    'No Flutter project found. Run from the repo, or pass --project '
    '<dir> (a folder containing $sidecarEntry).';
