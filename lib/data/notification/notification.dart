import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../constants.dart';
import '../../functions/theme_path.dart';
import '../../provider/element.dart';
import '../bg_stack.dart';
import '../element_map_dart.dart';

class Notification extends StatelessWidget {
  const Notification({super.key});

  static Widget getChild({ElementProvider? value, String? themePath}) {
    final ele = value!.getElementFromList(ElementType.notification);
    return commonWidget(
        child: Container(
          height: 183 * MIUIConstants.ratio,
          width: 1024 * MIUIConstants.ratio,
          decoration: BoxDecoration(
            color: ele.color,
            borderRadius: BorderRadius.circular(ele.radius!),
          ),
          // child: ele.child,
        ),
        type: ElementType.notification,
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
