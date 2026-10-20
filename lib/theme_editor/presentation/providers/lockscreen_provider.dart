import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'package:archive/archive_io.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path/path.dart' as p;
import 'package:screenshot/screenshot.dart';
import 'package:xml/xml.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/path_constants.dart';
import 'package:theme_core/theme_core.dart';
import '../../core/utils/remote_fonts.dart';
import '../../domain/entities/element_widget.dart';
import '../../domain/entities/lock_element_spec_bridge.dart';
import 'package:theme_raster_flutter/theme_raster_flutter.dart'
    show LockscreenCanvas;
import 'element_provider.dart';
import 'font_provider.dart';
import 'export_provider.dart';
import 'wallpaper_provider.dart';
import 'directory_provider.dart';
import 'service_providers.dart';
import 'spec_provider.dart';
import 'usecase_providers.dart';

class LockscreenState {
  const LockscreenState({
    this.isExporting = false,
    this.isExportingPngs = false,
    this.isTracing = false,
    this.isExported = false,
    this.isCopyingDefaults = false,
    this.dualMtzExport = false,
    this.pngsDone = 0,
    this.pngsTotal = 0,
    this.error,
  });

  final bool isExporting,
      isExportingPngs,
      isTracing,
      isExported,
      isCopyingDefaults;
  final bool dualMtzExport;
  final int pngsDone, pngsTotal;
  final String? error;

  bool get isBusy =>
      isExporting || isExportingPngs || isCopyingDefaults || isTracing;

  double get pngsProgress => pngsTotal == 0 ? 0 : pngsDone / pngsTotal;

  String get pngsLabel => isExportingPngs ? 'Frames $pngsDone/$pngsTotal' : '';

  LockscreenState copyWith({
    bool? isExporting,
    bool? isExportingPngs,
    bool? isTracing,
    bool? isExported,
    bool? isCopyingDefaults,
    bool? dualMtzExport,
    int? pngsDone,
    int? pngsTotal,
    String? error,
  }) => LockscreenState(
    isExporting: isExporting ?? this.isExporting,
    isExportingPngs: isExportingPngs ?? this.isExportingPngs,
    isTracing: isTracing ?? this.isTracing,
    isExported: isExported ?? this.isExported,
    isCopyingDefaults: isCopyingDefaults ?? this.isCopyingDefaults,
    dualMtzExport: dualMtzExport ?? this.dualMtzExport,
    pngsDone: pngsDone ?? this.pngsDone,
    pngsTotal: pngsTotal ?? this.pngsTotal,
    error: error,
  );
}

class LockscreenNotifier extends Notifier<LockscreenState> {
  @override
  LockscreenState build() => const LockscreenState();

  // ── Copy default PNGs ─────────────────────────────────────────────────────

