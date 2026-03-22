import 'package:flex_color_picker/flex_color_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../presentation/providers/icon_editor_provider.dart';

class ColorTab extends ConsumerWidget {
  const ColorTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 4,
      child: SizedBox(
        height: 550,
        width: 500,
        child: Scaffold(
          appBar: AppBar(
            automaticallyImplyLeading: false,
            title: const Text('Color'),
            centerTitle: true,
            backgroundColor: Colors.transparent,
            bottom: const TabBar(
              tabs: [
                Tab(text: 'BG'),
                Tab(text: 'Icon'),
                Tab(text: 'Border'),
                Tab(text: 'Accent'),
              ],
            ),
          ),
          body: Consumer(builder: (context, ref, _) {
            final s = ref.watch(iconEditorProvider);
            final n = ref.read(iconEditorProvider.notifier);
            return TabBarView(
              children: [
                _GradientPicker(
                  c1: s.bgColor, c2: s.bgColor2,
                  a1: s.bgGradStart, a2: s.bgGradEnd,
                  onColors: (c1, c2) {
                    n.setRandomColors(false);
                    n.setBgColor(c1);
                    n.setBgColor2(c2);
                  },
                  onAligns: (a1, a2) {
                    n.setBgGradStart(a1);
                    n.setBgGradEnd(a2);
                  },
                ),
                _WheelPicker(color: s.iconColor,  onChanged: n.setIconColor),
                _WheelPicker(color: s.borderColor,onChanged: n.setBorderColor),
                _WheelPicker(color: s.accentColor, onChanged: n.setAccentColor),
              ],
            );
          }),
        ),
      ),
    );
  }
}

class _WheelPicker extends StatelessWidget {
  const _WheelPicker({required this.color, required this.onChanged});
  final Color color;
  final ValueChanged<Color> onChanged;

  @override
  Widget build(BuildContext context) => ColorPicker(
    color: color,
    onColorChanged: onChanged,
    enableOpacity: true,
    showColorCode: true,
    pickersEnabled: const {ColorPickerType.wheel: true},
  );
}

class _GradientPicker extends StatefulWidget {
  const _GradientPicker({
    required this.c1, required this.c2,
    required this.a1, required this.a2,
    required this.onColors, required this.onAligns,
  });
  final Color c1, c2;
  final AlignmentGeometry a1, a2;
  final void Function(Color, Color) onColors;
  final void Function(AlignmentGeometry, AlignmentGeometry) onAligns;

  @override
  State<_GradientPicker> createState() => _GradientPickerState();
}

class _GradientPickerState extends State<_GradientPicker> {
  late Color _c1, _c2;
  late AlignmentGeometry _a1, _a2;

  @override
  void initState() {
    super.initState();
    _c1 = widget.c1; _c2 = widget.c2;
    _a1 = widget.a1; _a2 = widget.a2;
  }

  @override
  void didUpdateWidget(_GradientPicker old) {
    super.didUpdateWidget(old);
    _c1 = widget.c1; _c2 = widget.c2;
    _a1 = widget.a1; _a2 = widget.a2;
  }

  static const _alignOptions = {
    'Top Left': Alignment.topLeft, 'Top Center': Alignment.topCenter,
    'Top Right': Alignment.topRight, 'Center Left': Alignment.centerLeft,
    'Center': Alignment.center, 'Center Right': Alignment.centerRight,
    'Bottom Left': Alignment.bottomLeft, 'Bottom Center': Alignment.bottomCenter,
    'Bottom Right': Alignment.bottomRight,
  };

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 16),
    child: Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _ColorBtn(color: _c1, label: 'Start', onChanged: (c) {
              setState(() => _c1 = c);
              widget.onColors(_c1, _c2);
            }),
            _ColorBtn(color: _c2, label: 'End', onChanged: (c) {
              setState(() => _c2 = c);
              widget.onColors(_c1, _c2);
            }),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _AlignDrop(value: _a1, options: _alignOptions, onChanged: (a) {
              setState(() => _a1 = a);
              widget.onAligns(_a1, _a2);
            }),
            _AlignDrop(value: _a2, options: _alignOptions, onChanged: (a) {
              setState(() => _a2 = a);
              widget.onAligns(_a1, _a2);
            }),
          ],
        ),
      ],
    ),
  );
}

class _ColorBtn extends StatelessWidget {
  const _ColorBtn({required this.color, required this.label, required this.onChanged});
  final Color color;
  final String label;
  final ValueChanged<Color> onChanged;

  @override
  Widget build(BuildContext context) => ElevatedButton(
    style: ElevatedButton.styleFrom(
      backgroundColor: color,
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 28),
    ),
    onPressed: () => ColorPicker(
      color: color,
      onColorChanged: onChanged,
      enableOpacity: true,
      showColorCode: true,
      colorCodeHasColor: true,
      pickersEnabled: const {
        ColorPickerType.wheel: true,
        ColorPickerType.primary: false,
        ColorPickerType.accent: false,
      },
    ).showPickerDialog(context),
    child: Text(label, style: const TextStyle(color: Colors.white,
        shadows: [Shadow(color: Colors.black, offset: Offset(1,1), blurRadius: 1)])),
  );
}

class _AlignDrop extends StatelessWidget {
  const _AlignDrop({required this.value, required this.options, required this.onChanged});
  final AlignmentGeometry value;
  final Map<String, AlignmentGeometry> options;
  final ValueChanged<AlignmentGeometry> onChanged;

  @override
  Widget build(BuildContext context) => DropdownButtonHideUnderline(
    child: DropdownButton<AlignmentGeometry>(
      value: value,
      borderRadius: BorderRadius.circular(16),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      items: options.entries.map((e) =>
        DropdownMenuItem(value: e.value, child: Text(e.key))).toList(),
      onChanged: (v) { if (v != null) onChanged(v); },
    ),
  );
}
