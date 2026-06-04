import 'package:flex_color_picker/flex_color_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:miui_icon_generator/core/theme/app_theme.dart';
import 'package:morphable_shape/morphable_shape.dart';
import 'package:miui_icon_generator/theme_editor/domain/entities/icon_effect.dart';
import 'package:miui_icon_generator/theme_editor/domain/entities/icon_shape.dart';
import 'package:miui_icon_generator/theme_editor/domain/entities/icon_texture.dart';
import 'package:miui_icon_generator/theme_editor/presentation/providers/icon_editor_provider.dart';
import 'package:miui_icon_generator/theme_editor/presentation/providers/wallpaper_provider.dart';
import '../utils/icon_shape_utils.dart';
import '../utils/icon_visual_utils.dart';

class SlidersPanel extends ConsumerWidget {
  const SlidersPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(iconEditorProvider);
    final n = ref.read(iconEditorProvider.notifier);
    final scheme = Theme.of(context).colorScheme;
    
    const cardBg = AppTheme.proCard;
    const borderColor = Colors.black;

    return Container(
      width: 450,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min, 
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel('SHAPE', scheme),
          _ShapeSelector(current: s.shape, onSelected: n.setIconShape, state: s),
          const SizedBox(height: 12),
          _sectionLabel('EFFECTS', scheme),
          _EffectSelector(current: s.effect, onSelected: n.setIconEffect, state: s),
          if (s.effect != IconEffect.none) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: _Slider('Intensity', s.effectIntensity, 0, 1, n.setEffectIntensity, isPercent: true)),
                const SizedBox(width: 8),
                Expanded(child: _Slider('Blur', s.effectBlur, 0, 100, n.setEffectBlur)),
              ],
            ),
            _Slider('Elevation', s.effectElevation, 0, 20, n.setEffectElevation),
          ],
          const SizedBox(height: 12),
          _sectionLabel('TEXTURES', scheme),
          _TextureSelector(current: s.texture, onSelected: n.setIconTexture, state: s),
          if (s.texture != IconTexture.none) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: _Slider('Scale', s.textureScale, 0.1, 5, n.setTextureScale)),
                const SizedBox(width: 8),
                Expanded(child: _Slider('Opacity', s.textureOpacity, 0, 1, n.setTextureOpacity, isPercent: true)),
              ],
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _Slider('Radius', s.radius, 0, 20, n.setRadius),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _Slider('Border', s.borderWidth, 0, 20, n.setBorderWidth),
              ),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: _Slider('Margin', s.margin, 0, 20, n.setMargin),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _Slider('Padding', s.padding, 0, 20, n.setPadding),
              ),
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

// ── Shape Selector ────────────────────────────────────────────────────────────

