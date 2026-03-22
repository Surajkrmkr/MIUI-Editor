import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:miui_icon_generator/theme_editor/presentation/providers/wallpaper_provider.dart';
import '../../../../core/constants/path_constants.dart';
import '../../../providers/element_provider.dart';
import '../../../providers/lockscreen_provider.dart';
import '../../../providers/service_providers.dart';
import '../../../providers/ai_provider.dart';
import '../../../common/widgets/drop_zone.dart';
import '../preset_dialog.dart';
import 'mtz_export_button.dart';

class LockscreenFunctionsPanel extends ConsumerWidget {
  const LockscreenFunctionsPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lsState = ref.watch(lockscreenProvider);
    final aiState = ref.watch(aiProvider);
    final busy = lsState.isExporting || aiState.isLoading;

    return SizedBox(
      width: 180,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('BG',
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            // Drop BG image
            Center(
              child: AppDropZone(
                label: 'Drop BG',
                allowedExtensions: const ['.png', '.jpg'],
                onDropped: (path) => _dropBg(ref, path),
              ),
            ),
            const SizedBox(height: 8),
            // Drop video
            Center(
              child: AppDropZone(
                label: 'Drop MP4',
                allowedExtensions: const ['.mp4'],
                onDropped: (path) => _dropVideo(ref, path),
              ),
            ),
            const SizedBox(height: 8),
            // BG Alpha
            Consumer(builder: (_, ref, __) {
              final alpha = ref.watch(elementProvider).bgAlpha;
              return Column(children: [
                Text('BG Dark: ${(alpha * 100).toStringAsFixed(0)}%',
                    style: const TextStyle(fontSize: 12)),
                Slider(
                  value: alpha,
                  min: 0,
                  max: 1,
                  divisions: 20,
                  onChanged: (v) =>
                      ref.read(elementProvider.notifier).setBgAlpha(v),
                ),
              ]);
            }),
            const Divider(),
            // AI generate
            FilledButton.icon(
              icon: const Icon(Icons.auto_awesome, size: 14),
              label: const Text('AI Generate'),
              onPressed: busy ? null : () => _showAiDialog(context, ref),
            ),
            const SizedBox(height: 8),
            // Save preset
            FilledButton.icon(
              icon: const Icon(Icons.save, size: 14),
              label: const Text('Save Preset'),
              onPressed: () => ref
                  .read(lockscreenProvider.notifier)
                  .savePreset(DateTime.now().millisecondsSinceEpoch.toString()),
            ),
            const SizedBox(height: 8),
            // Load preset
            TextButton.icon(
              icon: const Icon(Icons.layers, size: 14),
              label: const Text('Presets'),
              onPressed: () => showDialog(
                context: context,
                builder: (_) => const PresetDialog(),
              ),
            ),
            const Divider(),

            // Single export button — does XML + PNGs + MTZ in one tap
            Consumer(builder: (_, ref, __) {
              final s = ref.watch(lockscreenProvider);
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  FilledButton.icon(
                    icon: Icon(
                      s.isExported ? Icons.check : Icons.lock,
                      size: 14,
                    ),
                    label: Text(
                      s.isExportingPngs
                          ? s.pngsLabel // "Frames 23/127"
                          : s.isExporting
                              ? 'Exporting...'
                              : s.isExported
                                  ? 'Re-Export'
                                  : 'Export + MTZ',
                    ),
                    onPressed: s.isBusy ? null : () => _export(context, ref),
                  ),
                  // Progress bar visible during PNG phase
                  if (s.isExportingPngs) ...[
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: s.pngsProgress,
                        minHeight: 5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      s.pngsLabel,
                      style: const TextStyle(fontSize: 10),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  // MTZ button kept as manual fallback (re-zip without re-exporting)
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.archive, size: 14),
                    label: const Text('Re-pack MTZ'),
                    onPressed: s.isBusy ? null : () => _repackMtz(context, ref),
                  ),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  Future<void> _dropBg(WidgetRef ref, String path) async {
    final ws = ref.read(wallpaperProvider);
    if (ws.weekNum == null || ws.currentThemeName == null) return;
    final tp = PathConstants.themePath(ws.weekNum!, ws.currentThemeName!);
    final dest = '${PathConstants.lockscreenAdvance(tp)}bg.png';
    await ref.read(fileServiceProvider).copyFile(path, dest);
    // Trigger canvas rebuild
    ref
        .read(elementProvider.notifier)
        .setGuideLines(ref.read(elementProvider).activeType, false);
  }

  Future<void> _dropVideo(WidgetRef ref, String path) async {
    final ws = ref.read(wallpaperProvider);
    if (ws.weekNum == null || ws.currentThemeName == null) return;
    final tp = PathConstants.themePath(ws.weekNum!, ws.currentThemeName!);
    final dest = '${PathConstants.lockscreenAdvance(tp)}video.mp4';
    await ref.read(fileServiceProvider).copyFile(path, dest);
  }

  Future<void> _export(BuildContext context, WidgetRef ref) async {
    final failure = await ref.read(lockscreenProvider.notifier).export(context);
    if (failure != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Export failed: ${failure.message}')),
      );
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lockscreen exported ✅')),
      );
    }
  }

  Future<void> _repackMtz(BuildContext context, WidgetRef ref) async {
    final (path, failure) =
        await ref.read(lockscreenProvider.notifier).exportMtz();
    if (!context.mounted) return;
    if (failure != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('MTZ failed: ${failure.message}')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Re-packed: $path ✅')),
      );
    }
  }

  Future<void> _showAiDialog(BuildContext context, WidgetRef ref) async {
    final ctrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('AI Lockscreen'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration:
              const InputDecoration(hintText: 'Describe your lockscreen...'),
          maxLines: 3,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Generate')),
        ],
      ),
    );
    if (ok == true && ctrl.text.trim().isNotEmpty) {
      final failure = await ref
          .read(aiProvider.notifier)
          .generateLockscreen(ctrl.text.trim());
      if (failure != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('AI error: ${failure.message}')),
        );
      } else if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('AI layout applied ✅')),
        );
      }
    }
  }
}
