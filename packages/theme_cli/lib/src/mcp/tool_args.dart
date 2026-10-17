import 'package:path/path.dart' as p;

import '../root_config.dart';
import 'mcp_server.dart';
import 'tool_context.dart';

String? argPath(
  Map<String, dynamic> args,
  String key,
  ThemeToolContext ctx, {
  bool required = false,
}) {
  final v = args[key];
  if (v == null) {
    if (required) throw ToolException('$key is required.');
    return null;
  }
  if (v is! String || v.isEmpty) throw ToolException('$key must be a path.');
  return p.normalize(p.absolute(ctx.cwd.path, v));
}

bool? argBool(Map<String, dynamic> args, String key) {
  final v = args[key];
  if (v == null) return null;
  if (v is! bool) throw ToolException('$key must be true or false.');
  return v;
}

int? argInt(Map<String, dynamic> args, String key) {
  final v = args[key];
  if (v == null) return null;
  if (v is! int) throw ToolException('$key must be an integer.');
  return v;
}

List<String>? argStringList(Map<String, dynamic> args, String key) {
  final v = args[key];
  if (v == null) return null;
  if (v is! List || v.any((e) => e is! String)) {
    throw ToolException('$key must be a list of strings.');
  }
  return v.cast<String>();
}

List<String> argFontsDirs(Map<String, dynamic> args, ThemeToolContext ctx) => [
  for (final d in argStringList(args, 'fonts_dirs') ?? const <String>[])
    p.normalize(p.absolute(ctx.cwd.path, d)),
  ...ctx.fontsDirs,
];

/// A week or folder name given as text or as a number; null when absent.
String? argId(Map<String, dynamic> args, String key) {
  final v = args[key];
  if (v == null) return null;
  final id = v is int ? '$v' : v;
  if (id is! String || !isSafeSegment(id)) {
    throw ToolException(
      '$key must be a name like 3 or A_2: letters, digits, _ or -.',
    );
  }
  return id;
}
