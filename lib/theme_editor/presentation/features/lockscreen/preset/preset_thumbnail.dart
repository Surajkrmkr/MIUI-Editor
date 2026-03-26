import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/asset_paths.dart';
import '../../../../domain/entities/element_widget.dart';
import '../../../common/widgets/gradient_text.dart';
import '../../../providers/wallpaper_provider.dart';

/// Static, non-interactive phone-canvas preview of a preset's elements.
/// Renders at [thumbnailWidth] px wide (same 9:19.5 aspect ratio as the editor).
class PresetThumbnail extends ConsumerWidget {
  const PresetThumbnail({
    super.key,
    required this.elements,
    this.thumbnailWidth = 120,
  });

  final List<LockElement> elements;
  final double thumbnailWidth;

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
                ...elements.map((el) => _StaticElement(el: el)),
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
  const _StaticElement({required this.el});
  final LockElement el;

  static const _hw = AppConstants.screenHeight;
  static const _ww = AppConstants.screenWidth;

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

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: el.dx,
      top: el.dy,
      child: Transform.scale(
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
      ),
    );
  }

  Widget _buildChild() {
    if (el.type == ElementType.swipeUpUnlock) return const SizedBox.shrink();
    if (el.type.isClock) return _clock();
    if (el.type.isContainer) return _container();
    if (el.type == ElementType.notification) return _notification();
    if (el.type.isText) return _text();
    if (el.type == ElementType.weatherIconClock) {
      return Image.asset(AssetPaths.weatherIcon("0"), height: 40);
    }
    // Icon / PNG / music — subtle placeholder
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
        fontFamily: el.font,
        fontSize: 30,
        height: 1,
        color: el.color,
      ),
    );
  }

  Widget _container() => Container(
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

  Widget _notification() => Container(
        height: 60,
        width: 250,
        decoration: BoxDecoration(
          color: el.colorSecondary,
          borderRadius: BorderRadius.circular(el.radius),
        ),
        child: Row(
          children: [
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
                Text('Details',
                    style: TextStyle(color: el.color, fontSize: 10)),
              ],
            ),
          ],
        ),
      );

  Widget _text() {
    var t = el.text;
    final map = el.type.isDateTime ? _dt : _gv;
    for (final e in map.entries) {
      t = t.replaceAll(e.key, e.value);
    }
    return Text(
      t,
      style: TextStyle(
        color: el.color,
        fontSize: el.fontSize,
        fontWeight: el.fontWeight,
        height: 1,
      ),
    );
  }
}
