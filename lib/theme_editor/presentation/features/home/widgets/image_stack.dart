import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:screenshot/screenshot.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../providers/wallpaper_provider.dart';
import '../../icon_editor/widgets/icon_preview_on_phone.dart';
import '../../lockscreen/widgets/element_widget_preview.dart';

class ImageStack extends ConsumerStatefulWidget {
  const ImageStack({super.key, required this.isLockscreen});
  final bool isLockscreen;

  @override
  ConsumerState<ImageStack> createState() => _ImageStackState();
}

class _ImageStackState extends ConsumerState<ImageStack> {
  final _screenshotCtrl = ScreenshotController();

  @override
  Widget build(BuildContext context) {
    final wallState = ref.watch(wallpaperProvider);
    if (wallState.paths.isEmpty) return const SizedBox.shrink();

    final screenContent = Container(
      height: AppConstants.screenHeight,
      width: AppConstants.screenWidth,
      decoration: BoxDecoration(
        image: DecorationImage(
          image: FileImage(File(wallState.paths[wallState.index])),
          fit: BoxFit.cover,
        ),
      ),
      child: widget.isLockscreen
          ? const ElementWidgetPreview()
          : const IconPreviewOnPhone(),
    );

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (!widget.isLockscreen && wallState.index > 0)
              _NavArrow(
                icon: Icons.chevron_left_rounded,
                onTap: () => ref
                    .read(wallpaperProvider.notifier)
                    .setIndex(wallState.index - 1),
              )
            else
              const SizedBox(width: 40),
            _IPhoneFrame(
              screenshotController: _screenshotCtrl,
              child: screenContent,
            ),
            if (!widget.isLockscreen &&
                wallState.index < wallState.paths.length - 1)
              _NavArrow(
                icon: Icons.chevron_right_rounded,
                onTap: () => ref
                    .read(wallpaperProvider.notifier)
                    .setIndex(wallState.index + 1),
              )
            else
              const SizedBox(width: 40),
          ],
        ),
      ],
    );
  }
}

// ── iPhone 17 Dynamic Island Frame ───────────────────────────────────────────

class _IPhoneFrame extends StatelessWidget {
  const _IPhoneFrame({
    required this.child,
    required this.screenshotController,
  });

  final Widget child;
  final ScreenshotController screenshotController;

  // Layout constants
  static const _sw = AppConstants.screenWidth;
  static const _sh = AppConstants.screenHeight;
  static const _bezelH = 8.0; // horizontal bezel (each side)
  static const _bezelT = 8.0; // top bezel
  static const _bezelB = 8.0; // bottom bezel
  static const _btnGap = 5.0; // space for side buttons on each side
  static const _totalW = _sw + _bezelH * 2 + _btnGap * 2;
  static const _totalH = _sh + _bezelT + _bezelB;
  static const _bodyRadius = 48.0;
  static const _screenRadius = 40.0;

