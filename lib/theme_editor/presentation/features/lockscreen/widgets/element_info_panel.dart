import 'package:flex_color_picker/flex_color_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:miui_icon_generator/core/theme/app_radius.dart';
import '../../../../../core/theme/theme_extensions.dart';
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
    final colors = context.appColors;
    final scheme = Theme.of(context).colorScheme;
    final state = ref.watch(elementProvider);

    if (state.elements.isEmpty) return const SizedBox.shrink();

    final n = ref.read(elementProvider.notifier);

    if (state.isGroupMode && state.selectedTypes.isNotEmpty) {
      return _GroupPanel(state: state, n: n);
    }

    if (state.active == null) return const SizedBox.shrink();

    final el = state.active!;
    final isHourMinSec = el.type == ElementType.hourClock ||
        el.type == ElementType.minClock ||
        el.type == ElementType.secClock;
    // When digit colors are on, colorDigit1/colorDigit2 drive the render and
    // Primary/Secondary have no visual effect — hide them to avoid the
    // "picking a color does nothing" confusion.
    final usesDigitColors = isHourMinSec && el.useSeparateColors;
    // Only clock text and containers are actually painted with the
    // Primary→Secondary gradient (see _clock()/_container() in the preview) —
    // text/notification/etc. use a solid color, so gradient direction is moot there.
    final usesGradient =
        !usesDigitColors && (el.type.isContainer || el.type.isClock);

    return SizedBox(
      width: 450,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Element title header
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: colors.border),
            ),
            child: Row(
              children: [
                Icon(Icons.widgets_rounded,
                    size: 16, color: colors.primary),
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
                IconButton.outlined(
                  icon: const Icon(Icons.restart_alt_rounded, size: 18),
                  tooltip: 'Reset position',
                  visualDensity: VisualDensity.compact,
                  onPressed: () => n.resetPosition(el.type),
                ),
                const SizedBox(width: 4),
                IconButton.outlined(
                  icon: const Icon(Icons.delete_rounded, size: 18),
                  tooltip: 'Remove',
                  visualDensity: VisualDensity.compact,
                  style: IconButton.styleFrom(
                    foregroundColor: scheme.error,
                    side: BorderSide(color: scheme.error.withAlpha(60)),
                  ),
                  onPressed: el.type == ElementType.swipeUpUnlock
                      ? null
                      : () => n.remove(el.type),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

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

          if (!el.type.isIcon &&
              !el.type.isMusic &&
              !el.type.isVideo &&
              !el.type.isPng &&
              !usesDigitColors)
            _Section(
              title: 'COLOR',
              child: Column(
                children: [
                  Row(
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
                  if (usesGradient) ...[
                    const SizedBox(height: 10),
                    _GradAlignRow(
                      start: el.gradStartAlign,
                      end: el.gradEndAlign,
                      onStart: (a) => n.setGradStart(el.type, a),
                      onEnd: (a) => n.setGradEnd(el.type, a),
                    ),
                  ],
                ],
              ),
            ),

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
                  if (el.type == ElementType.hourClock ||
                      el.type == ElementType.minClock || el.type == ElementType.secClock) ...[
                    const SizedBox(height: 6),
                    _ToggleRow(
                      label: 'Separate Digit Colors',
                      value: el.useSeparateColors,
                      onChanged: (v) => n.setUseSeparateColors(el.type, v),
                    ),
                    if (el.useSeparateColors) ...[
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: _ColorBtn(
                              color: el.colorDigit1,
                              label: 'Digit 1',
                              onChanged: (c) => n.setColorDigit1(el.type, c),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _ColorBtn(
                              color: el.colorDigit2,
                              label: 'Digit 2',
                              onChanged: (c) => n.setColorDigit2(el.type, c),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ],
              ),
            ),

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
                const SizedBox(width: 6),
                IconButton.outlined(
                  icon: const Icon(Icons.align_horizontal_center, size: 18),
                  tooltip: 'Center horizontally',
                  visualDensity: VisualDensity.compact,
                  onPressed: () => n.centerHorizontal(el.type),
                ),
                const SizedBox(width: 4),
                IconButton.outlined(
                  icon: const Icon(Icons.align_vertical_center, size: 18),
                  tooltip: 'Center vertically',
                  visualDensity: VisualDensity.compact,
                  onPressed: () => n.centerVertical(el.type),
                ),
              ],
            ),
          ),

          _Section(
            title: el.type.isText ? 'FONT SIZE' : 'SCALE',
            child: Column(
              children: [
                _SliderRow(
                  label: el.type.isText ? 'Font Size' : 'Scale',
                  value: el.type.isText ? el.fontSize : el.scale,
                  min: 0,
                  max: el.type.isText ? 100 : 4,
                  onChanged: (v) => el.type.isText
                      ? n.setFontSize(el.type, v)
                      : n.setScale(el.type, v),
                ),
                const SizedBox(height: 4),
                _ScalePresets(
                  isText: el.type.isText,
                  value: el.type.isText ? el.fontSize : el.scale,
                  onSelected: (v) => el.type.isText
                      ? n.setFontSize(el.type, v)
                      : n.setScale(el.type, v),
                ),
              ],
            ),
          ),

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
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  _ColorBtn(
                    color: el.borderColor,
                    label: 'Border',
                    onChanged: (c) => n.setBorderColor(el.type, c),
                  ),
                ],
              ),
            ),

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

          if (!el.type.isIcon &&
              !el.type.isMusic &&
              !el.type.isContainer)
            _Section(
              title: 'ALIGNMENT',
              child: Row(
                children: [
                  Expanded(
                      child:
                          _AlignChip('Left', Alignment.centerLeft, el, n)),
                  const SizedBox(width: 6),
                  Expanded(
                      child: _AlignChip('Center', Alignment.center, el, n)),
                  const SizedBox(width: 6),
                  Expanded(
                      child: _AlignChip(
                          'Right', Alignment.centerRight, el, n)),
                ],
              ),
            ),

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
    );
  }

  Future<void> _copyAsset(
      WidgetRef ref, String src, LockElement el) async {
    final ws = ref.read(wallpaperProvider);
    if (ws.weekNum == null || ws.currentThemeName == null) return;
    final tp = PathConstants.themePath(ws.weekNum!, ws.currentThemeName!);
    final lsAdv = PathConstants.lockscreenAdvance(tp);
    final ext = el.type.isVideo ? 'mp4' : 'png';
    final resolvedPath =
        el.path.isNotEmpty ? el.path : el.type.defaultPath;
    final relative = resolvedPath.startsWith(r'')
        ? resolvedPath.substring(1)
        : resolvedPath;
    final dest = PathConstants.p('$lsAdv$relative.$ext');
    await ref.read(fileServiceProvider).copyFile(src, dest);
    ref.read(elementProvider.notifier).setGuideLines(el.type, false);
  }
}

