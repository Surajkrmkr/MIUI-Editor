import 'package:flex_color_picker/flex_color_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
    if (state.elements.isEmpty || state.active == null) {
      return const SizedBox(width: 300);
    }
    final el = state.active!;
    final n = ref.read(elementProvider.notifier);

    return SizedBox(
      width: 300,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Name
            Text(el.name, style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),

            // Drop zone for assets
            if (el.type.isIcon ||
                el.type.isMusic ||
                el.type.isVideo ||
                el.type.isPng)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Center(
                  child: AppDropZone(
                    label: 'Drop ${el.type.isVideo ? "MP4" : "PNG"}',
                    allowedExtensions:
                        el.type.isVideo ? ['.mp4'] : ['.png', '.jpg'],
                    onDropped: (path) => _copyAsset(ref, path, el),
                  ),
                ),
              ),

            // Color pickers
            if (!el.type.isIcon &&
                !el.type.isMusic &&
                !el.type.isVideo &&
                !el.type.isPng) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _ColorBtn(
                      color: el.color,
                      label: 'Color 1',
                      onChanged: (c) => n.setColor(el.type, c)),
                  _ColorBtn(
                      color: el.colorSecondary,
                      label: 'Color 2',
                      onChanged: (c) => n.setColorSecondary(el.type, c)),
                ],
              ),
              const SizedBox(height: 8),
            ],

            // isShort / isWrap
            if (el.type.isClock && !el.type.isIcon) ...[
              SwitchListTile(
                  dense: true,
                  value: el.isShort,
                  title: const Text('Short'),
                  onChanged: (v) => n.setIsShort(el.type, v)),
              SwitchListTile(
                  dense: true,
                  value: el.isWrap,
                  title: const Text('Wrap'),
                  onChanged: (v) => n.setIsWrap(el.type, v)),
            ],

            // X / Y
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _NumField(
                    label: 'X',
                    value: el.dx,
                    onChanged: (v) => n.setPosition(el.type, v, el.dy)),
                _NumField(
                    label: 'Y',
                    value: el.dy,
                    onChanged: (v) => n.setPosition(el.type, el.dx, v)),
              ],
            ),
            const SizedBox(height: 8),

            // Scale / FontSize
            _SliderRow(
              label: el.type.isText ? 'Font Size' : 'Scale',
              value: el.type.isText ? el.fontSize : el.scale,
              min: 0,
              max: el.type.isText ? 100 : 4,
              onChanged: (v) => el.type.isText
                  ? n.setFontSize(el.type, v)
                  : n.setScale(el.type, v),
            ),

            // Height / Width (container)
            if (el.type.isContainer) ...[
              _SliderRow(
                  label: 'Height',
                  value: el.height,
                  min: 0,
                  max: 800,
                  onChanged: (v) => n.setHeight(el.type, v)),
              _SliderRow(
                  label: 'Width',
                  value: el.width,
                  min: 0,
                  max: 400,
                  onChanged: (v) => n.setWidth(el.type, v)),
              _SliderRow(
                  label: 'Border Radius',
                  value: el.radius,
                  min: 0,
                  max: 200,
                  onChanged: (v) => n.setRadius(el.type, v)),
              _SliderRow(
                  label: 'Border Width',
                  value: el.borderWidth,
                  min: 0,
                  max: 10,
                  onChanged: (v) => n.setBorderWidth(el.type, v)),
              const Text('Border Color'),
              ColorPicker(
                color: el.borderColor,
                onColorChanged: (c) => n.setBorderColor(el.type, c),
                enableOpacity: true,
                pickersEnabled: const {ColorPickerType.wheel: true},
              ),
            ],

            // Text expression
            if (el.type.isText)
              TextFormField(
                initialValue: el.text,
                decoration: const InputDecoration(
                  labelText: 'Text / Expression',
                  border: OutlineInputBorder(),
                ),
                onChanged: (v) => n.setText(el.type, v),
              ),

            // Alignment chips
            if (el.type.isText || el.type.isDateTime)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _AlignChip('left', Alignment.centerLeft, el, n),
                    _AlignChip('center', Alignment.center, el, n),
                    _AlignChip('right', Alignment.centerRight, el, n),
                  ],
                ),
              ),

            // Angle
            _SliderRow(
                label: 'Angle',
                value: el.angle,
                min: 0,
                max: 360,
                divisions: 36,
                onChanged: (v) => n.setAngle(el.type, v)),

            // Reset + Delete
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.restore),
                  color: Theme.of(context).colorScheme.primary,
                  tooltip: 'Reset position',
                  onPressed: () => n.resetPosition(el.type),
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  color: Theme.of(context).colorScheme.error,
                  tooltip: 'Remove',
                  onPressed: () => n.remove(el.type),
                ),
              ],
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
    final dest = '$lsAdv${el.path.isNotEmpty ? el.path : el.name}.$ext';
    await ref.read(fileServiceProvider).copyFile(src, dest);
    // Trigger rebuild
    ref.read(elementProvider.notifier).setGuideLines(el.type, false);
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

class _ColorBtn extends StatelessWidget {
  const _ColorBtn(
      {required this.color, required this.label, required this.onChanged});
  final Color color;
  final String label;
  final ValueChanged<Color> onChanged;

  @override
  Widget build(BuildContext context) => ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
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
            ColorPickerType.accent: false
          },
        ).showPickerDialog(context),
        child: Text(label,
            style: const TextStyle(color: Colors.white, shadows: [
              Shadow(color: Colors.black, offset: Offset(1, 1), blurRadius: 1)
            ])),
      );
}

class _AlignChip extends StatelessWidget {
  const _AlignChip(this.label, this.align, this.el, this.n);
  final String label;
  final AlignmentGeometry align;
  final LockElement el;
  final ElementNotifier n;

  @override
  Widget build(BuildContext context) => ChoiceChip(
        label: Text(label),
        selected: el.align == align,
        onSelected: (_) => n.setAlign(el.type, align),
      );
}

class _SliderRow extends StatelessWidget {
  const _SliderRow(
      {required this.label,
      required this.value,
      required this.onChanged,
      this.min = 0,
      required this.max,
      this.divisions});
  final String label;
  final double value, min, max;
  final int? divisions;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$label: ${value.toStringAsFixed(0)}'),
          Slider(
              value: value,
              min: min,
              max: max,
              divisions: divisions,
              onChanged: onChanged),
        ],
      );
}

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
  Widget build(BuildContext context) => SizedBox(
        width: 100,
        child: TextField(
          controller: _c,
          decoration: InputDecoration(
              labelText: widget.label, border: const OutlineInputBorder()),
          keyboardType: const TextInputType.numberWithOptions(signed: true),
          onChanged: (v) {
            final d = double.tryParse(v);
            if (d != null) widget.onChanged(d);
          },
        ),
      );
}