class _ShapeSelector extends StatelessWidget {
  const _ShapeSelector({required this.current, required this.onSelected, required this.state});
  final IconShape current;
  final ValueChanged<IconShape> onSelected;
  final IconEditorState state;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppTheme.proSidebar,
        borderRadius: BorderRadius.circular(12),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: IconShape.values.map((shape) {
            final isSelected = shape == current;
            return Padding(
              padding: const EdgeInsets.only(right: 10),
              child: InkWell(
                onTap: () => onSelected(shape),
                borderRadius: BorderRadius.circular(12),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 80,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? scheme.primary : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? Colors.transparent
                          : scheme.outlineVariant.withAlpha(80),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        shape.label,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight:
                              isSelected ? FontWeight.w700 : FontWeight.w500,
                          color:
                              isSelected ? scheme.onPrimary : scheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: 32,
                        height: 32,
                        child: CustomPaint(
                          painter: _PreviewPainter(
                            shape: shape,
                            color: isSelected ? scheme.onPrimary : scheme.primary,
                            state: state,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

// ── Effect Selector ───────────────────────────────────────────────────────────

class _EffectSelector extends StatelessWidget {
  const _EffectSelector({required this.current, required this.onSelected, required this.state});
  final IconEffect current;
  final ValueChanged<IconEffect> onSelected;
  final IconEditorState state;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppTheme.proSidebar,
        borderRadius: BorderRadius.circular(12),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: IconEffect.values.map((effect) {
            final isSelected = effect == current;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: InkWell(
                onTap: () => onSelected(effect),
                borderRadius: BorderRadius.circular(12),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 75,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? scheme.primary : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? Colors.transparent
                          : scheme.outlineVariant.withAlpha(80),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        effect.label,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected ? scheme.onPrimary : scheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 6),
                      SizedBox(
                        width: 28,
                        height: 28,
                        child: CustomPaint(
                          painter: _PreviewPainter(
                            shape: state.shape,
                            effect: effect,
                            color: isSelected ? scheme.onPrimary : scheme.primary,
                            state: state,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

// ── Texture Selector ──────────────────────────────────────────────────────────

class _TextureSelector extends StatelessWidget {
  const _TextureSelector({required this.current, required this.onSelected, required this.state});
  final IconTexture current;
  final ValueChanged<IconTexture> onSelected;
  final IconEditorState state;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppTheme.proSidebar,
        borderRadius: BorderRadius.circular(12),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: IconTexture.values.map((texture) {
            final isSelected = texture == current;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: InkWell(
                onTap: () => onSelected(texture),
                borderRadius: BorderRadius.circular(12),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 75,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? scheme.primary : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? Colors.transparent
                          : scheme.outlineVariant.withAlpha(80),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        texture.label,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected ? scheme.onPrimary : scheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 6),
                      SizedBox(
                        width: 28,
                        height: 28,
                        child: CustomPaint(
                          painter: _PreviewPainter(
                            shape: state.shape,
                            texture: texture,
                            color: isSelected ? scheme.onPrimary : scheme.primary,
                            state: state,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _PreviewPainter extends CustomPainter {
  final IconShape shape;
  final IconEffect? effect;
  final IconTexture? texture;
  final Color color;
  final IconEditorState state;

  _PreviewPainter({
    required this.shape,
    this.effect,
    this.texture,
    required this.color,
    required this.state,
  });

  @override
  void paint(Canvas canvas, Size size) {
    try {
      final rect = Offset.zero & size;
      final shapeBorder = IconShapeUtils.getBorder(shape, 5, scale: 1.0);
      final path = (shapeBorder as OutlinedShapeBorder).getOuterPath(rect);

      final isHighLuminance = color.computeLuminance() > 0.5;
      final paint = Paint()..color = color.withAlpha(isHighLuminance ? 120 : 80);
      canvas.drawPath(path, paint);

      IconVisualUtils.applyTexture(
        canvas, 
        path, 
        texture ?? state.texture, 
        rect,
        scale: state.textureScale,
        opacity: state.textureOpacity,
      );
      IconVisualUtils.applyEffect(
        canvas, 
        path, 
        effect ?? state.effect, 
        rect, 
        color,
        intensity: state.effectIntensity,
        blur: state.effectBlur,
        elevation: state.effectElevation,
      );
    } catch (e) {
      debugPrint('Icon preview error: $e');
    }
  }

  @override
  bool shouldRepaint(covariant _PreviewPainter oldDelegate) => true;
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
  const _Slider(this.label, this.value, this.min, this.max, this.onChanged, {this.isPercent = false});
  final String label;
  final double value, min, max;
  final ValueChanged<double> onChanged;
  final bool isPercent;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
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
                    isPercent ? '${(value * 100).toStringAsFixed(0)}%' : value.toStringAsFixed(1),
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
          Slider(
            value: value, 
            min: min, 
            max: max, 
            onChanged: onChanged,
            activeColor: AppTheme.accent,
          ),
        ],
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.proSidebar,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black),
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
            activeThumbColor: AppTheme.accent,
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
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppTheme.proSidebar,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black),
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
            showColorCode: true,
            colorCodeHasColor: true,
            copyPasteBehavior: const ColorPickerCopyPasteBehavior(
              copyButton: true,
              pasteButton: true,
              longPressMenu: true,
              copyFormat: ColorPickerCopyFormat.numHexAARRGGBB,
            ),
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
