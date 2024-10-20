import 'dart:io';

import 'package:flutter/material.dart';
import 'package:miui_icon_generator/constants.dart';
import 'package:provider/provider.dart';

import '../../functions/theme_path.dart';
import '../../functions/windows_utils.dart';
import '../../provider/element.dart';
import '../bg_stack.dart';
import '../element_map_dart.dart';

class PngBG extends StatelessWidget {
  const PngBG({super.key, required this.path, required this.type});

  final String? path;
  final ElementType? type;

  static Widget getChild(
      {ElementProvider? value,
      String? themePath,
      String? path,
      ElementType? type}) {
    return commonWidget(
        child: File(platformBasedPath(
                    "${themePath}lockscreen\\advance\\$path.png"))
                .existsSync()
            ? Image.memory(
                File(platformBasedPath(
                        "${themePath}lockscreen\\advance\\$path.png"))
                    .readAsBytesSync(),
                gaplessPlayback: true,
                height: MIUIConstants.screenHeight,
                width: MIUIConstants.screenWidth,
              )
            : Container(),
        type: type,
        value: value);
  }

  @override
  Widget build(BuildContext context) {
    final themePath = CurrentTheme.getPath(context);
    return Consumer<ElementProvider>(builder: (context, value, _) {
      return getChild(
          value: value, path: path, type: type, themePath: themePath);
    });
  }
}

// Future exportPngBG1Png(BuildContext context) async {
//   final value = Provider.of<ElementProvider>(context, listen: false);
//   final themePath = CurrentTheme.getPath(context);
//   ScreenshotController()
//       .captureFromWidget(
//           getBGStack(
//               child: PngBg.getChild(
//                   value: value, type: ElementType.pngBG1)),
//           context: context,
//           pixelRatio: 3)
//       .then((value) async {
//     final imagePath = File(platformBasedPath(
//         '$themePath\\lockscreen\\advance\\png\\pngBG1.png'));
//     await imagePath.writeAsBytes(value);
//   });
// }

// Future exportContainerBG2Png(BuildContext context) async {
//   final value = Provider.of<ElementProvider>(context, listen: false);
//   final themePath = CurrentTheme.getPath(context);
//   ScreenshotController()
//       .captureFromWidget(
//           getBGStack(
//               child: ContainerBG.getChild(
//                   value: value, type: ElementType.containerBG2)),
//           context: context,
//           pixelRatio: 3)
//       .then((value) async {
//     final imagePath = File(platformBasedPath(
//         '$themePath\\lockscreen\\advance\\container\\containerBG2.png'));
//     await imagePath.writeAsBytes(value);
//   });
// }

// Future exportContainerBG3Png(BuildContext context) async {
//   final value = Provider.of<ElementProvider>(context, listen: false);
//   final themePath = CurrentTheme.getPath(context);
//   ScreenshotController()
//       .captureFromWidget(
//           getBGStack(
//               child: ContainerBG.getChild(
//                   value: value, type: ElementType.containerBG3)),
//           context: context,
//           pixelRatio: 3)
//       .then((value) async {
//     final imagePath = File(platformBasedPath(
//         '$themePath\\lockscreen\\advance\\container\\containerBG3.png'));
//     await imagePath.writeAsBytes(value);
//   });
// }

// Future exportContainerBG4Png(BuildContext context) async {
//   final value = Provider.of<ElementProvider>(context, listen: false);
//   final themePath = CurrentTheme.getPath(context);
//   ScreenshotController()
//       .captureFromWidget(
//           getBGStack(
//               child: ContainerBG.getChild(
//                   value: value, type: ElementType.containerBG4)),
//           context: context,
//           pixelRatio: 3)
//       .then((value) async {
//     final imagePath = File(platformBasedPath(
//         '$themePath\\lockscreen\\advance\\container\\containerBG4.png'));
//     await imagePath.writeAsBytes(value);
//   });
// }

// Future exportContainerBG5Png(BuildContext context) async {
//   final value = Provider.of<ElementProvider>(context, listen: false);
//   final themePath = CurrentTheme.getPath(context);
//   ScreenshotController()
//       .captureFromWidget(
//           getBGStack(
//               child: ContainerBG.getChild(
//                   value: value, type: ElementType.containerBG5)),
//           context: context,
//           pixelRatio: 3)
//       .then((value) async {
//     final imagePath = File(platformBasedPath(
//         '$themePath\\lockscreen\\advance\\container\\containerBG5.png'));
//     await imagePath.writeAsBytes(value);
//   });
// }
