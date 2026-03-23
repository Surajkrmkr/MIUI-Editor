import 'package:flex_color_picker/flex_color_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:miui_icon_generator/core/theme/app_theme.dart';
import '../../../../presentation/providers/icon_editor_provider.dart';

class ColorTab extends ConsumerWidget {
  const ColorTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppTheme.cardDark : Colors.white;
    final sectionBg = isDark ? AppTheme.surfaceDark : const Color(0xFFF0F0F5);
    final borderColor = isDark ? Colors.white.withAlpha(18) : Colors.black.withAlpha(15);

    return DefaultTabController(
      length: 4,
      child: SizedBox(
        height: 560,
        width: 500,
        child: Column(
          children: [
            // Custom tab bar header
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                border: Border.all(color: borderColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
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
                        'COLORS',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: scheme.onSurfaceVariant,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: sectionBg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TabBar(
                      tabs: const [
                        Tab(text: 'Background'),
                        Tab(text: 'Icon'),
                        Tab(text: 'Border'),
                        Tab(text: 'Accent'),
                      ],
                      dividerColor: Colors.transparent,
                      indicator: BoxDecoration(
                        color: scheme.primaryContainer,
                        borderRadius: BorderRadius.circular(9),
                      ),
                      indicatorSize: TabBarIndicatorSize.tab,
                      labelColor: scheme.onPrimaryContainer,
                      unselectedLabelColor: scheme.onSurfaceVariant,
                      labelStyle: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                      unselectedLabelStyle: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
                      ),
                      overlayColor:
                          WidgetStateProperty.all(Colors.transparent),
                    ),
                  ),
                ],
              ),
            ),

            // Tab content
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(16),
                  ),
                  border: Border(
                    left: BorderSide(color: borderColor),
                    right: BorderSide(color: borderColor),
                    bottom: BorderSide(color: borderColor),
                  ),
                ),
                child: Consumer(builder: (context, ref, _) {
                  final s = ref.watch(iconEditorProvider);
                  final n = ref.read(iconEditorProvider.notifier);
                  return TabBarView(
                    children: [
                      _GradientPicker(
                        c1: s.bgColor,
                        c2: s.bgColor2,
                        a1: s.bgGradStart,
                        a2: s.bgGradEnd,
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
                      _WheelPicker(
                          color: s.iconColor, onChanged: n.setIconColor),
                      _WheelPicker(
                          color: s.borderColor, onChanged: n.setBorderColor),
                      _WheelPicker(
                          color: s.accentColor, onChanged: n.setAccentColor),
                    ],
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Wheel Picker ──────────────────────────────────────────────────────────────

class _WheelPicker extends StatelessWidget {
  const _WheelPicker({required this.color, required this.onChanged});
  final Color color;
  final ValueChanged<Color> onChanged;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(8),
        child: ColorPicker(
          color: color,
          onColorChanged: onChanged,
          enableOpacity: true,
          showColorCode: true,
          pickersEnabled: const {ColorPickerType.wheel: true},
        ),
      );
}

// ── Gradient Picker ───────────────────────────────────────────────────────────

class _GradientPicker extends StatefulWidget {
  const _GradientPicker({
    required this.c1,
    required this.c2,
    required this.a1,
    required this.a2,
    required this.onColors,
    required this.onAligns,
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
    _c1 = widget.c1;
    _c2 = widget.c2;
    _a1 = widget.a1;
    _a2 = widget.a2;
  }

  @override
  void didUpdateWidget(_GradientPicker old) {
    super.didUpdateWidget(old);
    _c1 = widget.c1;
    _c2 = widget.c2;
    _a1 = widget.a1;
    _a2 = widget.a2;
  }

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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? Colors.white.withAlpha(18) : Colors.black.withAlpha(15);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Gradient preview strip
          Container(
            height: 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: _a1 as Alignment,
                end: _a2 as Alignment,
                colors: [_c1, _c2],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor),
            ),
          ),
          const SizedBox(height: 16),

          // Color buttons row
          Row(
            children: [
              Expanded(
                child: _ColorBtn(
                  color: _c1,
                  label: 'Start Color',
                  onChanged: (c) {
                    setState(() => _c1 = c);
                    widget.onColors(_c1, _c2);
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ColorBtn(
                  color: _c2,
                  label: 'End Color',
                  onChanged: (c) {
                    setState(() => _c2 = c);
                    widget.onColors(_c1, _c2);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Direction dropdowns
          Row(
            children: [
              Expanded(
                child: _AlignDrop(
                  value: _a1,
                  options: _alignOptions,
                  label: 'From',
                  onChanged: (a) {
                    setState(() => _a1 = a);
                    widget.onAligns(_a1, _a2);
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _AlignDrop(
                  value: _a2,
                  options: _alignOptions,
                  label: 'To',
                  onChanged: (a) {
                    setState(() => _a2 = a);
                    widget.onAligns(_a1, _a2);
                  },
                ),
              ),
            ],
          ),
        ],
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
        height: 52,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: isDark ? Colors.white.withAlpha(18) : Colors.black.withAlpha(15)),
          boxShadow: [
            BoxShadow(
              color: color.withAlpha(80),
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
                    blurRadius: 2),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Align Dropdown ────────────────────────────────────────────────────────────

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
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
            color: isDark ? AppTheme.surfaceDark : const Color(0xFFF0F0F5),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
                color: isDark ? Colors.white.withAlpha(18) : Colors.black.withAlpha(15)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<AlignmentGeometry>(
              value: value,
              isExpanded: true,
              borderRadius: BorderRadius.circular(12),
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
