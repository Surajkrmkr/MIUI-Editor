import 'dart:io';

import 'package:args/args.dart';
import 'package:path/path.dart' as p;

import 'root_config.dart';

void addRootOption(ArgParser parser) => parser.addOption(
  'root',
  valueHelp: 'dir',
  help:
      'Your work folder with Wall/, THEMES/, Sample2/ and Preset/. Fills in '
      'the default lockscreen assets and finds wallpapers by name. Also read '
      'from \$THEME_ROOT.',
);

/// The work folder from `--root` or `$THEME_ROOT`, if either is set.
ThemeRoot? rootOf(ArgResults args, Directory cwd) {
  final given = args['root'] as String? ?? Platform.environment['THEME_ROOT'];
  if (given == null || given.isEmpty) return null;
  return ThemeRoot(p.absolute(cwd.path, given));
}
