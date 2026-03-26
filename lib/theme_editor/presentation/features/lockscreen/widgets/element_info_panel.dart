import 'package:flex_color_picker/flex_color_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:miui_icon_generator/core/theme/app_theme.dart';
import '../../../../domain/entities/element_widget.dart';
import '../../../providers/element_provider.dart';
import '../../../common/widgets/drop_zone.dart';
import '../../../../core/constants/path_constants.dart';
import '../../../providers/wallpaper_provider.dart';
import '../../../providers/service_providers.dart';

class ElementInfoPanel extends ConsumerWidget {
  const ElementInfoPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(elementProvider);
    final scheme = Theme.of(context).colorScheme;

    if (state.elements.isEmpty || state.active == null) {
      return SizedBox(
        width: 300,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.touch_app_rounded,
                  size: 40, color: scheme.onSurfaceVariant.withAlpha(80)),
              const SizedBox(height: 8),
              Text(
                'Select a widget',
                style: TextStyle(
                  fontSize: 13,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final el = state.active!;
    final n = ref.read(elementProvider.notifier);

    return SizedBox(
      width: 300,
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(right: 8, bottom: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Element title header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppTheme.accent.withAlpha(30),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: AppTheme.accent.withAlpha(60), width: 1.5),
              ),
              child: Row(
                children: [
                  const Icon(Icons.widgets_rounded,
                      size: 16, color: AppTheme.accent),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      el.name,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: scheme.onSurface,
                      ),
                    ),
                  ),
                  // Reset + Delete
                  IconButton(
                    icon: const Icon(Icons.restart_alt_rounded,
                        size: 18, color: AppTheme.accent),
                    tooltip: 'Reset position',
                    padding: EdgeInsets.zero,
                    constraints:
                        const BoxConstraints(minWidth: 32, minHeight: 32),
                    onPressed: () => n.resetPosition(el.type),
                  ),
                  IconButton(
                    icon: Icon(Icons.delete_rounded,
                        size: 18, color: scheme.error),
                    tooltip: 'Remove',
                    padding: EdgeInsets.zero,
                    constraints:
                        const BoxConstraints(minWidth: 32, minHeight: 32),
                    onPressed: () => n.remove(el.type),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // Drop zone for asset-based widgets
            if (el.type.isIcon ||
                el.type.isMusic ||
                el.type.isVideo ||
                el.type.isPng)
              _Section(
                title: 'ASSET',
                child: Center(
                  child: AppDropZone(
                    label: 'Drop ${el.type.isVideo ? "MP4" : "PNG"}',
                    allowedExtensions:
                        el.type.isVideo ? ['.mp4'] : ['.png', '.jpg'],
                    onDropped: (path) => _copyAsset(ref, path, el),
                  ),
                ),
              ),

            // Colors
            if (!el.type.isIcon &&
                !el.type.isMusic &&
                !el.type.isVideo &&
                !el.type.isPng)
              _Section(
                title: 'COLOR',
                child: Row(
                  children: [
                    Expanded(
                      child: _ColorBtn(
                        color: el.color,
                        label: 'Primary',
                        onChanged: (c) => n.setColor(el.type, c),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _ColorBtn(
                        color: el.colorSecondary,
                        label: 'Secondary',
                        onChanged: (c) => n.setColorSecondary(el.type, c),
                      ),
                    ),
                  ],
                ),
              ),

            // Clock options
            if (el.type.isClock && !el.type.isIcon)
              _Section(
                title: 'CLOCK OPTIONS',
                child: Column(
                  children: [
                    _ToggleRow(
                      label: 'Short format',
                      value: el.isShort,
                      onChanged: (v) => n.setIsShort(el.type, v),
                    ),
                    const SizedBox(height: 6),
                    _ToggleRow(
                      label: 'Wrap text',
                      value: el.isWrap,
                      onChanged: (v) => n.setIsWrap(el.type, v),
                    ),
                  ],
                ),
              ),

            // Position
            _Section(
              title: 'POSITION',
              child: Row(
                children: [
                  Expanded(
                    child: _NumField(
                      label: 'X',
                      value: el.dx,
                      onChanged: (v) => n.setPosition(el.type, v, el.dy),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _NumField(
                      label: 'Y',
                      value: el.dy,
                      onChanged: (v) => n.setPosition(el.type, el.dx, v),
                    ),
                  ),
                ],
              ),
            ),

            // Scale / FontSize
            _Section(
              title: el.type.isText ? 'FONT SIZE' : 'SCALE',
              child: _SliderRow(
                label: el.type.isText ? 'Font Size' : 'Scale',
                value: el.type.isText ? el.fontSize : el.scale,
                min: 0,
                max: el.type.isText ? 100 : 4,
                onChanged: (v) => el.type.isText
                    ? n.setFontSize(el.type, v)
                    : n.setScale(el.type, v),
              ),
            ),

            // Container properties
            if (el.type.isContainer)
              _Section(
                title: 'CONTAINER',
                child: Column(
                  children: [
                    _SliderRow(
                      label: 'Height',
                      value: el.height,
                      min: 0,
                      max: 800,
                      onChanged: (v) => n.setHeight(el.type, v),
                    ),
                    _SliderRow(
                      label: 'Width',
                      value: el.width,
                      min: 0,
                      max: 400,
                      onChanged: (v) => n.setWidth(el.type, v),
                    ),
                    _SliderRow(
                      label: 'Border Radius',
                      value: el.radius,
                      min: 0,
                      max: 200,
                      onChanged: (v) => n.setRadius(el.type, v),
                    ),
                    _SliderRow(
                      label: 'Border Width',
                      value: el.borderWidth,
                      min: 0,
                      max: 10,
                      onChanged: (v) => n.setBorderWidth(el.type, v),
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Border Color',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    ColorPicker(
                      color: el.borderColor,
                      onColorChanged: (c) => n.setBorderColor(el.type, c),
                      enableOpacity: true,
                      pickersEnabled: const {ColorPickerType.wheel: true},
                    ),
                  ],
                ),
              ),

            // Text expression
            if (el.type.isText)
              _Section(
                title: 'TEXT / EXPRESSION',
                child: TextField(
                  controller: TextEditingController(text: el.text)
                    ..selection =
                        TextSelection.collapsed(offset: el.text.length),
                  decoration: const InputDecoration(
                    hintText: 'Enter text or expression…',
                  ),
                  onChanged: (v) => n.setText(el.type, v),
                ),
              ),

            // Alignment chips
            if (!el.type.isIcon && !el.type.isMusic && !el.type.isContainer)
              _Section(
                title: 'ALIGNMENT',
                child: Row(
                  children: [
                    Expanded(
                        child: _AlignChip('Left', Alignment.centerLeft, el, n)),
                    const SizedBox(width: 6),
                    Expanded(
                        child: _AlignChip('Center', Alignment.center, el, n)),
                    const SizedBox(width: 6),
                    Expanded(
                        child:
                            _AlignChip('Right', Alignment.centerRight, el, n)),
                  ],
                ),
              ),

            // Angle
            _Section(
              title: 'ROTATION',
              child: _SliderRow(
                label: 'Angle',
                value: el.angle,
                min: 0,
                max: 360,
                divisions: 36,
                onChanged: (v) => n.setAngle(el.type, v),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _copyAsset(WidgetRef ref, String src, LockElement el) async {
    final ws = ref.read(wallpaperProvider);
    if (ws.weekNum == null || ws.currentThemeName == null) return;
    final tp = PathConstants.themePath(ws.weekNum!, ws.currentThemeName!);
    final lsAdv = PathConstants.lockscreenAdvance(tp);
    final ext = el.type.isVideo ? 'mp4' : 'png';
    final resolvedPath = el.path.isNotEmpty ? el.path : el.type.defaultPath;
    final relative = resolvedPath.startsWith(r'\') ? resolvedPath.substring(1) : resolvedPath;
    final dest = PathConstants.p('$lsAdv$relative.$ext');
    await ref.read(fileServiceProvider).copyFile(src, dest);
    ref.read(elementProvider.notifier).setGuideLines(el.type, false);
  }
}

// ── Section wrapper ───────────────────────────────────────────────────────────

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.cardDark : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: isDark
                  ? Colors.white.withAlpha(18)
                  : Colors.black.withAlpha(15)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurfaceVariant,
                  letterSpacing: 0.8,
                ),
              ),
            ),
            child,
          ],
        ),
      ),
    );
  }
}

