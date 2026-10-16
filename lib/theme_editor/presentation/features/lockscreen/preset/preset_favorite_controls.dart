import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/preset_favorites_provider.dart';

class PresetFavoritesFilterButton extends ConsumerWidget {
  const PresetFavoritesFilterButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(favoritePresetsOnlyProvider);
    return IconButton(
      isSelected: selected,
      icon: const Icon(Icons.star_border_rounded, size: 18),
      selectedIcon: const Icon(Icons.star_rounded, size: 18),
      tooltip: selected ? 'Show all presets' : 'Show favorites only',
      style: IconButton.styleFrom(minimumSize: const Size(28, 28)),
      onPressed: () =>
          ref.read(favoritePresetsOnlyProvider.notifier).state = !selected,
    );
  }
}

class PresetFavoriteButton extends ConsumerWidget {
  const PresetFavoriteButton({super.key, required this.path});
  final String path;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(
      presetFavoritesProvider.select(
        (favorites) => favorites.contains(presetFavoriteKey(path)),
      ),
    );
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surface,
      shape: const CircleBorder(),
      child: IconButton(
        isSelected: selected,
        icon: const Icon(Icons.star_border_rounded, size: 18),
        selectedIcon: const Icon(Icons.star_rounded, size: 18),
        tooltip: selected ? 'Remove from favorites' : 'Add to favorites',
        style: IconButton.styleFrom(
          minimumSize: const Size(32, 32),
          foregroundColor: scheme.primary,
        ),
        onPressed: () async {
          try {
            await ref.read(presetFavoritesProvider.notifier).toggle(path);
          } catch (error) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Could not save favorites: $error')),
              );
            }
          }
        },
      ),
    );
  }
}

class EmptyFavoritePresets extends ConsumerWidget {
  const EmptyFavoritePresets({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.star_border_rounded,
          size: 40,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        const SizedBox(height: 10),
        const Text('No favorite presets yet'),
        TextButton(
          onPressed: () =>
              ref.read(favoritePresetsOnlyProvider.notifier).state = false,
          child: const Text('Show all presets'),
        ),
      ],
    ),
  );
}
