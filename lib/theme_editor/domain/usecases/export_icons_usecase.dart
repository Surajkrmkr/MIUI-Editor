import 'package:theme_core/theme_core.dart';
import 'package:theme_raster_flutter/theme_raster_flutter.dart';
import '../../domain/entities/user_profile.dart';

/// Renders every icon of the active pack into the theme workspace; the
/// drawing itself lives in theme_raster_flutter.
class ExportIconsUseCase {
  const ExportIconsUseCase();

  Future<Failure?> call({
    required IconStyle style,
    required UserProfile profile,
    required ThemeLayout layout,
    required List<String> iconNames,
    required void Function(int done, int total) onProgress,
  }) => const IconRenderer().render(
    style: style,
    pack: profile.iconFolder,
    layout: layout,
    iconNames: iconNames,
    onProgress: onProgress,
  );
}
