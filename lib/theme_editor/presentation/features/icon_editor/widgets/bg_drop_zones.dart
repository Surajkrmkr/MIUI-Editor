import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../presentation/common/widgets/drop_zone.dart';
import '../../../../presentation/providers/icon_editor_provider.dart';
import '../../../../presentation/providers/wallpaper_provider.dart';
import '../../../../presentation/providers/service_providers.dart';
import '../../../../core/constants/path_constants.dart';

class BgDropZones extends ConsumerWidget {
  const BgDropZones({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      AppDropZone(
        label: 'Before\nVector',
        allowedExtensions: const ['.png'],
        onDropped: (path) => _save(ref, path, 'beforeVector'),
      ),
      const SizedBox(width: 16),
      AppDropZone(
        label: 'After\nVector',
        allowedExtensions: const ['.png'],
        onDropped: (path) => _save(ref, path, 'afterVector'),
      ),
    ],
  );

  Future<void> _save(WidgetRef ref, String srcPath, String name) async {
    final ws = ref.read(wallpaperProvider);
    if (ws.weekNum == null || ws.currentThemeName == null) return;
    final tp = PathConstants.themePath(ws.weekNum!, ws.currentThemeName!);
    final dest = PathConstants.p('${PathConstants.lockscreenAdvance(tp)}$name.png');
    await ref.read(fileServiceProvider).copyFile(srcPath, dest);
    if (name == 'beforeVector') {
      ref.read(iconEditorProvider.notifier).setBeforeVector(dest);
    } else {
      ref.read(iconEditorProvider.notifier).setAfterVector(dest);
    }
  }
}