  // Dynamic Island
  static const _diWidth = 116.0;
  static const _diHeight = 30.0;
  static const _diTopOffset = 14.0; // from top of screen area

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _totalW,
      height: _totalH,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // ── Phone body ────────────────────────────────────────────────
          Positioned(
            left: _btnGap,
            right: _btnGap,
            top: 0,
            bottom: 0,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(_bodyRadius),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF404042),
                    Color(0xFF1C1C1E),
                    Color(0xFF2C2C2E),
                  ],
                  stops: [0.0, 0.55, 1.0],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(160),
                    blurRadius: 45,
                    offset: const Offset(0, 20),
                    spreadRadius: 2,
                  ),
                  BoxShadow(
                    color: Colors.white.withAlpha(14),
                    blurRadius: 1,
                    offset: const Offset(-1, -1),
                  ),
                ],
              ),
            ),
          ),

          // ── Screen content (clipped) ──────────────────────────────────
          Positioned(
            left: _btnGap + _bezelH,
            right: _btnGap + _bezelH,
            top: _bezelT,
            bottom: _bezelB,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(_screenRadius),
              child: Screenshot(
                controller: screenshotController,
                child: child,
              ),
            ),
          ),

          // ── Dynamic Island ─────────────────────────────────────────────
          Positioned(
            top: _bezelT + _diTopOffset,
            left: _btnGap + _bezelH,
            right: _btnGap + _bezelH,
            child: Center(
              child: Container(
                width: _diWidth,
                height: _diHeight,
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(_diHeight / 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(120),
                      blurRadius: 14,
                      spreadRadius: 3,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Front camera lens
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: const Color(0xFF0A0A0A),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFF1E1E1E),
                          width: 1.5,
                        ),
                      ),
                      child: Center(
                        child: Container(
                          width: 4.5,
                          height: 4.5,
                          decoration: const BoxDecoration(
                            color: Color(0xFF050505),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Microphone dot
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Color(0xFF111111),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Home indicator bar ─────────────────────────────────────────
          Positioned(
            bottom: _bezelB + 7,
            left: _btnGap + _bezelH,
            right: _btnGap + _bezelH,
            child: Center(
              child: Container(
                width: 108,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(170),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),

          // ── Frame gloss highlight (top-left sheen) ─────────────────────
          Positioned(
            left: _btnGap,
            right: _btnGap,
            top: 0,
            bottom: 0,
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(_bodyRadius),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: const Alignment(0.3, 0.5),
                    colors: [
                      Colors.white.withAlpha(22),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── Side buttons ───────────────────────────────────────────────
          // Action button (left, top)
          const _SideButton(isLeft: true, top: 86, height: 26),
          // Volume up (left)
          const _SideButton(isLeft: true, top: 124, height: 44),
          // Volume down (left)
          const _SideButton(isLeft: true, top: 180, height: 44),
          // Power button (right)
          const _SideButton(isLeft: false, top: 152, height: 70),
        ],
      ),
    );
  }
}

// ── Side Button (volume / power) ──────────────────────────────────────────────

class _SideButton extends StatelessWidget {
  const _SideButton({
    required this.isLeft,
    required this.top,
    required this.height,
  });

  final bool isLeft;
  final double top;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: isLeft ? 0 : null,
      right: isLeft ? null : 0,
      top: top,
      child: Container(
        width: 6,
        height: height,
        decoration: BoxDecoration(
          borderRadius: isLeft
              ? const BorderRadius.horizontal(left: Radius.circular(3))
              : const BorderRadius.horizontal(right: Radius.circular(3)),
          gradient: LinearGradient(
            begin: isLeft ? Alignment.centerRight : Alignment.centerLeft,
            end: isLeft ? Alignment.centerLeft : Alignment.centerRight,
            colors: const [
              Color(0xFF3C3C3E),
              Color(0xFF1A1A1C),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Navigation Arrow ──────────────────────────────────────────────────────────

class _NavArrow extends StatelessWidget {
  const _NavArrow({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHigh,
          shape: BoxShape.circle,
          border: Border.all(color: scheme.outlineVariant, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(20),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, size: 22, color: scheme.onSurface),
      ),
    );
  }
}

// ── Lockscreen Bottom Bar ─────────────────────────────────────────────────────

class _LockscreenBar extends StatelessWidget {
  const _LockscreenBar({
    required this.themeName,
    required this.onScreenshot,
  });

  final String themeName;
  final VoidCallback onScreenshot;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: scheme.outlineVariant.withAlpha(80)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(12),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (themeName.isNotEmpty) ...[
            Icon(Icons.palette_outlined,
                size: 13, color: scheme.onSurfaceVariant),
            const SizedBox(width: 6),
            Text(
              themeName,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 12,
                color: scheme.onSurface,
              ),
            ),
            const SizedBox(width: 12),
            Container(width: 1, height: 16, color: scheme.outlineVariant),
            const SizedBox(width: 12),
          ],
          FilledButton.icon(
            icon: const Icon(Icons.photo_camera_outlined, size: 14),
            label: const Text('Screenshot',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            onPressed: onScreenshot,
          ),
        ],
      ),
    );
  }
}
