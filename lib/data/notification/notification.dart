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
        child:
            // ListView(
            //   children: List.generate(
            //     1,
            //     (_) =>
            Container(
          height: 60,
          width: 250,
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: ele.colorSecondary,
            borderRadius: BorderRadius.circular(ele.radius!),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    margin: const EdgeInsets.only(left: 10),
                    decoration: BoxDecoration(
                        color: Colors.pinkAccent,
                        borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.all(10),
                    child: const Icon(
                      Icons.android,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Notification",
                          style: TextStyle(color: ele.color, fontSize: 12)),
                      Text("Details",
                          style: TextStyle(color: ele.color, fontSize: 12)),
                    ],
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(right: 10.0),
                child: Text("02:26 AM",
                    style: TextStyle(color: ele.color, fontSize: 12)),
              ),
            ],
          ),
        ),
        //   ),
        // ),
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
