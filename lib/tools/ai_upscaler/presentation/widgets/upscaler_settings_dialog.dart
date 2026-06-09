import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:miui_icon_generator/core/theme/theme_extensions.dart';
import '../../application/providers/upscaler_settings_provider.dart';
import '../../application/providers/upscaler_provider.dart';

class UpscalerSettingsDialog extends ConsumerWidget {
  const UpscalerSettingsDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(upscalerSettingsProvider);
    final cs = Theme.of(context).colorScheme;

    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 500),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: cs.primary.withValues(alpha: 0.1),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  Icon(Icons.settings_suggest_rounded, color: context.appColors.primary),
                  const SizedBox(width: 12),
                  Text(
                    'Upscaler Studio Configuration',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const Spacer(),
                  IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close_rounded)),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _LabeledPathField(
                      label: 'Real-ESRGAN Binary Path',
                      value: settings.customBinaryPath ?? 'Auto-detected',
                      hint: 'Select realesrgan-ncnn-vulkan.exe...',
                      onPick: () async {
                        FilePickerResult? result = await FilePicker.platform.pickFiles(
                          type: FileType.custom,
                          allowedExtensions: ['exe'],
                        );
                        if (result != null && result.files.single.path != null) {
                          await ref.read(upscalerSettingsProvider.notifier).updateBinaryPath(result.files.single.path!);
                          ref.read(upscalerProvider.notifier).checkInstallation();
                        }
                      },
                    ),
                    const SizedBox(height: 24),
                    _LabeledPathField(
                      label: 'Models Directory',
                      value: settings.customModelsPath ?? 'Auto-detected',
                      hint: 'Select models folder...',
                      onPick: () async {
                        String? path = await FilePicker.platform.getDirectoryPath();
                        if (path != null) {
                          await ref.read(upscalerSettingsProvider.notifier).updateModelsPath(path);
                        }
                      },
                    ),
                    const SizedBox(height: 40),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline_rounded, color: Colors.blueAccent, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'These paths are stored locally and will be used to launch the AI backend.',
                              style: TextStyle(color: context.appColors.textSecondary, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  FilledButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Save Configuration'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LabeledPathField extends StatelessWidget {
  final String label;
  final String value;
  final String hint;
  final VoidCallback onPick;

  const _LabeledPathField({required this.label, required this.value, required this.hint, required this.onPick});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: colors.borderSubtle),
                ),
                child: Text(
                  value,
                  style: TextStyle(color: value == 'Auto-detected' ? Colors.white38 : Colors.white, fontSize: 11),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.outlined(onPressed: onPick, icon: const Icon(Icons.folder_open_rounded, size: 18)),
          ],
        ),
      ],
    );
  }
}
