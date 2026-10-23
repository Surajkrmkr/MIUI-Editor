import 'dart:io';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../presentation/common/widgets/drop_zone.dart';
import '../../../providers/wallpaper_provider.dart';

const _imageExtensions = ['.jpg', '.jpeg', '.png', '.webp'];

class HomeWallpaperPanel extends ConsumerWidget {
  const HomeWallpaperPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(wallpaperProvider);
    final notifier = ref.read(wallpaperProvider.notifier);
    final customPath = state.homeWallpaperPath;
    final hasCustomImage = customPath != null && File(customPath).existsSync();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Homescreen', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            'Choose a separate wallpaper for the home screen.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          Material(
            color: Colors.transparent,
            child: SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: const Text('Use custom wallpaper'),
              value: state.homeWallpaperEnabled,
              onChanged: notifier.setHomeWallpaperEnabled,
            ),
          ),
          if (state.homeWallpaperEnabled) ...[
            const SizedBox(height: 8),
            if (hasCustomImage)
              DropTarget(
                onDragDone: (d) {
                  if (d.files.isEmpty) return;
                  final path = d.files.first.path;
                  if (_imageExtensions.any(path.toLowerCase().endsWith)) {
                    notifier.setHomeWallpaper(path);
                  }
                },
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(
                    File(customPath),
                    key: ValueKey(customPath),
                    width: double.infinity,
                    height: 180,
                    fit: BoxFit.cover,
                  ),
                ),
              )
            else
              AppDropZone(
                label: 'Drop a wallpaper image here',
                size: const Size(double.infinity, 180),
                allowedExtensions: _imageExtensions,
                onDropped: notifier.setHomeWallpaper,
              ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final result = await FilePicker.platform.pickFiles(
                        type: FileType.image,
                        dialogTitle: 'Choose homescreen wallpaper',
                      );
                      final path = result?.files.single.path;
                      if (path != null) notifier.setHomeWallpaper(path);
                    },
                    icon: const Icon(Icons.image_outlined, size: 18),
                    label: const Text('Browse'),
                  ),
                ),
                if (customPath != null) ...[
                  const SizedBox(width: 8),
                  IconButton(
                    tooltip: 'Remove custom wallpaper',
                    onPressed: notifier.clearHomeWallpaper,
                    icon: const Icon(Icons.delete_outline),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }
}
