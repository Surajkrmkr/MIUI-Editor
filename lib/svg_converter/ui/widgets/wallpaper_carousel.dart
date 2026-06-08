import 'dart:io';
import 'package:flutter/material.dart';
import 'package:miui_icon_generator/core/theme/theme_extensions.dart';
import 'package:miui_icon_generator/widgets/iphone_frame.dart';
import '../../models/conversion_task.dart';

class WallpaperCarousel extends StatefulWidget {
  final List<ConversionTask> tasks;
  const WallpaperCarousel({super.key, required this.tasks});

  @override
  State<WallpaperCarousel> createState() => _WallpaperCarouselState();
}

class _WallpaperCarouselState extends State<WallpaperCarousel> {
  late PageController _pageController;
  double _currentPage = 0.0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.38);
    _pageController.addListener(() {
      setState(() {
        _currentPage = _pageController.page ?? 0.0;
      });
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.tasks.isEmpty) return const SizedBox.shrink();

    return PageView.builder(
      controller: _pageController,
      itemCount: widget.tasks.length,
      itemBuilder: (context, index) {
        final task = widget.tasks[index];
        final offset = (index - _currentPage).abs();
        final scale = (1.0 - offset * 0.15).clamp(0.7, 1.0);
        final opacity = (1.0 - offset * 0.4).clamp(0.4, 1.0);

        return Center(
          child: AnimatedScale(
            scale: scale,
            duration: const Duration(milliseconds: 200),
            child: Opacity(
              opacity: opacity,
              child: _CarouselItem(task: task),
            ),
          ),
        );
      },
    );
  }
}

class _CarouselItem extends StatelessWidget {
  final ConversionTask task;
  const _CarouselItem({required this.task});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return IPhoneFrame(
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.file(
            File(task.inputPath),
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              color: colors.surface,
              child: Icon(Icons.image_not_supported, color: colors.textDisabled),
            ),
          ),
          _buildOverlay(context),
        ],
      ),
    );
  }

  Widget _buildOverlay(BuildContext context) {
    final colors = context.appColors;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            Colors.black.withValues(alpha: 0.8),
          ],
        ),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatusBadge(context),
          const SizedBox(height: 4),
          Text(
            task.inputPath.split(Platform.pathSeparator).last,
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(BuildContext context) {
    Color color = Theme.of(context).colorScheme.onSurfaceVariant;
    IconData icon = Icons.timer_outlined;

    if (task.status == TaskStatus.processing) {
      color = Theme.of(context).colorScheme.primary;
      icon = Icons.refresh;
    } else if (task.status == TaskStatus.success) {
      color = Colors.greenAccent;
      icon = Icons.check_circle;
    } else if (task.status == TaskStatus.failed) {
      color = Colors.redAccent;
      icon = Icons.error;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 4),
          Text(
            task.status.name.toUpperCase(),
            style: TextStyle(color: color, fontSize: 8, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}