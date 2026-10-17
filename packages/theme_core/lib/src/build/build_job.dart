import 'dart:convert';

/// One theme to build, handed to the process that does the drawing.
class BuildJob {
  const BuildJob({
    required this.id,
    required this.spec,
    required this.outDir,
    this.preview = false,
    this.fontsDirs = const [],
    this.baseDir,
  });

  /// Caller's label, echoed back in the result.
  final String id;

  /// Absolute path to the spec file.
  final String spec;

  /// Folder that receives `<name>/` and `<name>.mtz`.
  final String outDir;

  /// Also draw the lockscreen to `<outDir>/<name>.lockscreen.png`.
  final bool preview;

  /// Absolute folders searched for fonts the spec doesn't give a path for.
  final List<String> fontsDirs;

  /// Relative paths in the spec resolve here instead of next to the spec file.
  final String? baseDir;

  Map<String, Object?> toJson() => {
    'id': id,
    'spec': spec,
    'outDir': outDir,
    if (preview) 'preview': true,
    if (fontsDirs.isNotEmpty) 'fontsDirs': fontsDirs,
    if (baseDir != null) 'baseDir': baseDir,
  };

  factory BuildJob.fromJson(Map<String, dynamic> j) => BuildJob(
    id: j['id'] as String,
    spec: j['spec'] as String,
    outDir: j['outDir'] as String,
    preview: j['preview'] as bool? ?? false,
    fontsDirs: [for (final d in j['fontsDirs'] as List? ?? const []) '$d'],
    baseDir: j['baseDir'] as String?,
  );

  static String encodeAll(List<BuildJob> jobs) => jsonEncode({
    'jobs': [for (final j in jobs) j.toJson()],
  });

  static List<BuildJob> decodeAll(String text) => [
    for (final j in (jsonDecode(text) as Map)['jobs'] as List)
      BuildJob.fromJson(Map<String, dynamic>.from(j as Map)),
  ];
}

/// Outcome of one [BuildJob]; written as one JSON line per job.
class BuildJobResult {
  const BuildJobResult({
    required this.id,
    required this.ok,
    this.mtz,
    this.workspace,
    this.lockscreenPreview,
    this.errorCode,
    this.message,
    this.seconds = 0,
  });

  final String id;
  final bool ok;
  final String? mtz, workspace, lockscreenPreview;

  /// `spec.invalid`, `build.invalid`, `build.failed`, `build.crash` or
  /// `preview.failed`.
  final String? errorCode;
  final String? message;
  final double seconds;

  Map<String, Object?> toJson() => {
    'id': id,
    'ok': ok,
    if (mtz != null) 'mtz': mtz,
    if (workspace != null) 'workspace': workspace,
    if (lockscreenPreview != null) 'lockscreenPreview': lockscreenPreview,
    if (errorCode != null) 'errorCode': errorCode,
    if (message != null) 'message': message,
    'seconds': seconds,
  };

  factory BuildJobResult.fromJson(Map<String, dynamic> j) => BuildJobResult(
    id: j['id'] as String,
    ok: j['ok'] as bool,
    mtz: j['mtz'] as String?,
    workspace: j['workspace'] as String?,
    lockscreenPreview: j['lockscreenPreview'] as String?,
    errorCode: j['errorCode'] as String?,
    message: j['message'] as String?,
    seconds: (j['seconds'] as num?)?.toDouble() ?? 0,
  );

  /// Reads results written one per line, ignoring blank or torn lines.
  static List<BuildJobResult> decodeLines(String text) {
    final out = <BuildJobResult>[];
    for (final line in const LineSplitter().convert(text)) {
      if (line.trim().isEmpty) continue;
      try {
        out.add(
          BuildJobResult.fromJson(
            Map<String, dynamic>.from(jsonDecode(line) as Map),
          ),
        );
      } catch (_) {
        // A crash mid-write leaves a partial line; treat it as no result.
      }
    }
    return out;
  }
}
