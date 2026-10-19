import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:theme_raster_flutter/theme_raster_flutter.dart'
    show LockElementFrame, LockElementView;
import '../../../../core/extensions/maml_ease_ext.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/path_constants.dart';
import '../../../../domain/entities/element_widget.dart';
import '../../../providers/element_provider.dart';
import '../../../providers/lockscreen_provider.dart';
import '../../../providers/wallpaper_provider.dart';
import 'video_wallpaper.dart';

class ElementWidgetPreview extends ConsumerWidget {
  const ElementWidgetPreview({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final els = ref.watch(elementProvider);
    final wallState = ref.watch(wallpaperProvider);
    final videoRevision = ref.watch(videoWallpaperRevisionProvider);
    final weekNum = wallState.weekNum ?? '1';
    final themeName = wallState.currentThemeName ?? '';
    final currentWallPath = wallState.currentPath;
    final isExporting = ref.watch(
      lockscreenProvider.select((state) => state.isExporting),
    );

    String? bgPath, videoPath;
    if (themeName.isNotEmpty) {
      final tp = PathConstants.themePath(weekNum, themeName);
      final lsAdv = PathConstants.lockscreenAdvance(tp);
      bgPath = PathConstants.p('${lsAdv}bg.png');
      videoPath = PathConstants.p('${lsAdv}video.mp4');
    }
    final hasBg = bgPath != null && File(bgPath).existsSync();
    final hasCurrentWall =
        currentWallPath != null && File(currentWallPath).existsSync();
    final hasVisibleVideoElement = els.elements.any(
      (element) =>
          element.type.isVideo &&
          element.isVisible &&
          element.path == 'video.mp4',
    );
    final hasVideo =
        hasVisibleVideoElement &&
        videoPath != null &&
        File(videoPath).existsSync();

    return Container(
      height: AppConstants.screenHeight,
      width: AppConstants.screenWidth,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(20)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: TickerMode(
          enabled: !isExporting,
          child: Stack(
            children: [
              // 1. Wallpaper (Current selected or exported bg.png)
              if (hasBg)
                RepaintBoundary(
                  child: Image.file(
                    File(bgPath),
                    gaplessPlayback: true,
                    fit: BoxFit.cover,
                    width: AppConstants.screenWidth,
                    height: AppConstants.screenHeight,
                  ),
                )
              else if (hasCurrentWall)
                RepaintBoundary(
                  child: Image.file(
                    File(currentWallPath),
                    gaplessPlayback: true,
                    fit: BoxFit.cover,
                    width: AppConstants.screenWidth,
                    height: AppConstants.screenHeight,
                  ),
                ),

              // 2. Video layer
              if (hasVideo)
                RepaintBoundary(
                  child: VideoWallpaperWidget(
                    key: ValueKey((videoPath, videoRevision)),
                    path: videoPath,
                    isPaused: isExporting,
                  ),
                ),

              // 3. Darken overlay (tap to deselect / exit group mode)
              GestureDetector(
                onTap: () {
                  final n = ref.read(elementProvider.notifier);
                  n.deselect();
                  n.exitGroupMode();
                },
                child: Container(
                  width: AppConstants.screenWidth,
                  height: AppConstants.screenHeight,
                  color: Colors.black.withAlpha((els.bgAlpha * 255).round()),
                ),
              ),

              // 4. Elements
              ...els.elements
                  .where((el) => el.isVisible)
                  .map(
                    (el) => RepaintBoundary(
                      child: _DraggableElement(
                        key: ValueKey(el.name),
                        el: el,
                        isGroupMode: els.isGroupMode,
                        isGroupSelected: els.isSelected(el),
                      ),
                    ),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _DraggableElement extends ConsumerStatefulWidget {
  const _DraggableElement({
    super.key,
    required this.el,
    required this.isGroupMode,
    required this.isGroupSelected,
  });
  final LockElement el;
  final bool isGroupMode;
  final bool isGroupSelected;

  @override
  ConsumerState<_DraggableElement> createState() => _DraggableElementState();
}

class _DraggableElementState extends ConsumerState<_DraggableElement>
    with TickerProviderStateMixin {
  bool _isDragging = false;
  final _controllers = <ElementAnimation, AnimationController>{};
  Timer? _progressTimer;

  @override
  void initState() {
    super.initState();
    _configureAnimations();
    _configureProgressClock();
  }

  @override
  void didUpdateWidget(covariant _DraggableElement oldWidget) {
    super.didUpdateWidget(oldWidget);
    _configureAnimations(oldElement: oldWidget.el);
    _configureProgressClock(oldElement: oldWidget.el);
  }

  void _configureProgressClock({LockElement? oldElement}) {
    if (oldElement?.effectiveProgressSource ==
        widget.el.effectiveProgressSource) {
      return;
    }
    _progressTimer?.cancel();
    _progressTimer = null;
    if (widget.el.type == ElementType.arcShape &&
        const {
          ArcProgressSource.hour,
          ArcProgressSource.minute,
          ArcProgressSource.second,
        }.contains(widget.el.effectiveProgressSource)) {
      _progressTimer = Timer.periodic(
        const Duration(seconds: 1),
        (_) => setState(() {}),
      );
    }
  }

  void _configureAnimations({LockElement? oldElement, bool replay = false}) {
    final tracks = widget.el.activeAnimations;
    final activeTypes = tracks.map((track) => track.type).toSet();
    for (final type
        in _controllers.keys
            .where((type) => !activeTypes.contains(type))
            .toList()) {
      _controllers.remove(type)!.dispose();
    }
    for (final track in tracks) {
      final previous = oldElement?.activeAnimations
          .where((old) => old.type == track.type)
          .firstOrNull;
      final controller = _controllers.putIfAbsent(
        track.type,
        () => AnimationController(vsync: this),
      );
      if (!replay &&
          previous != null &&
          previous.duration == track.duration &&
          previous.loop == track.loop) {
        continue;
      }
      controller.stop();
      controller.duration = Duration(
        milliseconds: track.duration.clamp(100, 60000),
      );
      controller.value = 0;
      if (track.loop) {
        controller.repeat();
      } else {
        controller.forward();
      }
    }
  }

  @override
  void dispose() {
    _progressTimer?.cancel();
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<int>(
      animationReplayProvider,
      (previous, next) => _configureAnimations(replay: true),
    );
    final el = widget.el;
    final n = ref.read(elementProvider.notifier);
    const hw = AppConstants.screenHeight;
    const ww = AppConstants.screenWidth;

    return Stack(
      children: [
        // Guide lines
        if (el.showGuideLines) ...[
          Positioned(
            left: 0,
            top: el.dy + hw / 2,
            child: Container(
              width: ww,
              height: 1,
              color: Theme.of(context).colorScheme.primary.withAlpha(120),
            ),
          ),
          Positioned(
            left: el.dx + ww / 2,
            top: 0,
            child: Container(
              width: 1,
              height: hw,
              color: Theme.of(context).colorScheme.primary.withAlpha(120),
            ),
          ),
          Positioned(
            left: el.dx + ww / 2 + 10,
            top: el.dy + hw / 2 - 26,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '${el.dx.toStringAsFixed(0)}, ${el.dy.toStringAsFixed(0)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],

        // Element
        Positioned(
          left: el.dx,
          top: el.dy,
          child: GestureDetector(
            onTap: () {
              if (widget.isGroupMode) {
                n.toggleGroupSelect(el.type, id: el.name);
              } else {
                n.setActive(el.type, id: el.name);
              }
            },
            onLongPress: el.isLocked
                ? null
                : () {
                    if (widget.isGroupMode) {
                      n.toggleGroupSelect(el.type, id: el.name);
                    } else {
                      n.enterGroupMode(el.type, id: el.name);
                    }
                  },
            onPanDown: el.isLocked
                ? null
                : (_) {
                    if (widget.isGroupMode && widget.isGroupSelected) {
                      n.snapshotForGroupDrag();
                    } else {
                      n.snapshotForDrag();
                      n.setActive(el.type, id: el.name);
                    }
                  },
            onPanUpdate: el.isLocked
                ? null
                : (d) {
                    if (widget.isGroupMode && widget.isGroupSelected) {
                      n.moveGroupElements(d.delta.dx, d.delta.dy);
                    } else {
                      n.moveElement(el.type, d.delta.dx, d.delta.dy);
                    }
                    if (!_isDragging) setState(() => _isDragging = true);
                  },
            onPanEnd: el.isLocked
                ? null
                : (_) {
                    setState(() => _isDragging = false);
                  },
            child: AnimatedScale(
              scale: _isDragging ? 1.05 : 1.0,
              duration: const Duration(milliseconds: 100),
              child: LockElementFrame(
                element: el,
                child: MouseRegion(
                  cursor: el.isLocked
                      ? SystemMouseCursors.basic
                      : _isDragging
                      ? SystemMouseCursors.grabbing
                      : SystemMouseCursors.grab,
                  child: _buildWithGroupHighlight(
                    AnimatedBuilder(
                      animation: Listenable.merge(_controllers.values.toList()),
                      builder: (context, child) => _animatedChild(el),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWithGroupHighlight(Widget child) {
    if (!widget.isGroupSelected) return child;
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.blue.withAlpha(200), width: 2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: child,
    );
  }

  Widget _animatedChild(LockElement element) {
    final progress = <ElementAnimation, double>{};
    final tracks = element.activeAnimations;
    for (final track in tracks) {
      final time = _controllers[track.type]?.value ?? 0;
      progress[track.type] = track.hasCustomStart
          ? track.ease.curve.transform(time)
          : time <= 0.5
          ? track.ease.curve.transform(time * 2)
          : 1 - track.ease.curve.transform((time - 0.5) * 2);
    }
    var sizedElement = element;
    for (final track in tracks.where(
      (track) => track.type == ElementAnimation.size,
    )) {
      final factor = max(
        0.01,
        1 + (track.amount.clamp(0.1, 4) - 1) * progress[track.type]!,
      );
      sizedElement = element.copyWith(
        width: element.width * factor,
        height: element.height * factor,
      );
    }
    Widget child = sizedElement.type.isVideo
        ? const SizedBox.shrink()
        : LockElementView(element: sizedElement, resolveImage: _resolveImage);
    for (final type in const [
      ElementAnimation.scale,
      ElementAnimation.rotation,
      ElementAnimation.alpha,
      ElementAnimation.position,
    ]) {
      final track = tracks.where((track) => track.type == type).firstOrNull;
      if (track == null) continue;
      final value = progress[track.type]!;
      final key = ValueKey('animation-${element.name}-${track.type.name}');
      child = switch (track.type) {
        ElementAnimation.none || ElementAnimation.size => child,
        ElementAnimation.position => Transform.translate(
          key: key,
          offset: Offset(
            track.hasCustomStart
                ? (track.startX! - element.dx) * (1 - value)
                : track.amount * value / AppConstants.screenRatio,
            track.hasCustomStart
                ? (track.startY! - element.dy) * (1 - value)
                : track.offsetY * value / AppConstants.screenRatio,
          ),
          child: child,
        ),
        ElementAnimation.rotation => Transform.rotate(
          key: key,
          angle: track.amount * value * pi / 180,
          child: child,
        ),
        ElementAnimation.alpha => Opacity(
          key: key,
          opacity: (1 + (track.amount.clamp(0, 255) / 255 - 1) * value).clamp(
            0,
            1,
          ),
          child: child,
        ),
        ElementAnimation.scale => Transform.scale(
          key: key,
          scale: max(0.01, 1 + (track.amount.clamp(0.1, 4) - 1) * value),
          child: child,
        ),
      };
    }
    return child;
  }

  File? _resolveImage(String relativePath) {
    final wallState = ref.read(wallpaperProvider);
    final themeName = wallState.currentThemeName ?? '';
    if (themeName.isEmpty) return null;
    final tp = PathConstants.themePath(wallState.weekNum ?? '1', themeName);
    final lsAdv = PathConstants.lockscreenAdvance(tp);
    return File(PathConstants.p('$lsAdv$relativePath.png'));
  }
}