// ── Group Mode Panel ──────────────────────────────────────────────────────────

class _GroupPanel extends StatefulWidget {
  const _GroupPanel({required this.state, required this.n});
  final ElementState state;
  final ElementNotifier n;

  @override
  State<_GroupPanel> createState() => _GroupPanelState();
}

class _GroupPanelState extends State<_GroupPanel> {
  final _xController = TextEditingController(text: '0');
  final _yController = TextEditingController(text: '0');

  @override
  void dispose() {
    _xController.dispose();
    _yController.dispose();
    super.dispose();
  }

  void _applyOffset() {
    final dx = double.tryParse(_xController.text) ?? 0;
    final dy = double.tryParse(_yController.text) ?? 0;
    if (dx != 0 || dy != 0) {
      widget.n.nudgeGroupElements(dx, dy);
      _xController.text = '0';
      _yController.text = '0';
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final state = widget.state;
    final n = widget.n;

    final selectedElements = state.elements
        .where((e) => state.selectedTypes.contains(e.type))
        .toList();
    final colorableElements = selectedElements
        .where((e) => !e.type.isIcon && !e.type.isMusic && !e.type.isVideo && !e.type.isPng)
        .toList();

    final firstColor = colorableElements.isNotEmpty ? colorableElements.first.color : Colors.white;

    return SizedBox(
      width: 450,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Group header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: context.appColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: context.appColors.border),
            ),
            child: Row(
              children: [
                Icon(Icons.select_all_rounded, size: 16, color: context.appColors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Group — ${state.selectedTypes.length} elements',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: scheme.onSurface,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: n.exitGroupMode,
                  icon: const Icon(Icons.close, size: 14),
                  label: const Text('Exit', style: TextStyle(fontSize: 12)),
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    foregroundColor: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // Position offset section
          _Section(
            title: 'POSITION OFFSET',
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _xController,
                        decoration: const InputDecoration(labelText: 'X'),
                        keyboardType: const TextInputType.numberWithOptions(signed: true),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _yController,
                        decoration: const InputDecoration(labelText: 'Y'),
                        keyboardType: const TextInputType.numberWithOptions(signed: true),
                      ),
                    ),
                    const SizedBox(width: 6),
                    IconButton.outlined(
                      icon: const Icon(Icons.align_horizontal_center, size: 18),
                      tooltip: 'Center all horizontally',
                      visualDensity: VisualDensity.compact,
                      onPressed: () {
                        for (final t in state.selectedTypes) {
                          n.centerHorizontal(t);
                        }
                      },
                    ),
                    const SizedBox(width: 4),
                    IconButton.outlined(
                      icon: const Icon(Icons.align_vertical_center, size: 18),
                      tooltip: 'Center all vertically',
                      visualDensity: VisualDensity.compact,
                      onPressed: () {
                        for (final t in state.selectedTypes) {
                          n.centerVertical(t);
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.tonal(
                    onPressed: _applyOffset,
                    child: const Text('Apply Offset'),
                  ),
                ),
              ],
            ),
          ),

          // Color section (only if there are colorable elements)
          if (colorableElements.isNotEmpty)
            _Section(
              title: 'COLOR',
              child: Row(
                children: [
                  Expanded(
                    child: _ColorBtn(
                      color: firstColor,
                      label: 'Primary',
                      onChanged: (c) => n.setGroupColor(c),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _ColorBtn(
                      color: colorableElements.first.colorSecondary,
                      label: 'Secondary',
                      onChanged: (c) => n.setGroupColorSecondary(c),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ── Section wrapper ───────────────────────────────────────────────────────────

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
        decoration: BoxDecoration(
          color: colors.surfaceOverlay,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: colors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Container(
                    width: 3,
                    height: 12,
                    margin: const EdgeInsets.only(right: 6),
                    decoration: BoxDecoration(
                      color: colors.primary,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: scheme.onSurfaceVariant,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
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
  const _ColorBtn({
    required this.color,
    required this.label,
    required this.onChanged,
  });
  final Color color;
  final String label;
  final ValueChanged<Color> onChanged;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<void>(
      offset: const Offset(0, 52),
      constraints: const BoxConstraints(minWidth: 260, maxWidth: 260),
      padding: EdgeInsets.zero,
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      itemBuilder: (_) {
        var pickerColor = color;
        return [
          PopupMenuItem<void>(
            enabled: false,
            padding: EdgeInsets.zero,
            height: 0,
            child: StatefulBuilder(
              builder: (_, setMenuState) => ColorPicker(
                color: pickerColor,
                onColorChanged: (c) {
                  setMenuState(() => pickerColor = c);
                  onChanged(c);
                },
                enableOpacity: true,
                opacityTrackHeight: 20,
                enableShadesSelection: false,
                showColorName: false,
                showMaterialName: false,
                showColorCode: true,
                colorCodeHasColor: true,
                wheelDiameter: 200,
                wheelWidth: 16,
                wheelSquarePadding: 8,
                columnSpacing: 4,
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
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
            ),
          ),
        ];
      },
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          height: 46,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: context.appColors.border),
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
                  Shadow(color: Colors.black54, offset: Offset(0, 1), blurRadius: 2),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Gradient Alignment Row ────────────────────────────────────────────────────

class _GradAlignRow extends StatelessWidget {
  const _GradAlignRow({
    required this.start,
    required this.end,
    required this.onStart,
    required this.onEnd,
  });
  final AlignmentGeometry start, end;
  final ValueChanged<AlignmentGeometry> onStart;
  final ValueChanged<AlignmentGeometry> onEnd;

  static const _alignOptions = {
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
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'GRADIENT DIRECTION',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: scheme.onSurfaceVariant,
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: _AlignDrop(
                value: start,
                options: _alignOptions,
                label: 'From',
                onChanged: onStart,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _AlignDrop(
                value: end,
                options: _alignOptions,
                label: 'To',
                onChanged: onEnd,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _AlignDrop extends StatelessWidget {
  const _AlignDrop({
    required this.value,
    required this.options,
    required this.label,
    required this.onChanged,
  });
  final AlignmentGeometry value;
  final Map<String, AlignmentGeometry> options;
  final String label;
  final ValueChanged<AlignmentGeometry> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: scheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(AppRadius.sm),
            border: Border.all(color: colors.border),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<AlignmentGeometry>(
              value: value,
              isExpanded: true,
              borderRadius: BorderRadius.circular(AppRadius.md),
              items: options.entries
                  .map((e) => DropdownMenuItem(
                        value: e.value,
                        child: Text(e.key, style: const TextStyle(fontSize: 12)),
                      ))
                  .toList(),
              onChanged: (v) {
                if (v != null) onChanged(v);
              },
            ),
          ),
        ),
      ],
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
    final colors = context.appColors;
    final scheme = Theme.of(context).colorScheme;
    final selected = el.align == align;
    return GestureDetector(
      onTap: () => n.setAlign(el.type, align),
      child: Container(
        height: 34,
        decoration: BoxDecoration(
          color: selected
              ? colors.primary.withAlpha(30)
              : colors.surface,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: selected
              ? Border.all(color: colors.primary.withAlpha(120), width: 1.5)
              : Border.all(color: colors.border),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight:
                  selected ? FontWeight.w700 : FontWeight.w500,
              color: selected ? colors.primary : scheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Scale Presets ─────────────────────────────────────────────────────────────

class _ScalePresets extends StatelessWidget {
  const _ScalePresets({
    required this.isText,
    required this.value,
    required this.onSelected,
  });

  final bool isText;
  final double value;
  final ValueChanged<double> onSelected;

  static const _scalePresets = [0.25, 0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0, 2.5, 3.0, 3.5, 4.0];
  static const _fontPresets = [8.0, 10.0, 12.0, 14.0, 16.0, 18.0, 20.0, 24.0, 28.0, 32.0, 36.0, 40.0, 48.0, 60.0, 72.0];

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final scheme = Theme.of(context).colorScheme;
    final presets = isText ? _fontPresets : _scalePresets;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        spacing: 4,
        children: presets.map((preset) {
        final selected = (value - preset).abs() < 0.01;
        final label = isText
            ? preset.toInt().toString()
            : preset == preset.truncateToDouble()
                ? '${preset.toInt()}×'
                : '$preset×';
        return GestureDetector(
          onTap: () => onSelected(preset),
          child: Container(
            height: 22,
            padding: const EdgeInsets.symmetric(horizontal: 7),
            decoration: BoxDecoration(
              color: selected ? colors.primary.withAlpha(25) : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: selected ? colors.primary.withAlpha(140) : colors.border,
                width: 1,
              ),
            ),
            child: Center(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                  color: selected ? colors.primary : scheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
        );
        }).toList(),
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
        Text(label,
            style: TextStyle(fontSize: 13, color: scheme.onSurface)),
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
            _EditableValue(
              value: value,
              onChanged: onChanged,
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

class _EditableValue extends StatefulWidget {
  const _EditableValue({required this.value, required this.onChanged});
  final double value;
  final ValueChanged<double> onChanged;

  @override
  State<_EditableValue> createState() => _EditableValueState();
}

class _EditableValueState extends State<_EditableValue> {
  late final TextEditingController _controller;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value.toStringAsFixed(2));
  }

  @override
  void didUpdateWidget(covariant _EditableValue oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value && !_isEditing) {
      _controller.text = widget.value.toStringAsFixed(2);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: 60,
      height: 24,
      child: _isEditing
          ? TextField(
              controller: _controller,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: scheme.onPrimaryContainer,
              ),
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.all(0),
                filled: true,
                fillColor: scheme.primaryContainer,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
              onSubmitted: (value) {
                final newValue = double.tryParse(value);
                if (newValue != null) {
                  widget.onChanged(newValue.clamp(0, 300));
                }
                setState(() => _isEditing = false);
              },
            )
          : GestureDetector(
              onTap: () => setState(() => _isEditing = true),
              child: Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: scheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  widget.value.toStringAsFixed(2),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: scheme.onPrimaryContainer,
                  ),
                ),
              ),
            ),
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
  late final FocusNode _focus;

  @override
  void initState() {
    super.initState();
    _c = TextEditingController(text: widget.value.toStringAsFixed(0));
    _focus = FocusNode();
  }

  @override
  void didUpdateWidget(_NumField o) {
    super.didUpdateWidget(o);
    // Only sync from external value changes when the user isn't typing in the field.
    // Updating the controller while focused resets the selection mid-edit.
    if (o.value != widget.value && !_focus.hasFocus) {
      _c.text = widget.value.toStringAsFixed(0);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => TextField(
        controller: _c,
        focusNode: _focus,
        decoration: InputDecoration(labelText: widget.label),
        keyboardType: const TextInputType.numberWithOptions(signed: true),
        onChanged: (v) {
          final d = double.tryParse(v);
          if (d != null) widget.onChanged(d);
        },
      );
}
