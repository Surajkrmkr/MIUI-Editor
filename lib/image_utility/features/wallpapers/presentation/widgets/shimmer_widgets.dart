import 'package:flutter/material.dart';
import 'package:miui_icon_generator/core/theme/theme_extensions.dart';
import 'package:shimmer/shimmer.dart';

/// Shimmer loading widget for wallpaper cards
class WallpaperCardShimmer extends StatelessWidget {
  const WallpaperCardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Shimmer.fromColors(
        baseColor: Theme.of(context).colorScheme.surfaceContainerHighest,
        highlightColor: Theme.of(context).colorScheme.surface,
        child: AspectRatio(
          aspectRatio: 3.0 / 5.0,
          child: Container(
            color: context.appColors.surface,
          ),
        ),
      ),
    );
  }
}

/// Shimmer loading for wallpaper grid
class WallpaperGridShimmer extends StatelessWidget {
  final int itemCount;

  const WallpaperGridShimmer({
    super.key,
    this.itemCount = 6,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 3.0 / 5.0,
      ),
      itemCount: itemCount,
      itemBuilder: (context, index) => const WallpaperCardShimmer(),
    );
  }
}

/// Shimmer loading for detail page
class WallpaperDetailShimmer extends StatelessWidget {
  const WallpaperDetailShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Theme.of(context).colorScheme.surfaceContainerHighest,
      highlightColor: Theme.of(context).colorScheme.surface,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image placeholder
            SizedBox(
              height: 400,
              width: double.infinity,
              child: Container(
                color: context.appColors.surface,
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Photographer info
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: context.appColors.surface,
                        radius: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 120,
                              height: 16,
                              color: context.appColors.surface,
                            ),
                            const SizedBox(height: 4),
                            Container(
                              width: 80,
                              height: 12,
                              color: context.appColors.surface,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Description
                  Container(
                    width: 100,
                    height: 16,
                    color: context.appColors.surface,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    height: 12,
                    color: context.appColors.surface,
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: double.infinity,
                    height: 12,
                    color: context.appColors.surface,
                  ),
                  const SizedBox(height: 24),

                  // Dimensions
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 80,
                              height: 14,
                              color: context.appColors.surface,
                            ),
                            const SizedBox(height: 4),
                            Container(
                              width: 100,
                              height: 12,
                              color: context.appColors.surface,
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 20,
                        height: 20,
                        color: context.appColors.surface,
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 80,
                              height: 14,
                              color: context.appColors.surface,
                            ),
                            const SizedBox(height: 4),
                            Container(
                              width: 100,
                              height: 12,
                              color: context.appColors.surface,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Tags
                  Container(
                    width: 60,
                    height: 16,
                    color: context.appColors.surface,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: List.generate(
                      4,
                      (index) => Container(
                        width: 60 + (index * 10.0),
                        height: 32,
                        decoration: BoxDecoration(
                          color: context.appColors.surface,
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
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

/// Shimmer for list items
class ListItemShimmer extends StatelessWidget {
  const ListItemShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Theme.of(context).colorScheme.surfaceContainerHighest,
      highlightColor: Theme.of(context).colorScheme.surface,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: context.appColors.surface,
        ),
        title: Container(
          width: double.infinity,
          height: 12,
          color: context.appColors.surface,
        ),
        subtitle: Container(
          width: double.infinity,
          height: 10,
          color: context.appColors.surface,
          margin: const EdgeInsets.only(top: 4),
        ),
      ),
    );
  }
}
