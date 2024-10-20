import 'package:flex_color_picker/flex_color_picker.dart';
import 'package:flutter/material.dart';
import 'package:miui_icon_generator/constants.dart';
import 'package:miui_icon_generator/widgets/color_picker.dart';
import 'package:provider/provider.dart';
import '../data/element_map_dart.dart';
import '../provider/element.dart';
import 'bg_drop_zone.dart';
import 'text_field.dart';

class ElementInfo extends StatelessWidget {
  const ElementInfo({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ElementProvider>(builder: (context, provider, _) {
      if (provider.elementList.isEmpty) {
        return Container(
          width: 300,
        );
      }
      final ElementWidget ele =
          provider.getElementFromList(provider.activeType!);
      final isContainer =
          elementWidgetMap[provider.activeType]!["isContainerType"] ?? false;
      final isIcon =
          elementWidgetMap[provider.activeType]!["isIconType"] ?? false;
      final isVideo =
          elementWidgetMap[provider.activeType]!["isVideo"] ?? false;
      final isMusic =
          elementWidgetMap[provider.activeType]!["isMusic"] ?? false;
      final isText =
          elementWidgetMap[provider.activeType]!["isTextType"] ?? false;
      return SizedBox(
        width: 300,
        child: SingleChildScrollView(
          child: Column(
            children: [
              Text(ele.name!),
              if (isIcon || isMusic || isVideo)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20.0),
                  child: BGDropZone(
                    path: isVideo ? "video" : ele.path,
                    extension: isVideo ? "mp4" : "png",
                  ),
                ),
              if (!isIcon && !isMusic && !isVideo)
                GradientColorPicker(
                  color1: ele.color!,
                  color2: ele.colorSecondary!,
                  align1: ele.gradStartAlign!,
                  align2: ele.gradEndAlign!,
                  onColorChanged: (value, value2) {
                    provider.updateElementColorInList(ele.type!, value);
                    provider.updateElementSecondaryColorInList(
                        ele.type!, value2);
                  },
                  onAlignmentChanged: (value, value2) {
                    provider.updateElementGradStartAlignInList(
                        ele.type!, value);
                    provider.updateElementGradEndAlignInList(ele.type!, value2);
                  },
                ),
              if (!isIcon && !isMusic && !isText && !isContainer && !isVideo)
                SwitchListTile(
                    value: ele.isShort!,
                    activeColor: Theme.of(context).colorScheme.primary,
                    title: Text(
                      "Make Short",
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    onChanged: (value) {
                      provider.updateElementIsShortInList(ele.type!, value);
                    }),
              if (!isIcon && !isMusic && !isText && !isContainer && !isVideo)
                SwitchListTile(
                    value: ele.isWrap!,
                    activeColor: Theme.of(context).colorScheme.primary,
                    title: Text(
                      "Make Wrap",
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    onChanged: (value) {
                      provider.updateElementIsWrapInList(ele.type!, value);
                    }),
              Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        SizedBox(
                          width: 100,
                          child: BuffyTextField(
                            onChanged: (String val) {
                              if (val.isNotEmpty) {
                                provider.updateElementPositionInList(
                                    ele.type!, double.parse(val), ele.dy!);
                              }
                            },
                            title: 'X',
                            value: ele.dx!.toString(),
                          ),
                        ),
                        SizedBox(
                          width: 100,
                          child: BuffyTextField(
                            onChanged: (String val) {
                              if (val.isNotEmpty) {
                                provider.updateElementPositionInList(
                                    ele.type!, ele.dx!, double.parse(val));
                              }
                            },
                            title: 'Y',
                            value: ele.dy!.toString(),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                      "Scale : ${isText ? ele.fontSize!.toStringAsFixed(2) : ele.scale!.toStringAsFixed(2)}"),
                  Slider(
                    value: isText ? ele.fontSize! : ele.scale!,
                    onChanged: (val) {
                      isText
                          ? provider.updateElementFontSizeInList(ele.type!, val)
                          : provider.updateElementScaleInList(ele.type!, val);
                    },
                    min: isText ? 0 : 0,
                    max: isText ? 100 : 4,
                    divisions: isText ? 100 : 4 ~/ 0.05,
                  ),
                ],
              ),
              if (isContainer) buildHeightWidthUI(ele, provider),
              if (isText)
                Padding(
                  padding: const EdgeInsets.only(bottom: 20.0),
                  child: TextFormField(
                      initialValue: ele.text,
                      onChanged: (str) {
                        provider.updateElementTextInList(ele.type!, str);
                      },
                      decoration: InputDecoration(
                          border: const OutlineInputBorder(),
                          suffixIcon: PopupMenuButton(
                            tooltip: 'Font Weight',
                            itemBuilder: (context) => [
                              PopupMenuItem(
                                  child: const Text("Normal"),
                                  onTap: () {
                                    provider.updateElementFontWeightInList(
                                        ele.type!, FontWeight.normal);
                                  }),
                              PopupMenuItem(
                                  child: const Text("bold"),
                                  onTap: () {
                                    provider.updateElementFontWeightInList(
                                        ele.type!, FontWeight.bold);
                                  })
                            ],
                            child: const Icon(Icons.more_vert),
                          ),
                          label: const Text("Text Expression"))),
                ),
              if (!isIcon && !isMusic && !isContainer)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    buildChoiceChips(provider, ele, index: 0),
                    buildChoiceChips(provider, ele, index: 1),
                    buildChoiceChips(provider, ele, index: 2),
                  ],
                ),
              const SizedBox(height: 10),
              if (isContainer)
                Column(
                  children: [
                    Text("Border Radius : ${ele.radius!.toStringAsFixed(0)}"),
                    Slider(
                      value: ele.radius!,
                      onChanged: (val) {
                        provider.updateElementRadiusInList(ele.type!, val);
                      },
                      divisions: 200,
                      min: 0,
                      max: 200,
                    ),
                    Text(
                        "Border Width : ${ele.borderWidth!.toStringAsFixed(0)}"),
                    Slider(
                      value: ele.borderWidth!,
                      onChanged: (val) {
                        provider.updateElementBorderWidthInList(ele.type!, val);
                      },
                      divisions: 10,
                      min: 0,
                      max: 10,
                    ),
                    const Text("Border Color "),
                    ColorPicker(
                      color: ele.borderColor!,
                      enableShadesSelection: false,
                      showColorCode: true,
                      opacityTrackHeight: 30,
                      opacityThumbRadius: 15,
                      colorCodeHasColor: true,
                      onColorChanged: (value) {
                        provider.updateElementBorderColorInList(
                            ele.type!, value);
                      },
                      enableOpacity: true,
                      pickersEnabled: const {
                        ColorPickerType.wheel: true,
                        ColorPickerType.primary: false,
                        ColorPickerType.accent: false
                      },
                    ),
                  ],
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
                          color: Theme.of(context).colorScheme.primary,
                          onPressed: () {
                            provider.updateElementPositionInList(
                                ele.type!, 0, 0);
                          },
                          icon: const Icon(Icons.restore)),
                      const SizedBox(
                        width: 10,
                      ),
                      IconButton(
                          color: Theme.of(context).colorScheme.primary,
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
        ),
      );
    });
  }

  Row buildHeightWidthUI(ElementWidget ele, ElementProvider provider) {
    return Row(
      children: [
        Expanded(
          child: Column(
            children: [
              Text("Height : ${ele.height!.toStringAsFixed(2)}"),
              Slider(
                value: ele.height!,
                onChanged: (val) {
                  provider.updateElementHeightInList(ele.type!, val);
                },
                min: 0,
                max: 800,
                divisions: 100 ~/ 0.05,
              ),
            ],
          ),
        ),
        Expanded(
          child: Column(
            children: [
              Text("Width : ${ele.width!.toStringAsFixed(2)}"),
              Slider(
                value: ele.width!,
                onChanged: (val) {
                  provider.updateElementWidthInList(ele.type!, val);
                },
                min: 0,
                max: 400,
                divisions: 100 ~/ 0.05,
              ),
            ],
          ),
        ),
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

class ElementList extends StatelessWidget {
  const ElementList({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ElementProvider>(context);
    return SizedBox(
        width: 200,
        child: Column(
          children: [
            if (MIUIConstants.isDesktop)
              Text(
                "Widget Lists",
                style: Theme.of(context).textTheme.bodyLarge!,
              ),
            if (MIUIConstants.isDesktop) const SizedBox(height: 20),
            Expanded(
              child: ListView(
                children: elementsByGroup.keys.map((groupName) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 5.0),
                    child: ExpansionTile(
                      collapsedShape: RoundedRectangleBorder(
                          side:
                              const BorderSide(width: 2, color: Colors.white30),
                          borderRadius: BorderRadius.circular(25)),
                      shape: RoundedRectangleBorder(
                          side:
                              const BorderSide(width: 2, color: Colors.white30),
                          borderRadius: BorderRadius.circular(25)),
                      title: Text(
                        groupName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      children: elementsByGroup[groupName]!.map((element) {
                        final bool isAdded =
                            provider.getElementFromList(element).type != null;
                        return Material(
                          type: MaterialType.transparency,
                          child: Padding(
                            padding: const EdgeInsets.only(
                                left: 10, right: 10, bottom: 10.0),
                            child: ListTile(
                              selected: isAdded,
                              title: Text(
                                element.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              onTap: () {
                                if (!isAdded) {
                                  addToList(context: context, type: element);
                                } else {
                                  provider.removeElementFromList(element);
                                }
                              },
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  );
                }).toList(),
              ),
            )
          ],
        ));
  }
}

void addToList({ElementType? type, BuildContext? context}) {
  final eleType = type!;
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
  if (eleType == ElementType.notification) {
    ele.colorSecondary = Colors.white24;
  }
  final provider = Provider.of<ElementProvider>(context!, listen: false);
  provider.addElementInList(ele);
  provider.setActiveType = eleType;
}
