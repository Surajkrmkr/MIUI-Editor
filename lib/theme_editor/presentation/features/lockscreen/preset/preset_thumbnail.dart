import 'dart:io';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/font_utils.dart';
import '../../../../core/constants/asset_paths.dart';
import '../../../../domain/entities/element_widget.dart';
import '../../../common/widgets/gradient_text.dart';
import '../../../providers/wallpaper_provider.dart';

/// Static phone-canvas preview of a preset's elements.
///
/// Colour adaptation priority:
///   1. [colorMap] — explicit per-original-colour replacement (used by preview dialog).
///   2. [accentColor] — replaces every non-white colour with a single accent (card thumbnails).
///   3. No adaptation — original preset colours.
class PresetThumbnail extends ConsumerWidget {
  const PresetThumbnail({
    super.key,
    required this.elements,
    this.thumbnailWidth = 120,
    this.accentColor,
    this.colorMap,
  });

  final List<LockElement> elements;
  final double thumbnailWidth;
  final Color? accentColor;

  /// Per-colour remapping. Keys are original element colours; values are
  /// the replacement colours chosen by the user.
  final Map<Color, Color>? colorMap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scale = thumbnailWidth / AppConstants.screenWidth;
    final thumbnailHeight = AppConstants.screenHeight * scale;

    final wallState = ref.watch(wallpaperProvider);
    String? bgPath;
    if (wallState.paths.isNotEmpty) {
      bgPath = wallState.paths[wallState.index];
    }
    final hasBg = bgPath != null && File(bgPath).existsSync();

    return SizedBox(
      width: thumbnailWidth,
      height: thumbnailHeight,
      child: OverflowBox(
        alignment: Alignment.topLeft,
        maxWidth: AppConstants.screenWidth,
        maxHeight: AppConstants.screenHeight,
        child: Transform.scale(
          scale: scale,
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: AppConstants.screenWidth,
            height: AppConstants.screenHeight,
            child: Stack(
              children: [
                if (hasBg)
                  Image.memory(
                    File(bgPath).readAsBytesSync(),
                    gaplessPlayback: true,
                    fit: BoxFit.cover,
                    width: AppConstants.screenWidth,
                    height: AppConstants.screenHeight,
                  )
                else
                  Container(
                    width: AppConstants.screenWidth,
                    height: AppConstants.screenHeight,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0xFF0D1B2A), Color(0xFF1A2744)],
                      ),
                    ),
                  ),
                ...elements
                    .where((el) => el.isVisible)
                    .map((el) => Positioned(
                          left: el.dx,
                          top: el.dy,
                          child: _StaticElement(
                            el: el,
                            accentColor: accentColor,
                            colorMap: colorMap,
                          ),
                        )),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _StaticElement extends StatelessWidget {
  const _StaticElement({required this.el, this.accentColor, this.colorMap});

  final LockElement el;
  final Color? accentColor;
  final Map<Color, Color>? colorMap;

  static const _hw = AppConstants.screenHeight;
  static const _ww = AppConstants.screenWidth;

  static const _dt = {
    'dd': '08', 'E': 'Wed', 'MM': '02', 'yy': '22',
    'aa': 'PM', 'hh': '02', 'mm': '36', 'ss': '06',
  };
  static const _gv = {
    '#battery_level': '100', '#temp': '24',
    '@cityName': 'Cuttack', '@airQuality': 'Good',
    "'": '', '+': '',
  };

  /// Colour adaptation:
  /// - [colorMap] lookup wins if present.
  /// - [accentColor] replaces non-white colours.
  /// - White (#FFFFFFFF) is always kept as-is.
  Color _adapt(Color c) {
    if (colorMap != null) return colorMap![c] ?? c;
    if (accentColor == null) return c;
    if (c.toARGB32() == 0xFFFFFFFF) return c;
    return accentColor!;
  }

  @override
  Widget build(BuildContext context) {
    return Transform.scale(
      scale: el.scale,
      child: Transform.rotate(
        angle: -el.angle * pi / 180,
        child: SizedBox(
          height: _hw,
          width: _ww,
          child: Align(
            alignment: el.align,
            child: _buildChild(),
          ),
        ),
      ),
    );
  }

  Widget _buildChild() {
    if (el.type == ElementType.swipeUpUnlock ||
        el.type == ElementType.tapToUnlock ||
        el.type == ElementType.slideToUnlock) {
      return const SizedBox.shrink();
    }
    if (el.type == ElementType.weatherIconClock) {
      return Image.asset(AssetPaths.weatherIcon("0"), height: 40);
    }
    if (el.type.isClock) return _clock();
    if (el.type.isContainer) return _container();
    if (el.type == ElementType.notification) return _notification();
    if (el.type.isText) return _text();
    return Container(
      height: el.height / AppConstants.screenRatio,
      width: el.width / AppConstants.screenRatio,
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(el.radius),
      ),
    );
  }

  Widget _clock() {
    final txt = switch (el.type) {
      ElementType.hourClock  => '02',
      ElementType.minClock   => '36',
      ElementType.secClock   => '55',
      ElementType.dotClock   => ':',
      ElementType.dotClock2  => ':',
      ElementType.amPmClock  => 'AM',
      ElementType.weekClock  => el.isShort
          ? 'Wed'
          : el.isWrap
              ? _wrapText('Wednesday')
              : 'Wednesday',
      ElementType.monthClock => el.isShort ? 'Feb' : 'February',
      ElementType.dateClock  => '08',
      _ => '',
    };

    if (el.type == ElementType.analogClockBg  ||
        el.type == ElementType.analogHourHand ||
        el.type == ElementType.analogMinHand  ||
        el.type == ElementType.analogSecHand) {
      return Container(
        height: el.height / AppConstants.screenRatio,
        width:  el.width  / AppConstants.screenRatio,
        decoration: BoxDecoration(
          color: _adapt(el.color).withAlpha(60),
          shape: BoxShape.circle,
        ),
      );
    }

    if (el.useSeparateColors &&
        (el.type == ElementType.hourClock ||
         el.type == ElementType.minClock  ||
         el.type == ElementType.secClock) &&
        txt.length == 2) {
      final c1 = _adapt(el.colorDigit1);
      final c2 = _adapt(el.colorDigit2);
      final sc1 = _adapt(el.strokeColorDigit1.a > 0 ? el.strokeColorDigit1 : el.strokeColor);
      final sc2 = _adapt(el.strokeColorDigit2.a > 0 ? el.strokeColorDigit2 : el.strokeColor);
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GradientText(txt[0],
              gradient: LinearGradient(colors: [c1, c1],
                  begin: el.gradStartAlign as Alignment,
                  end: el.gradEndAlign as Alignment),
              style: fontTextStyle(font: el.font, fontSize: 35, height: 1, color: c1),
              strokeWidth: el.strokeWidth,
              strokeColor: sc1,
              blurRadius: el.blurRadius,
              isLiquidGlass: el.isLiquidGlass),
          GradientText(txt[1],
              gradient: LinearGradient(colors: [c2, c2],
                  begin: el.gradStartAlign as Alignment,
                  end: el.gradEndAlign as Alignment),
              style: fontTextStyle(font: el.font, fontSize: 35, height: 1, color: c2),
              strokeWidth: el.strokeWidth,
              strokeColor: sc2,
              blurRadius: el.blurRadius,
              isLiquidGlass: el.isLiquidGlass),
        ],
      );
    }

