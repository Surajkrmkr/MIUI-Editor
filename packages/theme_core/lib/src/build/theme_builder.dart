import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import '../errors/failures.dart';
import '../layout/theme_layout.dart';
import '../lockscreen/element_enums.dart';
import '../lockscreen/manifest_builder.dart';
import '../spec/font_lookup.dart';
import '../spec/font_ref.dart';
import '../spec/theme_spec.dart';
import 'mtz_packager.dart';
import 'theme_base_writer.dart';
import 'theme_renderer.dart';

class BuildOptions {
  const BuildOptions({
    required this.baseDir,
    required this.outDir,
    this.fontsDirs = const [],
  });

  /// Relative paths in the spec (wallpapers, fonts, assets) resolve here.
  final String baseDir;

  /// Receives `<name>/` (the workspace) and `<name>.mtz`.
  final String outDir;

  /// Folders searched for a font file when the spec doesn't name one.
  final List<String> fontsDirs;
}

enum BuildStep { prepare, base, icons, systemUi, lockscreen, pack }

class BuildProgress {
  const BuildProgress(this.step, {this.done = 0, this.total = 0});

  final BuildStep step;

  /// Items finished within [step]; both are 0 when the step has no count.
  final int done, total;
}

class BuildResult {
  const BuildResult({required this.mtzPath, required this.workspacePath});

  final String mtzPath;
  final String workspacePath;
}

/// App and system icons that lockscreen icons and shortcuts reuse.
final _homeScreenIcons = <ElementType, String>{
  for (final type in ElementType.values)
    if (type.isIcon && type.defaultIconAsset != null)
      type: type.defaultIconAsset!,
};

/// Marks a workspace folder as builder-owned, so a rebuild may replace it.
const buildMarkerName = '.theme_build';

class _Inputs {
  const _Inputs({
    required this.layout,
    required this.home,
    required this.fonts,
    this.lock,
    this.assetsDir,
  });

  final ThemeLayout layout;
  final String home;
  final String? lock, assetsDir;
  final List<FontFile> fonts;
}

/// Turns a [ThemeSpec] into a `.mtz`: base files, icons, system UI, lockscreen
/// and packaging, with the drawing delegated to a [ThemeRenderer].
///
/// Expects a spec that passed validation; it still fails cleanly when a file
/// it needs is missing.
class ThemeBuilder {
  const ThemeBuilder(this.renderer);

  final ThemeRenderer renderer;

  Future<(BuildResult?, Failure?)> build(
    ThemeSpec spec,
    BuildOptions options, {
    void Function(BuildProgress progress)? onProgress,
  }) => _guard<BuildResult>(() async {
    void step(BuildStep s, [int done = 0, int total = 0]) =>
        onProgress?.call(BuildProgress(s, done: done, total: total));

    final layout = _layoutOf(spec, options);
    final elements = spec.lockscreen.elements;
    final (inputs, bad) = _inputs(
      spec,
      options,
      layout,
      assets: elements.isNotEmpty,
      fonts: true,
    );
    if (inputs == null) return (null, bad);

    var failure = await _writeBaseAndIcons(spec, inputs, step);
    if (failure != null) return (null, failure);

    // ── System UI ──────────────────────────────────────────────────────────
    step(BuildStep.systemUi);
    failure = await renderer.renderSystemModules(
      layout: layout,
      style: spec.iconStyle,
      iconPack: spec.icons.pack,
      wallpaperPath: inputs.home,
    );
    if (failure != null) return (null, failure);

    // ── Lockscreen ─────────────────────────────────────────────────────────
    if (elements.isNotEmpty) {
      step(BuildStep.lockscreen);
      if (inputs.fonts.isNotEmpty) await renderer.loadFonts(inputs.fonts);

      await _copyDir(
        Directory(inputs.assetsDir!),
        Directory(layout.lockscreenAdvance),
      );
      await _copyHomeScreenIcons(layout);
      await File(
        p.join(layout.lockscreenAdvance, 'manifest.xml'),
      ).writeAsString(
        const ManifestBuilder()
            .build(elements, bgAlpha: spec.lockscreen.bgAlpha)
            .toXmlString(),
      );

      failure = await renderer.renderLockscreenFrames(
        layout: layout,
        elements: elements,
        onProgress: (d, t) => step(BuildStep.lockscreen, d, t),
      );
      if (failure != null) return (null, failure);
    }

    // ── Package ────────────────────────────────────────────────────────────
    step(BuildStep.pack);
    await File(p.join(layout.root, 'theme.spec.json')).writeAsString(
      '${const JsonEncoder.withIndent('  ').convert(spec.toJson())}\n',
    );
    final (mtz, packFailure) = await const MtzPackager().pack(
      layout: layout,
      name: spec.outputName,
    );
    if (packFailure != null) return (null, packFailure);
    return (BuildResult(mtzPath: mtz!, workspacePath: layout.root), null);
  });

