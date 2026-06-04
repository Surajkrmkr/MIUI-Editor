import 'package:flutter/material.dart';
import '../../domain/entities/element_widget.dart';
import '../../domain/entities/lock_widget.dart';

class ThemePresets {
  static List<LockElement> get blackWhiteDesert => [
        const LockElement(
          type: ElementType.hourClock,
          dx: 0,
          dy: -1000,
          fontSize: 400,
          fontWeight: FontWeight.w200,
          color: Colors.white,
        ),
        const LockElement(
          type: ElementType.minClock,
          dx: 0,
          dy: -600,
          fontSize: 400,
          fontWeight: FontWeight.w200,
          color: Colors.white,
        ),
        const LockElement(
          type: ElementType.weekClock,
          dx: 0,
          dy: -200,
          fontSize: 80,
          color: Colors.white70,
        ),
        const LockElement(
          type: ElementType.dateTimeText1,
          dx: 0,
          dy: -100,
          text: 'yyyy/MM/dd',
          fontSize: 60,
          color: Colors.white54,
        ),
        const LockElement(
          type: ElementType.pngBG1,
          dx: -400,
          dy: 400,
          width: 500,
          height: 300,
          path: r'birds',
        ),
      ];

  static List<LockElement> get bentoDesert => kPresetWidgets.firstWhere((w) => w.name == 'Bento Desert').elements;

  static List<LockElement> get whiteBackgroundWidgets => [
        const LockElement(
          type: ElementType.containerBG1,
          dx: 0,
          dy: 400,
          width: 1000,
          height: 600,
          radius: 80,
          color: Colors.white,
          colorSecondary: Colors.white,
        ),
        const LockElement(
          type: ElementType.containerBG2,
          dx: 0,
          dy: 1100,
          width: 1000,
          height: 300,
          radius: 80,
          color: Colors.white,
          colorSecondary: Colors.white,
          blurRadius: 40,
        ),
      ];
}
