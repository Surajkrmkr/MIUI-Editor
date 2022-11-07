import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../constants.dart';
import '../../functions/theme_path.dart';
import '../../functions/windows_utils.dart';
import '../../provider/element.dart';
import '../bg_stack.dart';
import '../element_map_dart.dart';

class MusicBG extends StatelessWidget {
  const MusicBG({super.key});

  static Widget getChild({ElementProvider? value, String? themePath}) {
    final ele = value!.getElementFromList(ElementType.musicBg);
    return commonWidget(
        child: Image.memory(
          File(platformBasedPath(
                  "${themePath}lockscreen\\advance\\music\\bg.png"))
              .readAsBytesSync(),
          gaplessPlayback: true,
          height: ele.height! / MIUIConstants.ratio,
          width: ele.width! / MIUIConstants.ratio,
        ),
        type: ElementType.musicBg,
        value: value);
  }

  @override
  Widget build(BuildContext context) {
    final themePath = CurrentTheme.getPath(context);
    return Consumer<ElementProvider>(builder: (context, value, _) {
      return getChild(value: value, themePath: themePath);
    });
  }
}

class MusicNext extends StatelessWidget {
  const MusicNext({super.key});

  static Widget getChild({ElementProvider? value, String? themePath}) {
    final ele = value!.getElementFromList(ElementType.musicNext);
    return commonWidget(
        child: Image.memory(
          File(platformBasedPath(
                  "${themePath}lockscreen\\advance\\music\\next.png"))
              .readAsBytesSync(),
          gaplessPlayback: true,
          height: ele.height! / MIUIConstants.ratio,
          width: ele.width! / MIUIConstants.ratio,
        ),
        type: ElementType.musicNext,
        value: value);
  }

  @override
  Widget build(BuildContext context) {
    final themePath = CurrentTheme.getPath(context);
    return Consumer<ElementProvider>(builder: (context, value, _) {
      return getChild(value: value, themePath: themePath);
    });
  }
}

class MusicPrev extends StatelessWidget {
  const MusicPrev({super.key});

  static Widget getChild({ElementProvider? value, String? themePath}) {
    final ele = value!.getElementFromList(ElementType.musicPrev);
    return commonWidget(
        child: Image.memory(
          File(platformBasedPath(
                  "${themePath}lockscreen\\advance\\music\\prev.png"))
              .readAsBytesSync(),
          gaplessPlayback: true,
          height: ele.height! / MIUIConstants.ratio,
          width: ele.width! / MIUIConstants.ratio,
        ),
        type: ElementType.musicPrev,
        value: value);
  }

  @override
  Widget build(BuildContext context) {
    final themePath = CurrentTheme.getPath(context);
    return Consumer<ElementProvider>(builder: (context, value, _) {
      return getChild(value: value, themePath: themePath);
    });
  }
}
