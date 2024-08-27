import 'package:flex_color_picker/flex_color_picker.dart';
import 'package:flutter/material.dart';
import 'package:miui_icon_generator/constants.dart';
import 'package:provider/provider.dart';

import '../provider/icon.dart';

class ColorsTab extends StatelessWidget {
  const ColorsTab({super.key});

  Widget child(context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
            automaticallyImplyLeading: false,
            title: const Text("Color"),
            centerTitle: true,
            backgroundColor: Colors.transparent,
            bottom: TabBar(
                indicatorColor: Theme.of(context).colorScheme.primary,
                dividerColor: Colors.transparent,
                splashBorderRadius: BorderRadius.circular(25),
                tabs: [
                  Padding(
                    padding:
                        EdgeInsets.all(MIUIConstants.isDesktop ? 8.0 : 6.0),
                    child: const Text("BG"),
                  ),
                  Padding(
                    padding:
                        EdgeInsets.all(MIUIConstants.isDesktop ? 8.0 : 6.0),
                    child: const Text("Icon"),
                  ),
                  Padding(
                    padding:
                        EdgeInsets.all(MIUIConstants.isDesktop ? 8.0 : 6.0),
                    child: const Text("Border"),
                  ),
                  Padding(
                    padding:
                        EdgeInsets.all(MIUIConstants.isDesktop ? 8.0 : 6.0),
                    child: const Text("Accent"),
                  )
                ])),
        body: Builder(builder: (context) {
          final provider = Provider.of<IconProvider>(context, listen: false);
          return TabBarView(children: [
            // ColorPicker(
            //   color: provider.bgColor!,
            //   showRecentColors: true,
            //   onColorChanged: (value) {
            //     provider.setBgColor = value;
            //   },
            //   enableOpacity: true,
            //   pickersEnabled: const {ColorPickerType.wheel: true},
            // ),
            GradientColorPicker(
                onColorChanged: (value, value2) {
                  provider.setBgColor = value;
                  provider.setBgColor2 = value2;
                },
                onAlignmentChanged: (value, value2) {
                  provider.setbgGradAlign = value;
                  provider.setbgGradAlign2 = value2;
                },
                color1: provider.bgColor!,
                color2: provider.bgColor2!,
                align1: provider.bgGradAlign!,
                align2: provider.bgGradAlign2!),
            ColorPicker(
              color: provider.iconColor!,
              onColorChanged: (value) {
                provider.setIconColor = value;
              },
              enableOpacity: true,
              pickersEnabled: const {ColorPickerType.wheel: true},
            ),
            ColorPicker(
              color: provider.borderColor!,
              onColorChanged: (value) {
                provider.setBorderColor = value;
              },
              enableOpacity: true,
              pickersEnabled: const {ColorPickerType.wheel: true},
            ),
            ColorPicker(
              color: provider.accentColor!,
              onColorChanged: (value) {
                provider.setAccentColor = value;
              },
              enableOpacity: true,
              pickersEnabled: const {ColorPickerType.wheel: true},
            )
          ]);
        }),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MIUIConstants.isDesktop
        ? SizedBox(height: 550, width: 500, child: child(context))
        : SizedBox(height: 650, child: child(context));
  }
}

class GradientColorPicker extends StatefulWidget {
  const GradientColorPicker(
      {super.key,
      required this.onColorChanged,
      required this.onAlignmentChanged,
      required this.color1,
      required this.color2,
      required this.align1,
      required this.align2});
  final Function(Color value, Color value2) onColorChanged;
  final Function(AlignmentGeometry value, AlignmentGeometry value2)
      onAlignmentChanged;
  final Color color1;
  final Color color2;
  final AlignmentGeometry align1;
  final AlignmentGeometry align2;
  @override
  State<GradientColorPicker> createState() => _GradientColorPickerState();
}

class _GradientColorPickerState extends State<GradientColorPicker> {
  Color _startColor = Colors.white;
  Color _endColor = Colors.white;
  AlignmentGeometry _align1 = Alignment.centerLeft;
  AlignmentGeometry _align2 = Alignment.centerRight;

  @override
  void initState() {
    _startColor = widget.color1;
    _endColor = widget.color2;
    _align1 = widget.align1;
    _align2 = widget.align2;
    super.initState();
  }

