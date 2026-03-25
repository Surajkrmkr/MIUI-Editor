import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/constants/theme_defaults.dart';

/// Loading placeholder for the icon grid.
class ShimmerGrid extends StatelessWidget {
  const ShimmerGrid({super.key, this.count = 24});
  final int count;

  @override
  Widget build(BuildContext context) => Shimmer.fromColors(
        baseColor: ThemeDefaults.surfaceVariantDark,
        highlightColor: const Color(0xFF3E3E3E),
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
              color: ThemeDefaults.surfaceVariantDark,
              borderRadius: BorderRadius.circular(ThemeDefaults.radiusSm),
            ),
          ),
        ),
      );
}
