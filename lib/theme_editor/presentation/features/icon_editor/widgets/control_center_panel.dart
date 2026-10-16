import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:miui_icon_generator/core/theme/app_radius.dart';
import 'package:miui_icon_generator/core/theme/theme_extensions.dart';

import '../../../../core/utils/wallpaper_palette.dart';
import '../../../../domain/entities/control_center_template.dart';
import '../../../providers/icon_editor_provider.dart';
import '../../../providers/wallpaper_provider.dart';
import '../utils/control_center_painter.dart';

/// Current wallpaper decoded (downscaled) with its extracted palette.
final _ccWallpaperProvider =
    FutureProvider.autoDispose<(ui.Image, WallpaperPalette)?>((ref) async {
      final path = ref.watch(wallpaperProvider.select((w) => w.currentPath));
      if (path == null || !File(path).existsSync()) return null;
      final codec = await ui.instantiateImageCodec(
        await File(path).readAsBytes(),
        targetWidth: 360,
      );
      final image = (await codec.getNextFrame()).image;
      ref.onDispose(image.dispose);
      return (image, await WallpaperPalette.fromImage(image));
    });

/// Picker for the exported control center template. Each template has its
/// own effect, tile shape/size and card shape; colours follow the wallpaper.
class ControlCenterPanel extends ConsumerWidget {
  const ControlCenterPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.appColors;
    final scheme = Theme.of(context).colorScheme;
    final editor = ref.watch(iconEditorProvider);
    final wall = ref.watch(_ccWallpaperProvider).valueOrNull;
    final palette =
        wall?.$2 ??
        WallpaperPalette.fromSeed(editor.accentColor, editor.bgColor2);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surfaceOverlay,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Container(
                  width: 3,
                  height: 12,
                  margin: const EdgeInsets.only(right: 6),
                  decoration: BoxDecoration(
                    color: colors.primary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Text(
                  'CONTROL CENTER',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: scheme.onSurfaceVariant,
                    letterSpacing: 0.8,
                  ),
                ),
                const Spacer(),
                for (final c in [palette.primary, palette.secondary])
                  Container(
                    width: 12,
                    height: 12,
                    margin: const EdgeInsets.only(left: 4),
                    decoration: BoxDecoration(
                      color: c,
                      shape: BoxShape.circle,
                      border: Border.all(color: colors.border),
                    ),
                  ),
              ],
            ),
          ),
          Text(
            wall == null
                ? 'Colors follow the accent until a wallpaper is added.'
                : 'Colors are taken from the current wallpaper.',
            style: TextStyle(fontSize: 10, color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ControlCenterTemplate.values.map((t) {
              final selected = editor.ccTemplate == t;
              return InkWell(
                borderRadius: BorderRadius.circular(AppRadius.lg),
                onTap: () =>
                    ref.read(iconEditorProvider.notifier).setCcTemplate(t),
                child: Container(
                  width: 112,
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    border: Border.all(
                      color: selected ? colors.primary : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: Column(
                    children: [
                      CustomPaint(
                        size: const Size(100, 124),
                        painter: _PreviewPainter(
                          CcStyle(template: t, palette: palette),
                          wall?.$1,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        t.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: selected
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: selected
                              ? colors.primary
                              : scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _PreviewPainter extends CustomPainter {
  _PreviewPainter(this.style, this.wallpaper);
  final CcStyle style;
  final ui.Image? wallpaper;

  @override
  void paint(Canvas canvas, Size size) =>
      ControlCenterPainter.preview(canvas, size, style, wallpaper: wallpaper);

  @override
  bool shouldRepaint(_PreviewPainter old) =>
      old.style.template != style.template ||
      old.style.palette != style.palette ||
      old.wallpaper != wallpaper;
}
