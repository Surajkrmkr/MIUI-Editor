import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import '../../../../core/extensions/maml_ease_ext.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/asset_paths.dart';
import '../../../../core/constants/path_constants.dart';
import '../../../../core/utils/font_utils.dart';
import '../../../../domain/entities/element_widget.dart';
import '../../../providers/element_provider.dart';
import '../../../providers/wallpaper_provider.dart';
import '../../../common/widgets/gradient_text.dart';
import 'video_wallpaper.dart';
import 'unlock_control_preview.dart';

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
            if (hasVideo)
              VideoWallpaperWidget(key: ValueKey(videoPath), path: videoPath),

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
                  (el) => _DraggableElement(
                    key: ValueKey(el.name),
                    el: el,
                    isGroupMode: els.isGroupMode,
                    isGroupSelected: els.isSelected(el),
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
  final _dismissedNotifications = <int>{};
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
    if (oldWidget.el.notificationLimit != widget.el.notificationLimit) {
      _dismissedNotifications.clear();
    }
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
                        child: _buildWithGroupHighlight(
                          AnimatedBuilder(
                            animation: Listenable.merge(
                              _controllers.values.toList(),
                            ),
                            builder: (context, child) => _animatedChild(el),
                          ),
                        ),
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
    Widget child = _buildChild(sizedElement);
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

  Widget _buildChild(LockElement el) {
    if (el.type == ElementType.swipeUpUnlock) return const SizedBox.shrink();
    if (el.type == ElementType.weatherIconClock) {
      return Image.asset(
        AssetPaths.weatherIcon("0"),
        width: 40,
        height: 40,
        fit: BoxFit.contain,
      );
    }
    if (el.type.isWeatherText) {
      return _weatherText(
        el,
        const {
          ElementType.weatherTemp: '24°C',
          ElementType.weatherDesc: 'Clear',
          ElementType.weatherCity: 'Cuttack',
          ElementType.weatherTemperatureRange: '20-30°C',
          ElementType.weatherAqi: 'AQI 42',
          ElementType.weatherHumidity: '65%',
        }[el.type]!,
      );
    }
    if (el.type == ElementType.calendarGrid) return _calendar(el);
    if (el.type.isUnlockControl) {
      return _unlock(el);
    }
    if (el.type == ElementType.batteryText ||
        el.type == ElementType.batteryLevel) {
      return _weatherText(el, '75%');
    }
    if (el.type.isHealth) {
      return _weatherText(
        el,
        const {
          ElementType.stepsCount: '6240',
          ElementType.stepsGoal: '10000',
          ElementType.stepsDistance: '4.2 km',
          ElementType.stepsCalories: '248 kcal',
          ElementType.stepsDuration: '35 min',
          ElementType.stepsSummary: 'Goal reached',
        }[el.type]!,
      );
    }
    if (el.type.isShape) {
      return CustomPaint(
        size: Size(
          el.width / AppConstants.screenRatio,
          (el.type == ElementType.circleShape || el.type == ElementType.arcShape
                  ? el.width
                  : el.height) /
              AppConstants.screenRatio,
        ),
        painter: _GeometryPainter(
          el,
          el.effectiveProgressSource.fraction(
            time: DateTime.now(),
            batteryLevel: 75,
            stepCount: 6240,
            stepGoal: 10000,
          ),
        ),
      );
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

    if (el.type.defaultIconAsset case final asset?) {
      return SvgPicture.asset(
        AssetPaths.iconSvg(IconVariant.u1, asset),
        width: el.width / AppConstants.screenRatio,
        height: el.height / AppConstants.screenRatio,
      );
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

  Widget _weatherText(LockElement el, String text) {
    return Text(
      text,
      style: fontTextStyle(
        font: 'Roboto',
        color: el.color,
        fontSize: el.fontSize,
        fontWeight: el.fontWeight,
        height: 1,
      ),
    );
  }

  Widget _calendar(LockElement element) {
    final now = DateTime.now();
    final dates = element.calendarDates(now);
    final width = element.width / AppConstants.screenRatio;
    final rowHeight =
        element.height / AppConstants.screenRatio / element.calendarDisplayRows;
    final style = fontTextStyle(
      font: 'Roboto',
      fontSize: element.fontSize,
      color: element.color,
      fontWeight: element.fontWeight,
      height: 1,
    );
    return SizedBox(
      width: width,
      height: rowHeight * element.calendarDisplayRows,
      child: Column(
        children: [
          if (element.calendarShowMonth)
            SizedBox(
              height: rowHeight,
              child: Center(
                child: Text(DateFormat('MMMM yyyy').format(now), style: style),
              ),
            ),
          if (element.calendarShowWeekdays)
            SizedBox(
              height: rowHeight,
              child: Row(
                children: [
                  for (final day in ['S', 'M', 'T', 'W', 'T', 'F', 'S'])
                    Expanded(
                      child: Center(child: Text(day, style: style)),
                    ),
                ],
              ),
            ),
          for (var row = 0; row < element.calendarWeekRows; row++)
            SizedBox(
              height: rowHeight,
              child: Row(
                children: [
                  for (var column = 0; column < 7; column++)
                    Expanded(
                      child: Container(
                        key: ValueKey('calendar-cell-${row * 7 + column}'),
                        decoration: BoxDecoration(
                          color:
                              dates[row * 7 + column]?.year == now.year &&
                                  dates[row * 7 + column]?.month == now.month &&
                                  dates[row * 7 + column]?.day == now.day
                              ? element.colorSecondary
                              : null,
                          borderRadius: BorderRadius.circular(element.radius),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          dates[row * 7 + column]?.day.toString() ?? '',
                          style: style,
                        ),
                      ),
                    ),
                ],
              ),
            ),
        ],
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
      ElementType.weekClock =>
        el.isShort
            ? 'Wed'
            : el.isWrap
            ? _wrapText('Wednesday')
            : 'Wednesday',
      ElementType.monthClock => el.isShort ? 'Feb' : 'February',
      ElementType.dateClock => '08',
      _ => '',
    };

    if (el.useSeparateColors &&
        (el.type == ElementType.hourClock ||
            el.type == ElementType.minClock ||
            el.type == ElementType.secClock) &&
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
              font: el.font,
              fontSize: 35,
              fontWeight: el.fontWeight,
              height: 1,
              color: el.colorDigit1,
            ),
            strokeWidth: el.strokeWidth,
            strokeColor: el.strokeColorDigit1.a > 0
                ? el.strokeColorDigit1
                : el.strokeColor,
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
              font: el.font,
              fontSize: 35,
              fontWeight: el.fontWeight,
              height: 1,
              color: el.colorDigit2,
            ),
            strokeWidth: el.strokeWidth,
            strokeColor: el.strokeColorDigit2.a > 0
                ? el.strokeColorDigit2
                : el.strokeColor,
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
      style: fontTextStyle(
        font: el.font,
        fontSize: 35,
        fontWeight: el.fontWeight,
        height: 1,
        color: el.color,
      ),
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
                    filter: ImageFilter.blur(
                      sigmaX: frostBlur,
                      sigmaY: frostBlur,
                    ),
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
                        Color(
                          0x00FFFFFF,
                        ), // Ultra-clear center (shows background sharp & magnified)
                        Color(
                          0x08FF3366,
                        ), // Red-orange chromatic dispersion fringe
                        Color(
                          0x1033CCFF,
                        ), // Cyan-blue chromatic dispersion fringe
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
                        Color(
                          0xCCFFFFFF,
                        ), // 80% light specular highlight at top-left
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
            filter: ImageFilter.blur(
              sigmaX: el.blurRadius,
              sigmaY: el.blurRadius,
            ),
            child: base,
          ),
        );
      } else {
        containerWidget = base;
      }
    }

    return containerWidget;
  }

  Widget _unlock(LockElement element) => UnlockControlPreview(element: element);

  Widget _notification(LockElement el) {
    const ratio = AppConstants.screenRatio;
    Widget child = SizedBox(
      width: 1024 / ratio,
      height: 206 * el.notificationLimit.clamp(1, 10) / ratio,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (
            var index = 0;
            index < el.notificationLimit.clamp(1, 10);
            index++
          )
            if (!_dismissedNotifications.contains(index))
              Padding(
                padding: const EdgeInsets.only(bottom: 20 / ratio),
                child: Container(
                  height: 186 / ratio,
                  width: 1024 / ratio,
                  decoration: BoxDecoration(
                    color: el.colorSecondary,
                    borderRadius: BorderRadius.circular(el.radius),
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        left: 36 / ratio,
                        top: 32 / ratio,
                        width: 96 / ratio,
                        height: 96 / ratio,
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFC300),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Icon(Icons.android, size: 20),
                        ),
                      ),
                      Positioned(
                        left: 156 / ratio,
                        top: 32 / ratio,
                        width: 500 / ratio,
                        child: Text(
                          'Notification',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: el.color,
                            fontSize: 44 / ratio,
                            fontWeight: el.fontWeight,
                            height: 1,
                          ),
                        ),
                      ),
                      Positioned(
                        left: 156 / ratio,
                        top: 100 / ratio,
                        width: 740 / ratio,
                        child: Text(
                          'Details',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: el.color,
                            fontSize: 34 / ratio,
                            fontWeight: el.fontWeight,
                            height: 1,
                          ),
                        ),
                      ),
                      Positioned(
                        right: 124 / ratio,
                        top: 40 / ratio,
                        width: 220 / ratio,
                        child: Text(
                          '4:54 pm',
                          textAlign: TextAlign.right,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: el.color,
                            fontSize: 28 / ratio,
                            height: 1,
                          ),
                        ),
                      ),
                      Positioned(
                        left: 920 / ratio,
                        top: 28 / ratio,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => setState(
                            () => _dismissedNotifications.add(index),
                          ),
                          child: SizedBox(
                            width: 80 / ratio,
                            height: 80 / ratio,
                            child: Center(
                              child: Icon(
                                Icons.close_rounded,
                                size: 14,
                                color: el.color,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
        ],
      ),
    );

    if (el.blurRadius > 0) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(el.radius),
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: el.blurRadius,
            sigmaY: el.blurRadius,
          ),
          child: child,
        ),
      );
    }

    return child;
  }

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
    if (el.type.isDateTime) {
      try {
        t = DateFormat(el.text).format(DateTime.now());
      } on FormatException {
        t = el.text;
      }
    } else {
      for (final entry in _gv.entries) {
        t = t.replaceAll(entry.key, entry.value);
      }
    }

    final textStyle = fontTextStyle(
      font: 'Roboto',
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

class _GeometryPainter extends CustomPainter {
  const _GeometryPainter(this.element, this.progress);
  final LockElement element;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final stroke = Paint()
      ..color = element.color
      ..style = PaintingStyle.stroke
      ..strokeWidth = element.shapeStrokeWidth / AppConstants.screenRatio
      ..strokeCap = StrokeCap.round;
    final fill = Paint()..color = element.colorSecondary;
    void draw(Paint paint) {
      switch (element.type) {
        case ElementType.rectangleShape:
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              rect,
              Radius.circular(element.radius / AppConstants.screenRatio),
            ),
            paint,
          );
        case ElementType.circleShape:
          canvas.drawCircle(rect.center, size.width / 2, paint);
        case ElementType.ellipseShape:
          canvas.drawOval(rect, paint);
        case ElementType.lineShape:
          canvas.drawLine(rect.topLeft, rect.bottomRight, paint);
        case ElementType.arcShape:
          canvas.drawArc(
            rect,
            element.startAngle * pi / 180,
            element.sweepAngle * progress * pi / 180,
            false,
            paint,
          );
        default:
          break;
      }
    }

    if (element.type != ElementType.lineShape &&
        element.type != ElementType.arcShape) {
      draw(fill);
    }
    if (element.shapeStrokeWidth > 0) {
      if (element.type == ElementType.arcShape) {
        canvas.drawArc(
          rect,
          element.startAngle * pi / 180,
          element.sweepAngle * pi / 180,
          false,
          Paint()
            ..color = element.arcTrackColor
            ..style = PaintingStyle.stroke
            ..strokeWidth = element.shapeStrokeWidth / AppConstants.screenRatio
            ..strokeCap = StrokeCap.round,
        );
      }
      draw(stroke);
    }
  }

  @override
  bool shouldRepaint(covariant _GeometryPainter oldDelegate) =>
      oldDelegate.element != element || oldDelegate.progress != progress;
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