// ── Color Button ──────────────────────────────────────────────────────────────

class _ColorBtn extends StatelessWidget {
  const _ColorBtn(
      {required this.color, required this.label, required this.onChanged});
  final Color color;
  final String label;
  final ValueChanged<Color> onChanged;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: () => ColorPicker(
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
      child: Container(
        height: 46,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: isDark
                  ? Colors.white.withAlpha(18)
                  : Colors.black.withAlpha(15)),
          boxShadow: [
            BoxShadow(
              color: color.withAlpha(70),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Center(
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 12,
              shadows: [
                Shadow(
                    color: Colors.black54, offset: Offset(0, 1), blurRadius: 2),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Align Chip ────────────────────────────────────────────────────────────────

class _AlignChip extends StatelessWidget {
  const _AlignChip(this.label, this.align, this.el, this.n);
  final String label;
  final AlignmentGeometry align;
  final LockElement el;
  final ElementNotifier n;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final selected = el.align == align;
    return GestureDetector(
      onTap: () => n.setAlign(el.type, align),
      child: Container(
        height: 34,
        decoration: BoxDecoration(
          color: selected
              ? AppTheme.accent.withAlpha(30)
              : isDark
                  ? AppTheme.surfaceDark
                  : const Color(0xFFF0F0F5),
          borderRadius: BorderRadius.circular(10),
          border: selected
              ? Border.all(color: AppTheme.accent.withAlpha(120), width: 1.5)
              : null,
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: selected ? AppTheme.accent : scheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Toggle Row ────────────────────────────────────────────────────────────────

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
    required this.label,
    required this.value,
    required this.onChanged,
  });
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Text(label, style: TextStyle(fontSize: 13, color: scheme.onSurface)),
        const Spacer(),
        Switch.adaptive(value: value, onChanged: onChanged),
      ],
    );
  }
}

// ── Slider Row ────────────────────────────────────────────────────────────────

class _SliderRow extends StatelessWidget {
  const _SliderRow({
    required this.label,
    required this.value,
    required this.onChanged,
    this.min = 0,
    required this.max,
    this.divisions,
  });
  final String label;
  final double value, min, max;
  final int? divisions;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
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
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
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
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: divisions,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

// ── Num Field ─────────────────────────────────────────────────────────────────

class _NumField extends StatefulWidget {
  const _NumField(
      {required this.label, required this.value, required this.onChanged});
  final String label;
  final double value;
  final ValueChanged<double> onChanged;

  @override
  State<_NumField> createState() => _NumFieldState();
}

class _NumFieldState extends State<_NumField> {
  late final TextEditingController _c;

  @override
  void initState() {
    super.initState();
    _c = TextEditingController(text: widget.value.toStringAsFixed(0));
  }

  @override
  void didUpdateWidget(_NumField o) {
    super.didUpdateWidget(o);
    if (o.value != widget.value) _c.text = widget.value.toStringAsFixed(0);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => TextField(
        controller: _c,
        decoration: InputDecoration(labelText: widget.label),
        keyboardType: const TextInputType.numberWithOptions(signed: true),
        onChanged: (v) {
          final d = double.tryParse(v);
          if (d != null) widget.onChanged(d);
        },
      );
}
