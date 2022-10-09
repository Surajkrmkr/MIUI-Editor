import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import '../../provider/element.dart';

class ElementWidgetPreview extends StatelessWidget {
  const ElementWidgetPreview({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<ElementProvider>(builder: (context, value, child) {
      return Stack(children: [
        // Image.file(
        //   File(
        //       "E:\\Xiaomi Contract\\THEMES\\Week98\\Dark Durga\\lockscreen\\advance\\hour\\hour_2.png"),
        //   height: 2340,
        //   width: 1080,
        // ),
        ...(value.elementList.map((e) => e.child!).toList())
      ]);
    });
  }
}
