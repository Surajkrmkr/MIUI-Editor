import 'package:flex_color_picker/flex_color_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:miui_icon_generator/core/theme/app_theme.dart';
import '../../../../presentation/providers/icon_editor_provider.dart';
import '../../../../presentation/providers/wallpaper_provider.dart';

class SlidersPanel extends ConsumerWidget {
  const SlidersPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(iconEditorProvider);
    final n = ref.read(iconEditorProvider.notifier);
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppTheme.cardDark : Colors.white;
    final borderColor = isDark ? Colors.white.withAlpha(18) : Colors.black.withAlpha(15);

    return Container(
      width: 500,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel('SHAPE', scheme),
          Row(
            children: [
              _Slider('Radius', s.radius, 0, 20, n.setRadius),
              const SizedBox(width: 8),
              _Slider('Border', s.borderWidth, 0, 20, n.setBorderWidth),
            ],
          ),
          Row(
            children: [
              _Slider('Margin', s.margin, 0, 20, n.setMargin),
              const SizedBox(width: 8),
              _Slider('Padding', s.padding, 0, 20, n.setPadding),
            ],
          ),
          const SizedBox(height: 8),
          _sectionLabel('COLORS', scheme),
          _ModernSwitch(
            value: s.randomColors,
            title: 'Random Colors',
            onChanged: (v) {
              n.setRandomColors(v);
              if (v) {
                final palette = ref.read(wallpaperProvider).colorPalette;
                final dark = palette
                    .where((c) =>
                        ThemeData.estimateBrightnessForColor(c) ==
                        Brightness.dark)
                    .toList();
                if (dark.isNotEmpty) n.setBgColors(dark);
              }
            },
          ),
          if (s.randomColors) ...[
            const SizedBox(height: 8),
            _RandomColorsRow(colors: s.bgColors, notifier: n),
          ],
        ],
      ),
    );
  }
}

Widget _sectionLabel(String text, ColorScheme scheme) => Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 12,
            margin: const EdgeInsets.only(right: 6),
            decoration: BoxDecoration(
              color: AppTheme.accent,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Text(
            text,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: scheme.onSurfaceVariant,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );

// ── Slider ────────────────────────────────────────────────────────────────────

class _Slider extends StatelessWidget {
  const _Slider(this.label, this.value, this.min, this.max, this.onChanged);
  final String label;
  final double value, min, max;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: scheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    value.toStringAsFixed(0),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: scheme.onPrimaryContainer,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Slider(value: value, min: min, max: max, onChanged: onChanged),
        ],
      ),
    );
  }
}

// ── Modern Switch ─────────────────────────────────────────────────────────────

class _ModernSwitch extends StatelessWidget {
  const _ModernSwitch({
    required this.value,
    required this.title,
    required this.onChanged,
  });
  final bool value;
  final String title;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.surfaceDark : const Color(0xFFF0F0F5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: scheme.onSurface,
            ),
          ),
          const Spacer(),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: scheme.primary,
          ),
        ],
      ),
    );
  }
}

// ── Random Colors Row ─────────────────────────────────────────────────────────

class _RandomColorsRow extends StatelessWidget {
  const _RandomColorsRow({required this.colors, required this.notifier});
  final List<Color> colors;
  final IconEditorNotifier notifier;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.surfaceDark : const Color(0xFFF0F0F5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          ...colors.map((c) => GestureDetector(
                onTap: () {
                  if (colors.length > 1) {
                    notifier.setBgColors(colors
                        .where((e) => e.toARGB32() != c.toARGB32())
                        .toList());
                  }
                },
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: c,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: Colors.white.withAlpha(50), width: 1.5),
                  ),
                  child: Icon(Icons.close_rounded,
                      color: Colors.white.withAlpha(180), size: 14),
                ),
              )),
          ColorPicker(
            color: colors.first,
            onColorChangeEnd: (c) => notifier.setBgColors([...colors, c]),
            onColorChanged: (_) {},
            enableOpacity: true,
            width: 28,
            height: 28,
            pickersEnabled: const {
              ColorPickerType.wheel: true,
              ColorPickerType.primary: false,
              ColorPickerType.accent: false,
            },
          ),
        ],
      ),
    );
  }
}
