import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../presentation/providers/icon_editor_provider.dart';
import '../../../../presentation/providers/wallpaper_provider.dart';
import 'package:flex_color_picker/flex_color_picker.dart';

class SlidersPanel extends ConsumerWidget {
  const SlidersPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(iconEditorProvider);
    final n = ref.read(iconEditorProvider.notifier);

    return SizedBox(
      width: 500,
      child: Column(
        children: [
          Row(
            children: [
              _Slider('Radius',  s.radius,      0, 20, n.setRadius),
              _Slider('Border',  s.borderWidth, 0, 20, n.setBorderWidth),
            ],
          ),
          Row(
            children: [
              _Slider('Margin',  s.margin,  0, 20, n.setMargin),
              _Slider('Padding', s.padding, 0, 20, n.setPadding),
            ],
          ),
          SwitchListTile(
            value: s.randomColors,
            title: const Text('Random Colors'),
            activeColor: Theme.of(context).colorScheme.primary,
            onChanged: (v) {
              n.setRandomColors(v);
              if (v) {
                final palette = ref.read(wallpaperProvider).colorPalette;
                final dark = palette.where((c) =>
                    ThemeData.estimateBrightnessForColor(c) == Brightness.dark)
                    .toList();
                if (dark.isNotEmpty) n.setBgColors(dark);
              }
            },
          ),
          if (s.randomColors) _RandomColorsRow(colors: s.bgColors, notifier: n),
        ],
      ),
    );
  }
}

class _Slider extends StatelessWidget {
  const _Slider(this.label, this.value, this.min, this.max, this.onChanged);
  final String label;
  final double value, min, max;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(
      children: [
        Text('$label: ${value.toStringAsFixed(0)}'),
        Slider(value: value, min: min, max: max, onChanged: onChanged),
      ],
    ),
  );
}

class _RandomColorsRow extends StatelessWidget {
  const _RandomColorsRow({required this.colors, required this.notifier});
  final List<Color> colors;
  final IconEditorNotifier notifier;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 8, runSpacing: 8,
    children: [
      ...colors.map((c) => GestureDetector(
        onTap: () {
          if (colors.length > 1) {
            notifier.setBgColors(colors.where((e) => e.toARGB32() != c.toARGB32()).toList());
          }
        },
        child: Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
            color: c, borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.close, color: Colors.white10, size: 16),
        ),
      )),
      ColorPicker(
        color: colors.first,
        onColorChangeEnd: (c) => notifier.setBgColors([...colors, c]),
        onColorChanged: (_) {},
        enableOpacity: true,
        width: 28, height: 28,
        pickersEnabled: const {
          ColorPickerType.wheel: true,
          ColorPickerType.primary: false,
          ColorPickerType.accent: false,
        },
      ),
    ],
  );
}