  /// Draws only the wallpaper and app icons: enough for a home-screen look,
  /// without the system UI, lockscreen or package. Returns the workspace.
  Future<(String?, Failure?)> buildIcons(
    ThemeSpec spec,
    BuildOptions options, {
    void Function(BuildProgress progress)? onProgress,
  }) => _guard<String>(() async {
    final (inputs, bad) = _inputs(
      spec,
      options,
      _layoutOf(spec, options),
      assets: false,
      fonts: false,
    );
    if (inputs == null) return (null, bad);
    final failure = await _writeBaseAndIcons(
      spec,
      inputs,
      (s, [done = 0, total = 0]) =>
          onProgress?.call(BuildProgress(s, done: done, total: total)),
    );
    return failure == null ? (inputs.layout.root, null) : (null, failure);
  });

  /// A throwaway folder with only what the lockscreen preview reads: the
  /// lock wallpaper and the assets folder (linked, not copied). Registers
  /// the spec's fonts. Shortcuts show the default app icons, since the
  /// theme's own icons are not drawn.
  Future<(ThemeLayout?, Failure?)> prepareLockscreenPreview(
    ThemeSpec spec,
    BuildOptions options,
  ) => _guard<ThemeLayout>(() async {
    final layout = ThemeLayout(
      p.join(p.absolute(options.outDir), '${spec.outputName}.lockscreen_src'),
    );
    final (inputs, bad) = _inputs(
      spec,
      options,
      layout,
      assets: true,
      fonts: true,
    );
    if (inputs == null) return (null, bad);
    final fresh = _freshWorkspace(layout);
    if (fresh != null) return (null, fresh);

    if (inputs.fonts.isNotEmpty) await renderer.loadFonts(inputs.fonts);
    await Directory(layout.wallpaperDir).create(recursive: true);
    await File(inputs.lock ?? inputs.home).copy(layout.defaultLockWallpaper);
    final advance = Directory(layout.lockscreenAdvance);
    await advance.parent.create(recursive: true);
    try {
      await Link(advance.path).create(inputs.assetsDir!);
    } on FileSystemException {
      await _copyDir(Directory(inputs.assetsDir!), advance);
    }
    return (layout, null);
  });

  static ThemeLayout _layoutOf(ThemeSpec spec, BuildOptions options) =>
      ThemeLayout(p.join(p.absolute(options.outDir), spec.outputName));

  /// Checks everything a run needs from outside the workspace: wallpapers,
  /// the lockscreen assets folder when [assets], and font files when [fonts].
  (_Inputs?, Failure?) _inputs(
    ThemeSpec spec,
    BuildOptions options,
    ThemeLayout layout, {
    required bool assets,
    required bool fonts,
  }) {
    final baseDir = p.absolute(options.baseDir);
    String resolve(String path) => p.isAbsolute(path)
        ? p.normalize(path)
        : p.normalize(p.join(baseDir, path));
    Failure invalid(String message) => ValidationFailure(message);

    final home = resolve(spec.wallpaper.home);
    final lock = spec.wallpaper.lock == null
        ? null
        : resolve(spec.wallpaper.lock!);
    for (final w in [home, ?lock]) {
      if (!File(w).existsSync()) {
        return (null, invalid('Wallpaper not found: $w'));
      }
    }

    String? assetsDir;
    if (assets) {
      final dir = spec.lockscreen.assetsDir;
      if (dir == null) {
        return (null, invalid('The lockscreen has elements but no assetsDir.'));
      }
      assetsDir = resolve(dir);
      if (!Directory(assetsDir).existsSync()) {
        return (null, invalid('Lockscreen assetsDir not found: $assetsDir'));
      }
      if (p.equals(layout.root, assetsDir) ||
          p.isWithin(layout.root, assetsDir) ||
          p.isWithin(assetsDir, layout.root)) {
        return (
          null,
          invalid(
            'assetsDir overlaps the output folder ${layout.root}; '
            'rebuilding would delete its own inputs. Choose another output '
            'folder.',
          ),
        );
      }
    }

    final files = <FontFile>[];
    if (fonts) {
      for (final ref in spec.requiredFontRefs) {
        final declared = spec.fontFor(ref)?.path;
        final file =
            declared ??
            findFontFile(FontRef.parse(ref).family, options.fontsDirs);
        if (file == null) {
          return (null, invalid('Font "$ref" has no file in fonts[].'));
        }
        final path = resolve(file);
        if (!File(path).existsSync()) {
          return (null, invalid('Font file not found: $path'));
        }
        files.add(
          FontFile(ref: ref, family: FontRef.parse(ref).family, path: path),
        );
      }
    }
    return (
      _Inputs(
        layout: layout,
        home: home,
        lock: lock,
        assetsDir: assetsDir,
        fonts: files,
      ),
      null,
    );
  }

