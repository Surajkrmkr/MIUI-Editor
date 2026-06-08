import 'package:flutter/material.dart';
import 'package:miui_icon_generator/core/theme/theme_extensions.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/constants/theme_defaults.dart';

/// Loading placeholder for the icon grid.
class ShimmerGrid extends StatelessWidget {
  const ShimmerGrid({super.key, this.count = 24});
  final int count;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Shimmer.fromColors(
        baseColor: colors.surface,
        highlightColor: colors.surfaceElevated,
        child: GridView.builder(
          padding: const EdgeInsets.all(ThemeDefaults.paddingMd),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 5,
            mainAxisSpacing: ThemeDefaults.paddingSm,
            crossAxisSpacing: ThemeDefaults.paddingSm,
          ),
          itemCount: count,
          itemBuilder: (_, __) => Container(
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(ThemeDefaults.radiusSm),
            ),
          ),
        ),
      );
  }
}
