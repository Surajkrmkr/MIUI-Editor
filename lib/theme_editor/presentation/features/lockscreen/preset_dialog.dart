import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:miui_icon_generator/theme_editor/presentation/providers/directory_provider.dart';
import 'package:miui_icon_generator/theme_editor/presentation/providers/lockscreen_provider.dart';

class PresetDialog extends ConsumerStatefulWidget {
  const PresetDialog({super.key});
  @override
  ConsumerState<PresetDialog> createState() => _PresetDialogState();
}

class _PresetDialogState extends ConsumerState<PresetDialog> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
        (_) => ref.read(directoryProvider.notifier).loadPresetPaths());
  }

  @override
  Widget build(BuildContext context) {
    final dirState = ref.watch(directoryProvider);
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.7,
        width: MediaQuery.of(context).size.width * 0.7,
        child: Scaffold(
          appBar: AppBar(title: const Text('Preset Collections')),
          body: dirState.isLoadingPresets
              ? const Center(child: CircularProgressIndicator())
              : dirState.presetPaths.isEmpty
                  ? const Center(child: Text('NO PRESET AVAILABLE'))
                  : GridView.builder(
                      padding: const EdgeInsets.all(20),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 6,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                      ),
                      itemCount: dirState.presetPaths.length,
                      itemBuilder: (_, i) {
                        final path = dirState.presetPaths[i];
                        final name = path.split(Platform.pathSeparator).last;
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(20),
                            onTap: () async {
                              final jsonPath =
                                  '$path${Platform.pathSeparator}preset.json';
                              await ref
                                  .read(lockscreenProvider.notifier)
                                  .loadPreset(jsonPath);
                              if (context.mounted) Navigator.pop(context);
                            },
                            child: Card(
                              color: Theme.of(context)
                                  .colorScheme
                                  .primaryContainer,
                              margin: EdgeInsets.zero,
                              child: Center(
                                child: Text('Preset #${i + 1}\n$name',
                                    textAlign: TextAlign.center),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
        ),
      ),
    );
  }
}
