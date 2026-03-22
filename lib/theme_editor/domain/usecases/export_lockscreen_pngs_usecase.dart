import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:screenshot/screenshot.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/asset_paths.dart';
import '../../core/constants/path_constants.dart';
import '../../core/errors/failures.dart';
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

      case ElementType.dotClock:
        return [
          _Frame(
            widget: _phoneFrame(el, _clockText(el, ':')),
            path: PathConstants.p('${dir("dot")}dot.png'),
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
                      Image.asset(AssetPaths.weatherIcon(code), height: 40)),
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

  // ── FIX 1: apply the EXACT same transform stack as the live preview ────────
  //
  // Preview stack (from _DraggableElement):
  //   Positioned(left: el.dx, top: el.dy)
  //     Transform.scale(el.scale)
  //       Transform.rotate(-el.angle * pi/180)
  //         SizedBox(screenH × screenW)
  //           Align(el.align)
  //             <child>
  //
  // For export we don't use Positioned (no parent Stack), so we replicate
  // the same effect using a transparent full-screen SizedBox with the child
  // placed at (el.dx, el.dy) via a custom Stack — identical pixel output.

  Widget _phoneFrame(LockElement el, Widget child) {
    return SizedBox(
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
              alignment: Alignment.topLeft,
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
    );
  }

  // ── Child widget builders ──────────────────────────────────────────────────

  Widget _clockText(LockElement el, String text) => GradientText(
        text,
        gradient: LinearGradient(
          begin: el.gradStartAlign as Alignment,
          end: el.gradEndAlign as Alignment,
          colors: [el.color, el.colorSecondary],
        ),
        style: TextStyle(
          fontFamily: el.font,
          fontSize: 60,
          height: 1,
          color: el.color,
        ),
      );

  Widget _containerWidget(LockElement el) => Container(
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

  // ── Helpers ────────────────────────────────────────────────────────────────

  String _wrapText(String input) {
    const slices = [3, 2];
    final parts = <String>[];
    var start = 0;
    for (final len in slices) {
      if (start + len <= input.length) {
        parts.add(input.substring(start, start + len));
        start += len;
      }
    }
    if (start < input.length) parts.add(input.substring(start));
    return parts.join('\n');
  }
}

// ── Immutable frame descriptor ────────────────────────────────────────────────

class _Frame {
  const _Frame({required this.widget, required this.path});
  final Widget widget;
  final String path;
}
