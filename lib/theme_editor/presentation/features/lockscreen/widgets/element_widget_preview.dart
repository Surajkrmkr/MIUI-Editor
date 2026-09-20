import 'dart:io';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/asset_paths.dart';
import '../../../../core/constants/path_constants.dart';
import '../../../../core/utils/font_utils.dart';
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
    final currentWallPath = wallState.currentPath;

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
    final hasVideo = videoPath != null && File(videoPath).existsSync();

    return Container(
      height: AppConstants.screenHeight,
      width: AppConstants.screenWidth,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(20)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            // 1. Wallpaper (Current selected or exported bg.png)
            if (hasBg)
              Image.memory(
                File(bgPath).readAsBytesSync(),
                gaplessPlayback: true,
                fit: BoxFit.cover,
                width: AppConstants.screenWidth,
                height: AppConstants.screenHeight,
              )
            else if (hasCurrentWall)
              Image.file(
                File(currentWallPath),
                gaplessPlayback: true,
                fit: BoxFit.cover,
                width: AppConstants.screenWidth,
                height: AppConstants.screenHeight,
              ),

            // 2. Video layer
            if (hasVideo) VideoWallpaperWidget(key: ValueKey(videoPath), path: videoPath),

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
            ...els.elements.where((el) => el.isVisible).map(
                  (el) => _DraggableElement(
                    el: el,
                    isGroupMode: els.isGroupMode,
                    isGroupSelected: els.selectedTypes.contains(el.type),
                  ),
                ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _DraggableElement extends ConsumerStatefulWidget {
  const _DraggableElement({
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
            onTap: () {
              if (widget.isGroupMode) {
                n.toggleGroupSelect(el.type);
              } else {
                n.setActive(el.type);
              }
            },
            onLongPress: el.isLocked
                ? null
                : () {
                    if (widget.isGroupMode) {
                      n.toggleGroupSelect(el.type);
                    } else {
                      n.enterGroupMode(el.type);
                    }
                  },
            onPanDown: el.isLocked
                ? null
                : (_) {
                    if (widget.isGroupMode && widget.isGroupSelected) {
                      n.snapshotForGroupDrag();
                    } else {
                      n.snapshotForDrag();
                      n.setActive(el.type);
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
                        cursor: el.isLocked
                            ? SystemMouseCursors.basic
                            : _isDragging
                                ? SystemMouseCursors.grabbing
                                : SystemMouseCursors.grab,
                        child: _buildWithGroupHighlight(_buildChild(el)),
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

  Widget _buildWithGroupHighlight(Widget child) {
    if (!widget.isGroupSelected) return child;
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: Colors.blue.withAlpha(200),
          width: 2,
        ),
        borderRadius: BorderRadius.circular(4),
      ),
      child: child,
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
      ElementType.secClock => '55',
      ElementType.dotClock => ':',
      ElementType.dotClock2 => ':',
      ElementType.amPmClock => 'AM',
      ElementType.weekClock => el.isShort
          ? 'Wed'
          : el.isWrap
              ? _wrapText('Wednesday')
              : 'Wednesday',
      ElementType.monthClock => el.isShort ? 'Feb' : 'February',
      ElementType.dateClock => '08',
      _ => '',
    };

    if (el.useSeparateColors &&
        (el.type == ElementType.hourClock || el.type == ElementType.minClock || el.type == ElementType.secClock) &&
        txt.length == 2) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GradientText(
            txt[0],
            gradient: LinearGradient(
              begin: el.gradStartAlign as Alignment,
              end: el.gradEndAlign as Alignment,
              colors: [el.colorDigit1, el.colorDigit1],
              stops: const [0.0, 1.0],
            ),
            style: fontTextStyle(
                font: el.font, fontSize: 35, height: 1, color: el.colorDigit1),
            strokeWidth: el.strokeWidth,
            strokeColor: el.strokeColorDigit1.a > 0 ? el.strokeColorDigit1 : el.strokeColor,
            blurRadius: el.blurRadius,
            isLiquidGlass: el.isLiquidGlass,
          ),
          GradientText(
            txt[1],
            gradient: LinearGradient(
              begin: el.gradStartAlign as Alignment,
              end: el.gradEndAlign as Alignment,
              colors: [el.colorDigit2, el.colorDigit2],
              stops: const [0.0, 1.0],
            ),
            style: fontTextStyle(
                font: el.font, fontSize: 35, height: 1, color: el.colorDigit2),
            strokeWidth: el.strokeWidth,
            strokeColor: el.strokeColorDigit2.a > 0 ? el.strokeColorDigit2 : el.strokeColor,
            blurRadius: el.blurRadius,
            isLiquidGlass: el.isLiquidGlass,
          ),
        ],
      );
    }

    return GradientText(
      txt,
      gradient: LinearGradient(
        begin: el.gradStartAlign as Alignment,
        end: el.gradEndAlign as Alignment,
        colors: [el.color, el.colorSecondary],
        stops: const [0.0, 1.0],
      ),
      style: fontTextStyle(font: el.font, fontSize: 35, height: 1, color: el.color),
      strokeWidth: el.strokeWidth,
      strokeColor: el.strokeColor,
      blurRadius: el.blurRadius,
      isLiquidGlass: el.isLiquidGlass,
    );
  }

  // "Wednesday" -> "Wed\nnesday": first 3 letters, then the remainder.
  String _wrapText(String input) {
    if (input.length <= 3) return input;
    return '${input.substring(0, 3)}\n${input.substring(3)}';
  }

  Widget _container(LockElement el) {
    Widget containerWidget;
    if (el.isLiquidGlass) {
      final frostBlur = el.blurRadius > 0 ? el.blurRadius : 0.0;
      containerWidget = Container(
        height: el.height,
        width: el.width,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(el.radius),
          boxShadow: [
            // Splay & Depth ambient occlusion (Figma Depth 100, Splay 100)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.16),
              blurRadius: 28,
              offset: const Offset(0, 8),
              spreadRadius: -2,
            ),
            // Soft outer refraction glow
            BoxShadow(
              color: Colors.white.withValues(alpha: 0.14),
              blurRadius: 18,
              spreadRadius: -1,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(el.radius),
          child: Stack(
            children: [
              // 1. Frost Blur (Figma Frost = 0 by default, or user adjustable)
              if (frostBlur > 0)
                Positioned.fill(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: frostBlur, sigmaY: frostBlur),
                    child: const SizedBox.expand(),
                  ),
                ),

              // 2. Base Glass Fill (Figma Fill: #D9D9D9 at 20% opacity)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(el.radius),
                    color: const Color(0xFFD9D9D9).withValues(alpha: 0.20),
                  ),
                ),
              ),

              // 3. Chromatic Dispersion & Refraction (Figma Refraction 80, Dispersion 100, Depth 100)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(el.radius),
                    gradient: const RadialGradient(
                      center: Alignment(-0.2, -0.2),
                      radius: 1.1,
                      colors: [
                        Color(0x00FFFFFF), // Ultra-clear center (shows background sharp & magnified)
                        Color(0x08FF3366), // Red-orange chromatic dispersion fringe
                        Color(0x1033CCFF), // Cyan-blue chromatic dispersion fringe
                        Color(0x28FFFFFF), // Outer refraction edge
                      ],
                      stops: [0.65, 0.85, 0.94, 1.0],
                    ),
                  ),
                ),
              ),

              // 4. Directional Light & Specular Bevel (Figma Light: -45° at 80% intensity)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(el.radius),
                    // Light angle -45°: top-left bright light fading across to bottom-right
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xCCFFFFFF), // 80% light specular highlight at top-left
                        Color(0x22FFFFFF),
                        Color(0x00FFFFFF),
                        Color(0x55FFFFFF), // Bottom-right refraction bounce
                      ],
                      stops: [0.0, 0.25, 0.70, 1.0],
                    ),
                    border: Border.all(
                      width: el.borderWidth > 0 ? el.borderWidth : 1.5,
                      color: const Color(0x99FFFFFF), // Crisp glass outline
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      Widget base = Container(
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

      if (el.blurRadius > 0) {
        containerWidget = ClipRRect(
          borderRadius: BorderRadius.circular(el.radius),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: el.blurRadius, sigmaY: el.blurRadius),
            child: base,
          ),
        );
      } else {
        containerWidget = base;
      }
    }

    return containerWidget;
  }

  Widget _notification(LockElement el) {
    Widget child = Container(
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
            color: const Color(0xFFFFC300),
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

    if (el.blurRadius > 0) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(el.radius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: el.blurRadius, sigmaY: el.blurRadius),
          child: child,
        ),
      );
    }

    return child;
  }

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

    final textStyle = fontTextStyle(
      font: el.font,
      color: el.color,
      fontSize: el.fontSize,
      fontWeight: el.fontWeight,
      height: 1,
    );

    if (el.blurRadius > 0) {
      return Stack(
        alignment: Alignment.center,
        children: [
          Text(
            t,
            style: textStyle.copyWith(
              foreground: Paint()
                ..maskFilter = MaskFilter.blur(BlurStyle.normal, el.blurRadius)
                ..color = el.color,
            ),
          ),
          Text(t, style: textStyle),
        ],
      );
    }

    return Text(t, style: textStyle);
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
