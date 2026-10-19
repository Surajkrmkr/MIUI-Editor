import 'dart:convert';
import 'dart:io';

import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:theme_cli/theme_cli.dart';
import 'package:theme_core/theme_core.dart';

/// Pretends to render: writes a workspace and the two preview images, and
/// remembers what it was asked and how many renders overlapped.
class FakeRenderer implements Sidecar {
  final jobs = <BuildJob>[];

  /// The spec each job pointed at, read while it was still there.
  final specs = <Map<String, dynamic>>[];
  int running = 0, mostAtOnce = 0;
  Duration delay = Duration.zero;
  String? launchError;

  @override
  Future<SidecarOutcome> run(
    List<BuildJob> batch, {
    void Function(BuildJobResult result)? onResult,
  }) async {
    jobs.addAll(batch);
    if (launchError != null) return SidecarOutcome(launchError: launchError);
    running++;
    if (running > mostAtOnce) mostAtOnce = running;
    await Future<void>.delayed(delay);
    final results = <BuildJobResult>[];
    for (final job in batch) {
      final spec = jsonDecode(File(job.spec).readAsStringSync()) as Map;
      specs.add(Map<String, dynamic>.from(spec));
      final name = (spec['meta'] as Map)['title'] as String;
      final workspace = p.join(job.outDir, name);
      final shot = p.join(job.outDir, '$name.lockscreen.png');
      if (job.mode == BuildMode.lockscreen) {
        _png(shot, 554, 1200);
        final r = BuildJobResult(
          id: job.id,
          ok: true,
          lockscreenPreview: shot,
          seconds: 1,
        );
        results.add(r);
        onResult?.call(r);
        continue;
      }
      _png(p.join(workspace, 'wallpaper', 'default_wallpaper.jpg'), 40, 90);
      _png(
        p.join(
          workspace,
          'icons',
          'res',
          'drawable-xxhdpi',
          'com.android.settings.png',
        ),
        180,
        180,
      );
      if (job.mode == BuildMode.icons) {
        final r = BuildJobResult(
          id: job.id,
          ok: true,
          workspace: workspace,
          seconds: 1,
        );
        results.add(r);
        onResult?.call(r);
        continue;
      }
      if (job.preview) _png(shot, 554, 1200);
      File(p.join(job.outDir, '$name.mtz')).writeAsBytesSync([1]);
      final r = BuildJobResult(
        id: job.id,
        ok: true,
        mtz: p.join(job.outDir, '$name.mtz'),
        workspace: workspace,
        lockscreenPreview: job.preview ? shot : null,
        seconds: 1,
      );
      results.add(r);
      onResult?.call(r);
    }
    running--;
    return SidecarOutcome(results: results);
  }

  static void _png(String path, int w, int h) => File(path)
    ..createSync(recursive: true)
    ..writeAsBytesSync(
      img.encodePng(
        img.Image(width: w, height: h)..clear(img.ColorRgb8(30, 60, 90)),
      ),
    );
}
