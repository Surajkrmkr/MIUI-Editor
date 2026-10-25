import 'dart:io';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:theme_core/theme_core.dart';
import 'package:theme_core/lockscreen_layout.dart' show AnalogClockType;
import 'art/analog_clock_art.dart';
import 'art/calendar_style_art.dart';
import 'art/shortcut_set_art.dart';
import 'font_text_style.dart';
import 'gradient_text.dart';
import 'lock_element.dart';
import 'lockscreen_clock.dart';
import 'unlock_control_preview.dart';

/// Finds an exported lockscreen image: [relativePath] is under
/// `lockscreen/advance`, without the `.png`.
typedef LockscreenImageResolver = File? Function(String relativePath);

/// What one element looks like on the lockscreen canvas (sample text and
/// numbers stand in for live data). Placement is [LockElementFrame]'s job.
class LockElementView extends StatefulWidget {
  const LockElementView({
    super.key,
    required this.element,
    this.resolveImage = noLockscreenImages,
  });

  final LockElement element;
  final LockscreenImageResolver resolveImage;

  @override
  State<LockElementView> createState() => _LockElementViewState();
}

File? noLockscreenImages(String relativePath) => null;

class _LockElementViewState extends State<LockElementView> {
  final _dismissedNotifications = <int>{};

  @override
  void didUpdateWidget(covariant LockElementView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.element.notificationLimit !=
        widget.element.notificationLimit) {
      _dismissedNotifications.clear();
    }
  }

  @override
  Widget build(BuildContext context) => _buildChild(widget.element);

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
    if (el.type == ElementType.depthLayer) {
      final file = widget.resolveImage('depth/${el.name}');
      if (file == null || !file.existsSync()) return const SizedBox.shrink();
      return Image.file(
        file,
        width: lockscreenViewWidth,
        height: lockscreenViewHeight,
        fit: BoxFit.cover,
        gaplessPlayback: true,
      );
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
          el.width / lockscreenScreenRatio,
          (el.type == ElementType.circleShape || el.type == ElementType.arcShape
                  ? el.width
                  : el.height) /
              lockscreenScreenRatio,
        ),
        painter: _GeometryPainter(
          el,
          el.effectiveProgressSource.fraction(
            time: lockscreenNow(),
            batteryLevel: 75,
            stepCount: 6240,
            stepGoal: 10000,
          ),
        ),
      );
    }
    if (el.type == ElementType.shortcutSet) {
      return ShortcutSetPreview(element: el, resolveImage: widget.resolveImage);
    }
    if (el.type.isAnalog) return AnalogClockPreview(element: el);
    if (el.type.isClock) return _clock(el);
    if (el.type.isContainer) return _container(el);
    if (el.type == ElementType.notification) return _notification(el);
    if (el.type.isText) return _text(el);

    // PNG / icon / music: the exported file if there is one.
    final resolvedPath = el.path.isNotEmpty ? el.path : el.type.defaultPath;
    if (resolvedPath.isNotEmpty) {
      // Element paths use Windows separators, e.g. \icon\camera.
      final normalized = resolvedPath.replaceAll(r'\', '/');
      final relative = normalized.startsWith('/')
          ? normalized.substring(1)
          : normalized;
      final file = widget.resolveImage(relative);
      if (file != null && file.existsSync()) {
        return Image.memory(
          file.readAsBytesSync(),
          height: el.height / lockscreenScreenRatio,
          width: el.width / lockscreenScreenRatio,
          gaplessPlayback: true,
        );
      }
    }

    if (el.type.defaultIconAsset case final asset?) {
      final w = el.width / lockscreenScreenRatio;
      final h = el.height / lockscreenScreenRatio;
      return SvgPicture.asset(
        AssetPaths.iconSvg(IconVariant.u1, asset),
        width: w,
        height: h,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => Icon(
          el.type == ElementType.flashlightIcon
              ? Icons.flashlight_on_rounded
              : Icons.apps_rounded,
          size: min(w, h),
          color: el.color,
        ),
      );
    }

    // Fallback placeholder
    return Container(
      height: el.height / lockscreenScreenRatio,
      width: el.width / lockscreenScreenRatio,
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
    if (element.calendarStyle != CalendarStyle.classic) {
      return CalendarStylePreview(element: element);
    }
    final now = lockscreenNow();
    final dates = element.calendarDates(now);
    final width = element.width / lockscreenScreenRatio;
    final rowHeight =
        element.height / lockscreenScreenRatio / element.calendarDisplayRows;
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
            isFrostedGlass: el.isFrostedGlass,
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
            isFrostedGlass: el.isFrostedGlass,
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
      isFrostedGlass: el.isFrostedGlass,
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
    const ratio = lockscreenScreenRatio;
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
        t = DateFormat(el.text).format(lockscreenNow());
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
      ..strokeWidth = element.shapeStrokeWidth / lockscreenScreenRatio
      ..strokeCap = StrokeCap.round;
    final fill = Paint()..color = element.colorSecondary;
    if (element.type == ElementType.rectangleShape &&
        element.effectiveProgressSource != ArcProgressSource.none) {
      final radius = Radius.circular(element.radius / lockscreenScreenRatio);
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, radius),
        Paint()..color = element.arcTrackColor,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Offset.zero & Size(size.width * progress, size.height),
          radius,
        ),
        Paint()..color = element.color,
      );
      return;
    }
    void draw(Paint paint) {
      switch (element.type) {
        case ElementType.rectangleShape:
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              rect,
              Radius.circular(element.radius / lockscreenScreenRatio),
            ),
            paint,
          );
        case ElementType.circleShape:
          canvas.drawCircle(rect.center, size.width / 2, paint);
        case ElementType.ellipseShape:
          canvas.drawOval(rect, paint);
        case ElementType.lineShape:
          canvas.drawLine(rect.centerLeft, rect.centerRight, paint);
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
            ..strokeWidth = element.shapeStrokeWidth / lockscreenScreenRatio
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
