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

/// App icons that the lockscreen shortcuts reuse, by element type.
const _homeScreenIcons = <ElementType, String>{
  ElementType.cameraIcon: 'com.android.camera',
  ElementType.themeIcon: 'com.android.thememanager',
  ElementType.settingIcon: 'com.android.settings',
  ElementType.galleryIcon: 'com.miui.gallery',
  ElementType.musicIcon: 'com.miui.player',
  ElementType.dialerIcon: 'com.android.contacts.activities.TwelveKeyDialer',
  ElementType.mmsIcon: 'com.android.mms',
  ElementType.contactIcon: 'com.android.contacts',
  ElementType.whatsAppIcon: 'com.whatsapp',
  ElementType.telegramIcon: 'org.telegram.messenger',
  ElementType.instagramIcon: 'com.instagram.android',
  ElementType.spotifyIcon: 'com.spotify.music',
};

/// Marks a workspace folder as builder-owned, so a rebuild may replace it.
const buildMarkerName = '.theme_build';

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
  }) async {
    void step(BuildStep s, [int done = 0, int total = 0]) =>
        onProgress?.call(BuildProgress(s, done: done, total: total));

    final baseDir = p.absolute(options.baseDir);
    String resolve(String path) => p.isAbsolute(path)
        ? p.normalize(path)
        : p.normalize(p.join(baseDir, path));

    final layout = ThemeLayout(
      p.join(p.absolute(options.outDir), spec.outputName),
    );
    final style = spec.iconStyle;
    final elements = spec.lockscreen.elements;

    try {
      // ── Inputs ───────────────────────────────────────────────────────────
      final home = resolve(spec.wallpaper.home);
      final lock = spec.wallpaper.lock == null
          ? null
          : resolve(spec.wallpaper.lock!);
      for (final w in [home, ?lock]) {
        if (!File(w).existsSync()) return _fail('Wallpaper not found: $w');
      }

      String? assetsDir;
      if (elements.isNotEmpty) {
        final dir = spec.lockscreen.assetsDir;
        if (dir == null) {
          return _fail('The lockscreen has elements but no assetsDir.');
        }
        assetsDir = resolve(dir);
        if (!Directory(assetsDir).existsSync()) {
          return _fail('Lockscreen assetsDir not found: $assetsDir');
        }
        if (p.equals(layout.root, assetsDir) ||
            p.isWithin(layout.root, assetsDir) ||
            p.isWithin(assetsDir, layout.root)) {
          return _fail(
            'assetsDir overlaps the output folder ${layout.root}; '
            'rebuilding would delete its own inputs. Choose another output '
            'folder.',
          );
        }
      }

      final fonts = <FontFile>[];
      for (final ref in spec.requiredFontRefs) {
        final declared = spec.fontFor(ref)?.path;
        final file =
            declared ??
            findFontFile(FontRef.parse(ref).family, options.fontsDirs);
        if (file == null) return _fail('Font "$ref" has no file in fonts[].');
        final path = resolve(file);
        if (!File(path).existsSync()) {
          return _fail('Font file not found: $path');
        }
        fonts.add(
          FontFile(ref: ref, family: FontRef.parse(ref).family, path: path),
        );
      }

      // ── Workspace ────────────────────────────────────────────────────────
      step(BuildStep.prepare);
      final workspace = Directory(layout.root);
      if (workspace.existsSync()) {
        final owned = File(p.join(layout.root, buildMarkerName)).existsSync();
        if (!owned && workspace.listSync().isNotEmpty) {
          return _fail(
            '${layout.root} exists and was not created by the theme builder. '
            'Choose another output folder or remove it.',
          );
        }
        workspace.deleteSync(recursive: true);
      }
      workspace.createSync(recursive: true);
      File(p.join(layout.root, buildMarkerName)).writeAsStringSync('');

      // ── Base files ───────────────────────────────────────────────────────
      step(BuildStep.base);
      await const ThemeBaseWriter().write(
        layout: layout,
        title: spec.meta.title,
        designer: spec.meta.designer,
        authorTag: spec.meta.authorTag,
        wallpaperSourcePath: home,
        lockWallpaperSourcePath: lock,
        uiVersion: '${spec.meta.uiVersion}',
      );

      // ── Icons ────────────────────────────────────────────────────────────
      final names = await renderer.iconNames(spec.icons.pack);
      if (names.isEmpty) {
        return _fail('Icon pack "${spec.icons.pack}" has no icons.');
      }
      step(BuildStep.icons, 0, names.length);
      var failure = await renderer.renderIcons(
        layout: layout,
        style: style,
        pack: spec.icons.pack,
        iconNames: names,
        onProgress: (d, t) => step(BuildStep.icons, d, t),
      );
      if (failure != null) return (null, failure);

      // ── System UI ────────────────────────────────────────────────────────
      step(BuildStep.systemUi);
      failure = await renderer.renderSystemModules(
        layout: layout,
        style: style,
        iconPack: spec.icons.pack,
        wallpaperPath: home,
      );
      if (failure != null) return (null, failure);

      // ── Lockscreen ───────────────────────────────────────────────────────
      if (elements.isNotEmpty) {
        step(BuildStep.lockscreen);
        if (fonts.isNotEmpty) await renderer.loadFonts(fonts);

        await _copyDir(
          Directory(assetsDir!),
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

      // ── Package ──────────────────────────────────────────────────────────
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
    } on FileSystemException catch (e) {
      return _fail(
        '${e.message}: ${e.path ?? ''} ${e.osError?.message ?? ''}'.trim(),
        io: true,
      );
    } catch (e) {
      return _fail(e.toString(), io: true);
    }
  }

  static (BuildResult?, Failure?) _fail(String message, {bool io = false}) =>
      (null, io ? ExportFailure(message) : ValidationFailure(message));

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
