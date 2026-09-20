import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:screenshot/screenshot.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/asset_paths.dart';
import '../../core/constants/path_constants.dart';
import '../../core/errors/failures.dart';
import '../../core/utils/font_utils.dart';
import '../../domain/entities/element_widget.dart';
import '../../presentation/common/widgets/gradient_text.dart';
import '../../presentation/providers/element_provider.dart';

class ExportLockscreenPngsUseCase {
  const ExportLockscreenPngsUseCase({this.batchSize = 8});

  /// Number of frames captured in parallel per batch.
  /// 8 is a safe default for desktop — increase to 12-16 on fast machines.
  final int batchSize;

  Future<Failure?> call({
    required BuildContext context,
    required ElementState elementState,
    required String themePath,
    required void Function(int done, int total) onProgress,
  }) async {
    try {
      final lsAdv = PathConstants.lockscreenAdvance(themePath);
      final exportable =
          elementState.elements.where((e) => e.type.isExportable).toList();

      if (exportable.isEmpty) return null;

      // Build the full flat list of (widget, destPath) pairs up front
      // so we know the exact total before starting.
      final frames = <_Frame>[];
      for (final el in exportable) {
        frames.addAll(_framesFor(el, lsAdv));
      }

      // Pre-create all directories (fast — do sequentially before batching)
      final dirs = frames.map((f) => File(f.path).parent.path).toSet();
      for (final d in dirs) {
        await Directory(d).create(recursive: true);
      }

      int done = 0;

      // ── Parallel batch export ─────────────────────────────────────────────
      for (int i = 0; i < frames.length; i += batchSize) {
        final batch = frames.sublist(
          i,
          (i + batchSize).clamp(0, frames.length),
        );

        await Future.wait(
          batch.map((frame) async {
            final bytes = await ScreenshotController().captureFromWidget(
              frame.widget,
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
    }
  }

  // ── Build frame list for a single element ─────────────────────────────────

  List<_Frame> _framesFor(LockElement el, String lsAdv) {
    String dir(String sub) => PathConstants.p('$lsAdv$sub${PathConstants.sep}');

    switch (el.type) {
      case ElementType.hourClock:
        return List.generate(
            13,
            (i) => _Frame(
                  widget: _phoneFrame(
                      el, _clockText(el, i.toString().padLeft(2, '0'))),
                  path: PathConstants.p('${dir("hour")}hour_$i.png'),
                ));

      case ElementType.minClock:
        return List.generate(
            60,
            (i) => _Frame(
                  widget: _phoneFrame(
                      el, _clockText(el, i.toString().padLeft(2, '0'))),
                  path: PathConstants.p('${dir("min")}min_$i.png'),
                ));

      case ElementType.secClock:
        return List.generate(
            60,
            (i) => _Frame(
                  widget: _phoneFrame(
                      el, _clockText(el, i.toString().padLeft(2, '0'))),
                  path: PathConstants.p('${dir("sec")}sec_$i.png'),
                ));

      case ElementType.dotClock:
        return [
          _Frame(
            widget: _phoneFrame(el, _clockText(el, ':')),
            path: PathConstants.p('${dir("dot")}dot.png'),
          )
        ];

      case ElementType.dotClock2:
        return [
          _Frame(
            widget: _phoneFrame(el, _clockText(el, ':')),
            path: PathConstants.p('${dir("dot")}dot2.png'),
          )
        ];

      case ElementType.amPmClock:
        return List.generate(
            2,
            (i) => _Frame(
                  widget: _phoneFrame(el, _clockText(el, i == 0 ? 'AM' : 'PM')),
                  path: PathConstants.p('${dir("ampm")}ampm_$i.png'),
                ));

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
            path: PathConstants.p('${dir("week")}week_$i.png'),
          );
        });

      case ElementType.monthClock:
        return List.generate(12, (i) {
          final raw = AssetPaths.monthNames[i]!;
          return _Frame(
            widget: _phoneFrame(
                el, _clockText(el, el.isShort ? raw.substring(0, 3) : raw)),
            path: PathConstants.p('${dir("month")}month_${i + 1}.png'),
          );
        });

      case ElementType.dateClock:
        return List.generate(
            31,
            (i) => _Frame(
                  widget: _phoneFrame(
                      el, _clockText(el, (i + 1).toString().padLeft(2, '0'))),
                  path: PathConstants.p('${dir("date")}date_${i + 1}.png'),
                ));

      case ElementType.weatherIconClock:
        return AssetPaths.weatherCodes
            .map((code) => _Frame(
                  widget: _phoneFrame(el,
                      Image.asset(AssetPaths.weatherIcon(code.toString()), height: 40)),
                  path: PathConstants.p('${dir("weather")}weather_$code.png'),
                ))
            .toList();

      default:
        // Container types (containerBG1–5)
        if (el.type.isContainer) {
          return [
            _Frame(
              widget: _phoneFrame(el, _containerWidget(el)),
              path: PathConstants.p('${dir("container")}${el.name}.png'),
            )
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
        height: AppConstants.screenHeight,
        width: AppConstants.screenWidth,
        // Transparent background — MIUI composites layers itself
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
                  height: AppConstants.screenHeight,
                  width: AppConstants.screenWidth,
                  child: Align(
                    alignment: el.align,
                    child: child,
                  ),
                ),
              ),
            ),
          ),
        ],
        ),
      ),
    );
  }

  // ── Child widget builders ──────────────────────────────────────────────────

  Widget _clockText(LockElement el, String text) {
    if (el.useSeparateColors &&
        (el.type == ElementType.hourClock || el.type == ElementType.minClock || el.type == ElementType.secClock) &&
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
              height: 1,
              color: el.colorDigit1,
            ),
            strokeWidth: el.strokeWidth,
            strokeColor: el.strokeColorDigit1.a > 0 ? el.strokeColorDigit1 : el.strokeColor,
            blurRadius: el.blurRadius,
            isLiquidGlass: el.isLiquidGlass,
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
              height: 1,
              color: el.colorDigit2,
            ),
            strokeWidth: el.strokeWidth,
            strokeColor: el.strokeColorDigit2.a > 0 ? el.strokeColorDigit2 : el.strokeColor,
            blurRadius: el.blurRadius,
            isLiquidGlass: el.isLiquidGlass,
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
        height: 1,
        color: el.color,
      ),
      strokeWidth: el.strokeWidth,
      strokeColor: el.strokeColor,
      blurRadius: el.blurRadius,
      isLiquidGlass: el.isLiquidGlass,
    );
  }

  Widget _containerWidget(LockElement el) {
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
