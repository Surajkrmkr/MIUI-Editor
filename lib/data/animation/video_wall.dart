import 'package:flutter/material.dart';
import 'package:miui_icon_generator/data/element_map_dart.dart';
import 'package:provider/provider.dart';

import '../../provider/element.dart';

class VideoWallpapaer extends StatelessWidget {
  final ElementType type;
  const VideoWallpapaer({super.key, required this.type});

  static Widget getChild({ElementProvider? value, ElementType? type}) {
    final ele = value!.getElementFromList(type!);
    return Container();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ElementProvider>(builder: (context, value, _) {
      return getChild(value: value, type: type);
    });
  }
}
