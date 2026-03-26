import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/asset_paths.dart';
import '../../../../core/constants/path_constants.dart';
import '../../../../domain/entities/element_widget.dart';
import '../../../providers/element_provider.dart';
import '../../../providers/wallpaper_provider.dart';
import '../../../common/widgets/gradient_text.dart';
import 'video_wallpaper.dart';

class ElementWidgetPreview extends ConsumerWidget {
  const ElementWidgetPreview({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final els = ref.watch(elementProvider);
    final wallState = ref.watch(wallpaperProvider);
    final weekNum = wallState.weekNum ?? '1';
    final themeName = wallState.currentThemeName ?? '';

    String? bgPath, videoPath;
    if (themeName.isNotEmpty) {
      final tp = PathConstants.themePath(weekNum, themeName);
      final lsAdv = PathConstants.lockscreenAdvance(tp);
      bgPath = PathConstants.p('${lsAdv}bg.png');
      videoPath = PathConstants.p('${lsAdv}video.mp4');
    }
    final hasBg = bgPath != null && File(bgPath).existsSync();
    final hasVideo = videoPath != null && File(videoPath).existsSync();

    return Container(
      height: AppConstants.screenHeight,
      width: AppConstants.screenWidth,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(20)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            // Tap empty space → deselect
            GestureDetector(
              onTap: () => ref.read(elementProvider.notifier).deselect(),
              child: Container(
                width: AppConstants.screenWidth,
                height: AppConstants.screenHeight,
                color: Colors.black.withAlpha((els.bgAlpha * 255).round()),
              ),
            ),
            if (hasBg)
              Image.memory(
                File(bgPath).readAsBytesSync(),
                gaplessPlayback: true,
                fit: BoxFit.cover,
                width: AppConstants.screenWidth,
                height: AppConstants.screenHeight,
              ),
            if (hasVideo) VideoWallpaperWidget(path: videoPath),
            ...els.elements.map((el) => _DraggableElement(el: el)),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _DraggableElement extends ConsumerStatefulWidget {
  const _DraggableElement({required this.el});
  final LockElement el;

  @override
  ConsumerState<_DraggableElement> createState() => _DraggableElementState();
}

class _DraggableElementState extends ConsumerState<_DraggableElement> {
  bool _isDragging = false;

  @override
  Widget build(BuildContext context) {
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
            onTap: () => n.setActive(el.type),
            onPanDown: (_) {
              n.setActive(el.type);
              // n.setGuideLines(el.type, true);
            },
            onPanUpdate: (d) {
              n.moveElement(el.type, d.delta.dx, d.delta.dy);
              setState(() => _isDragging = true);
            },
            onPanEnd: (_) {
              // n.setGuideLines(el.type, false);
              setState(() => _isDragging = false);
            },
            child: AnimatedScale(
              scale: _isDragging ? 1.05 : 1.0,
              duration: const Duration(milliseconds: 100),
              child: Transform.scale(
                scale: el.scale,
                child: Transform.rotate(
                  angle: -el.angle * pi / 180,
                  child: SizedBox(
                    height: hw,
                    width: ww,
                    child: Align(
                      alignment: el.align,
                      child: MouseRegion(
                        cursor: _isDragging
                            ? SystemMouseCursors.grabbing
                            : SystemMouseCursors.grab,
                        child: _buildChild(el),
                      ),
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

  Widget _buildChild(LockElement el) {
    if (el.type == ElementType.swipeUpUnlock) return const SizedBox.shrink();
    if (el.type == ElementType.weatherIconClock) {
      return Image.asset(AssetPaths.weatherIcon("0"), height: 40);
    }
    if (el.type.isClock) return _clock(el);
    if (el.type.isContainer) return _container(el);
    if (el.type == ElementType.notification) return _notification(el);
    if (el.type.isText) return _text(el);

    // PNG / icon / music — try to load the image from disk
    final resolvedPath = el.path.isNotEmpty ? el.path : el.type.defaultPath;
    if (resolvedPath.isNotEmpty) {
      final wallState = ref.read(wallpaperProvider);
      final weekNum = wallState.weekNum ?? '1';
      final themeName = wallState.currentThemeName ?? '';
      if (themeName.isNotEmpty) {
        final tp = PathConstants.themePath(weekNum, themeName);
        final lsAdv = PathConstants.lockscreenAdvance(tp);
        final relative = resolvedPath.startsWith(r'\')
            ? resolvedPath.substring(1)
            : resolvedPath;
        final fullPath = PathConstants.p('$lsAdv$relative.png');
        final file = File(fullPath);
        if (file.existsSync()) {
          return Image.memory(
            file.readAsBytesSync(),
            height: el.height / AppConstants.screenRatio,
            width: el.width / AppConstants.screenRatio,
            gaplessPlayback: true,
          );
        }
      }
    }

    // Fallback placeholder
    return Container(
      height: el.height / AppConstants.screenRatio,
      width: el.width / AppConstants.screenRatio,
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(el.radius),
      ),
    );
  }

  Widget _clock(LockElement el) {
    final txt = switch (el.type) {
      ElementType.hourClock => '02',
      ElementType.minClock => '36',
      ElementType.dotClock => ':',
      ElementType.amPmClock => 'AM',
      ElementType.weekClock => el.isShort ? 'Wed' : 'Wednesday',
      ElementType.monthClock => el.isShort ? 'Feb' : 'February',
      ElementType.dateClock => '08',
      _ => '',
    };
    return GradientText(
      txt,
      gradient: LinearGradient(
        begin: el.gradStartAlign as Alignment,
        end: el.gradEndAlign as Alignment,
        colors: [el.color, el.colorSecondary],
      ),
      style: TextStyle(
          fontFamily: el.font, fontSize: 35, height: 1, color: el.color),
    );
  }

  Widget _container(LockElement el) => Container(
        height: el.height,
        width: el.width,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(el.radius),
          border: el.borderWidth > 0
              ? Border.all(width: el.borderWidth, color: el.borderColor)
              : null,
          gradient: LinearGradient(
            begin: el.gradStartAlign as Alignment,
            end: el.gradEndAlign as Alignment,
            colors: [el.color, el.colorSecondary],
          ),
        ),
      );

  Widget _notification(LockElement el) => Container(
        height: 60,
        width: 250,
        decoration: BoxDecoration(
          color: el.colorSecondary,
          borderRadius: BorderRadius.circular(el.radius),
        ),
        child: Row(children: [
          Container(
            margin: const EdgeInsets.only(left: 8),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.pinkAccent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.android, size: 14),
          ),
          const SizedBox(width: 8),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Notification',
                  style: TextStyle(color: el.color, fontSize: 10)),
              Text('Details', style: TextStyle(color: el.color, fontSize: 10)),
            ],
          ),
        ]),
      );

  static const _dt = {
    'dd': '08',
    'E': 'Wed',
    'MM': '02',
    'yy': '22',
    'aa': 'PM',
    'hh': '02',
    'mm': '36',
    'ss': '06',
  };
  static const _gv = {
    '#battery_level': '100',
    '#temp': '24',
    '@cityName': 'Cuttack',
    '@airQuality': 'Good',
    "'": '',
    '+': '',
  };

  Widget _text(LockElement el) {
    var t = el.text;
    final map = el.type.isDateTime ? _dt : _gv;
    for (final e in map.entries) {
      t = t.replaceAll(e.key, e.value);
    }
    return Text(t,
        style: TextStyle(
          color: el.color,
          fontSize: el.fontSize,
          fontWeight: el.fontWeight,
          height: 1,
        ));
  }
}

// ─────────────────────────────────────────────────────────────────────────────

// class _ElementHighlight extends StatelessWidget {
//   const _ElementHighlight({
//     required this.isActive,
//     required this.isDragging,
//     required this.child,
//   });

//   final bool isActive;
//   final bool isDragging;
//   final Widget child;

//   @override
//   Widget build(BuildContext context) {
//     if (!isActive) return child;

//     final primary = Theme.of(context).colorScheme.primary;

//     return AnimatedContainer(
//       duration: const Duration(milliseconds: 150),
//       padding: const EdgeInsets.all(4),
//       decoration: BoxDecoration(
//         borderRadius: BorderRadius.circular(6),
//         boxShadow: isDragging
//             ? [
//                 BoxShadow(
//                   color: primary.withAlpha(110),
//                   blurStyle: BlurStyle.inner,
//                   blurRadius: 24,
//                   spreadRadius: 1,
//                 )
//               ]
//             : null,
//       ),
//       child: child,
//     );
//   }
// }
