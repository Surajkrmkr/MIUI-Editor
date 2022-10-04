import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../provider/element.dart';
import '../element_map_dart.dart';

class VerticalClock extends StatelessWidget {
  const VerticalClock({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ElementProvider>(builder: (context, provider, _) {
      final ele = provider.getElementFromList(ElementType.verticalClock);
      return SizedBox(
        width: 200,
        child: Column(
          children: [
            Text(
              "02",
              style: TextStyle(
                  fontFamily: ele.font,
                  fontSize: 60,
                  height: 1,
                  color: ele.color),
            ),
            Text(
              "36",
              style: TextStyle(
                  fontFamily: ele.font,
                  fontSize: 60,
                  height: 1,
                  color: ele.color),
            ),
          ],
        ),
      );
    });
  }
}

class HorizontalClock extends StatelessWidget {
  const HorizontalClock({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ElementProvider>(builder: (context, provider, _) {
      final ele = provider.getElementFromList(ElementType.horizontalClock);
      return SizedBox(
        width: 200,
        child: Row(
          children: [
            Text(
              "02",
              style: TextStyle(
                  fontFamily: ele.font,
                  fontSize: 60,
                  height: 1,
                  color: ele.color),
            ),
            Text(
              ":",
              style: TextStyle(
                  fontFamily: ele.font,
                  fontSize: 60,
                  height: 1,
                  color: ele.color),
            ),
            Text(
              "36",
              style: TextStyle(
                  fontFamily: ele.font,
                  fontSize: 60,
                  height: 1,
                  color: ele.color),
            ),
          ],
        ),
      );
    });
  }
}
