import 'package:flutter/widgets.dart';
import 'package:theme_core/theme_core.dart';
import 'package:theme_raster_flutter/theme_raster_flutter.dart';
import '../../presentation/providers/element_provider.dart';

/// Renders the lockscreen's PNG frames into the theme workspace; the drawing
/// lives in theme_raster_flutter's [LockscreenFrameRenderer].
class ExportLockscreenPngsUseCase {
  const ExportLockscreenPngsUseCase({this.batchSize = 8});

  /// Frames captured in parallel per batch.
  final int batchSize;

  Future<Failure?> call({
    required BuildContext context,
    required ElementState elementState,
    required ThemeLayout layout,
    required void Function(int done, int total) onProgress,
  }) => LockscreenFrameRenderer(batchSize: batchSize).render(
    context: context,
    elements: elementState.elements,
    layout: layout,
    onProgress: onProgress,
  );
}
