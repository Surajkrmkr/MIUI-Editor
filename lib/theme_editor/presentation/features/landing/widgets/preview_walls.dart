import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:miui_icon_generator/widgets/iphone_frame.dart';
import '../../../providers/directory_provider.dart';

class PreviewWallsPanel extends ConsumerStatefulWidget {
  const PreviewWallsPanel({super.key});

  @override
  ConsumerState<PreviewWallsPanel> createState() => _PreviewWallsPanelState();
}

class _PreviewWallsPanelState extends ConsumerState<PreviewWallsPanel> {
  final PageController _pageController = PageController(viewportFraction: 0.72);
  int _currentIndex = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dirState = ref.watch(directoryProvider);
    final paths = dirState.previewWallPaths;

    return SizedBox(
      height: 600,
      width: 370,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Previews',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      )),
              if (paths.isNotEmpty) ...[
                const SizedBox(width: 8),
                Text(
                  '${_currentIndex + 1} / ${paths.length}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withAlpha(100),
                      ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: dirState.isLoadingWalls
                ? const Center(child: CircularProgressIndicator())
                : paths.isEmpty
                    ? const Center(child: Text('No walls found'))
                    : PageView.builder(
                        controller: _pageController,
                        itemCount: paths.length,
                        onPageChanged: (i) => setState(() => _currentIndex = i),
                        itemBuilder: (_, i) {
                          final isActive = i == _currentIndex;
                          return AnimatedScale(
                            scale: isActive ? 1.0 : 0.88,
                            duration: const Duration(milliseconds: 250),
                            curve: Curves.easeOut,
                            child:
                                IPhoneFrame(child: _WallCard(path: paths[i])),
                          );
                        },
                      ),
          ),
          const SizedBox(height: 14),
          // Dot indicator
          if (paths.isNotEmpty)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                paths.length.clamp(0, 10),
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: i == _currentIndex ? 18 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: i == _currentIndex
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.onSurface.withAlpha(50),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _WallCard extends StatelessWidget {
  const _WallCard({required this.path});
  final String path;

  @override
  Widget build(BuildContext context) {
    final name = path.split(Platform.pathSeparator).last;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(60),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
        image: DecorationImage(
          fit: BoxFit.cover,
          image: FileImage(File(path)),
        ),
      ),
      alignment: Alignment.bottomCenter,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(12, 40, 12, 24),
        decoration: BoxDecoration(
          borderRadius:
              const BorderRadius.vertical(bottom: Radius.circular(24)),
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [Colors.black.withAlpha(180), Colors.transparent],
          ),
        ),
        child: Text(
          name.split(".").first,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
              color: Colors.white, fontSize: 11, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }
}
