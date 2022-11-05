import 'package:flex_color_picker/flex_color_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/element_map_dart.dart';
import '../provider/element.dart';
import 'bg_drop_zone.dart';

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
          final isIconType =
              (elementWidgetMap[provider.activeType]!["isIconType"] ?? false) ||
                  (elementWidgetMap[provider.activeType]!["isMusic"] ?? false);
          return SizedBox(
            width: 300,
            child: Column(
              children: [
                Text(ele.name!),
                if (isIconType)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20.0),
                    child: BGDropZone(
                      path: ele.path,
                    ),
                  ),
                if (!isIconType)
                  ColorPicker(
                    color: ele.color!,
                    enableShadesSelection: false,
                    showColorCode: true,
                    opacityTrackHeight: 30,
                    opacityThumbRadius: 15,
                    colorCodeHasColor: true,
                    onColorChanged: (value) {
                      provider.updateElementColorInList(ele.type!, value);
                    },
                    enableOpacity: true,
                    pickersEnabled: const {
                      ColorPickerType.wheel: true,
                      ColorPickerType.primary: false,
                      ColorPickerType.accent: false
                    },
                  ),
                if (!isIconType)
                  SwitchListTile(
                      value: ele.isShort!,
                      activeColor: Colors.pinkAccent,
                      title: Text(
                        "Make Short",
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      onChanged: (value) {
                        provider.updateElementIsShortInList(ele.type!, value);
                      }),
                Column(
                  children: [
                    Text("Scale : ${ele.scale!.toStringAsFixed(2)}"),
                    Slider(
                      value: ele.scale!,
                      onChanged: (val) {
                        provider.updateElementScaleInList(ele.type!, val);
                      },
                      min: 0,
                      max: 4,
                      divisions: 4 ~/ 0.05,
                    ),
                  ],
                ),
                if (ele.type == ElementType.textLineClock)
                  TextFormField(
                    initialValue: "8 feb,Tue",
                  ),
                if (!isIconType)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      buildChoiceChips(provider, ele, index: 0),
                      buildChoiceChips(provider, ele, index: 1),
                      buildChoiceChips(provider, ele, index: 2),
                    ],
                  ),
                const SizedBox(
                  height: 10,
                ),
                Column(
                  children: [
                    Text("Angle : ${ele.angle!.toStringAsFixed(0)}"),
                    Slider(
                      value: ele.angle!,
                      onChanged: (val) {
                        provider.updateElementAngleInList(ele.type!, val);
                      },
                      divisions: 360 ~/ 10,
                      min: 0,
                      max: 360,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                            color: Colors.pinkAccent,
                            onPressed: () {
                              provider.updateElementPositionInList(
                                  ele.type!, 0, 0);
                            },
                            icon: const Icon(Icons.restore)),
                        const SizedBox(
                          width: 10,
                        ),
                        IconButton(
                            color: Colors.pinkAccent,
                            onPressed: () {
                              provider.removeElementFromList(ele.type!);
                            },
                            icon: const Icon(Icons.delete)),
                      ],
                    )
                  ],
                ),
              ],
            ),
          );
        }),
        elementList(context)
      ],
    );
  }

  ChoiceChip buildChoiceChips(ElementProvider provider, ElementWidget ele,
      {required int? index}) {
    String text;
    AlignmentGeometry align;

    switch (index) {
      case 0:
        text = "left";
        align = Alignment.centerLeft;
        break;
      case 1:
        text = "center";
        align = Alignment.center;
        break;
      case 2:
        text = "right";
        align = Alignment.centerRight;
        break;
      default:
        text = "center";
        align = Alignment.center;
    }
    bool isSelected = ele.align == align;
    return ChoiceChip(
      label: Text(text),
      selected: isSelected,
      onSelected: (val) {
        provider.updateElementAlignInList(ele.type!, align);
      },
    );
  }
}

Widget elementList(context) {
  return SizedBox(
      width: 200,
      child: Column(
        children: [
          Text(
            "Widget Lists",
            style: Theme.of(context).textTheme.bodyLarge!,
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
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: ListTile(
                      selected: isAdded,
                      title: Text(
                        ElementType.values[i].name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      onTap: () {
                        if (!isAdded) {
                          addToList(context: context, i: i);
                        } else {
                          Provider.of<ElementProvider>(context, listen: false)
                              .removeElementFromList(ElementType.values[i]);
                        }
                      },
                    ),
                  );
                }),
          ),
        ],
      ));
}

void addToList({int? i, BuildContext? context}) {
  final eleType = ElementType.values[i!];
  final elementWidgetFromMap = elementWidgetMap[eleType];
  ElementWidget ele = ElementWidget(
      type: eleType,
      name: eleType.name,
      child: elementWidgetFromMap!["widget"]);
  final isIconType = (elementWidgetFromMap["isIconType"] ?? false) ||
      (elementWidgetFromMap["isMusic"] ?? false);
  if (isIconType) {
    ele.path = elementWidgetFromMap["path"];
  }
  final provider = Provider.of<ElementProvider>(context!, listen: false);
  provider.addElementInList(ele);
  provider.setActiveType = ElementType.values[i];
}
