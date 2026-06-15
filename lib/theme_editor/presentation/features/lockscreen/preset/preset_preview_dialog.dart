import 'dart:math';
import 'package:flex_color_picker/flex_color_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:miui_icon_generator/core/theme/app_radius.dart';
import 'package:miui_icon_generator/widgets/iphone_frame.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../domain/entities/element_widget.dart';
import '../../../providers/wallpaper_provider.dart';
import 'preset_thumbnail.dart';

const _frameW = AppConstants.screenWidth + 26;
const _frameH = AppConstants.screenHeight + 16;

/// Two-column interactive preview dialog.
///
/// Left  — phone preview (scales to fit available height).
/// Right — preset name, per-colour remapping slots, wallpaper palette, actions.
class PresetPreviewDialog extends ConsumerStatefulWidget {
  const PresetPreviewDialog({
    super.key,
    required this.elements,
    required this.presetName,
    required this.onApply,
  });

  final List<LockElement> elements;
  final String presetName;
  final ValueChanged<List<LockElement>> onApply;

  @override
  ConsumerState<PresetPreviewDialog> createState() =>
      _PresetPreviewDialogState();
}

class _PresetPreviewDialogState extends ConsumerState<PresetPreviewDialog> {
  /// originalColor → replacementColor chosen by user.
  final Map<Color, Color> _colorMap = {};

  /// Which slot is currently expanded for editing. null = none.
  Color? _expandedSlot;

  late final List<Color> _presetColors;

  @override
  void initState() {
    super.initState();
    _presetColors = extractPresetColors(widget.elements).toList();
  }

