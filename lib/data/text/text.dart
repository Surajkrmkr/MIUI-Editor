import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../provider/element.dart';
import '../../resources/strings.dart';
import '../bg_stack.dart';
import '../element_map_dart.dart';

class DateTimeText extends StatelessWidget {
  const DateTimeText({super.key, required this.type});
  final ElementType? type;

  static Widget getChild({ElementType? type, ElementProvider? value}) {
    final ele = value!.getElementFromList(type!);
    return commonWidget(
        child: Text(
          MIUIString.getReplacedText(ele.text),
          style: TextStyle(
              fontWeight: ele.fontWeight!,
              fontSize: ele.fontSize,
              height: 1,
              color: ele.color),
        ),
        type: type,
        value: value);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ElementProvider>(builder: (context, value, _) {
      return getChild(type: type, value: value);
    });
  }
}

class NormalText extends StatelessWidget {
  const NormalText({super.key, required this.type});
  final ElementType? type;

  static Widget getChild({ElementType? type, ElementProvider? value}) {
    final ele = value!.getElementFromList(type!);
    return commonWidget(
        child: Text(
          MIUIString.getGlobalVarText(ele.text),
          style: TextStyle(
              fontWeight: ele.fontWeight!,
              fontSize: ele.fontSize,
              height: 1,
              color: ele.color),
        ),
        type: type,
        value: value);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ElementProvider>(builder: (context, value, _) {
      return getChild(type: type, value: value);
    });
  }
}
