import 'package:flutter/material.dart';
import 'package:miui_icon_generator/theme_editor/core/constants/app_constants.dart';

class IPhoneFrame extends StatelessWidget {
  const IPhoneFrame({super.key, 
    required this.child,
  });

  final Widget child;

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
              child: child,
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