  Future<void> copyDefaultPngs() async {
    state = state.copyWith(isCopyingDefaults: true);
    try {
      final ws = ref.read(wallpaperProvider);
      if (ws.weekNum == null || ws.currentThemeName == null) return;
      final tp = PathConstants.themePath(ws.weekNum!, ws.currentThemeName!);
      final lsPath = PathConstants.lockscreenAdvance(tp);
      final sample = PathConstants.sample2Lockscreen();
      final fs = ref.read(fileServiceProvider);
      await fs.createDir(lsPath);
      for (final png in PathConstants.lockscreenDefaultPngs) {
        if (png == null) continue;
        final src = PathConstants.p('$sample$png.png');
        final dst = PathConstants.p('$lsPath$png.png');
        if (await fs.exists(src)) await fs.copyFile(src, dst);
      }

      final homeScreenIcons = <ElementType, String>{
        for (final type in ElementType.values)
          if (type.isIcon && type.defaultIconAsset != null)
            type: type.defaultIconAsset!,
      };
      final homeIconsDir = PathConstants.iconsXxhdpi(tp);
      for (final entry in homeScreenIcons.entries) {
        final source = PathConstants.p('$homeIconsDir${entry.value}.png');
        if (!await fs.exists(source)) continue;
        final relativePath = entry.key.defaultPath.startsWith(r'\')
            ? entry.key.defaultPath.substring(1)
            : entry.key.defaultPath;
        final destination = PathConstants.p('$lsPath$relativePath.png');
        await fs.copyFile(source, destination);
      }
    } finally {
      state = state.copyWith(isCopyingDefaults: false);
    }
  }

  // ── Export manifest XML ───────────────────────────────────────────────────

  ValidationFailure? _validateUnlock() {
    final elements = ref.read(elementProvider);
    if (!elements.hasVisibleUnlock) {
      const failure = ValidationFailure(
        'Add and enable at least one unlock widget: Swipe Up, Tap, Slide, or Drag.',
      );
      state = state.copyWith(error: failure.message);
      return failure;
    }
    for (final el in elements.elements) {
      if (!el.isVisible || el.type != ElementType.tapToUnlock) continue;
      final gap = bottomPaddingOf(el.toSpec());
      if (gap >= minUnlockBottomPadding) continue;
      final failure = ValidationFailure(
        '${el.label} is too close to the bottom edge '
        '(${gap.toStringAsFixed(0)}px). Move it up so it keeps at least '
        '${minUnlockBottomPadding.toStringAsFixed(0)}px above the gesture bar.',
      );
      state = state.copyWith(error: failure.message);
      return failure;
    }
    return null;
  }

  Future<Failure?> exportWorkspace(BuildContext context) async {
    final unlockFailure = _validateUnlock();
    if (unlockFailure != null) return unlockFailure;
    await ref.read(exportProvider.notifier).exportAll();
    if (!context.mounted) return null;
    return export(context);
  }

  Future<Failure?> export(BuildContext context) async {
    final unlockFailure = _validateUnlock();
    if (unlockFailure != null) return unlockFailure;
    state = state.copyWith(isExporting: true, error: null);
    try {
      final ws = ref.read(wallpaperProvider);
      final els = ref.read(elementProvider);

      if (ws.weekNum == null || ws.currentThemeName == null) {
        state = state.copyWith(isExporting: false, error: 'No active theme');
        return const ValidationFailure('No active theme');
      }

      final tp = PathConstants.themePath(ws.weekNum!, ws.currentThemeName!);
      final lsPath = PathConstants.lockscreenAdvance(tp);

      // ── Step 1: write manifest.xml ────────────────────────────────────────
      await _writeManifest(lsPath, els);

      // ── Step 2: export PNG frames (parallel batches) ──────────────────────
      final pngFailure = await exportPngs(context);
      if (pngFailure != null) {
        state = state.copyWith(isExporting: false, error: pngFailure.message);
        return pngFailure;
      }

      // ── Step 3: auto-pack MTZ and save preset ─────────────────────────────
      // No extra button tap — the full theme is ready, so zip it immediately.
      final (_, mtzFailure) = await exportMtz(context, recordFontUsage: false);

      if (mtzFailure != null) {
        // MTZ failure is non-fatal — XML + PNGs are still exported correctly.
        // Surface it as a warning rather than aborting.
        state = state.copyWith(
          isExporting: false,
          isExported: true,
          error: 'MTZ warning: ${mtzFailure.message}',
        );
        return null; // don't propagate — LS export itself succeeded
      }

      await checkExported();
      state = state.copyWith(isExporting: false, isExported: true);
      return null;
    } catch (e) {
      state = state.copyWith(isExporting: false, error: e.toString());
      return ExportFailure(e.toString());
    }
  }

  // ── Export PNG frames via use case ────────────────────────────────────────

  Future<Failure?> exportPngs(BuildContext context) async {
    final unlockFailure = _validateUnlock();
    if (unlockFailure != null) return unlockFailure;
    final ws = ref.read(wallpaperProvider);
    if (ws.weekNum == null || ws.currentThemeName == null) return null;

    final tp = PathConstants.themePath(ws.weekNum!, ws.currentThemeName!);
    final els = ref.read(elementProvider);

    state = state.copyWith(isExportingPngs: true, pngsDone: 0, pngsTotal: 0);

    final failure = await ref
        .read(exportLockscreenPngsUseCaseProvider)
        .call(
          context: context,
          elementState: els,
          layout: ThemeLayout(tp),
          onProgress: (done, total) =>
              state = state.copyWith(pngsDone: done, pngsTotal: total),
        );

    state = state.copyWith(isExportingPngs: false);
    if (failure == null) {
      await ref.read(fontUsageProvider.notifier).recordExport(els.elements);
    }
    return failure;
  }

  // ── Generate Layered SVG ───────────────────────────────────────────────────

  Future<void> generateLayeredSvg() async {
    state = state.copyWith(isTracing: true, error: null);
    try {
      final ws = ref.read(wallpaperProvider);
      if (ws.weekNum == null ||
          ws.currentThemeName == null ||
          ws.currentPath == null) {
        state = state.copyWith(
          isTracing: false,
          error: 'No active theme or wallpaper selected',
        );
        return;
      }

      // The original wallpaper path (e.g. E:\Xiaomi Contract\Wall\1\image.jpg)
      final sourceWallPath = ws.currentPath!;

      // Save SVG folder: E:\Xiaomi Contract\svg\<FolderNum>\
      final svgFolder =
          '${PathConstants.basePath}svg${PathConstants.sep}${ws.folderNum}${PathConstants.sep}';
      final fs = ref.read(fileServiceProvider);

      await fs.createDir(svgFolder);

      if (!(await fs.exists(sourceWallPath))) {
        state = state.copyWith(
          isTracing: false,
          error: 'Source wallpaper not found',
        );
        return;
      }

      // Final SVG path (e.g. E:\Xiaomi Contract\svg\1\wallpaper1.svg)
      final finalPath = '$svgFolder${ws.currentThemeName}.svg';
      final tracedSvgPath = '${svgFolder}temp_trace.svg';

      String vtracerPath = PathConstants.p(
        '${Directory.current.path}${PathConstants.sep}bin${PathConstants.sep}vtracer.exe',
      );
      if (!File(vtracerPath).existsSync()) {
        vtracerPath = 'vtracer.exe'; // Try PATH as fallback
      }

      debugPrint('Executing vtracer on source: $sourceWallPath');

      final result = await Process.run(vtracerPath, [
        '--input',
        sourceWallPath,
        '--output',
        tracedSvgPath,
        '--preset',
        'photo',
        '--mode',
        'spline',
        '--hierarchical',
        'stacked',
      ]);

      if (result.exitCode != 0) {
        final err = result.stderr.toString();
        debugPrint('vtracer failed: $err');
        state = state.copyWith(isTracing: false, error: 'vtracer failed: $err');
        return;
      }

      if (!(await fs.exists(tracedSvgPath))) {
        state = state.copyWith(
          isTracing: false,
          error: 'vtracer did not produce output',
        );
        return;
      }

      final tracedContent = await fs.readString(tracedSvgPath);
      if (tracedContent.isEmpty) {
        state = state.copyWith(isTracing: false, error: 'Traced SVG is empty');
      } else {
        await fs.writeString(finalPath, tracedContent);

        // ── Create ZIP file ──────────────────────────────────────────────────
        try {
          final archive = Archive();
          final svgBytes = await File(finalPath).readAsBytes();
          archive.addFile(
            ArchiveFile(
              '${ws.currentThemeName}.svg',
              svgBytes.length,
              svgBytes,
            ),
          );
          final zipBytes = ZipEncoder().encode(archive);
          final zipPath = '$svgFolder${ws.currentThemeName}.zip';
          await File(zipPath).writeAsBytes(zipBytes);
          debugPrint('Generated ZIP at: $zipPath');
        } catch (e) {
          debugPrint('Error creating ZIP: $e');
        }

        state = state.copyWith(isTracing: false, error: null);
        debugPrint('Generated traced wallpaper at: $finalPath');
      }

      // Cleanup temporary file
      if (await fs.exists(tracedSvgPath)) {
        await File(tracedSvgPath).delete();
      }
    } catch (e) {
      state = state.copyWith(isTracing: false, error: 'SVG Error: $e');
      debugPrint('Error generating SVG: $e');
    }
  }

  // ── Preset — delegates to use cases ──────────────────────────────────────

  Future<Failure?> savePreset(
    String name, {
    required BuildContext context,
  }) async {
    if (name.isEmpty ||
        p.basename(name) != name ||
        name == '.' ||
        name == '..') {
      return const ValidationFailure(
        'Preset name must be a single folder name.',
      );
    }
    if (ref.read(themeSpecProvider) == null) {
      return const ValidationFailure('No active theme');
    }
    try {
      final preview = await _capturePresetPreview(context);
      final presetDir = Directory(p.join(PathConstants.presetPath, name));
      await presetDir.create(recursive: true);
      final specFailure = await ref.read(themeSpecSaveAsProvider)(
        p.join(presetDir.path, 'preset.json'),
      );
      if (specFailure != null) return specFailure;
      await File(p.join(presetDir.path, 'preview.png')).writeAsBytes(preview);
      await ref.read(directoryProvider.notifier).loadPresetPaths();
      return null;
    } catch (e) {
      return ExportFailure(e.toString());
    }
  }

  Future<Uint8List> _capturePresetPreview(BuildContext context) async {
    final ws = ref.read(wallpaperProvider);
    final elements = ref.read(elementProvider);
    final themePath = PathConstants.themePath(
      ws.weekNum!,
      ws.currentThemeName!,
    );
    final lockscreenPath = PathConstants.lockscreenAdvance(themePath);
    final wallpaper =
        ws.currentPath != null && File(ws.currentPath!).existsSync()
        ? FileImage(File(ws.currentPath!))
        : null;
    final background = File(PathConstants.p('${lockscreenPath}bg.png'));
    final canvas = LockscreenCanvas(
      elements: elements.elements,
      wallpaper: wallpaper,
      bgImage: background.existsSync() ? FileImage(background) : null,
      dimming: elements.bgAlpha,
      resolveImage: (relative) {
        final file = File(PathConstants.p('$lockscreenPath$relative.png'));
        if (file.existsSync()) return file;
        final icon = exportedIconForLockscreenPath(relative);
        if (icon == null) return null;
        final exported = File(
          PathConstants.p('${PathConstants.iconsXxhdpi(themePath)}$icon.png'),
        );
        return exported.existsSync() ? exported : null;
      },
    );
    return ScreenshotController().captureFromWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: DefaultTextStyle(
          style: const TextStyle(fontFamily: 'Roboto'),
          child: canvas,
        ),
      ),
      context: context,
      pixelRatio: 1,
      targetSize: const Size(
        AppConstants.screenWidth,
        AppConstants.screenHeight,
      ),
      delay: const Duration(milliseconds: 100),
    );
  }

  Future<Failure?> loadPreset(String jsonPath) async {
    try {
      final json = jsonDecode(await File(jsonPath).readAsString());
      if (json is Map) {
        final parsed = ThemeSpec.parse(json);
        final spec = parsed.spec;
        if (spec == null) {
          return ValidationFailure(
            parsed.issues
                .where((issue) => issue.severity == IssueSeverity.error)
                .join('\n'),
          );
        }
        final (elements, failure) = await ref
            .read(loadPresetUseCaseProvider)
            .call(jsonPath);
        if (failure != null) return failure;
        if (elements != null) {
          await applyElements(elements);
          ref
              .read(elementProvider.notifier)
              .setBgAlpha(spec.lockscreen.bgAlpha);
        }
        return null;
      }
    } on FileSystemException catch (e) {
      return ExportFailure('Cannot read $jsonPath: ${e.message}');
    } on FormatException catch (e) {
      return ValidationFailure('$jsonPath is not valid JSON: ${e.message}');
    }
    final (elements, failure) = await ref
        .read(loadPresetUseCaseProvider)
        .call(jsonPath);
    if (failure != null) return failure;
    if (elements != null) {
      await applyElements(elements);
    }
    return null;
  }

  /// Applies [elements] to the lockscreen, pre-loading any Google and catalog fonts first.
  Future<void> applyElements(List<LockElement> elements) async {
    final fonts = elements.map((e) => e.font).toSet();
    await Future.wait(fonts.where(isRemoteFont).map(RemoteFonts.ensureKey));
    final gfStyles = fonts
        .where((f) => f.startsWith('gf:'))
        .map((f) {
          try {
            return GoogleFonts.getFont(f.substring(3));
          } catch (_) {
            return null;
          }
        })
        .whereType<TextStyle>()
        .toList();
    if (gfStyles.isNotEmpty) {
      try {
        await GoogleFonts.pendingFonts(gfStyles);
      } catch (_) {}
    }
    ref.read(elementProvider.notifier).setAll(elements);
  }

  // ── MTZ — delegates to use case ───────────────────────────────────────────

  void toggleDualMtzExport() =>
      state = state.copyWith(dualMtzExport: !state.dualMtzExport);

  Future<(String?, Failure?)> exportMtz(
    BuildContext context, {
    bool recordFontUsage = true,
  }) async {
    final unlockFailure = _validateUnlock();
    if (unlockFailure != null) return (null, unlockFailure);
    final ws = ref.read(wallpaperProvider);
    if (ws.weekNum == null || ws.currentThemeName == null) {
      return (null, const ValidationFailure('No active theme'));
    }
    final tp = PathConstants.themePath(ws.weekNum!, ws.currentThemeName!);

    final elementState = ref.read(elementProvider);
    final elements = elementState.elements;
    final lsPath = PathConstants.lockscreenAdvance(tp);
    try {
      await _writeManifest(lsPath, elementState);
    } catch (e) {
      return (null, ExportFailure(e.toString()));
    }

    final result = await ref
        .read(exportMtzUseCaseProvider)
        .call(
          layout: ThemeLayout(tp),
          themeName: ws.currentThemeName!,
          dualVersion: state.dualMtzExport,
        );
    if (result.$2 == null) {
      final presetFailure = await savePreset(
        ws.currentThemeName!,
        context: context,
      );
      if (presetFailure != null) {
        debugPrint(
          'Exported theme preset could not be saved: ${presetFailure.message}',
        );
      }
      if (recordFontUsage) {
        await ref.read(fontUsageProvider.notifier).recordExport(elements);
      }
    }
    return result;
  }

  void resetExportState() {
    state = state.copyWith(
      isExported: false,
      isExporting: false,
      isExportingPngs: false,
      pngsDone: 0,
      pngsTotal: 0,
      error: null,
    );
  }

  // checkExported() already exists — just make sure it's public (no underscore).
  Future<void> checkExported() async {
    final ws = ref.read(wallpaperProvider);
    if (ws.weekNum == null || ws.currentThemeName == null) return;
    final tp = PathConstants.themePath(ws.weekNum!, ws.currentThemeName!);
    final manifest = PathConstants.p(
      '${PathConstants.lockscreenAdvance(tp)}manifest.xml',
    );
    final exists = await ref.read(fileServiceProvider).exists(manifest);
    state = state.copyWith(isExported: exists);
  }

  // ── Manifest builder ───────────────────────────────────────────────────────

  /// Builds the live MAML document for the current lockscreen elements.
  XmlDocument buildManifest(ElementState els) => const ManifestBuilder().build([
    for (final e in els.elements) e.toSpec(),
  ], bgAlpha: els.bgAlpha);

  Future<void> _writeManifest(String lockscreenPath, ElementState elements) =>
      ref
          .read(fileServiceProvider)
          .writeString(
            '${lockscreenPath}manifest.xml',
            buildManifest(elements).toXmlString(pretty: true, indent: '\t'),
          );
}

final lockscreenProvider =
    NotifierProvider<LockscreenNotifier, LockscreenState>(
      LockscreenNotifier.new,
    );
