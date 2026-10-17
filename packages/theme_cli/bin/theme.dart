import 'dart:io';

import 'package:theme_cli/theme_cli.dart';

Future<void> main(List<String> args) async {
  exitCode = await runCli(args);
}
