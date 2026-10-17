import '../errors/failures.dart';
import '../icons/icon_style.dart';
import '../layout/theme_layout.dart';
import '../lockscreen/lock_element_spec.dart';

/// A font file the renderer must register before drawing text.
class FontFile {
  const FontFile({required this.ref, required this.family, required this.path});

  /// The `font` string elements use, e.g. `gf:Inter`.
  final String ref;

  /// Family name the renderer registers the file under.
  final String family;
  final String path;
}

typedef ProgressCallback = void Function(int done, int total);

/// Draws the images a theme needs. Implemented with `dart:ui` in
/// theme_raster_flutter, so this package stays free of Flutter.
///
/// Every method writes into [ThemeLayout] and returns a failure instead of
/// throwing, mirroring how the editor reports export errors.
abstract interface class ThemeRenderer {
  /// Makes [fonts] available to the render calls that follow.
  Future<void> loadFonts(List<FontFile> fonts);

  /// Icon names (SVG file names without extension) available in [pack];
  /// empty when the pack doesn't exist.
  Future<List<String>> iconNames(String pack);

  /// App icons into `icons/res/drawable-*` plus `transform_config.xml`.
  Future<Failure?> renderIcons({
    required ThemeLayout layout,
    required IconStyle style,
    required String pack,
    required List<String> iconNames,
    ProgressCallback? onProgress,
  });

  /// Control center, notification, dialer, messaging and settings modules.
  Future<Failure?> renderSystemModules({
    required ThemeLayout layout,
    required IconStyle style,
    required String iconPack,
    required String wallpaperPath,
  });

  /// PNG frames the lockscreen manifest refers to, under
  /// `lockscreen/advance`.
  Future<Failure?> renderLockscreenFrames({
    required ThemeLayout layout,
    required List<LockElementSpec> elements,
    ProgressCallback? onProgress,
  });
}
