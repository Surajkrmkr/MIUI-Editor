import 'dart:io';

import 'package:args/args.dart';
import 'package:path/path.dart' as p;

const _option = 'fonts-dir';

void addFontsDirOption(ArgParser parser) => parser.addMultiOption(
  _option,
  valueHelp: 'dir',
  help:
      'Folder with font files for fonts the spec gives no path for, e.g. '
      'Ground.ttf. Repeatable; also read from \$THEME_FONTS_DIR.',
);

/// Absolute font folders from `--fonts-dir` and `$THEME_FONTS_DIR`.
List<String> fontsDirsOf(ArgResults args, Directory cwd) {
  final fromEnv = (Platform.environment['THEME_FONTS_DIR'] ?? '')
      .split(Platform.isWindows ? ';' : ':')
      .where((d) => d.isNotEmpty);
  return [
    for (final d in [...args[_option] as List<String>, ...fromEnv])
      p.normalize(p.absolute(cwd.path, d)),
  ];
}
