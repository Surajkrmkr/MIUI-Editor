import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:miui_icon_generator/image_utility/features/wallpapers/presentation/providers/wallpaper_providers.dart';

class SourceSelector extends ConsumerWidget {
  const SourceSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final availableSources = ref.watch(availableSourcesProvider);
    final selectedSource = ref.watch(selectedSourceProvider);

    return availableSources.when(
      data: (sources) {
        if (sources.isEmpty) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'No image sources configured. Please add API keys in Settings.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          );
        }

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              // All Sources option
              Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: ChoiceChip(
                  label: const Text('All Sources'),
                  selected: selectedSource == null,
                  onSelected: (selected) {
                    if (selected) {
                      ref.read(selectedSourceProvider.notifier).state = null;
                      ref
                          .read(wallpaperNotifierProvider.notifier)
                          .loadCurated();
                    }
                  },
                ),
              ),
              // Individual source options
              ...sources.map((source) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ChoiceChip(
                    label: Text(source.sourceName),
                    selected: selectedSource == source.sourceId,
                    onSelected: (selected) {
                      if (selected) {
                        ref.read(selectedSourceProvider.notifier).state =
                            source.sourceId;
                        ref
                            .read(wallpaperNotifierProvider.notifier)
                            .loadCurated();
                      }
                    },
                  ),
                );
              }),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Text('Error: $error'),
    );
  }
}
