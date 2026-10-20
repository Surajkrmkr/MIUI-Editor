import 'dart:math';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:theme_raster_flutter/theme_raster_flutter.dart'
    show LockscreenCanvas;
import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/failures.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/theme_extensions.dart';
import '../../../../domain/entities/builtin_widget_styles.dart';
import '../../../../domain/entities/element_widget.dart';
import '../../../../domain/entities/widget_style.dart';
import '../../../providers/element_provider.dart';
import '../../../providers/widget_style_provider.dart';
import 'unlock_control_preview.dart';
import 'analog_clock_art.dart';
import 'shortcut_set_art.dart';
import 'calendar_style_art.dart';

class WidgetStylesPanel extends ConsumerStatefulWidget {
  const WidgetStylesPanel({super.key, required this.element});
  final LockElement element;
  @override
  ConsumerState<WidgetStylesPanel> createState() => _WidgetStylesPanelState();
}

class _WidgetStylesPanelState extends ConsumerState<WidgetStylesPanel> {
  String? _setId;
  bool _busy = false;

  Future<void> _run(
    Future<Failure?> Function() action, {
    bool reload = false,
  }) async {
    setState(() => _busy = true);
    try {
      final failure = await action();
      if (failure != null) throw Exception(failure.message);
      if (reload && mounted) {
        ref.invalidate(widgetStyleSetsProvider);
        await ref.read(widgetStyleSetsProvider.future);
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.toString())));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _save(List<WidgetStyleSet> sets) async {
    final element = widget.element;
    var styleName = 'My ${element.type.label}';
    var setName =
        sets.where((set) => set.id == _setId).firstOrNull?.name ?? 'Personal';
    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Save Style'),
        content: SizedBox(
          width: 320,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                initialValue: styleName,
                autofocus: true,
                maxLength: 120,
                decoration: const InputDecoration(labelText: 'Style name'),
                onChanged: (value) => styleName = value,
              ),
              TextFormField(
                initialValue: setName,
                maxLength: 120,
                decoration: const InputDecoration(labelText: 'Style set'),
                onChanged: (value) => setName = value,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (styleName.trim().isNotEmpty && setName.trim().isNotEmpty) {
                Navigator.pop(dialogContext, styleName.trim());
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (name == null || !mounted) return;
    await _run(() async {
      final (set, failure) = await ref
          .read(manageWidgetStylesProvider)
          .saveCurrent(
            element: element,
            name: name,
            setName: setName,
            set: sets
                .where(
                  (set) =>
                      set.name.toLowerCase() == setName.trim().toLowerCase(),
                )
                .firstOrNull,
          );
      if (failure == null && mounted) setState(() => _setId = set!.id);
      return failure;
    }, reload: true);
  }

  Future<void> _import() => _run(() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
      dialogTitle: 'Import Style Set',
    );
    final path = result?.files.single.path;
    if (path == null) return null;
    final (set, failure) = await ref
        .read(manageWidgetStylesProvider)
        .importSet(path);
    if (failure == null && mounted) setState(() => _setId = set!.id);
    return failure;
  }, reload: true);

