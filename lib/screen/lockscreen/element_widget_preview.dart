
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../provider/element.dart';

class ElementWidgetPreview extends StatelessWidget {
  const ElementWidgetPreview({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<ElementProvider>(
        builder: (context, value, child) {
        return Stack(
            children: value.elementList
                .map((e) => Positioned(
                      left: e.dx!,
                      top: e.dy!,
                      child: Transform.scale(
                        scale: e.scale,
                        child: GestureDetector(
                            onTap: () {
                              value.setActiveType =
                                  e.type!;
                            },
                            onPanUpdate: ((details) {
                              value.setActiveType =
                                  e.type!;
                              value
                                  .updateElementPositionInList(
                                      e.type!,
                                      e.dx! +
                                          details
                                              .delta.dx,
                                      e.dy! +
                                          details.delta
                                              .dy);
                            }),
                            child: e.child!),
                      ),
                    ))
                .toList());
      });
  }
}