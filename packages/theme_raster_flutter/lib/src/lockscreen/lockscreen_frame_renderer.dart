import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:ui';
import 'dart:ui' as ui show Image;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:path/path.dart' as pth;
import 'package:screenshot/screenshot.dart';
import 'package:theme_core/theme_core.dart';
import 'package:theme_core/lockscreen_layout.dart' show AnalogClockType;

import 'art/analog_clock_art.dart';
import 'art/calendar_style_art.dart';
import 'art/day_strip_art.dart';
import 'art/gauge_art.dart';
import 'art/ticker_art.dart';
import 'art/shortcut_set_art.dart';
import 'art/unlock_skin_art.dart';
import 'font_text_style.dart';
import 'gradient_text.dart';
import 'lock_element.dart';
import 'surface_fx.dart';
import 'wallpaper_glass.dart';

class LockscreenFrameRenderer {
  const LockscreenFrameRenderer({this.batchSize = 8});

  /// Number of frames captured in parallel per batch.
  /// 8 is a safe default for desktop — increase to 12-16 on fast machines.
  final int batchSize;

  Future<Failure?> render({
    required BuildContext context,
    required List<LockElement> elements,
    required ThemeLayout layout,
    required void Function(int done, int total) onProgress,
    // Bottom first; defaults to the theme's lock wallpaper under bg.png.
    List<String?>? glassBackground,
  }) async {
    var glass = const <ui.Image>[];
    try {
      final lsAdv = '${layout.lockscreenAdvance}${pth.separator}';
      final exportable = elements
          .where(
            (e) =>
                e.isVisible &&
                (e.type.isExportable ||
                    e.type.isIcon ||
                    e.type.isUnlockControl),
          )
          .toList();

      if (exportable.isEmpty) return null;

      // Reuse the theme's exported app icons for icon widgets not yet copied.
      for (final el in exportable.where(
        (e) => e.type.isIcon && e.path.isEmpty,
      )) {
        final relative = el.type.defaultPath
            .replaceAll(r'\', '/')
            .replaceFirst('/', '');
        final target = File(pth.normalize('$lsAdv$relative.png'));
        final asset = el.type.defaultIconAsset;
        if (target.existsSync() || asset == null) continue;
        final source = File(pth.join(layout.iconsXxhdpi, '$asset.png'));
        if (!source.existsSync()) continue;
        await target.parent.create(recursive: true);
        await source.copy(target.path);
      }

      // Build the full flat list of (widget, destPath) pairs up front
      // so we know the exact total before starting.
      final frames = <_Frame>[];
      for (final el in exportable) {
        frames.addAll(_framesFor(el, lsAdv, layout.iconsXxhdpi));
      }

      // Pre-create all directories (fast — do sequentially before batching)
      final dirs = frames.map((f) => File(f.path).parent.path).toSet();
      for (final d in dirs) {
        await Directory(d).create(recursive: true);
      }

      int done = 0;

      if (exportable.any((e) => e.isWallpaperGlass)) {
        glass = await WallpaperGlassScope.decode(
          glassBackground ??
              [
                File(layout.defaultLockWallpaper).existsSync()
                    ? layout.defaultLockWallpaper
                    : layout.defaultWallpaper,
                pth.join(layout.lockscreenAdvance, 'bg.png'),
              ],
        );
      }

      // ── Parallel batch export ─────────────────────────────────────────────
      for (int i = 0; i < frames.length; i += batchSize) {
        final batch = frames.sublist(
          i,
          (i + batchSize).clamp(0, frames.length),
        );

        await Future.wait(
          batch.map((frame) async {
            final bytes = await ScreenshotController().captureFromWidget(
              WallpaperGlassScope(images: glass, child: frame.widget),
              context: context,
              pixelRatio: 3,
            );
            await File(frame.path).writeAsBytes(bytes);
            // Progress is updated after each frame, even inside a batch,
            // because Future.wait runs them concurrently not simultaneously.
            onProgress(++done, frames.length);
          }),
        );
      }

      return null;
    } catch (e) {
      return ExportFailure(e.toString());
    } finally {
      for (final image in glass) {
        image.dispose();
      }
    }
  }

  // ── Build frame list for a single element ─────────────────────────────────

  List<_Frame> _framesFor(LockElement el, String lsAdv, String iconsDir) {
    String dir(String sub) => '$lsAdv$sub${pth.separator}';

    if (el.type.defaultIconAsset case final asset?) {
      final relative = (el.path.isEmpty ? el.type.defaultPath : el.path)
          .replaceAll(r'\', '/');
      final path = pth.normalize(
        '$lsAdv${relative.startsWith('/') ? relative.substring(1) : relative}.png',
      );
      if (File(path).existsSync()) return [];
      return [
        _Frame(
          widget: SizedBox(
            width: el.width,
            height: el.height,
            child: SvgPicture.asset(AssetPaths.iconSvg(IconVariant.u1, asset)),
          ),
          path: path,
        ),
      ];
    }

    switch (el.type) {
      case ElementType.tapToUnlock:
      case ElementType.slideToUnlock:
      case ElementType.dragToUnlock:
        final skinParts = [
          if (el.unlockSkin != UnlockSkin.classic)
            for (final part in UnlockSkinArt.exportParts(el).entries)
              _Frame(
                widget: Directionality(
                  textDirection: TextDirection.ltr,
                  child: part.value,
                ),
                path: pth.normalize(
                  '${dir("unlock")}${el.name}${part.key}.png',
                ),
              ),
        ];
        if (el.unlockSkin == UnlockSkin.meet ||
            el.effectiveUnlockIcon == UnlockIcon.none) {
          return skinParts;
        }
        final customPng = el.effectiveUnlockIcon == UnlockIcon.customPng;
        if (customPng &&
            (el.unlockIconPath.isEmpty ||
                !File(el.unlockIconPath).existsSync())) {
          throw FileSystemException(
            'Custom unlock PNG not found. Choose a PNG for ${el.label}.',
            el.unlockIconPath,
          );
        }
        return [
          ...skinParts,
          _Frame(
            widget: Directionality(
              textDirection: TextDirection.ltr,
              child: SizedBox(
                width: 128,
                height: 128,
                child: customPng
                    ? Image.memory(
                        File(el.unlockIconPath).readAsBytesSync(),
                        fit: BoxFit.contain,
                      )
                    : Icon(
                        el.effectiveUnlockIcon.icon,
                        size: 128,
                        color: el.color,
                      ),
              ),
            ),
            path: pth.normalize('${dir("unlock")}${el.name}.png'),
          ),
        ];
      case ElementType.hourClock:
        return List.generate(
          13,
          (i) => _Frame(
            widget: _phoneFrame(
              el,
              _clockText(el, i.toString().padLeft(2, '0')),
            ),
            path: pth.normalize('${dir("hour")}hour_$i.png'),
          ),
        );

      case ElementType.minClock:
        return List.generate(
          60,
          (i) => _Frame(
            widget: _phoneFrame(
              el,
              _clockText(el, i.toString().padLeft(2, '0')),
            ),
            path: pth.normalize('${dir("min")}min_$i.png'),
          ),
        );

      case ElementType.secClock:
        return List.generate(
          60,
          (i) => _Frame(
            widget: _phoneFrame(
              el,
              _clockText(el, i.toString().padLeft(2, '0')),
            ),
            path: pth.normalize('${dir("sec")}sec_$i.png'),
          ),
        );

      case ElementType.dotClock:
        return [
          _Frame(
            widget: _phoneFrame(el, _clockText(el, ':')),
            path: pth.normalize('${dir("dot")}dot.png'),
          ),
        ];

      case ElementType.dotClock2:
        return [
          _Frame(
            widget: _phoneFrame(el, _clockText(el, ':')),
            path: pth.normalize('${dir("dot")}dot2.png'),
          ),
        ];

      case ElementType.amPmClock:
        return List.generate(
          2,
          (i) => _Frame(
            widget: _phoneFrame(el, _clockText(el, i == 0 ? 'AM' : 'PM')),
            path: pth.normalize('${dir("ampm")}ampm_$i.png'),
          ),
        );

      case ElementType.weekClock:
        return List.generate(7, (i) {
          final raw = AssetPaths.weekNames[i]!;
          final txt = el.isShort
              ? raw.substring(0, 3)
              : el.isWrap
              ? _wrapText(raw)
              : raw;
          return _Frame(
            widget: _phoneFrame(el, _clockText(el, txt)),
            path: pth.normalize('${dir("week")}week_$i.png'),
          );
        });

      case ElementType.monthClock:
        return List.generate(12, (i) {
          final raw = AssetPaths.monthNames[i]!;
          return _Frame(
            widget: _phoneFrame(
              el,
              _clockText(el, el.isShort ? raw.substring(0, 3) : raw),
            ),
            path: pth.normalize('${dir("month")}month_${i + 1}.png'),
          );
        });

      case ElementType.dateClock:
        return List.generate(
          31,
          (i) => _Frame(
            widget: _phoneFrame(
              el,
              _clockText(el, (i + 1).toString().padLeft(2, '0')),
            ),
            path: pth.normalize('${dir("date")}date_${i + 1}.png'),
          ),
        );

      case ElementType.weatherIconClock:
        return AssetPaths.weatherCodes
            .map(
              (code) => _Frame(
                widget: SizedBox(
                  width: 40,
                  height: 40,
                  child: Image.asset(
                    AssetPaths.weatherIcon(code.toString()),
                    fit: BoxFit.contain,
                  ),
                ),
                path: pth.normalize('${dir("weather")}weather_$code.png'),
              ),
            )
            .toList();

      default:
        if (el.type == ElementType.gaugeSet) {
          return [
            _Frame(
              widget: Directionality(
                textDirection: TextDirection.ltr,
                child: GaugeArt.exportPanel(el),
              ),
              path: pth.normalize('${dir("calendar")}${el.name}_gauges.png'),
            ),
          ];
        }
        if (el.type == ElementType.countdownTicker) {
          return [
            _Frame(
              widget: Directionality(
                textDirection: TextDirection.ltr,
                child: TickerArt.exportPanel(el),
              ),
              path: pth.normalize('${dir("calendar")}${el.name}_ticker.png'),
            ),
          ];
        }
        if (el.type == ElementType.dayStrip) {
          return [
            _Frame(
              widget: Directionality(
                textDirection: TextDirection.ltr,
                child: DayStripArt.exportPanel(el),
              ),
              path: pth.normalize('${dir("calendar")}${el.name}_strip.png'),
            ),
          ];
        }
        if (el.type == ElementType.calendarGrid) {
          if (el.calendarStyle == CalendarStyle.classic) return [];
          return [
            _Frame(
              widget: Directionality(
                textDirection: TextDirection.ltr,
                child: CalendarStyleArt.exportPanel(el),
              ),
              path: pth.normalize('${dir("calendar")}${el.name}_panel.png'),
            ),
          ];
        }
        if (el.type == ElementType.shortcutSet) {
          return [
            for (final part in ShortcutSetArt.exportParts(
              el,
              resolveImage: (relative) {
                final file = File(pth.normalize('$lsAdv$relative.png'));
                if (file.existsSync()) return file;
                final icon = exportedIconForLockscreenPath(relative);
                if (icon == null) return null;
                final exported = File(pth.join(iconsDir, '$icon.png'));
                return exported.existsSync() ? exported : null;
              },
            ).entries)
              _Frame(
                widget: Directionality(
                  textDirection: TextDirection.ltr,
                  child: part.value,
                ),
                path: pth.normalize(
                  '${dir("shortcut")}${el.name}${part.key}.png',
                ),
              ),
          ];
        }
        if (el.type.isAnalog) {
          return [
            for (final part in analogPartsOf(el))
              _Frame(
                widget: Directionality(
                  textDirection: TextDirection.ltr,
                  child: AnalogClockArt.part(el, part, el.width / 3),
                ),
                path: pth.normalize(
                  '${dir("analog")}${el.name}${AnalogClockArt.suffix(el, part)}.png',
                ),
              ),
          ];
        }
        // Container types (containerBG1–5)
        if (el.type.isContainer) {
          return [
            _Frame(
              widget: _phoneFrame(el, _containerWidget(el)),
              path: pth.normalize('${dir("container")}${el.name}.png'),
            ),
          ];
        }
        return [];
    }
  }

  Widget _phoneFrame(LockElement el, Widget child) {
    // Directionality is required because captureFromWidget uses an independent
    // rendering pipeline (screenshot v3) that has no inherited widgets — without
    // it, Text throws and the captured PNG is fully transparent.
    return Directionality(
      textDirection: TextDirection.ltr,
      child: SizedBox(
        height: lockscreenViewHeight,
        width: lockscreenViewWidth,
        // Transparent background — MIUI composites layers itself
        child: Transform(
          transform: el.perspectiveMatrix ?? Matrix4.identity(),
          alignment: Alignment.center,
          child: Stack(
            children: [
              Positioned(
                left: el.dx,
                top: el.dy,
                child: Transform.scale(
                  scale: el.scale,
                  // No alignment override — default Alignment.center matches the
                  // live preview's Transform.scale behaviour exactly.
                  child: Transform.rotate(
                    angle: -el.angle * pi / 180,
                    child: SizedBox(
                      height: lockscreenViewHeight,
                      width: lockscreenViewWidth,
                      child: Align(alignment: el.align, child: child),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Child widget builders ──────────────────────────────────────────────────

  Widget _clockText(LockElement el, String text) =>
      SurfaceFx(element: el, child: _clockGlyphs(el, text));

  Widget _clockGlyphs(LockElement el, String text) {
    if (el.useSeparateColors &&
        (el.type == ElementType.hourClock ||
            el.type == ElementType.minClock ||
            el.type == ElementType.secClock) &&
        text.length == 2) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GradientText(
            text[0],
            gradient: LinearGradient(
              begin: el.gradStartAlign as Alignment,
              end: el.gradEndAlign as Alignment,
              colors: [el.colorDigit1, el.colorDigit1],
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
            isWallpaperGlass: el.isWallpaperGlass,
            glassBlur: el.glassBlur,
            glassTint: el.glassTint,
            glassRim: el.glassRim,
            glassShadow: el.glassShadow,
            glassEdgeLight: el.glassEdgeLight,
          ),
          GradientText(
            text[1],
            gradient: LinearGradient(
              begin: el.gradStartAlign as Alignment,
              end: el.gradEndAlign as Alignment,
              colors: [el.colorDigit2, el.colorDigit2],
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
            isWallpaperGlass: el.isWallpaperGlass,
            glassBlur: el.glassBlur,
            glassTint: el.glassTint,
            glassRim: el.glassRim,
            glassShadow: el.glassShadow,
            glassEdgeLight: el.glassEdgeLight,
          ),
        ],
      );
    }

    return GradientText(
      text,
      gradient: LinearGradient(
        begin: el.gradStartAlign as Alignment,
        end: el.gradEndAlign as Alignment,
        colors: [el.color, el.colorSecondary],
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
      isWallpaperGlass: el.isWallpaperGlass,
      glassBlur: el.glassBlur,
      glassTint: el.glassTint,
      glassRim: el.glassRim,
      glassShadow: el.glassShadow,
      glassEdgeLight: el.glassEdgeLight,
    );
  }

  Widget _containerWidget(LockElement el) =>
      SurfaceFx(element: el, child: _containerBody(el));

  Widget _containerBody(LockElement el) {
    if (el.isWallpaperGlass) return WallpaperGlassBox(element: el);
    final base = Container(
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
    if (el.blurRadius <= 0) return base;
    return ClipRRect(
      borderRadius: BorderRadius.circular(el.radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: el.blurRadius, sigmaY: el.blurRadius),
        child: base,
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  // "Monday" -> "Mon\nday": first 3 letters, then the remainder, on their own line.
  String _wrapText(String input) {
    if (input.length <= 3) return input;
    return '${input.substring(0, 3)}\n${input.substring(3)}';
  }
}

// ── Immutable frame descriptor ────────────────────────────────────────────────

class _Frame {
  const _Frame({required this.widget, required this.path});
  final Widget widget;
  final String path;
}
