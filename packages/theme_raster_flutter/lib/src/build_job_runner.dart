import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart' show FontLoader;
import 'package:flutter/widgets.dart';
import 'package:path/path.dart' as p;
import 'package:theme_core/theme_core.dart';

import 'flutter_theme_renderer.dart';
import 'lockscreen/lockscreen_preview_renderer.dart';

/// Registers the Flutter SDK's Roboto and Material Icons so text and glyphs
/// render with real fonts under the test runner, which otherwise draws
/// placeholder blocks. Does nothing when the SDK fonts can't be found.
Future<void> loadSdkFonts() async {
  final root =
      Platform.environment['FLUTTER_ROOT'] ??
      File(
        Platform.resolvedExecutable,
      ).parent.parent.parent.parent.parent.parent.path;
  final dir = Directory(
    p.join(root, 'bin', 'cache', 'artifacts', 'material_fonts'),
  );
  if (!dir.existsSync()) return;

  Future<void> load(String family, Iterable<File> files) async {
    final loader = FontLoader(family);
    for (final f in files) {
      loader.addFont(Future.value(ByteData.sublistView(f.readAsBytesSync())));
    }
    await loader.load();
  }

  final files = dir.listSync().whereType<File>().toList();
  bool named(File f, String prefix) {
    final n = p.basename(f.path);
    return n.startsWith(prefix) && n.endsWith('.ttf');
  }

  await load('Roboto', files.where((f) => named(f, 'Roboto-')));
  await load(
    'RobotoCondensed',
    files.where((f) => named(f, 'RobotoCondensed-')),
  );
  await load(
    'MaterialIcons',
    files.where((f) => p.basename(f.path) == 'MaterialIcons-Regular.otf'),
  );
}

/// Builds every job in [jobsFile], appending one [BuildJobResult] line per
/// job to [resultsFile] as soon as it finishes. A failing job never stops the
/// rest.
Future<void> runBuildJobs({
  required String jobsFile,
  required String resultsFile,
  required BuildContext context,
  void Function(String message)? log,
}) async {
  await loadSdkFonts();
  final jobs = BuildJob.decodeAll(await File(jobsFile).readAsString());
  final builder = ThemeBuilder(FlutterThemeRenderer(context: context));
  File(resultsFile).writeAsStringSync('');

  void record(BuildJobResult r) => File(resultsFile).writeAsStringSync(
    '${jsonEncode(r.toJson())}\n',
    mode: FileMode.append,
    flush: true,
  );

  for (final job in jobs) {
    final clock = Stopwatch()..start();
    double seconds() => clock.elapsedMilliseconds / 1000;
    log?.call('building ${job.id}');
    try {
      final parsed = ThemeSpec.parse(
        jsonDecode(await File(job.spec).readAsString()),
      );
      final spec = parsed.spec;
      if (spec == null) {
        record(
          BuildJobResult(
            id: job.id,
            ok: false,
            errorCode: 'spec.invalid',
            message: parsed.issues
                .where((i) => i.severity == IssueSeverity.error)
                .join('; '),
            seconds: seconds(),
          ),
        );
        continue;
      }
      final (result, failure) = await builder.build(
        spec,
        BuildOptions(
          baseDir: job.baseDir ?? p.dirname(job.spec),
          outDir: job.outDir,
          fontsDirs: job.fontsDirs,
        ),
        onProgress: (e) =>
            log?.call('  ${job.id}: ${e.step.name} ${e.done}/${e.total}'),
      );
      if (result == null) {
        record(
          BuildJobResult(
            id: job.id,
            ok: false,
            errorCode: failure is ValidationFailure
                ? 'build.invalid'
                : 'build.failed',
            message: failure?.message,
            seconds: seconds(),
          ),
        );
        continue;
      }

      String? previewPath;
      Failure? previewFailure;
      if (job.preview && spec.lockscreen.elements.isNotEmpty) {
        log?.call('  ${job.id}: lockscreen preview');
        previewPath = p.join(
          p.absolute(job.outDir),
          '${spec.outputName}.lockscreen.png',
        );
        previewFailure = await const LockscreenPreviewRenderer().render(
          context: context,
          layout: ThemeLayout(result.workspacePath),
          elements: spec.lockscreen.elements,
          bgAlpha: spec.lockscreen.bgAlpha,
          outPath: previewPath,
        );
      }
      record(
        BuildJobResult(
          id: job.id,
          ok: true,
          mtz: result.mtzPath,
          workspace: result.workspacePath,
          lockscreenPreview: previewFailure == null ? previewPath : null,
          errorCode: previewFailure == null ? null : 'preview.failed',
          message: previewFailure?.message,
          seconds: seconds(),
        ),
      );
    } catch (e) {
      record(
        BuildJobResult(
          id: job.id,
          ok: false,
          errorCode: 'build.crash',
          message: '$e',
          seconds: seconds(),
        ),
      );
    }
  }
}
