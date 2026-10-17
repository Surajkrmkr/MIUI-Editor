import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../domain/entities/element_widget.dart';
import 'unlock_skin_art.dart';

class UnlockControlPreview extends StatelessWidget {
  const UnlockControlPreview({super.key, required this.element});
  final LockElement element;

  @override
  Widget build(BuildContext context) {
    if (element.unlockSkin != UnlockSkin.classic) {
      return UnlockSkinView(
        key: ValueKey('unlock-preview-${element.name}'),
        element: element,
      );
    }
    final width = element.width / AppConstants.screenRatio;
    final height = element.unlockHeight / AppConstants.screenRatio;
    final tap = element.type == ElementType.tapToUnlock;
    final drag = element.type == ElementType.dragToUnlock;
    final hasText = element.unlockText.isNotEmpty;
    final hasIcon = element.effectiveUnlockIcon != UnlockIcon.none;
    final inline = tap && hasText && element.unlockInline && hasIcon;
    var iconSize = min(width, height) * element.unlockIconScale.clamp(.2, 1);
    if (tap && hasText && !inline) iconSize = min(iconSize, height * .45);
    final label = Text(
      element.unlockText,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: element.unlockTextFontSize,
        color: element.color,
        fontWeight: element.fontWeight,
        height: 1,
      ),
    );
    final icon = !hasIcon
        ? const SizedBox.shrink()
        : element.effectiveUnlockIcon == UnlockIcon.customPng
        ? SizedBox(
            width: iconSize,
            height: iconSize,
            child:
                element.unlockIconPath.isNotEmpty &&
                    File(element.unlockIconPath).existsSync()
                ? Image.memory(
                    File(element.unlockIconPath).readAsBytesSync(),
                    fit: BoxFit.contain,
                    gaplessPlayback: true,
                    errorBuilder: (_, error, stackTrace) =>
                        const Icon(Icons.broken_image_outlined),
                  )
                : const Icon(Icons.image_outlined),
          )
        : Icon(
            element.effectiveUnlockIcon.icon,
            color: element.color,
            size: iconSize,
          );
    return Container(
      key: ValueKey('unlock-preview-${element.name}'),
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: element.colorSecondary.withValues(
          alpha:
              element.colorSecondary.a *
              element.unlockBackgroundOpacity.clamp(0, 1),
        ),
        borderRadius: BorderRadius.circular(
          element.effectiveUnlockCornerRadius / AppConstants.screenRatio,
        ),
      ),
      child: tap
          ? inline
                ? Row(
                    children: [
                      SizedBox(
                        width: min(height, width * .4),
                        height: height,
                        child: Center(child: icon),
                      ),
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(right: width * .08),
                          child: label,
                        ),
                      ),
                    ],
                  )
                : hasText
                ? Stack(
                    children: [
                      if (hasIcon)
                        Positioned(
                          left: (width - iconSize) / 2,
                          top: height * .32 - iconSize / 2,
                          width: iconSize,
                          height: iconSize,
                          child: icon,
                        ),
                      Positioned(
                        left: width * .08,
                        right: width * .08,
                        top:
                            height * (hasIcon ? .78 : .5) -
                            element.unlockTextFontSize * .75,
                        height: element.unlockTextFontSize * 1.5,
                        child: Center(child: label),
                      ),
                    ],
                  )
                : icon
          : Stack(
              children: [
                if (drag) ...[
                  Positioned(
                    left: height / 2,
                    right: height / 2,
                    top: height * .47,
                    height: height * .06,
                    child: ColoredBox(color: element.colorSecondary),
                  ),
                  Positioned(
                    right: height * .14,
                    top: height * .14,
                    width: height * .72,
                    height: height * .72,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: element.colorSecondary,
                          width: height * .06,
                        ),
                      ),
                    ),
                  ),
                ],
                if (hasText)
                  Positioned(
                    left: height + (width - height * (drag ? 2 : 1)) * .08,
                    right:
                        (drag ? height : 0) +
                        (width - height * (drag ? 2 : 1)) * .08,
                    top: drag ? height * .65 : 0,
                    bottom: 0,
                    child: Center(child: label),
                  ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: SizedBox(
                    width: height,
                    height: height,
                    child: Padding(
                      padding: drag
                          ? EdgeInsets.symmetric(horizontal: height * .12)
                          : EdgeInsets.all(height * .08),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          shape: drag ? BoxShape.rectangle : BoxShape.circle,
                          borderRadius: drag
                              ? BorderRadius.circular(height * .12)
                              : null,
                          color: element.colorSecondary.withValues(
                            alpha:
                                element.colorSecondary.a *
                                element.unlockThumbOpacity.clamp(0, 1),
                          ),
                        ),
                        child: icon,
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
