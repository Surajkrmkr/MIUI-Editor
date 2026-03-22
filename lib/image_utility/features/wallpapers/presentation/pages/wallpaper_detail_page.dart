import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:miui_icon_generator/image_utility/features/wallpapers/domain/entities/wallpaper.dart';
import 'package:miui_icon_generator/image_utility/features/wallpapers/presentation/providers/wallpaper_providers.dart';

class WallpaperDetailPage extends ConsumerWidget {
  final String wallpaperId;
  final String source;

  const WallpaperDetailPage({
    super.key,
    required this.wallpaperId,
    required this.source,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wallpaperAsync = ref.watch(
      wallpaperByIdProvider((id: wallpaperId, source: source)),
    );

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              // TODO: Implement share
            },
          ),
        ],
      ),
      body: wallpaperAsync.when(
        data: (wallpaper) {
          if (wallpaper == null) {
            return const Center(child: Text('Wallpaper not found'));
          }
          return _buildDetailView(context, ref, wallpaper);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('Error: ${error.toString()}'),
        ),
      ),
    );
  }

  Widget _buildDetailView(
      BuildContext context, WidgetRef ref, Wallpaper wallpaper) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image
          Hero(
            tag: 'wallpaper_${wallpaper.id}',
            child: CachedNetworkImage(
              imageUrl: wallpaper.largeUrl,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                height: 400,
                color: Colors.grey[300],
                child: const Center(child: CircularProgressIndicator()),
              ),
              errorWidget: (context, url, error) => Container(
                height: 400,
                color: Colors.grey[300],
                child: const Icon(Icons.error),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Photographer Info
                Row(
                  children: [
                    CircleAvatar(
                      child: Text(wallpaper.photographer[0].toUpperCase()),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            wallpaper.photographer,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          Text(
                            wallpaper.source.toUpperCase(),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Description
                if (wallpaper.description != null &&
                    wallpaper.description!.isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Description',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(wallpaper.description!),
                      const SizedBox(height: 24),
                    ],
                  ),

                // Dimensions
                Text(
                  'Dimensions',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text('${wallpaper.width} × ${wallpaper.height}'),
                const SizedBox(height: 24),

                // Tags
                if (wallpaper.tags != null && wallpaper.tags!.isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tags',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: wallpaper.tags!.map((tag) {
                          return Chip(label: Text(tag));
                        }).toList(),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),

                // Download Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      await ref
                          .read(wallpaperNotifierProvider.notifier)
                          .downloadWallpaper(wallpaper);

                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Wallpaper downloaded successfully'),
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.download),
                    label: const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text('Download'),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // View on Source Button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      // TODO: Open URL in browser
                    },
                    icon: const Icon(Icons.open_in_new),
                    label: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text('View on ${wallpaper.source}'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
