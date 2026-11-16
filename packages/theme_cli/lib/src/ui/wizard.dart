import 'dart:io';

import 'package:path/path.dart' as p;

import '../batch_runner.dart' show discoverSpecs;
import 'terminal_ui.dart';

/// Asks for spec files or a folder until it finds `.json` specs. Returns
/// them as given, or null when the user entered nothing usable.
List<String>? askSpecs(TerminalUi ui, Directory cwd, {String what = 'specs'}) {
  final jsons = discoverSpecs(['.'], cwd);
  final String answer;
  if (jsons.isNotEmpty && jsons.length <= 12) {
    const other = 'Another path...';
    const all = 'All specs here';
    final picked = ui.chooseOne('Which $what?', [
      if (jsons.length > 1) all,
      for (final j in jsons) p.relative(j, from: cwd.path),
      other,
    ]);
    if (picked == all) return ['.'];
    answer = picked == other ? ui.prompt('Spec file or folder') : picked;
  } else {
    answer = ui.prompt('Spec file or folder', defaultValue: '.');
  }
  return answer.trim().isEmpty ? null : [answer.trim()];
}
