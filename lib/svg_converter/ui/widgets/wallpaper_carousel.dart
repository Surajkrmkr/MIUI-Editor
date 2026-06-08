import 'dart:io';
import 'package:flutter/material.dart';
import '../../models/conversion_task.dart';
import 'glass_card.dart';

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
    _pageController = PageController(viewportFraction: 0.35);
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
        final offset = index - _currentPage;
        
        // 3D Perspective Transformation - Subtle stacking like the reference
        final transform = Matrix4.identity()
          ..setEntry(3, 2, 0.001) // perspective
          ..translate(offset * 250, 0.0, -offset.abs() * 300)
          ..rotateY(-offset * 0.4)
          ..scale(1 - offset.abs() * 0.1);

        return Center(
          child: Transform(
            transform: transform,
            alignment: Alignment.center,
            child: Opacity(
              opacity: (1 - offset.abs()).clamp(0.2, 1.0),
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
    return AspectRatio(
      aspectRatio: 9 / 16,
      child: GlassCard(
        borderRadius: 20,
        padding: const EdgeInsets.all(4),
        hasGlow: task.status == TaskStatus.processing,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.file(
                File(task.inputPath),
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: Colors.grey[900],
                  child: const Icon(Icons.image_not_supported, color: Colors.white24),
                ),
              ),
              _buildOverlay(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOverlay(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            Colors.black.withOpacity(0.8),
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
            style: const TextStyle(
              color: Colors.white,
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
    Color color = Colors.grey;
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
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.5)),
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