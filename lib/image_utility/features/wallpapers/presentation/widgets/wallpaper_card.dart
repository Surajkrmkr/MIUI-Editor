import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:miui_icon_generator/image_utility/features/wallpapers/domain/entities/wallpaper.dart';
import 'package:miui_icon_generator/theme_editor/core/constants/app_constants.dart';
import 'package:miui_icon_generator/widgets/iphone_frame.dart';

class WallpaperCard extends StatelessWidget {
  final Wallpaper wallpaper;
  static const double aspectRatio = 6.0 / 13.0;

  const WallpaperCard({super.key, required this.wallpaper});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: () => context.push(
        '/wallpaper/${wallpaper.id}?source=${wallpaper.source}',
      ),
      child: AspectRatio(
        aspectRatio: aspectRatio,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: FittedBox(
            fit: BoxFit.contain,
            child: Hero(
              tag: 'wallpaper_${wallpaper.id}',
              child: IPhoneFrame(
                child: CachedNetworkImage(
                  imageUrl: wallpaper.largeUrl,
                  fit: BoxFit.cover,
                  width: AppConstants.screenWidth,
                  height: AppConstants.screenHeight,
                  placeholder: (_, __) => Container(
                    color: cs.surfaceContainerHighest,
                    width: AppConstants.screenWidth,
                    height: AppConstants.screenHeight,
                    child: Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: cs.onSurfaceVariant.withAlpha(80),
                      ),
                    ),
                  ),
                  errorWidget: (_, __, ___) => Container(
                    color: cs.surfaceContainerHighest,
                    width: AppConstants.screenWidth,
                    height: AppConstants.screenHeight,
                    child: Icon(Icons.broken_image_outlined,
                        color: cs.onSurfaceVariant),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