  @override
  void didUpdateWidget(covariant GradientColorPicker oldWidget) {
    _startColor = widget.color1;
    _endColor = widget.color2;
    _align1 = widget.align1;
    _align2 = widget.align2;
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ColorPickerButton(
                color: _startColor,
                onColorChanged: (color) {
                  setState(() {
                    _startColor = color;
                  });
                  widget.onColorChanged(_startColor, _endColor);
                },
              ),
              ColorPickerButton(
                color: _endColor,
                onColorChanged: (color) {
                  setState(() {
                    _endColor = color;
                    widget.onColorChanged(_startColor, _endColor);
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              AlignmentDropDown(
                align: _align1,
                onAlignmentChanged: (value) => setState(() {
                  _align1 = value;
                  widget.onAlignmentChanged(_align1, _align2);
                }),
              ),
              AlignmentDropDown(
                align: _align2,
                onAlignmentChanged: (value) => setState(() {
                  _align2 = value;
                  widget.onAlignmentChanged(_align1, _align2);
                }),
              ),
            ],
          )
        ],
      ),
    );
  }
}

class ColorPickerButton extends StatelessWidget {
  final Color color;
  final ValueChanged<Color> onColorChanged;

  const ColorPickerButton(
      {super.key, required this.color, required this.onColorChanged});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () => _showColorPickerDialog(context),
      style: ElevatedButton.styleFrom(
          backgroundColor: color,
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 30)),
      child: const Text(
        'Color',
        style: TextStyle(color: Colors.white, shadows: [
          BoxShadow(
              color: Color.fromARGB(255, 0, 0, 0),
              offset: Offset(1, 1),
              blurRadius: 1)
        ]),
      ),
    );
  }

  void _showColorPickerDialog(BuildContext context) {
    ColorPicker(
      color: color,
      enableShadesSelection: false,
      showColorCode: true,
      opacityTrackHeight: 30,
      opacityThumbRadius: 15,
      colorCodeHasColor: true,
      onColorChanged: onColorChanged,
      enableOpacity: true,
      pickersEnabled: const {
        ColorPickerType.wheel: true,
        ColorPickerType.primary: false,
        ColorPickerType.accent: false
      },
    ).showPickerDialog(context);
  }
}

class AlignmentDropDown extends StatefulWidget {
  const AlignmentDropDown(
      {super.key, required this.onAlignmentChanged, required this.align});

  final void Function(AlignmentGeometry value) onAlignmentChanged;
  final AlignmentGeometry align;

  @override
  State<AlignmentDropDown> createState() => _AlignmentDropDownState();
}

class _AlignmentDropDownState extends State<AlignmentDropDown> {
  AlignmentGeometry _selectedAlignment = Alignment.center;

  // List of alignment options
  final Map<String, AlignmentGeometry> _alignments = {
    'Top Left': Alignment.topLeft,
    'Top Center': Alignment.topCenter,
    'Top Right': Alignment.topRight,
    'Center Left': Alignment.centerLeft,
    'Center': Alignment.center,
    'Center Right': Alignment.centerRight,
    'Bottom Left': Alignment.bottomLeft,
    'Bottom Center': Alignment.bottomCenter,
    'Bottom Right': Alignment.bottomRight,
  };

  @override
  void initState() {
    _selectedAlignment = widget.align;
    super.initState();
  }

  @override
  void didUpdateWidget(covariant AlignmentDropDown oldWidget) {
    _selectedAlignment = widget.align;
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    return DropdownButtonHideUnderline(
      child: DropdownButton<AlignmentGeometry>(
        value: _selectedAlignment,
        borderRadius: BorderRadius.circular(20),
        padding: const EdgeInsets.symmetric(horizontal: 5),
        items: _alignments.entries.map((entry) {
          return DropdownMenuItem<AlignmentGeometry>(
            value: entry.value,
            child: Text(entry.key),
          );
        }).toList(),
        onChanged: (AlignmentGeometry? newValue) {
          setState(() {
            _selectedAlignment = newValue!;
          });
          widget.onAlignmentChanged(newValue!);
        },
      ),
    );
  }
}