  @override
  Widget build(BuildContext context) {
    final wallState = ref.watch(wallpaperProvider);
    final palette = wallState.colorPalette;
    final screenH = MediaQuery.of(context).size.height;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final dialogH = (screenH * 0.88).clamp(480.0, 820.0);
    const controlsW = 270.0;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      clipBehavior: Clip.antiAlias,
      insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 28),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 640, maxHeight: dialogH),
        child: SizedBox(
        height: dialogH,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── LEFT: phone preview ──────────────────────────────────────────
            Expanded(
              child: Container(
                color: cs.surfaceContainerHighest.withAlpha(80),
                child: LayoutBuilder(builder: (_, box) {
                  final scale = min(
                    (box.maxWidth - 32) / _frameW,
                    (box.maxHeight - 32) / _frameH,
                  ).clamp(0.3, 1.0);
                  final sw = _frameW * scale;
                  final sh = _frameH * scale;
                  return Center(
                    child: SizedBox(
                      width: sw,
                      height: sh,
                      child: OverflowBox(
                        alignment: Alignment.topLeft,
                        maxWidth: _frameW,
                        maxHeight: _frameH,
                        child: Transform.scale(
                          scale: scale,
                          alignment: Alignment.topLeft,
                          child: IPhoneFrame(
                            child: PresetThumbnail(
                              elements: widget.elements,
                              thumbnailWidth: AppConstants.screenWidth,
                              colorMap:
                                  _colorMap.isEmpty ? null : Map.of(_colorMap),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),

            // ── RIGHT: controls ──────────────────────────────────────────────
            SizedBox(
              width: controlsW,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header
                  _Header(
                    presetName: widget.presetName,
                    hasChanges: _colorMap.isNotEmpty,
                    onReset: () => setState(() {
                      _colorMap.clear();
                      _expandedSlot = null;
                    }),
                  ),

                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ── Preset colour slots ────────────────────────────
                          if (_presetColors.isNotEmpty) ...[
                            _SectionLabel(
                              icon: Icons.color_lens_rounded,
                              label: 'Preset Colours',
                              badge: '${_presetColors.length}',
                            ),
                            const SizedBox(height: 6),
                            ..._presetColors.map((orig) => _ColorSlot(
                                  originalColor: orig,
                                  mappedColor: _colorMap[orig],
                                  palette: palette,
                                  isExpanded: _expandedSlot == orig,
                                  onToggle: () => setState(() {
                                    _expandedSlot =
                                        _expandedSlot == orig ? null : orig;
                                  }),
                                  onPickColor: (picked) => setState(() {
                                    _colorMap[orig] = picked;
                                    _expandedSlot = null;
                                  }),
                                  onClear: () => setState(() {
                                    _colorMap.remove(orig);
                                    if (_expandedSlot == orig) {
                                      _expandedSlot = null;
                                    }
                                  }),
                                )),
                            const SizedBox(height: 14),
                          ],

                          // ── Wallpaper palette quick-pick ───────────────────
                          if (palette.isNotEmpty) ...[
                            const _SectionLabel(
                              icon: Icons.wallpaper_rounded,
                              label: 'Wallpaper Palette',
                            ),
                            const SizedBox(height: 8),
                            _PaletteGrid(
                              palette: palette,
                              colorMap: _colorMap,
                              presetColors: _presetColors,
                              onApplyToAll: (picked) => setState(() {
                                for (final c in _presetColors) {
                                  _colorMap[c] = picked;
                                }
                                _expandedSlot = null;
                              }),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  // Footer actions
                  const Divider(height: 1),
                  _Footer(
                    onCancel: () => Navigator.pop(context),
                    onApply: () {
                      widget.onApply(_applyColorMap(widget.elements, _colorMap));
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }

  List<LockElement> _applyColorMap(
      List<LockElement> elements, Map<Color, Color> colorMap) {
    if (colorMap.isEmpty) return elements;
    Color remap(Color c) => colorMap[c] ?? c;
    return elements
        .map((el) => el.copyWith(
              color: remap(el.color),
              colorSecondary: remap(el.colorSecondary),
              colorDigit1: remap(el.colorDigit1),
              colorDigit2: remap(el.colorDigit2),
              borderColor: remap(el.borderColor),
            ))
        .toList();
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  const _Header({
    required this.presetName,
    required this.hasChanges,
    required this.onReset,
  });
  final String presetName;
  final bool hasChanges;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: cs.outlineVariant)),
      ),
      padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
      child: Row(
        children: [
          Icon(Icons.style_rounded, color: cs.primary, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              presetName,
              style: theme.textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.w700),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (hasChanges)
            Tooltip(
              message: 'Reset colours',
              child: IconButton(
                onPressed: onReset,
                icon: Icon(Icons.restart_alt_rounded,
                    size: 16, color: cs.onSurfaceVariant),
                style: IconButton.styleFrom(
                    minimumSize: const Size(28, 28)),
              ),
            ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close_rounded, size: 18),
            style: IconButton.styleFrom(minimumSize: const Size(28, 28)),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _Footer extends StatelessWidget {
  const _Footer({required this.onCancel, required this.onApply});
  final VoidCallback onCancel;
  final VoidCallback onApply;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: onCancel,
              child: const Text('Cancel'),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: FilledButton.icon(
              onPressed: onApply,
              icon: const Icon(Icons.check_rounded, size: 15),
              label: const Text('Apply'),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.icon, required this.label, this.badge});
  final IconData icon;
  final String label;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Row(
      children: [
        Icon(icon, size: 12, color: cs.primary),
        const SizedBox(width: 5),
        Text(
          label.toUpperCase(),
          style: theme.textTheme.labelSmall?.copyWith(
            color: cs.primary,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
            fontSize: 10,
          ),
        ),
        if (badge != null) ...[
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
            decoration: BoxDecoration(
              color: cs.primaryContainer,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(badge!,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: cs.onPrimaryContainer,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                )),
          ),
        ],
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

/// One expandable row for a single preset colour slot.
class _ColorSlot extends StatefulWidget {
  const _ColorSlot({
    required this.originalColor,
    required this.palette,
    required this.isExpanded,
    required this.onToggle,
    required this.onPickColor,
    required this.onClear,
    this.mappedColor,
  });

  final Color originalColor;
  final Color? mappedColor;
  final List<Color> palette;
  final bool isExpanded;
  final VoidCallback onToggle;
  final ValueChanged<Color> onPickColor;
  final VoidCallback onClear;

  @override
  State<_ColorSlot> createState() => _ColorSlotState();
}

class _ColorSlotState extends State<_ColorSlot> {
  bool _showCustom = false;
  late Color _customColor;

  @override
  void initState() {
    super.initState();
    _customColor = widget.mappedColor ?? widget.originalColor;
  }

  @override
  void didUpdateWidget(_ColorSlot old) {
    super.didUpdateWidget(old);
    if (!widget.isExpanded) _showCustom = false;
    if (widget.mappedColor != old.mappedColor) {
      _customColor = widget.mappedColor ?? widget.originalColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isMapped = widget.mappedColor != null;
    final displayColor = widget.mappedColor ?? widget.originalColor;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: isMapped
            ? cs.primaryContainer.withAlpha(60)
            : cs.surfaceContainerHighest.withAlpha(60),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: isMapped
              ? cs.primary.withAlpha(80)
              : cs.outlineVariant.withAlpha(80),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Row header ───────────────────────────────────────────────────
          InkWell(
            onTap: widget.onToggle,
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Row(
                children: [
                  _Swatch(color: widget.originalColor, size: 22),
                  const SizedBox(width: 6),
                  Icon(Icons.arrow_forward_rounded,
                      size: 12, color: cs.onSurfaceVariant),
                  const SizedBox(width: 6),
                  _Swatch(
                    color: displayColor,
                    size: 22,
                    ring: isMapped ? cs.primary : null,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      _hexOf(isMapped ? displayColor : widget.originalColor),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: isMapped
                            ? cs.onSurfaceVariant
                            : cs.onSurfaceVariant.withAlpha(120),
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                  if (isMapped)
                    GestureDetector(
                      onTap: widget.onClear,
                      child: Icon(Icons.close_rounded,
                          size: 14, color: cs.error),
                    ),
                  const SizedBox(width: 4),
                  Icon(
                    widget.isExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    size: 14,
                    color: cs.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),

          // ── Expanded picker ──────────────────────────────────────────────
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 180),
            firstCurve: Curves.easeOut,
            secondCurve: Curves.easeIn,
            crossFadeState: widget.isExpanded
                ? CrossFadeState.showFirst
                : CrossFadeState.showSecond,
            firstChild: Padding(
              padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(height: 10),

                  if (!_showCustom) ...[
                    // ── Palette quick-pick ─────────────────────────────────
                    Text('Pick from palette',
                        style: theme.textTheme.labelSmall
                            ?.copyWith(color: cs.onSurfaceVariant)),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        ...widget.palette.take(10).map(
                              (c) => GestureDetector(
                                onTap: () => widget.onPickColor(c),
                                child: _Swatch(
                                  color: c,
                                  size: 26,
                                  ring: widget.mappedColor == c
                                      ? cs.primary
                                      : null,
                                ),
                              ),
                            ),
                        // Custom colour button
                        GestureDetector(
                          onTap: () =>
                              setState(() => _showCustom = true),
                          child: Container(
                            width: 26,
                            height: 26,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: cs.outline.withAlpha(120)),
                              gradient: const SweepGradient(colors: [
                                Colors.red,
                                Colors.yellow,
                                Colors.green,
                                Colors.cyan,
                                Colors.blue,
                                Colors.purple,
                                Colors.red,
                              ]),
                            ),
                            child: const Icon(Icons.add_rounded,
                                size: 12, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    // ── Inline custom colour picker ────────────────────────
                    Text('Custom colour',
                        style: theme.textTheme.labelSmall
                            ?.copyWith(color: cs.onSurfaceVariant)),
                    const SizedBox(height: 6),
                    ColorPicker(
                      color: _customColor,
                      onColorChanged: (c) =>
                          setState(() => _customColor = c),
                      wheelDiameter: 160,
                      wheelHasBorder: false,
                      pickersEnabled: const {
                        ColorPickerType.primary: false,
                        ColorPickerType.accent: false,
                        ColorPickerType.wheel: true,
                      },
                      showColorCode: true,
                      colorCodeHasColor: true,
                      heading: null,
                      subheading: null,
                      wheelSubheading: null,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () =>
                              setState(() => _showCustom = false),
                          child: const Text('Back'),
                        ),
                        const SizedBox(width: 6),
                        FilledButton(
                          onPressed: () {
                            widget.onPickColor(_customColor);
                            setState(() => _showCustom = false);
                          },
                          child: const Text('Use'),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            secondChild: const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  static String _hexOf(Color c) =>
      '#${c.toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';
}

// ─────────────────────────────────────────────────────────────────────────────

/// "Apply wallpaper colour to all preset colours" quick-pick grid.
class _PaletteGrid extends StatelessWidget {
  const _PaletteGrid({
    required this.palette,
    required this.colorMap,
    required this.presetColors,
    required this.onApplyToAll,
  });

  final List<Color> palette;
  final Map<Color, Color> colorMap;
  final List<Color> presetColors;
  final ValueChanged<Color> onApplyToAll;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: palette.take(12).map((c) {
        final isActive = presetColors.isNotEmpty &&
            presetColors.every((pc) => colorMap[pc] == c);
        return Tooltip(
          message: 'Apply to all',
          child: GestureDetector(
            onTap: () => onApplyToAll(c),
            child: _Swatch(
              color: c,
              size: 30,
              ring: isActive ? cs.primary : null,
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _Swatch extends StatelessWidget {
  const _Swatch({required this.color, required this.size, this.ring});
  final Color color;
  final double size;
  final Color? ring;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        border: Border.all(
          color: ring ?? Colors.white.withAlpha(40),
          width: ring != null ? 2.5 : 1,
        ),
        boxShadow: ring != null
            ? [
                BoxShadow(
                    color: ring!.withAlpha(80),
                    blurRadius: 6,
                    spreadRadius: 1)
              ]
            : null,
      ),
    );
  }
}