  Future<void> _export(WidgetStyleSet set) => _run(() async {
    final path = await FilePicker.platform.saveFile(
      dialogTitle: 'Export Style Set',
      fileName: '${set.id}.json',
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    if (path == null) return null;
    return ref
        .read(manageWidgetStylesProvider)
        .exportSet(set, path.endsWith('.json') ? path : '$path.json');
  });

  Future<void> _delete(WidgetStyleSet set) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Style Set?'),
        content: Text(set.name),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await _run(
        () => ref.read(manageWidgetStylesProvider).delete(set.id),
        reload: true,
      );
    }
  }

  Widget _clockSetPicker() {
    final colors = context.appColors;
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Custom Widgets',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: scheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Clock Sets',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: scheme.onSurface,
          ),
        ),
        const SizedBox(height: 10),
        LayoutBuilder(
          builder: (context, constraints) => GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: builtinClockSets.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: constraints.maxWidth >= 320 ? 2 : 1,
              mainAxisExtent: 170,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemBuilder: (context, index) {
              final preset = builtinClockSets[index];
              final ys = preset.elements.map((e) => e.dy);
              // Align so the 300px window is centred on the set's middle.
              final cropY = ((ys.reduce(min) + ys.reduce(max)) / 2 / 150).clamp(
                -1.0,
                1.0,
              );
              return Material(
                color: colors.surfaceOverlay,
                borderRadius: BorderRadius.circular(AppRadius.sm),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: widget.element.isLocked
                      ? null
                      : () => ref
                            .read(elementProvider.notifier)
                            .applyClockSet(preset.elements),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      border: Border.all(color: colors.border),
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: ColoredBox(
                              color: preset.background,
                              child: SizedBox.expand(
                                child: FittedBox(
                                  child: ClipRect(
                                    child: Align(
                                      alignment: Alignment(0, cropY),
                                      heightFactor: .5,
                                      child: IgnorePointer(
                                        child: DefaultTextStyle(
                                          style: const TextStyle(
                                            fontFamily: 'Roboto',
                                          ),
                                          child: LockscreenCanvas(
                                            elements: preset.elements,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          preset.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (clockSetElementTypes.contains(widget.element.type)) {
      return _clockSetPicker();
    }
    final colors = context.appColors;
    final scheme = Theme.of(context).colorScheme;
    final library = ref.watch(widgetStyleSetsProvider);
    final saved = library.asData?.value;
    final sets = [...builtinStyleSets, ...?saved]
        .where((item) => item.styles.any((s) => s.type == widget.element.type))
        .toList();
    final set =
        sets.where((item) => item.id == _setId).firstOrNull ??
        sets.firstOrNull ??
        builtinStyleSets.first;
    final styles = set.styles
        .where((style) => style.type == widget.element.type)
        // Calendar styles are listed for the layout currently chosen.
        .where(
          (style) =>
              style.type != ElementType.calendarGrid ||
              style.appearance['calendarRows'] == null ||
              style.appearance['calendarRows'] ==
                  widget.element.calendarWeekRows,
        )
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<String>(
          key: ValueKey(set.id),
          initialValue: set.id,
          isExpanded: true,
          dropdownColor: colors.surfaceElevated,
          style: TextStyle(
            fontSize: 12,
            color: scheme.onSurface,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 8,
            ),
            labelText: widget.element.type == ElementType.shortcutSet
                ? 'Custom Widgets'
                : 'Style Set',
            labelStyle: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
            prefixIcon: Icon(
              Icons.style_outlined,
              size: 16,
              color: colors.primary,
            ),
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
          items: [
            for (final item in sets)
              DropdownMenuItem(
                value: item.id,
                child: Row(
                  children: [
                    Text(
                      item.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12),
                    ),
                    if (builtinStyleSets.any((b) => b.id == item.id)) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 1.5,
                        ),
                        decoration: BoxDecoration(
                          color: colors.primary.withAlpha(25),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'BUILT-IN',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.4,
                            color: colors.primary,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
          ],
          onChanged: _busy ? null : (value) => setState(() => _setId = value),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Text(
              '${styles.length} ${styles.length == 1 ? "style" : "styles"}',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: scheme.onSurfaceVariant,
              ),
            ),
            const Spacer(),
            _ToolbarButton(
              icon: Icons.bookmark_add_outlined,
              label: 'Save',
              tooltip: 'Save current style preset',
              onPressed: _busy || saved == null ? null : () => _save(saved),
            ),
            const SizedBox(width: 4),
            _ToolbarButton(
              icon: Icons.file_upload_outlined,
              label: 'Import',
              tooltip: 'Import style set (.json)',
              onPressed: _busy ? null : _import,
            ),
            const SizedBox(width: 4),
            _ToolbarButton(
              icon: Icons.file_download_outlined,
              label: 'Export',
              tooltip: 'Export style set (.json)',
              onPressed: _busy ? null : () => _export(set),
            ),
            if (!builtinStyleSets.any((b) => b.id == set.id)) ...[
              const SizedBox(width: 4),
              _ToolbarButton(
                icon: Icons.delete_outline_rounded,
                tooltip: 'Delete custom style set',
                isDestructive: true,
                onPressed: _busy ? null : () => _delete(set),
              ),
            ],
          ],
        ),
        if (_busy || library.isLoading) ...[
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              minHeight: 2,
              color: colors.primary,
              backgroundColor: colors.primary.withAlpha(30),
            ),
          ),
        ],
        if (library.hasError) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: scheme.error.withAlpha(20),
              borderRadius: BorderRadius.circular(AppRadius.sm),
              border: Border.all(color: scheme.error.withAlpha(60)),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.error_outline_rounded,
                  size: 16,
                  color: scheme.error,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${library.error}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: scheme.error, fontSize: 11),
                  ),
                ),
                IconButton(
                  tooltip: 'Retry loading styles',
                  icon: const Icon(Icons.refresh, size: 16),
                  visualDensity: VisualDensity.compact,
                  onPressed: _busy
                      ? null
                      : () => ref.invalidate(widgetStyleSetsProvider),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 10),
        if (styles.isEmpty)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.symmetric(vertical: 8),
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: colors.border.withAlpha(80)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.style_outlined,
                  size: 28,
                  color: scheme.onSurfaceVariant.withAlpha(120),
                ),
                const SizedBox(height: 8),
                Text(
                  'No styles for this widget',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Save your customized widget as a style using the "Save" button above',
                  style: TextStyle(
                    fontSize: 11,
                    color: scheme.onSurfaceVariant.withAlpha(150),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          )
        else
          LayoutBuilder(
            builder: (context, constraints) => GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: styles.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: constraints.maxWidth >= 360
                    ? 3
                    : constraints.maxWidth >= 220
                    ? 2
                    : 1,
                mainAxisExtent: 114,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemBuilder: (context, index) {
                final style = styles[index];
                final element = style.applyTo(LockElement(type: style.type));
                final json = widget.element.toJson();
                final selected = style.appearance.entries.every(
                  (entry) => json[entry.key] == entry.value,
                );
                return _StyleCard(
                  key: ValueKey('style-${style.id}'),
                  style: style,
                  element: element,
                  selected: selected,
                  onTap: _busy || widget.element.isLocked
                      ? null
                      : () => ref
                            .read(elementProvider.notifier)
                            .applyStyle(style),
                );
              },
            ),
          ),
      ],
    );
  }
}

// ── Style Card ────────────────────────────────────────────────────────────────

class _StyleCard extends StatefulWidget {
  const _StyleCard({
    super.key,
    required this.style,
    required this.element,
    required this.selected,
    required this.onTap,
  });

  final WidgetStyle style;
  final LockElement element;
  final bool selected;
  final VoidCallback? onTap;

  @override
  State<_StyleCard> createState() => _StyleCardState();
}

class _StyleCardState extends State<_StyleCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final scheme = Theme.of(context).colorScheme;

    final borderColor = widget.selected
        ? colors.primary
        : _hovered
        ? colors.primary.withAlpha(130)
        : colors.border.withAlpha(90);

    return Tooltip(
      message: widget.style.name,
      child: MouseRegion(
        cursor: widget.onTap != null
            ? SystemMouseCursors.click
            : SystemMouseCursors.basic,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            color: widget.selected ? colors.surfaceElevated : colors.surface,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: borderColor,
              width: widget.selected ? 1.8 : 1.0,
            ),
            boxShadow: widget.selected
                ? [
                    BoxShadow(
                      color: colors.primary.withAlpha(45),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : _hovered
                ? [
                    BoxShadow(
                      color: Colors.black.withAlpha(50),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: widget.onTap,
            child: Column(
              children: [
                Expanded(
                  child: Container(
                    width: double.infinity,
                    color: colors.bgSubtle,
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: CustomPaint(
                            painter: _PreviewGridPainter(
                              dotColor: colors.borderSubtle.withAlpha(50),
                            ),
                          ),
                        ),
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 8,
                            ),
                            child: FittedBox(
                              fit: BoxFit.contain,
                              child: _StylePreview(element: widget.element),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: widget.selected
                        ? colors.primary.withAlpha(22)
                        : colors.surface,
                    border: Border(
                      top: BorderSide(
                        color: widget.selected
                            ? colors.primary.withAlpha(60)
                            : colors.border.withAlpha(60),
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          widget.style.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: widget.selected
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: widget.selected
                                ? colors.primary
                                : scheme.onSurface,
                          ),
                        ),
                      ),
                      if (widget.selected) ...[
                        const SizedBox(width: 4),
                        Icon(
                          Icons.check_circle_rounded,
                          size: 13,
                          color: colors.primary,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Toolbar Button ────────────────────────────────────────────────────────────

class _ToolbarButton extends StatelessWidget {
  const _ToolbarButton({
    required this.icon,
    this.label,
    required this.tooltip,
    required this.onPressed,
    this.isDestructive = false,
  });

  final IconData icon;
  final String? label;
  final String tooltip;
  final VoidCallback? onPressed;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final scheme = Theme.of(context).colorScheme;
    final color = isDestructive ? scheme.error : colors.primary;

    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(AppRadius.xs),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: label != null ? 8 : 6,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color: color.withAlpha(20),
              borderRadius: BorderRadius.circular(AppRadius.xs),
              border: Border.all(color: color.withAlpha(70)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 13, color: color),
                if (label != null) ...[
                  const SizedBox(width: 4),
                  Text(
                    label!,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Preview Dot Grid Painter ──────────────────────────────────────────────────

class _PreviewGridPainter extends CustomPainter {
  const _PreviewGridPainter({required this.dotColor});
  final Color dotColor;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = dotColor
      ..style = PaintingStyle.fill;
    const step = 12.0;
    for (double x = step / 2; x < size.width; x += step) {
      for (double y = step / 2; y < size.height; y += step) {
        canvas.drawCircle(Offset(x, y), 0.75, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _PreviewGridPainter oldDelegate) =>
      oldDelegate.dotColor != dotColor;
}

// ── Style Preview ─────────────────────────────────────────────────────────────

class _StylePreview extends StatelessWidget {
  const _StylePreview({required this.element});
  final LockElement element;
  @override
  Widget build(BuildContext context) {
    if (element.type == ElementType.shortcutSet) {
      return ShortcutSetPreview(element: element);
    }
    if (element.type == ElementType.calendarGrid) {
      return element.calendarStyle == CalendarStyle.classic
          ? SizedBox(
              width: element.width / AppConstants.screenRatio,
              height: element.height / AppConstants.screenRatio,
              child: const Center(child: Icon(Icons.calendar_month_rounded)),
            )
          : CalendarStylePreview(element: element);
    }
    if (element.type.isClock && element.type != ElementType.analogClock) {
      final sample = switch (element.type) {
        ElementType.hourClock => '02',
        ElementType.minClock => '36',
        ElementType.secClock => '08',
        ElementType.dotClock || ElementType.dotClock2 => ':',
        ElementType.weekClock => 'Thursday',
        ElementType.monthClock => 'July',
        ElementType.dateClock => '23',
        ElementType.dateTimeText1 => '07-23 Thursday',
        ElementType.dateTimeText2 => 'July 23',
        ElementType.dateTimeText3 => 'Thursday',
        _ => '12',
      };
      return Text(
        sample,
        style: TextStyle(
          color: element.color,
          fontSize: 48,
          fontWeight: element.fontWeight,
        ),
      );
    }
    final angle = element.angle * pi / 180;
    final width = element.width / AppConstants.screenRatio;
    final height = element.unlockHeight / AppConstants.screenRatio;
    return SizedBox(
      width: width * cos(angle).abs() + height * sin(angle).abs(),
      height: width * sin(angle).abs() + height * cos(angle).abs(),
      child: OverflowBox(
        minWidth: width,
        maxWidth: width,
        minHeight: height,
        maxHeight: height,
        child: Transform.rotate(
          angle: angle,
          child: element.type == ElementType.analogClock
              ? AnalogClockPreview(element: element)
              : UnlockControlPreview(element: element),
        ),
      ),
    );
  }
}
