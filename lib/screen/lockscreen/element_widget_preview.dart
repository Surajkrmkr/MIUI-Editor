import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import '../../functions/theme_path.dart';
import '../../provider/element.dart';

class ElementWidgetPreview extends StatelessWidget {
  const ElementWidgetPreview({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<ElementProvider>(builder: (context, value, child) {
      final themePath = CurrentTheme.getPath(context);
      final bgPath = File("$themePath\\lockscreen\\advance\\bg.png");
      return Stack(children: [
        Image.memory(
          bgPath.readAsBytesSync(),
        ),
        ...(value.elementList.map((e) => e.child!).toList())
      ]);
    });
  }
}
