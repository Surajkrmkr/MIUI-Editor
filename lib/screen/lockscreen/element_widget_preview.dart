import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import '../../constants.dart';
import '../../functions/theme_path.dart';
import '../../functions/windows_utils.dart';
import '../../provider/element.dart';

class ElementWidgetPreview extends StatelessWidget {
  const ElementWidgetPreview({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<ElementProvider>(builder: (context, value, child) {
      final themePath = CurrentTheme.getPath(context);
      final bgPath =
          File(platformBasedPath("${themePath}lockscreen\\advance\\bg.png"));
      return Stack(children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(40),
            color: Colors.black.withOpacity(value.bgAlpha!),
          ),
          width: MIUIConstants.screenWidth,
          height: MIUIConstants.screenHeight,
        ),
        Image.memory(bgPath.readAsBytesSync(), gaplessPlayback: true),
        ...(value.elementList.map((e) => e.child!).toList())
      ]);
    });
  }
}
