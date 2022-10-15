import 'package:flex_color_picker/flex_color_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/element_map_dart.dart';
import '../provider/element.dart';

class ElementInfo extends StatelessWidget {
  const ElementInfo({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Consumer<ElementProvider>(builder: (context, provider, _) {
          if (provider.elementList.isEmpty) {
            return Container(
              width: 300,
            );
          }
          final ElementWidget ele =
              provider.getElementFromList(provider.activeType!);
          return SizedBox(
            width: 300,
            child: Column(
              children: [
                Text(ele.name!),
                ColorPicker(
                  color: ele.color!,
                  onColorChanged: (value) {
                    provider.updateElementColorInList(ele.type!, value);
                  },
                  enableOpacity: true,
                  pickersEnabled: const {ColorPickerType.wheel: true},
                ),
                Slider(
                  label: "Scale",
                  value: ele.scale!,
                  onChanged: (val) {
                    provider.updateElementScaleInList(ele.type!, val);
                  },
                  min: 0,
                  max: 4,
                ),
                if (ele.type == ElementType.textLineClock)
                  TextFormField(
                    initialValue: "8 feb,Tue",
                  )
              ],
            ),
          );
        }),
        elementList(context)
      ],
    );
  }
}

Widget elementList(context) {
  return SizedBox(
      width: 250,
      child: Column(
        children: [
          Text(
            "Widget Lists",
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(
            height: 20,
          ),
          Expanded(
            child: ListView.builder(
                itemCount: ElementType.values.length,
                itemBuilder: (context, i) {
                  final provider =
                      Provider.of<ElementProvider>(context, listen: true);
                  final bool isAdded =
                      provider.getElementFromList(ElementType.values[i]).type !=
                          null;

                  return ListTile(
                    title: Text(
                      ElementType.values[i].name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: Icon(!isAdded ? Icons.add : Icons.remove),
                    onTap: () {
                      if (!isAdded) {
                        addToList(context: context, i: i);
                      } else {
                        Provider.of<ElementProvider>(context, listen: false)
                            .removeElementFromList(ElementType.values[i]);
                      }
                    },
                  );
                }),
          ),
        ],
      ));
}

void addToList({int? i, BuildContext? context}) {
  ElementWidget ele = ElementWidget(
      type: ElementType.values[i!],
      name: ElementType.values[i].name,
      child: elementWidgetMap[ElementType.values[i]]!["widget"]);
  final provider = Provider.of<ElementProvider>(context!, listen: false);
  provider.addElementInList(ele);
  provider.setActiveType = ElementType.values[i];
}