    final c  = _adapt(el.color);
    final c2 = _adapt(el.colorSecondary);
    final sc = _adapt(el.strokeColor);
    return GradientText(
      txt,
      gradient: LinearGradient(
        begin: el.gradStartAlign as Alignment,
        end:   el.gradEndAlign   as Alignment,
        colors: [c, c2],
      ),
      style: fontTextStyle(font: el.font, fontSize: 35, height: 1, color: c),
      strokeWidth: el.strokeWidth,
      strokeColor: sc,
      blurRadius: el.blurRadius,
      isLiquidGlass: el.isLiquidGlass,
    );
  }

  Widget _container() {
    if (el.isLiquidGlass) {
      final frostBlur = el.blurRadius > 0 ? el.blurRadius : 0.0;
      return Container(
        height: el.height,
        width:  el.width,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(el.radius),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.16),
              blurRadius: 28,
              offset: const Offset(0, 8),
              spreadRadius: -2,
            ),
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
              if (frostBlur > 0)
                Positioned.fill(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: frostBlur, sigmaY: frostBlur),
                    child: const SizedBox.expand(),
                  ),
                ),
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(el.radius),
                    color: const Color(0xFFD9D9D9).withValues(alpha: 0.20),
                  ),
                ),
              ),
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(el.radius),
                    gradient: const RadialGradient(
                      center: Alignment(-0.2, -0.2),
                      radius: 1.1,
                      colors: [
                        Color(0x00FFFFFF),
                        Color(0x08FF3366),
                        Color(0x1033CCFF),
                        Color(0x28FFFFFF),
                      ],
                      stops: [0.65, 0.85, 0.94, 1.0],
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(el.radius),
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xCCFFFFFF),
                        Color(0x22FFFFFF),
                        Color(0x00FFFFFF),
                        Color(0x55FFFFFF),
                      ],
                      stops: [0.0, 0.25, 0.70, 1.0],
                    ),
                    border: Border.all(
                      width: el.borderWidth > 0 ? el.borderWidth : 1.5,
                      color: const Color(0x99FFFFFF),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final c  = _adapt(el.color);
    final c2 = _adapt(el.colorSecondary);
    Widget child = Container(
      height: el.height,
      width:  el.width,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(el.radius),
        border: el.borderWidth > 0
            ? Border.all(width: el.borderWidth, color: _adapt(el.borderColor))
            : null,
        gradient: LinearGradient(
          begin: el.gradStartAlign as Alignment,
          end:   el.gradEndAlign   as Alignment,
          colors: [c, c2],
        ),
      ),
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

  // "Wednesday" -> "Wed\nnesday": first 3 letters, then the remainder.
  String _wrapText(String input) {
    if (input.length <= 3) return input;
    return '${input.substring(0, 3)}\n${input.substring(3)}';
  }

  Widget _notification() {
    final c = _adapt(el.color);
    Widget child = Container(
      height: 60,
      width: 250,
      decoration: BoxDecoration(
        color: _adapt(el.colorSecondary),
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
            Text('Notification', style: TextStyle(color: c, fontSize: 10)),
            Text('Details',      style: TextStyle(color: c, fontSize: 10)),
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

  Widget _text() {
    var t = el.text;
    final map = el.type.isDateTime ? _dt : _gv;
    for (final e in map.entries) {
      t = t.replaceAll(e.key, e.value);
    }
    final color = _adapt(el.color);
    final textStyle = fontTextStyle(
      font: el.font,
      color: color,
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
                ..color = color,
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

/// Extracts all unique non-white colours used across a list of elements.
/// Used by the preview dialog to build the per-colour remapping UI.
Set<Color> extractPresetColors(List<LockElement> elements) {
  const white = 0xFFFFFFFF;
  final seen = <Color>{};
  for (final el in elements) {
    for (final c in [
      el.color, el.colorSecondary, el.colorDigit1, el.colorDigit2,
    ]) {
      if (c.toARGB32() != white) seen.add(c);
    }
  }
  return seen;
}
