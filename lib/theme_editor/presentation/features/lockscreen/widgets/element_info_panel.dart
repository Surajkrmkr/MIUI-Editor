import 'package:flex_color_picker/flex_color_picker.dart';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:miui_icon_generator/core/theme/app_radius.dart';
import '../../../../../core/theme/theme_extensions.dart';
import '../../../../domain/entities/builtin_widget_styles.dart';
import '../../../../domain/entities/icon_texture.dart';
import '../../../../domain/entities/element_widget.dart';
import '../../../providers/element_provider.dart';
import '../../../common/widgets/drop_zone.dart';
import '../../../../core/constants/path_constants.dart';
import '../../../providers/wallpaper_provider.dart';
import '../../../providers/service_providers.dart';
import '../../../../domain/entities/widget_style.dart';
import '../../../../domain/usecases/export_system_modules_usecase.dart';
import 'widget_styles_panel.dart';
import 'analog_clock_art.dart';
import 'shortcut_set_art.dart';

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
    final isUnlock = el.type.isUnlockControl;
    final supportsOutlineWidth =
        (isUnlock && el.unlockSkin != UnlockSkin.classic) ||
        (el.type == ElementType.calendarGrid &&
            el.calendarStyle != CalendarStyle.classic) ||
        (el.type == ElementType.analogClock &&
            const {
              AnalogStyle.classic,
              AnalogStyle.ring,
              AnalogStyle.crimsonGlass,
              AnalogStyle.frostedGlass,
            }.contains(el.analogStyle)) ||
        (el.type == ElementType.shortcutSet &&
            const {
              ShortcutStyle.glossDock,
              ShortcutStyle.darkDock,
              ShortcutStyle.pastelDock,
              ShortcutStyle.neonCapsule,
              ShortcutStyle.socialRow,
              ShortcutStyle.glossOrbs,
            }.contains(el.shortcutStyle));
    final usesFontSize =
        (el.type.isText && el.type != ElementType.notification) ||
        el.type == ElementType.calendarGrid;
    final isHourMinSec =
        el.type == ElementType.hourClock ||
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
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: colors.border),
            ),
            child: Row(
              children: [
                Icon(Icons.widgets_rounded, size: 16, color: colors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    el.label,
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
                  onPressed: () => n.remove(el.type),
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
                  allowedExtensions: el.type.isVideo
                      ? ['.mp4']
                      : ['.png', '.jpg'],
                  onDropped: (path) => _copyAsset(ref, path, el),
                ),
              ),
            ),

          if (el.type.isAnalog && el.type != ElementType.analogClock)
            _Section(
              title: 'ASSET',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppDropZone(
                    label: el.type == ElementType.analogClockBg
                        ? 'Drop Dial PNG'
                        : 'Drop Hand PNG (pointing to 12)',
                    allowedExtensions: const ['.png', '.PNG'],
                    onDropped: (path) =>
                        _importAnalogPng(context, ref, el, path),
                  ),
                  if (AnalogClockArt.customPng(el) != null)
                    TextButton.icon(
                      icon: const Icon(Icons.restore_rounded, size: 16),
                      label: const Text(
                        'Reset to Default',
                        style: TextStyle(fontSize: 11),
                      ),
                      onPressed: () =>
                          n.update(el.type, (e) => e.copyWith(path: '')),
                    ),
                ],
              ),
            ),

          if (!el.type.isIcon &&
              !el.type.isMusic &&
              !el.type.isVideo &&
              !el.type.isPng)
            _Section(
              title: 'COLOR',
              child: Column(
                children: [
                  if (isHourMinSec) ...[
                    _ToggleRow(
                      label: 'Separate Digit Colors',
                      value: el.useSeparateColors,
                      onChanged: (v) => n.setUseSeparateColors(el.type, v),
                    ),
                    const SizedBox(height: 10),
                  ],
                  if (usesDigitColors) ...[
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
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _ColorBtn(
                            color: el.strokeColorDigit1,
                            label: 'Digit 1 Stroke',
                            onChanged: (c) =>
                                n.setStrokeColorDigit1(el.type, c),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _ColorBtn(
                            color: el.strokeColorDigit2,
                            label: 'Digit 2 Stroke',
                            onChanged: (c) =>
                                n.setStrokeColorDigit2(el.type, c),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    _SliderRow(
                      label: 'Stroke Width',
                      value: el.strokeWidth,
                      min: 0,
                      max: 20,
                      onChanged: (v) => n.setStrokeWidth(el.type, v),
                    ),
                  ] else ...[
                    Row(
                      children: [
                        Expanded(
                          child: _ColorBtn(
                            color: el.color,
                            label: el.type == ElementType.notification
                                ? 'Text'
                                : isUnlock
                                ? 'Icon'
                                : el.type == ElementType.arcShape
                                ? 'Progress'
                                : el.type == ElementType.calendarGrid
                                ? 'Dates & Text'
                                : 'Primary',
                            onChanged: (c) => n.setColor(el.type, c),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _ColorBtn(
                            color: el.colorSecondary,
                            label:
                                el.type == ElementType.notification || isUnlock
                                ? 'Background'
                                : el.type == ElementType.arcShape
                                ? 'Track'
                                : el.type == ElementType.calendarGrid
                                ? 'Today Highlight'
                                : 'Secondary',
                            onChanged: (c) => n.setColorSecondary(el.type, c),
                          ),
                        ),
                      ],
                    ),
                    if ((isUnlock && el.unlockSkin != UnlockSkin.classic) ||
                        el.type == ElementType.analogClock ||
                        el.type == ElementType.shortcutSet ||
                        (el.type == ElementType.calendarGrid &&
                            el.calendarStyle != CalendarStyle.classic)) ...[
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: _ColorBtn(
                              color: el.unlockAccent,
                              label: el.type == ElementType.analogClock
                                  ? 'Second Hand'
                                  : el.type == ElementType.shortcutSet
                                  ? 'Tile'
                                  : el.type == ElementType.calendarGrid
                                  ? 'Panel Fill'
                                  : 'Accent',
                              onChanged: (c) => n.update(
                                el.type,
                                (e) => e.copyWith(unlockAccent: c),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _ColorBtn(
                              color: el.borderColor,
                              label: el.type == ElementType.analogClock
                                  ? 'Ticks & Rim'
                                  : el.type == ElementType.shortcutSet
                                  ? 'Tile 2 / Outline'
                                  : el.type == ElementType.calendarGrid
                                  ? 'Border / Frame'
                                  : 'Outline',
                              onChanged: (c) => n.update(
                                el.type,
                                (e) => e.copyWith(borderColor: c),
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (el.type == ElementType.calendarGrid &&
                          el.calendarStyle != CalendarStyle.classic) ...[
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: _ColorBtn(
                                color: el.strokeColor,
                                label: 'Accent / Details',
                                onChanged: (c) => n.update(
                                  el.type,
                                  (e) => e.copyWith(strokeColor: c),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                      if (supportsOutlineWidth) ...[
                        const SizedBox(height: 6),
                        _SliderRow(
                          label: 'Outline Width',
                          value: el.borderWidth,
                          min: 0,
                          max: 40,
                          onChanged: (v) => n.update(
                            el.type,
                            (e) => e.copyWith(borderWidth: v),
                          ),
                        ),
                      ],
                    ],
                    if (WidgetStyle.supports(el.type)) ...[
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.wallpaper_rounded, size: 16),
                          label: const Text(
                            'Use Wallpaper Colors',
                            style: TextStyle(fontSize: 11),
                          ),
                          onPressed: el.isLocked
                              ? null
                              : () => _applyWallpaperColors(context, ref, el),
                        ),
                      ),
                    ],
                    if (isHourMinSec) ...[
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: _ColorBtn(
                              color: el.strokeColor,
                              label: 'Stroke Color',
                              onChanged: (c) => n.setStrokeColor(el.type, c),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      _SliderRow(
                        label: 'Stroke Width',
                        value: el.strokeWidth,
                        min: 0,
                        max: 20,
                        onChanged: (v) => n.setStrokeWidth(el.type, v),
                      ),
                    ],
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
                  if (el.type.isClock &&
                      !el.type.isAnalog &&
                      el.type != ElementType.weatherIconClock) ...[
                    const SizedBox(height: 6),
                    _ToggleRow(
                      label: 'Frosted Glass Text',
                      value: el.isFrostedGlass,
                      onChanged: (v) => n.setIsFrostedGlass(el.type, v),
                    ),
                    _SliderRow(
                      label: 'Perspective Tilt',
                      value: el.perspectiveTilt,
                      min: -60,
                      max: 60,
                      decimals: 0,
                      unit: '°',
                      onChanged: (v) => n.setPerspectiveTilt(v.roundToDouble()),
                    ),
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
            title: usesFontSize ? 'FONT SIZE' : 'SCALE',
            child: Column(
              children: [
                _SliderRow(
                  label: usesFontSize ? 'Font Size' : 'Scale',
                  value: usesFontSize ? el.fontSize : el.scale,
                  min: 0,
                  max: usesFontSize ? 100 : 10,
                  onChanged: (v) => usesFontSize
                      ? n.setFontSize(el.type, v)
                      : n.setScale(el.type, v),
                ),
                const SizedBox(height: 4),
                _ScalePresets(
                  isText: usesFontSize,
                  value: usesFontSize ? el.fontSize : el.scale,
                  onSelected: (v) => usesFontSize
                      ? n.setFontSize(el.type, v)
                      : n.setScale(el.type, v),
                ),
              ],
            ),
          ),

          if (el.type.isContainer ||
              (el.type.isClock &&
                  !el.type.isAnalog &&
                  el.type != ElementType.weatherIconClock))
            _Section(
              title: 'TEXTURE',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DropdownButtonFormField<IconTexture>(
                    key: ValueKey('tx-${el.type}-${el.surfaceTexture}'),
                    initialValue: el.surfaceTexture,
                    isDense: true,
                    decoration: const InputDecoration(
                      labelText: 'Texture',
                      isDense: true,
                    ),
                    items: [
                      for (final t in IconTexture.values)
                        DropdownMenuItem(value: t, child: Text(t.label)),
                    ],
                    onChanged: (v) => n.updateSurfaceFx(
                      el.type,
                      (e) => e.copyWith(surfaceTexture: v),
                    ),
                  ),
                  if (el.surfaceTexture != IconTexture.none) ...[
                    _SliderRow(
                      label: 'Scale',
                      value: el.textureScale,
                      min: 0.1,
                      max: 5,
                      onChanged: (v) => n.updateSurfaceFx(
                        el.type,
                        (e) => e.copyWith(textureScale: v),
                      ),
                    ),
                    _SliderRow(
                      label: 'Opacity',
                      value: el.textureOpacity,
                      max: 1,
                      onChanged: (v) => n.updateSurfaceFx(
                        el.type,
                        (e) => e.copyWith(textureOpacity: v),
                      ),
                    ),
                  ],
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
                  _SliderRow(
                    label: 'Background Blur',
                    value: el.blurRadius,
                    min: 0,
                    max: 50,
                    onChanged: (v) => n.setBlurRadius(el.type, v),
                  ),
                  const SizedBox(height: 6),
                  _ToggleRow(
                    label: 'Liquid Glass Effect',
                    value: el.isLiquidGlass,
                    onChanged: (v) => n.setIsLiquidGlass(el.type, v),
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

          if (el.type.isNormalText || el.type.isDateTime)
            _Section(
              title: el.type.isDateTime
                  ? 'DATE / TIME FORMAT'
                  : 'TEXT / EXPRESSION',
              child: TextField(
                controller: TextEditingController(text: el.text)
                  ..selection = TextSelection.collapsed(offset: el.text.length),
                decoration: InputDecoration(
                  hintText: el.type.isDateTime
                      ? 'dd/MM/yyyy HH:mm'
                      : 'Enter text or expression…',
                  suffixIcon: el.type.isDateTime
                      ? PopupMenuButton<({String pattern, bool replace})>(
                          tooltip: 'Date/time formats',
                          icon: const Icon(Icons.calendar_month_outlined),
                          onSelected: (selection) => n.setText(
                            el.type,
                            selection.replace
                                ? selection.pattern
                                : '${el.text}${selection.pattern}',
                          ),
                          itemBuilder: (context) => [
                            for (final pattern in [
                              'HH:mm',
                              'hh:mm a',
                              'dd/MM/yyyy',
                              'yyyy-MM-dd',
                              'EEEE, d MMMM',
                              'dd MMM yyyy HH:mm',
                            ])
                              PopupMenuItem(
                                value: (pattern: pattern, replace: true),
                                child: Text(pattern),
                              ),
                            const PopupMenuDivider(),
                            for (final entry in const {
                              'yyyy': 'Year (2026)',
                              'MM': 'Month (01-12)',
                              'MMM': 'Short month',
                              'MMMM': 'Full month',
                              'dd': 'Day (01-31)',
                              'EEE': 'Short weekday',
                              'EEEE': 'Full weekday',
                              'HH': '24-hour (00-23)',
                              'hh': '12-hour (01-12)',
                              'mm': 'Minute (00-59)',
                              'ss': 'Second (00-59)',
                              'a': 'AM / PM',
                            }.entries)
                              PopupMenuItem(
                                value: (pattern: entry.key, replace: false),
                                child: Text('${entry.key}  ${entry.value}'),
                              ),
                          ],
                        )
                      : null,
                ),
                onChanged: (v) => n.setText(el.type, v),
              ),
            ),

          if (el.type == ElementType.weekClock ||
              el.type == ElementType.monthClock)
            _Section(
              title: 'DATE FORMAT',
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

          if (el.type.isText || el.type == ElementType.calendarGrid || isUnlock)
            _Section(
              title: 'TEXT STYLE',
              child: _ToggleRow(
                label: 'Bold',
                value: el.isBold,
                onChanged: (value) => n.setFontWeight(
                  el.type,
                  value ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),

          if (el.type == ElementType.notification)
            _Section(
              title: 'NOTIFICATIONS',
              child: Column(
                children: [
                  _SliderRow(
                    label: 'Maximum Visible',
                    value: el.notificationLimit.toDouble().clamp(1, 10),
                    min: 1,
                    max: 10,
                    divisions: 9,
                    onChanged: (value) => n.update(
                      el.type,
                      (element) => element.copyWith(
                        notificationLimit: value.round().clamp(1, 10),
                      ),
                    ),
                  ),
                  _SliderRow(
                    label: 'Corner Radius',
                    value: el.radius.clamp(0, 40),
                    min: 0,
                    max: 40,
                    onChanged: (value) => n.update(
                      el.type,
                      (element) => element.copyWith(radius: value.clamp(0, 40)),
                    ),
                  ),
                ],
              ),
            ),

          if (!el.type.isIcon && !el.type.isMusic && !el.type.isContainer)
            _Section(
              title: 'ALIGNMENT',
              child: Row(
                children: [
                  Expanded(
                    child: _AlignChip('Left', Alignment.centerLeft, el, n),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: _AlignChip('Center', Alignment.center, el, n),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: _AlignChip('Right', Alignment.centerRight, el, n),
                  ),
                ],
              ),
            ),

          if (el.type == ElementType.analogClock)
            _Section(
              title: 'ANALOG CLOCK',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(
                      'Style',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  Container(
                    height: 36,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainerHighest.withValues(
                        alpha: 0.5,
                      ),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: scheme.outlineVariant.withValues(alpha: 0.5),
                      ),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<AnalogStyle>(
                        value: el.analogStyle,
                        isExpanded: true,
                        icon: const Icon(Icons.keyboard_arrow_down, size: 18),
                        style: TextStyle(
                          fontSize: 12,
                          color: scheme.onSurface,
                          fontWeight: FontWeight.w500,
                        ),
                        dropdownColor: scheme.surfaceContainerHigh,
                        items: AnalogStyle.values.map((style) {
                          final name = switch (style) {
                            AnalogStyle.indigo => 'Indigo',
                            AnalogStyle.minimal => 'Minimal',
                            AnalogStyle.classic => 'Classic',
                            AnalogStyle.numerals => 'Numerals',
                            AnalogStyle.dots => 'Dots',
                            AnalogStyle.ring => 'Ring',
                            AnalogStyle.sport => 'Sport',
                            AnalogStyle.woodPanel => 'Wood Panel',
                            AnalogStyle.crimsonGlass => 'Crimson Glass',
                            AnalogStyle.romanWall => 'Roman Wall',
                            AnalogStyle.neonGlow => 'Neon Glow',
                            AnalogStyle.auroraRing => 'Aurora Ring',
                            AnalogStyle.luxuryGold => 'Luxury Gold',
                            AnalogStyle.frostedGlass => 'Frosted Glass',
                            AnalogStyle.orbit => 'Orbit',
                            AnalogStyle.orbitDigital => 'Orbit Digital',
                            AnalogStyle.flowerCard => 'Flower Card',
                            AnalogStyle.bauhausPop => 'Bauhaus Pop',
                            AnalogStyle.ripple => 'Ripple',
                            AnalogStyle.solarEclipse => 'Solar Eclipse',
                            AnalogStyle.memphis => 'Memphis',
                            AnalogStyle.prism => 'Prism',
                            AnalogStyle.ribbon => 'Ribbon',
                            AnalogStyle.terrazzo => 'Terrazzo',
                            AnalogStyle.contour => 'Contour',
                            AnalogStyle.pixelSun => 'Pixel Sun',
                            AnalogStyle.kineticTiles => 'Kinetic Tiles',
                            AnalogStyle.fanFold => 'Fan Fold',
                            AnalogStyle.liquidLoops => 'Liquid Loops',
                            AnalogStyle.checkerWave => 'Checker Wave',
                            AnalogStyle.cyberReticle => 'Cyber Reticle',
                            AnalogStyle.sunsetGrid => 'Sunset Grid',
                            AnalogStyle.zenGarden => 'Zen Garden',
                            AnalogStyle.vortex => 'Vortex',
                            AnalogStyle.circuitTrace => 'Circuit Trace',
                            AnalogStyle.artDeco => 'Art Deco',
                            AnalogStyle.squirclePebble => 'Squircle Pebble',
                            AnalogStyle.moireRings => 'Moiré Rings',
                            AnalogStyle.brutalistPop => 'Brutalist Pop',
                            AnalogStyle.holoWarp => 'Holo Warp',
                          };
                          return DropdownMenuItem(
                            value: style,
                            child: Text(name),
                          );
                        }).toList(),
                        onChanged: (style) {
                          if (style != null) {
                            n.update(
                              el.type,
                              (element) => element.copyWith(analogStyle: style),
                            );
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),

          if (el.type == ElementType.calendarGrid)
            _Section(
              title: 'CALENDAR',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(
                      'Style',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  Container(
                    height: 36,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainerHighest.withValues(
                        alpha: 0.5,
                      ),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: scheme.outlineVariant.withValues(alpha: 0.5),
                      ),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<CalendarStyle>(
                        value: el.calendarStyle,
                        isExpanded: true,
                        icon: const Icon(Icons.keyboard_arrow_down, size: 18),
                        style: TextStyle(
                          fontSize: 12,
                          color: scheme.onSurface,
                          fontWeight: FontWeight.w500,
                        ),
                        dropdownColor: scheme.surfaceContainerHigh,
                        items: CalendarStyle.values.map((style) {
                          final name = switch (style) {
                            CalendarStyle.classic => 'Classic',
                            CalendarStyle.pillColumn => 'Pill Column',
                            CalendarStyle.plusCircles => 'Plus Circles',
                            CalendarStyle.stripHeader => 'Strip Header',
                            CalendarStyle.glassCard => 'Glass Card',
                            CalendarStyle.neonCyber => 'Neon Cyber',
                            CalendarStyle.neoBrutalism => 'Neo-Brutalism',
                            CalendarStyle.bentoGrid => 'Bento Grid',
                            CalendarStyle.gradientAura => 'Gradient Aura',
                            CalendarStyle.minimalDots => 'Minimal Dots',
                            CalendarStyle.splitFlap => 'Split Flap',
                            CalendarStyle.capsuleRow => 'Capsule Row',
                            CalendarStyle.floatingBadges => 'Floating Badges',
                            CalendarStyle.abstractGeometric =>
                              'Abstract Geometric',
                            CalendarStyle.outlineRings => 'Outline Rings',
                            CalendarStyle.monolith => 'Monolith',
                            CalendarStyle.bracketModern => 'Bracket Modern',
                            CalendarStyle.softNeumorphism => 'Soft Neumorphism',
                            CalendarStyle.lunarPhase => 'Lunar Phase',
                            CalendarStyle.polarArc => 'Polar Arc',
                            CalendarStyle.cyberMatrix => 'Cyber Matrix',
                            CalendarStyle.ticketStub => 'Ticket Stub',
                          };
                          return DropdownMenuItem(
                            value: style,
                            child: Text(name),
                          );
                        }).toList(),
                        onChanged: (style) {
                          if (style != null) {
                            n.update(
                              el.type,
                              (element) =>
                                  element.copyWith(calendarStyle: style),
                            );
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(
                      'Date rows',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: double.infinity,
                    child: SegmentedButton<int>(
                      segments: const [
                        ButtonSegment(value: 1, label: Text('One row')),
                        ButtonSegment(value: 2, label: Text('Two rows')),
                        ButtonSegment(value: 6, label: Text('Full month')),
                      ],
                      selected: {
                        el.calendarWeekRows == 1
                            ? 1
                            : el.calendarWeekRows == 2
                            ? 2
                            : 6,
                      },
                      showSelectedIcon: false,
                      style: const ButtonStyle(
                        visualDensity: VisualDensity.compact,
                        textStyle: WidgetStatePropertyAll(
                          TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                        ),
                      ),
                      onSelectionChanged: (values) {
                        final rows = values.single;
                        n.update(
                          el.type,
                          (element) => element.copyWith(
                            calendarRows: rows,
                            height:
                                (element.height /
                                        element.calendarDisplayRows *
                                        (rows +
                                            (element.calendarShowMonth
                                                ? 1
                                                : 0) +
                                            (element.calendarShowWeekdays
                                                ? 1
                                                : 0)))
                                    .roundToDouble(),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  _ToggleRow(
                    label: 'Month heading',
                    value: el.calendarShowMonth,
                    onChanged: (value) => n.update(
                      el.type,
                      (element) => element.copyWith(
                        calendarShowMonth: value,
                        height:
                            (element.height /
                                    element.calendarDisplayRows *
                                    (element.calendarDisplayRows +
                                        (value ? 1 : -1)))
                                .roundToDouble(),
                      ),
                    ),
                  ),
                  _ToggleRow(
                    label: 'Weekday headings',
                    value: el.calendarShowWeekdays,
                    onChanged: (value) => n.update(
                      el.type,
                      (element) => element.copyWith(
                        calendarShowWeekdays: value,
                        height:
                            (element.height /
                                    element.calendarDisplayRows *
                                    (element.calendarDisplayRows +
                                        (value ? 1 : -1)))
                                .roundToDouble(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  _SliderRow(
                    label: 'Highlight radius',
                    value: el.radius.clamp(0, 40).roundToDouble(),
                    min: 0,
                    max: 40,
                    decimals: 0,
                    unit: 'px',
                    onChanged: (value) => n.setRadius(el.type, value),
                  ),
                  _SliderRow(
                    label: 'Width',
                    value: el.width.clamp(140, 1080).roundToDouble(),
                    min: 140,
                    max: 1080,
                    decimals: 0,
                    unit: 'px',
                    onChanged: (value) => n.update(
                      el.type,
                      (element) => element.copyWith(
                        width: value.clamp(140, 1080).roundToDouble(),
                      ),
                    ),
                  ),
                  _SliderRow(
                    label: 'Height',
                    value: el.height.clamp(40, 1600).roundToDouble(),
                    min: 40,
                    max: 1600,
                    decimals: 0,
                    unit: 'px',
                    onChanged: (value) => n.update(
                      el.type,
                      (element) => element.copyWith(
                        height: value.clamp(40, 1600).roundToDouble(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          if (WidgetStyle.supports(el.type))
            _Section(
              title: 'WIDGET STYLES',
              child: WidgetStylesPanel(
                key: ValueKey('styles-${el.name}'),
                element: el,
              ),
            ),
          if (el.type == ElementType.shortcutSet)
            _Section(
              title: 'SHORTCUTS',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _ToggleRow(
                    label: 'Use icons from icons folder',
                    value: el.shortcutThemeIcons,
                    onChanged: (value) => n.update(
                      el.type,
                      (element) => element.copyWith(shortcutThemeIcons: value),
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (supportsShortcutEdge(el.shortcutStyle)) ...[
                    SegmentedButton<ShortcutEdge>(
                      segments: const [
                        ButtonSegment(
                          value: ShortcutEdge.left,
                          label: Text('Left edge'),
                        ),
                        ButtonSegment(
                          value: ShortcutEdge.floating,
                          label: Text('Floating'),
                        ),
                        ButtonSegment(
                          value: ShortcutEdge.right,
                          label: Text('Right edge'),
                        ),
                      ],
                      selected: {el.shortcutEdge},
                      showSelectedIcon: false,
                      style: const ButtonStyle(
                        visualDensity: VisualDensity.compact,
                        textStyle: WidgetStatePropertyAll(
                          TextStyle(fontSize: 11),
                        ),
                      ),
                      onSelectionChanged: (values) => n.update(
                        el.type,
                        (e) => e.copyWith(shortcutEdge: values.single),
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                  for (final (i, app) in ShortcutApp.parse(
                    el.shortcutApps,
                  ).indexed)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Container(
                        padding: const EdgeInsets.only(
                          left: 8,
                          right: 4,
                          top: 3,
                          bottom: 3,
                        ),
                        decoration: BoxDecoration(
                          color: scheme.surfaceContainerHighest.withValues(
                            alpha: 0.35,
                          ),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: scheme.outlineVariant.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: scheme.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'Slot ${i + 1}',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: scheme.primary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<ShortcutApp>(
                                  key: ValueKey(
                                    '${el.name}-slot-$i-${app.name}',
                                  ),
                                  value: app,
                                  isDense: true,
                                  isExpanded: true,
                                  icon: Icon(
                                    Icons.keyboard_arrow_down_rounded,
                                    size: 18,
                                    color: scheme.onSurfaceVariant,
                                  ),
                                  items: [
                                    for (final option in ShortcutApp.values)
                                      DropdownMenuItem(
                                        value: option,
                                        child: Row(
                                          children: [
                                            Icon(
                                              option.icon,
                                              size: 16,
                                              color: option == app
                                                  ? scheme.primary
                                                  : scheme.onSurfaceVariant,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              option.label,
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: option == app
                                                    ? FontWeight.w600
                                                    : FontWeight.normal,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                  ],
                                  onChanged: (value) {
                                    if (value == null) return;
                                    final apps = ShortcutApp.parse(
                                      el.shortcutApps,
                                    );
                                    apps[i] = value;
                                    n.update(
                                      el.type,
                                      (e) => e.copyWith(
                                        shortcutApps: apps
                                            .map((a) => a.name)
                                            .join(','),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                            IconButton(
                              tooltip: 'Remove',
                              visualDensity: VisualDensity.compact,
                              iconSize: 16,
                              splashRadius: 14,
                              style: IconButton.styleFrom(
                                foregroundColor: scheme.onSurfaceVariant,
                                hoverColor: scheme.error.withValues(alpha: 0.1),
                              ),
                              icon: const Icon(Icons.close_rounded),
                              onPressed: () {
                                final apps = ShortcutApp.parse(el.shortcutApps)
                                  ..removeAt(i);
                                n.update(
                                  el.type,
                                  (e) => e.copyWith(
                                    shortcutApps: apps
                                        .map((a) => a.name)
                                        .join(','),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  if (ShortcutApp.parse(el.shortcutApps).length < 8)
                    Padding(
                      padding: const EdgeInsets.only(top: 2, bottom: 4),
                      child: SizedBox(
                        height: 36,
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                              color: scheme.primary.withValues(alpha: 0.35),
                            ),
                            backgroundColor: scheme.primary.withValues(
                              alpha: 0.04,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          icon: Icon(
                            Icons.add_rounded,
                            size: 16,
                            color: scheme.primary,
                          ),
                          label: Text(
                            'Add Shortcut',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: scheme.primary,
                            ),
                          ),
                          onPressed: () => n.update(
                            el.type,
                            (e) => e.copyWith(
                              shortcutApps: [
                                ...ShortcutApp.parse(
                                  e.shortcutApps,
                                ).map((a) => a.name),
                                ShortcutApp.values
                                    .firstWhere(
                                      (a) =>
                                          a != ShortcutApp.messages &&
                                          a != ShortcutApp.phone &&
                                          !ShortcutApp.parse(
                                            e.shortcutApps,
                                          ).contains(a),
                                      orElse: () => ShortcutApp.camera,
                                    )
                                    .name,
                              ].join(','),
                            ),
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 8),
                  _SliderRow(
                    label: 'Icon Size',
                    value: (el.unlockIconScale.clamp(.2, 1) * 100)
                        .roundToDouble(),
                    min: 20,
                    max: 100,
                    decimals: 0,
                    unit: 'px',
                    onChanged: (v) => n.update(
                      el.type,
                      (e) => e.copyWith(unlockIconScale: v / 100),
                    ),
                  ),
                  _SliderRow(
                    label: 'Panel Opacity',
                    value: (el.unlockBackgroundOpacity.clamp(0, 1) * 100)
                        .roundToDouble(),
                    min: 0,
                    max: 100,
                    decimals: 0,
                    unit: '%',
                    onChanged: (v) => n.update(
                      el.type,
                      (e) => e.copyWith(unlockBackgroundOpacity: v / 100),
                    ),
                  ),
                ],
              ),
            ),

          if (isUnlock)
            _Section(
              title: 'UNLOCK AREA',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SubCard(
                    title: 'CONTENT & ICON',
                    icon: Icons.text_fields_rounded,
                    children: [
                      _UnlockTextField(
                        key: ValueKey('${el.name}-unlock-text-field'),
                        initialText: el.unlockText,
                        onChanged: (value) => n.update(
                          el.type,
                          (element) => element.copyWith(unlockText: value),
                        ),
                      ),
                      if (el.unlockText.isNotEmpty) ...[
                        if (el.type == ElementType.tapToUnlock)
                          SegmentedButton<bool>(
                            segments: const [
                              ButtonSegment(
                                value: false,
                                icon: Icon(Icons.view_agenda_outlined),
                                label: Text('Stacked'),
                              ),
                              ButtonSegment(
                                value: true,
                                icon: Icon(Icons.view_week_outlined),
                                label: Text('Inline'),
                              ),
                            ],
                            selected: {el.unlockInline},
                            onSelectionChanged: (values) => n.update(
                              el.type,
                              (element) =>
                                  element.copyWith(unlockInline: values.single),
                            ),
                          ),
                        const SizedBox(height: 10),
                        _SliderRow(
                          label: 'Text size',
                          value: el.fontSize.clamp(4, 40).roundToDouble(),
                          min: 4,
                          max: 40,
                          decimals: 0,
                          unit: 'sp',
                          onChanged: (value) => n.update(
                            el.type,
                            (element) => element.copyWith(fontSize: value),
                          ),
                        ),
                      ],
                      const SizedBox(height: 10),
                      DropdownButtonFormField<UnlockIcon>(
                        key: ValueKey('${el.name}-${el.unlockIcon.name}'),
                        initialValue: el.unlockIcon,
                        style: TextStyle(fontSize: 12, color: scheme.onSurface),
                        dropdownColor: colors.surfaceElevated,
                        decoration: InputDecoration(
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                          labelText: 'Unlock Icon',
                          labelStyle: TextStyle(
                            fontSize: 12,
                            color: scheme.onSurfaceVariant,
                          ),
                          // prefixIcon: Icon(
                          //   el.unlockIcon.icon ??
                          //       (el.unlockIcon == UnlockIcon.none
                          //           ? Icons.block_rounded
                          //           : el.unlockIcon == UnlockIcon.customPng
                          //           ? Icons.image_outlined
                          //           : Icons.auto_mode_rounded),
                          //   size: 18,
                          //   color: colors.primary,
                          // ),
                          filled: true,
                          fillColor: colors.bgSubtle,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                            borderSide: BorderSide(color: colors.border),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                            borderSide: BorderSide(
                              color: colors.border.withAlpha(120),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                            borderSide: BorderSide(
                              color: colors.primary,
                              width: 1.5,
                            ),
                          ),
                        ),
                        isExpanded: true,
                        items: [
                          for (final icon in UnlockIcon.values)
                            DropdownMenuItem(
                              value: icon,
                              child: Row(
                                children: [
                                  Icon(
                                    icon.icon ??
                                        (icon == UnlockIcon.none
                                            ? Icons.block_rounded
                                            : icon == UnlockIcon.customPng
                                            ? Icons.image_outlined
                                            : Icons.auto_mode_rounded),
                                    size: 16,
                                    color: icon == el.unlockIcon
                                        ? colors.primary
                                        : scheme.onSurfaceVariant,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    icon.label,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: icon == el.unlockIcon
                                          ? FontWeight.w600
                                          : FontWeight.normal,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                        onChanged: (icon) {
                          if (icon == null) return;
                          n.snapshotForDrag();
                          n.update(
                            el.type,
                            (element) => element.copyWith(unlockIcon: icon),
                          );
                        },
                      ),
                      if (el.effectiveUnlockIcon == UnlockIcon.customPng) ...[
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: colors.bgSubtle,
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                            border: Border.all(
                              color: colors.border.withAlpha(120),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              AppDropZone(
                                label: 'Drop Custom PNG',
                                allowedExtensions: const ['.png', '.PNG'],
                                onDropped: (path) =>
                                    _importUnlockPng(context, ref, el, path),
                              ),
                              const SizedBox(height: 8),
                              OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  visualDensity: VisualDensity.compact,
                                  side: BorderSide(color: colors.border),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                      AppRadius.sm,
                                    ),
                                  ),
                                ),
                                icon: const Icon(
                                  Icons.folder_open_rounded,
                                  size: 16,
                                ),
                                label: Text(
                                  el.unlockIconPath.isEmpty
                                      ? 'Choose PNG File'
                                      : 'Replace PNG File',
                                  style: const TextStyle(fontSize: 11),
                                ),
                                onPressed: () async {
                                  final result = await FilePicker.platform
                                      .pickFiles(
                                        type: FileType.custom,
                                        allowedExtensions: ['png'],
                                      );
                                  final path = result?.files.single.path;
                                  if (path == null || !context.mounted) return;
                                  await _importUnlockPng(
                                    context,
                                    ref,
                                    el,
                                    path,
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                      if (el.unlockSkin == UnlockSkin.meet) ...[
                        const SizedBox(height: 10),
                        Text(
                          'Left image: choose "PNG image" above. Right image:',
                          style: TextStyle(
                            fontSize: 11,
                            color: colors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        AppDropZone(
                          label: 'Drop Right PNG',
                          allowedExtensions: const ['.png', '.PNG'],
                          onDropped: (path) => _importUnlockPng(
                            context,
                            ref,
                            el,
                            path,
                            target: true,
                          ),
                        ),
                        if (el.unlockTargetPath.isNotEmpty)
                          TextButton.icon(
                            icon: const Icon(Icons.restore_rounded, size: 16),
                            label: const Text(
                              'Reset Right Image',
                              style: TextStyle(fontSize: 11),
                            ),
                            onPressed: () => n.update(
                              el.type,
                              (e) => e.copyWith(unlockTargetPath: ''),
                            ),
                          ),
                      ],
                      if (el.effectiveUnlockIcon != UnlockIcon.none) ...[
                        const SizedBox(height: 10),
                        _SliderRow(
                          label: 'Icon scale',
                          value: (el.unlockIconScale.clamp(.2, 1) * 100)
                              .roundToDouble(),
                          min: 20,
                          max: 100,
                          decimals: 0,
                          unit: '%',
                          onChanged: (value) => n.update(
                            el.type,
                            (element) =>
                                element.copyWith(unlockIconScale: value / 100),
                          ),
                        ),
                      ],
                    ],
                  ),
                  _SubCard(
                    title: 'APPEARANCE',
                    icon: Icons.tune_rounded,
                    children: [
                      _SliderRow(
                        label: 'Corner radius',
                        value: el.effectiveUnlockCornerRadius.roundToDouble(),
                        min: 0,
                        max:
                            ((el.width < el.unlockHeight
                                        ? el.width
                                        : el.unlockHeight) /
                                    2)
                                .clamp(1.0, 1080.0),
                        decimals: 0,
                        unit: 'px',
                        onChanged: (value) => n.update(
                          el.type,
                          (element) =>
                              element.copyWith(unlockCornerRadius: value),
                        ),
                      ),
                      const SizedBox(height: 8),
                      _SliderRow(
                        label: 'Background opacity',
                        value: (el.unlockBackgroundOpacity.clamp(0, 1) * 100)
                            .roundToDouble(),
                        min: 0,
                        max: 100,
                        decimals: 0,
                        unit: '%',
                        onChanged: (value) => n.update(
                          el.type,
                          (element) => element.copyWith(
                            unlockBackgroundOpacity: value / 100,
                          ),
                        ),
                      ),
                      if (el.type == ElementType.slideToUnlock ||
                          el.type == ElementType.dragToUnlock) ...[
                        const SizedBox(height: 8),
                        _SliderRow(
                          label: 'Thumb opacity',
                          value: (el.unlockThumbOpacity.clamp(0, 1) * 100)
                              .roundToDouble(),
                          min: 0,
                          max: 100,
                          decimals: 0,
                          unit: '%',
                          onChanged: (value) => n.update(
                            el.type,
                            (element) => element.copyWith(
                              unlockThumbOpacity: value / 100,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  _SubCard(
                    title: 'DIMENSIONS',
                    icon: Icons.aspect_ratio_rounded,
                    children: [
                      _SliderRow(
                        label: 'Width',
                        value: el.width.clamp(80, 1080).roundToDouble(),
                        min: 80,
                        max: 1080,
                        decimals: 0,
                        unit: 'px',
                        onChanged: (value) => n.update(
                          el.type,
                          (element) => element.copyWith(width: value),
                        ),
                      ),
                      const SizedBox(height: 8),
                      _SliderRow(
                        label: 'Height',
                        value: el.height.clamp(48, 800).roundToDouble(),
                        min: 48,
                        max: 800,
                        decimals: 0,
                        unit: 'px',
                        onChanged: (value) => n.update(
                          el.type,
                          (element) => element.copyWith(height: value),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          if (el.type.isShape)
            _Section(
              title: 'GEOMETRY',
              child: Column(
                children: [
                  if (el.type == ElementType.arcShape)
                    _SliderRow(
                      label: 'Radius',
                      value: (el.width / 2).clamp(1, 540),
                      min: 1,
                      max: 540,
                      onChanged: (value) => n.update(
                        el.type,
                        (element) => element.copyWith(
                          width: value * 2,
                          height: value * 2,
                        ),
                      ),
                    ),
                  if (el.type != ElementType.arcShape)
                    _SliderRow(
                      label: 'Width',
                      value: el.width.clamp(1, 1080),
                      min: 1,
                      max: 1080,
                      onChanged: (value) => n.update(
                        el.type,
                        (element) =>
                            element.copyWith(width: value.clamp(1, 1080)),
                      ),
                    ),
                  if (el.type != ElementType.circleShape &&
                      el.type != ElementType.arcShape)
                    _SliderRow(
                      label: 'Height',
                      value: el.height.clamp(1, 2340),
                      min: 1,
                      max: 2340,
                      onChanged: (value) => n.update(
                        el.type,
                        (element) =>
                            element.copyWith(height: value.clamp(1, 2340)),
                      ),
                    ),
                  _SliderRow(
                    label: 'Stroke Width',
                    value: el.shapeStrokeWidth.clamp(0, 100),
                    min: 0,
                    max: 100,
                    onChanged: (value) => n.update(
                      el.type,
                      (element) => element.copyWith(
                        shapeStrokeWidth: value.clamp(0, 100),
                      ),
                    ),
                  ),
                  if (el.type == ElementType.rectangleShape)
                    _SliderRow(
                      label: 'Corner Radius',
                      value: el.radius.clamp(0, 200),
                      min: 0,
                      max: 200,
                      onChanged: (value) => n.update(
                        el.type,
                        (element) =>
                            element.copyWith(radius: value.clamp(0, 200)),
                      ),
                    ),
                  if (el.type == ElementType.arcShape) ...[
                    _SliderRow(
                      label: 'Start Angle',
                      value: el.startAngle.clamp(-360, 360),
                      min: -360,
                      max: 360,
                      onChanged: (value) => n.update(
                        el.type,
                        (element) => element.copyWith(
                          startAngle: value.clamp(-360, 360),
                        ),
                      ),
                    ),
                    _SliderRow(
                      label: 'Sweep Angle',
                      value: el.sweepAngle.clamp(-360, 360),
                      min: -360,
                      max: 360,
                      onChanged: (value) => n.update(
                        el.type,
                        (element) => element.copyWith(
                          sweepAngle: value.clamp(-360, 360),
                        ),
                      ),
                    ),
                  ],
                  if (el.type == ElementType.arcShape ||
                      el.type == ElementType.rectangleShape) ...[
                    DropdownButtonFormField<ArcProgressSource>(
                      initialValue: el.effectiveProgressSource,
                      key: ValueKey(
                        '${el.name}-${el.effectiveProgressSource.name}',
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Progress source',
                      ),
                      items: [
                        for (final source in ArcProgressSource.values)
                          // Steps is hidden: Mi Health data doesn't load.
                          if (source != ArcProgressSource.steps ||
                              el.effectiveProgressSource == source)
                            DropdownMenuItem(
                              value: source,
                              child: Text(source.label),
                            ),
                      ],
                      onChanged: (source) {
                        if (source == null) return;
                        n.snapshotForDrag();
                        n.update(
                          el.type,
                          (element) => element.copyWith(
                            progressSource: source,
                            batteryArc: false,
                          ),
                        );
                      },
                    ),
                  ],
                ],
              ),
            ),
          if (el.type != ElementType.swipeUpUnlock && !el.type.isVideo)
            _AnimationTracksPanel(element: el, notifier: n),
          _Section(
            title: 'ROTATION',
            child: _SliderRow(
              label: 'Angle',
              value: el.angle,
              min: 0,
              max: 360,
              divisions: 36,
              decimals: 0,
              onChanged: (v) => n.setAngle(el.type, v),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _applyWallpaperColors(
    BuildContext context,
    WidgetRef ref,
    LockElement element,
  ) async {
    final path = ref.read(wallpaperProvider).currentPath;
    if (path == null || !File(path).existsSync()) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Load a wallpaper first')));
      return;
    }
    final palette = await ExportSystemModulesUseCase.wallpaperPalette(path);
    if (!context.mounted) return;
    final notifier = ref.read(elementProvider.notifier);
    if (clockSetElementTypes.contains(element.type)) {
      notifier.applyClockSetColors(
        color: palette.light,
        colorSecondary: palette.dark,
        accent: palette.primary,
        borderColor: palette.secondary,
      );
    } else {
      notifier.update(
        element.type,
        (current) => current.copyWith(
          color: palette.light,
          colorSecondary: current.type.isClock && !current.type.isAnalog
              ? palette.light
              : palette.dark,
          unlockAccent: palette.primary,
          borderColor: palette.secondary,
        ),
      );
    }
  }

  Future<void> _importUnlockPng(
    BuildContext context,
    WidgetRef ref,
    LockElement element,
    String source, {
    bool target = false,
  }) async {
    try {
      final codec = await ui.instantiateImageCodec(
        await File(source).readAsBytes(),
      );
      codec.dispose();
      if (!context.mounted) return;
      final wallpaper = ref.read(wallpaperProvider);
      var destination = source;
      if (wallpaper.weekNum != null && wallpaper.currentThemeName != null) {
        final theme = PathConstants.themePath(
          wallpaper.weekNum!,
          wallpaper.currentThemeName!,
        );
        destination = PathConstants.p(
          '${PathConstants.lockscreenAdvance(theme)}unlock/custom/${element.name}${target ? '_target' : ''}.png',
        );
        if (File(source).absolute.path != File(destination).absolute.path) {
          await ref.read(fileServiceProvider).copyFile(source, destination);
        }
      }
      if (!context.mounted) return;
      ref
          .read(elementProvider.notifier)
          .update(
            element.type,
            (current) => target
                ? current.copyWith(unlockTargetPath: destination)
                : current.copyWith(
                    unlockIcon: UnlockIcon.customPng,
                    unlockIconPath: destination,
                  ),
          );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not load PNG: $error')));
    }
  }

  Future<void> _importAnalogPng(
    BuildContext context,
    WidgetRef ref,
    LockElement element,
    String source,
  ) async {
    final ws = ref.read(wallpaperProvider);
    var destination = source;
    if (ws.weekNum != null && ws.currentThemeName != null) {
      final theme = PathConstants.themePath(ws.weekNum!, ws.currentThemeName!);
      destination = PathConstants.p(
        '${PathConstants.lockscreenAdvance(theme)}analog/custom/${element.name}.png',
      );
      if (File(source).absolute.path != File(destination).absolute.path) {
        await ref.read(fileServiceProvider).copyFile(source, destination);
      }
    }
    if (!context.mounted) return;
    ref
        .read(elementProvider.notifier)
        .update(element.type, (e) => e.copyWith(path: destination));
  }

  Future<void> _copyAsset(WidgetRef ref, String src, LockElement el) async {
    final ws = ref.read(wallpaperProvider);
    if (ws.weekNum == null || ws.currentThemeName == null) return;
    final tp = PathConstants.themePath(ws.weekNum!, ws.currentThemeName!);
    final lsAdv = PathConstants.lockscreenAdvance(tp);
    final resolvedPath = el.path.isNotEmpty ? el.path : el.type.defaultPath;
    final normalizedPath = resolvedPath.replaceAll(r'\', '/');
    final relative = normalizedPath.startsWith('/')
        ? normalizedPath.substring(1)
        : normalizedPath;
    final dest = el.type.isVideo
        ? PathConstants.p('${lsAdv}video.mp4')
        : PathConstants.p('$lsAdv$relative.png');
    await ref.read(fileServiceProvider).copyFile(src, dest);
    final notifier = ref.read(elementProvider.notifier);
    if (el.type.isVideo) {
      notifier.update(
        el.type,
        (element) => element.copyWith(
          path: 'video.mp4',
          isVisible: true,
          showGuideLines: false,
        ),
      );
      ref.read(videoWallpaperRevisionProvider.notifier).state++;
    } else {
      notifier.setGuideLines(el.type, false);
    }
  }
}

// ── Group Mode Panel ──────────────────────────────────────────────────────────

class _AnimationTracksPanel extends StatelessWidget {
  const _AnimationTracksPanel({required this.element, required this.notifier});
  final LockElement element;
  final ElementNotifier notifier;

  void _update(ElementAnimationTrack updated) => notifier.update(
    element.type,
    (current) => current.copyWith(
      animation: ElementAnimation.none,
      animations: [
        for (final track in current.activeAnimations)
          track.type == updated.type ? updated : track,
      ],
    ),
  );

  static String _trackDisplayName(ElementAnimation type) => switch (type) {
    ElementAnimation.scale => 'Scale',
    ElementAnimation.position => 'Position',
    ElementAnimation.rotation => 'Rotation',
    ElementAnimation.alpha => 'Opacity',
    ElementAnimation.size => 'Size',
    ElementAnimation.none => 'None',
  };

  static IconData _iconForTrack(ElementAnimation type) => switch (type) {
    ElementAnimation.scale => Icons.zoom_out_map_rounded,
    ElementAnimation.position => Icons.open_with_rounded,
    ElementAnimation.rotation => Icons.rotate_right_rounded,
    ElementAnimation.alpha => Icons.opacity_rounded,
    ElementAnimation.size => Icons.aspect_ratio_rounded,
    ElementAnimation.none => Icons.motion_photos_off_rounded,
  };

  static String _formatEaseName(MamlEase ease) {
    final name = ease.name;
    final buffer = StringBuffer();
    for (int i = 0; i < name.length; i++) {
      final char = name[i];
      if (i == 0) {
        buffer.write(char.toUpperCase());
      } else if (char.toUpperCase() == char && char.toLowerCase() != char) {
        buffer.write(' ');
        buffer.write(char);
      } else {
        buffer.write(char);
      }
    }
    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final scheme = Theme.of(context).colorScheme;
    final tracks = element.activeAnimations;
    final available = ElementAnimation.values
        .where(
          (type) =>
              type != ElementAnimation.none &&
              !tracks.any((track) => track.type == type) &&
              (type != ElementAnimation.size ||
                  const {
                    ElementType.rectangleShape,
                    ElementType.ellipseShape,
                    ElementType.arcShape,
                  }.contains(element.type)),
        )
        .toList();

    return _Section(
      title: 'ELEMENT ANIMATION',
      trailing: available.isNotEmpty
          ? PopupMenuButton<ElementAnimation>(
              tooltip: 'Add animation',
              offset: const Offset(0, 24),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              color: colors.surface,
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: colors.primary.withAlpha(25),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    border: Border.all(color: colors.primary.withAlpha(100)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add_rounded, size: 14, color: colors.primary),
                      const SizedBox(width: 4),
                      Text(
                        'Add',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: colors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              itemBuilder: (context) => [
                for (final type in available)
                  PopupMenuItem(
                    value: type,
                    height: 36,
                    child: Row(
                      children: [
                        Icon(
                          _iconForTrack(type),
                          size: 16,
                          color: colors.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _trackDisplayName(type),
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
              ],
              onSelected: (type) {
                notifier.snapshotForDrag();
                notifier.update(
                  element.type,
                  (current) => current.copyWith(
                    animation: ElementAnimation.none,
                    animations: [
                      ...current.activeAnimations,
                      ElementAnimationTrack(
                        type: type,
                        amount: switch (type) {
                          ElementAnimation.scale ||
                          ElementAnimation.size => 1.2,
                          ElementAnimation.alpha => 80,
                          ElementAnimation.rotation => 360,
                          _ => 60,
                        },
                      ),
                    ],
                  ),
                );
              },
            )
          : null,
      child: tracks.isEmpty
          ? Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: colors.border.withAlpha(80)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.auto_awesome_motion_outlined,
                    size: 28,
                    color: scheme.onSurfaceVariant.withAlpha(120),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'No animations added',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Tap "+ Add" above to animate this element',
                    style: TextStyle(
                      fontSize: 11,
                      color: scheme.onSurfaceVariant.withAlpha(150),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final track in tracks)
                  Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colors.surface,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(color: colors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: colors.primary.withAlpha(22),
                                borderRadius: BorderRadius.circular(
                                  AppRadius.xs,
                                ),
                              ),
                              child: Icon(
                                _iconForTrack(track.type),
                                size: 14,
                                color: colors.primary,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _trackDisplayName(track.type),
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            IconButton(
                              tooltip:
                                  'Remove ${_trackDisplayName(track.type)} animation',
                              icon: const Icon(Icons.close_rounded, size: 16),
                              splashRadius: 14,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(
                                minWidth: 24,
                                minHeight: 24,
                              ),
                              onPressed: () {
                                notifier.snapshotForDrag();
                                notifier.update(
                                  element.type,
                                  (current) => current.copyWith(
                                    animation: ElementAnimation.none,
                                    animations: current.activeAnimations
                                        .where(
                                          (item) => item.type != track.type,
                                        )
                                        .toList(),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Easing',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              height: 34,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                              ),
                              decoration: BoxDecoration(
                                color: colors.surfaceOverlay,
                                borderRadius: BorderRadius.circular(
                                  AppRadius.sm,
                                ),
                                border: Border.all(color: colors.border),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<MamlEase>(
                                  key: ValueKey(
                                    '${element.type.name}-${track.type.name}-${track.ease.name}',
                                  ),
                                  value: track.ease,
                                  isExpanded: true,
                                  icon: const Icon(
                                    Icons.keyboard_arrow_down_rounded,
                                    size: 18,
                                  ),
                                  borderRadius: BorderRadius.circular(
                                    AppRadius.md,
                                  ),
                                  items: [
                                    for (final ease in MamlEase.values)
                                      DropdownMenuItem(
                                        value: ease,
                                        child: Text(
                                          _formatEaseName(ease),
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                      ),
                                  ],
                                  onChanged: (ease) {
                                    if (ease == null) return;
                                    notifier.snapshotForDrag();
                                    _update(track.copyWith(ease: ease));
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        _SliderRow(
                          label: 'Duration (ms)',
                          value: track.duration.toDouble().clamp(100, 10000),
                          min: 100,
                          max: 10000,
                          decimals: 0,
                          onChanged: (value) => _update(
                            track.copyWith(
                              duration: value.round().clamp(100, 60000),
                            ),
                          ),
                        ),
                        if (track.type == ElementAnimation.position)
                          _ToggleRow(
                            label: 'Custom start position',
                            value: track.hasCustomStart,
                            onChanged: (value) {
                              notifier.snapshotForDrag();
                              _update(
                                track.copyWith(
                                  startX: element.dx,
                                  startY: element.dy,
                                  clearStartPosition: !value,
                                ),
                              );
                            },
                          ),
                        if (track.hasCustomStart) ...[
                          _SliderRow(
                            label: 'Start X',
                            value: track.startX!.clamp(-600, 600),
                            min: -600,
                            max: 600,
                            onChanged: (value) =>
                                _update(track.copyWith(startX: value)),
                          ),
                          _SliderRow(
                            label: 'Start Y',
                            value: track.startY!.clamp(-1200, 1200),
                            min: -1200,
                            max: 1200,
                            onChanged: (value) =>
                                _update(track.copyWith(startY: value)),
                          ),
                        ],
                        if (!track.hasCustomStart)
                          _SliderRow(
                            label: switch (track.type) {
                              ElementAnimation.position =>
                                'Horizontal Distance (px)',
                              ElementAnimation.rotation => 'Rotation (degrees)',
                              ElementAnimation.alpha => 'Minimum Alpha',
                              _ => 'Peak Scale',
                            },
                            min: _minimum(track.type),
                            max: _maximum(track.type),
                            decimals: switch (track.type) {
                              ElementAnimation.scale ||
                              ElementAnimation.size => 2,
                              _ => 0,
                            },
                            value: track.amount.clamp(
                              _minimum(track.type),
                              _maximum(track.type),
                            ),
                            onChanged: (value) => _update(
                              track.copyWith(
                                amount: value.clamp(
                                  _minimum(track.type),
                                  _maximum(track.type),
                                ),
                              ),
                            ),
                          ),
                        if (track.type == ElementAnimation.position &&
                            !track.hasCustomStart)
                          _SliderRow(
                            label: 'Vertical Distance (px)',
                            value: track.offsetY.clamp(-2340, 2340),
                            min: -2340,
                            max: 2340,
                            decimals: 0,
                            onChanged: (value) => _update(
                              track.copyWith(offsetY: value.clamp(-2340, 2340)),
                            ),
                          ),
                        const SizedBox(height: 2),
                        _ToggleRow(
                          label: 'Loop Animation',
                          value: track.loop,
                          onChanged: (value) {
                            notifier.snapshotForDrag();
                            _update(track.copyWith(loop: value));
                          },
                        ),
                      ],
                    ),
                  ),
              ],
            ),
    );
  }

  double _minimum(ElementAnimation type) => switch (type) {
    ElementAnimation.scale || ElementAnimation.size => 0.1,
    ElementAnimation.position => -1080,
    _ => 0,
  };

  double _maximum(ElementAnimation type) => switch (type) {
    ElementAnimation.scale || ElementAnimation.size => 4,
    ElementAnimation.alpha => 255,
    _ => 1080,
  };
}

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

    final selectedElements = state.elements.where(state.isSelected).toList();
    final colorableElements = selectedElements
        .where(
          (e) =>
              !e.type.isIcon &&
              !e.type.isMusic &&
              !e.type.isVideo &&
              !e.type.isPng,
        )
        .toList();

    final firstColor = colorableElements.isNotEmpty
        ? colorableElements.first.color
        : Colors.white;

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
                Icon(
                  Icons.select_all_rounded,
                  size: 16,
                  color: context.appColors.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Group — ${selectedElements.length} elements',
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
                        keyboardType: const TextInputType.numberWithOptions(
                          signed: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _yController,
                        decoration: const InputDecoration(labelText: 'Y'),
                        keyboardType: const TextInputType.numberWithOptions(
                          signed: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    IconButton.outlined(
                      icon: const Icon(Icons.align_horizontal_center, size: 18),
                      tooltip: 'Center all horizontally',
                      visualDensity: VisualDensity.compact,
                      onPressed: () {
                        n.centerGroup(horizontal: true);
                      },
                    ),
                    const SizedBox(width: 4),
                    IconButton.outlined(
                      icon: const Icon(Icons.align_vertical_center, size: 18),
                      tooltip: 'Center all vertically',
                      visualDensity: VisualDensity.compact,
                      onPressed: () {
                        n.centerGroup(horizontal: false);
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
  const _Section({required this.title, required this.child, this.trailing});
  final String title;
  final Widget child;
  final Widget? trailing;

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
                crossAxisAlignment: CrossAxisAlignment.center,
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
                  if (trailing != null) ...[const Spacer(), trailing!],
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

// ── Sub-Card wrapper ──────────────────────────────────────────────────────────

class _SubCard extends StatelessWidget {
  const _SubCard({
    required this.title,
    required this.icon,
    required this.children,
  });

  final String title;
  final IconData icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final scheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: colors.border.withAlpha(90)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: colors.primary.withAlpha(22),
                  borderRadius: BorderRadius.circular(AppRadius.xs),
                ),
                child: Icon(icon, size: 14, color: colors.primary),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                    color: scheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

// ── Unlock Custom Text Field ──────────────────────────────────────────────────

class _UnlockTextField extends StatefulWidget {
  const _UnlockTextField({
    super.key,
    required this.initialText,
    required this.onChanged,
  });

  final String initialText;
  final ValueChanged<String> onChanged;

  @override
  State<_UnlockTextField> createState() => _UnlockTextFieldState();
}

class _UnlockTextFieldState extends State<_UnlockTextField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialText);
  }

  @override
  void didUpdateWidget(covariant _UnlockTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialText != oldWidget.initialText &&
        widget.initialText != _controller.text) {
      _controller.text = widget.initialText;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final scheme = Theme.of(context).colorScheme;

    return TextField(
      controller: _controller,
      style: const TextStyle(fontSize: 12),
      decoration: InputDecoration(
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 10,
        ),
        labelText: 'Custom Text',
        labelStyle: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
        hintText: 'e.g. Slide to unlock',
        hintStyle: TextStyle(
          fontSize: 12,
          color: scheme.onSurfaceVariant.withAlpha(120),
        ),
        prefixIcon: Icon(
          Icons.edit_note_rounded,
          size: 18,
          color: colors.primary,
        ),
        suffixIcon: _controller.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.close_rounded, size: 16),
                tooltip: 'Clear text',
                splashRadius: 14,
                onPressed: () {
                  _controller.clear();
                  widget.onChanged('');
                  setState(() {});
                },
              )
            : null,
        filled: true,
        fillColor: colors.bgSubtle,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: BorderSide(color: colors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: BorderSide(color: colors.border.withAlpha(120)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: BorderSide(color: colors.primary, width: 1.5),
        ),
      ),
      onChanged: (val) {
        widget.onChanged(val);
        setState(() {});
      },
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
                  Shadow(
                    color: Colors.black54,
                    offset: Offset(0, 1),
                    blurRadius: 2,
                  ),
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
                  .map(
                    (e) => DropdownMenuItem(
                      value: e.value,
                      child: Text(e.key, style: const TextStyle(fontSize: 12)),
                    ),
                  )
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
          color: selected ? colors.primary.withAlpha(30) : colors.surface,
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
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
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

  static const _scalePresets = [
    0.25,
    0.5,
    0.75,
    1.0,
    1.25,
    1.5,
    1.75,
    2.0,
    2.5,
    3.0,
    3.5,
    4.0,
    5.0,
    6.0,
    8.0,
    10.0,
  ];
  static const _fontPresets = [
    8.0,
    10.0,
    12.0,
    14.0,
    16.0,
    18.0,
    20.0,
    24.0,
    28.0,
    32.0,
    36.0,
    40.0,
    48.0,
    60.0,
    72.0,
  ];

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
                color: selected
                    ? colors.primary.withAlpha(25)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: selected
                      ? colors.primary.withAlpha(140)
                      : colors.border,
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
    this.decimals = 2,
    this.unit,
  });
  final String label;
  final double value, min, max;
  final int? divisions;
  final int decimals;
  final String? unit;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final clamped = value.clamp(min, max);
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
              value: clamped,
              decimals: decimals,
              unit: unit,
              min: min,
              max: max,
              onChanged: onChanged,
            ),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 3,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5.5),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 11),
          ),
          child: Slider(
            value: clamped,
            min: min,
            max: max,
            divisions: divisions,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}

class _EditableValue extends StatefulWidget {
  const _EditableValue({
    required this.value,
    required this.onChanged,
    this.decimals = 2,
    this.unit,
    this.min,
    this.max,
  });
  final double value;
  final int decimals;
  final String? unit;
  final double? min;
  final double? max;
  final ValueChanged<double> onChanged;

  @override
  State<_EditableValue> createState() => _EditableValueState();
}

class _EditableValueState extends State<_EditableValue> {
  late final TextEditingController _controller;
  bool _isEditing = false;

  String _format(double v) {
    if (widget.decimals == 0 || v == v.roundToDouble()) {
      return v.round().toString();
    }
    var s = v.toStringAsFixed(widget.decimals);
    if (s.contains('.')) {
      s = s.replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');
    }
    return s;
  }

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: _format(widget.value));
  }

  @override
  void didUpdateWidget(covariant _EditableValue oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value && !_isEditing) {
      _controller.text = _format(widget.value);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _commitValue() {
    final newValue = double.tryParse(_controller.text);
    if (newValue != null) {
      final clamped = (widget.min != null && widget.max != null)
          ? newValue.clamp(widget.min!, widget.max!)
          : newValue;
      widget.onChanged(clamped);
    }
    setState(() => _isEditing = false);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final formatted = _format(widget.value);
    final display = widget.unit != null
        ? '$formatted ${widget.unit}'
        : formatted;

    final badgeBg = isDark
        ? scheme.surfaceContainerHighest.withValues(alpha: 0.6)
        : scheme.primary.withValues(alpha: 0.08);
    final borderColor = isDark
        ? scheme.outlineVariant.withValues(alpha: 0.35)
        : scheme.primary.withValues(alpha: 0.2);
    final textColor = scheme.primary;

    return Container(
      // A TextField inside the Row needs a finite width while editing.
      constraints: BoxConstraints(
        minWidth: widget.unit != null ? 52 : 42,
        maxWidth: 90,
      ),
      height: 22,
      child: _isEditing
          ? TextField(
              controller: _controller,
              autofocus: true,
              keyboardType: TextInputType.numberWithOptions(
                decimal: widget.decimals > 0,
                signed: (widget.min ?? 0) < 0,
              ),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: scheme.onSurface,
              ),
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 4,
                  vertical: 0,
                ),
                isDense: true,
                filled: true,
                fillColor: scheme.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: BorderSide(color: scheme.primary, width: 1.5),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: BorderSide(color: scheme.primary, width: 1.5),
                ),
              ),
              onTapOutside: (_) => _commitValue(),
              onSubmitted: (_) => _commitValue(),
            )
          : InkWell(
              borderRadius: BorderRadius.circular(6),
              onTap: () {
                _controller.text = _format(widget.value);
                setState(() => _isEditing = true);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: borderColor),
                ),
                child: Text(
                  display,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                    letterSpacing: 0.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
    );
  }
}

// ── Num Field ─────────────────────────────────────────────────────────────────

class _NumField extends StatefulWidget {
  const _NumField({
    required this.label,
    required this.value,
    required this.onChanged,
  });
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