  /// Empties and marks the workspace folder; refuses one it didn't create.
  Failure? _freshWorkspace(ThemeLayout layout) {
    final workspace = Directory(layout.root);
    if (workspace.existsSync()) {
      final owned = File(p.join(layout.root, buildMarkerName)).existsSync();
      if (!owned && workspace.listSync().isNotEmpty) {
        return ValidationFailure(
          '${layout.root} exists and was not created by the theme builder. '
          'Choose another output folder or remove it.',
        );
      }
      // Unlink first so deleting never follows it into the assets folder.
      final linked = Link(layout.lockscreenAdvance);
      if (linked.existsSync()) linked.deleteSync();
      workspace.deleteSync(recursive: true);
    }
    workspace.createSync(recursive: true);
    File(p.join(layout.root, buildMarkerName)).writeAsStringSync('');
    return null;
  }

  Future<Failure?> _writeBaseAndIcons(
    ThemeSpec spec,
    _Inputs inputs,
    void Function(BuildStep, [int, int]) step,
  ) async {
    step(BuildStep.prepare);
    final fresh = _freshWorkspace(inputs.layout);
    if (fresh != null) return fresh;

    step(BuildStep.base);
    await const ThemeBaseWriter().write(
      layout: inputs.layout,
      title: spec.meta.title,
      designer: spec.meta.designer,
      authorTag: spec.meta.authorTag,
      wallpaperSourcePath: inputs.home,
      lockWallpaperSourcePath: inputs.lock,
      uiVersion: '${spec.meta.uiVersion}',
    );

    final names = await renderer.iconNames(spec.icons.pack);
    if (names.isEmpty) {
      return ValidationFailure('Icon pack "${spec.icons.pack}" has no icons.');
    }
    step(BuildStep.icons, 0, names.length);
    return renderer.renderIcons(
      layout: inputs.layout,
      style: spec.iconStyle,
      pack: spec.icons.pack,
      iconNames: names,
      onProgress: (d, t) => step(BuildStep.icons, d, t),
    );
  }

  static Future<(T?, Failure?)> _guard<T>(
    Future<(T?, Failure?)> Function() body,
  ) async {
    try {
      return await body();
    } on FileSystemException catch (e) {
      return (
        null,
        ExportFailure(
          '${e.message}: ${e.path ?? ''} ${e.osError?.message ?? ''}'.trim(),
        ),
      );
    } catch (e) {
      return (null, ExportFailure(e.toString()));
    }
  }

  /// Copies the theme's own app icons over the lockscreen defaults, so
  /// shortcuts match the home screen.
  Future<void> _copyHomeScreenIcons(ThemeLayout layout) async {
    for (final entry in _homeScreenIcons.entries) {
      final source = File(p.join(layout.iconsXxhdpi, '${entry.value}.png'));
      if (!source.existsSync()) continue;
      final segments = entry.key.defaultPath
          .split(RegExp(r'[\\/]'))
          .where((s) => s.isNotEmpty);
      final target = File(
        '${p.joinAll([layout.lockscreenAdvance, ...segments])}.png',
      );
      await target.parent.create(recursive: true);
      await source.copy(target.path);
    }
  }

  static Future<void> _copyDir(Directory from, Directory to) async {
    await to.create(recursive: true);
    await for (final e in from.list(followLinks: false)) {
      final name = p.basename(e.path);
      if (name.startsWith('.')) continue;
      if (e is File) {
        await e.copy(p.join(to.path, name));
      } else if (e is Directory) {
        await _copyDir(e, Directory(p.join(to.path, name)));
      }
    }
  }
}
