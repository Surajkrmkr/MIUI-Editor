import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/theme/theme_extensions.dart';

class SvgInspector extends ConsumerStatefulWidget {
  const SvgInspector({super.key});

  @override
  ConsumerState<SvgInspector> createState() => _SvgInspectorState();
}

class _SvgInspectorState extends ConsumerState<SvgInspector> {
  bool _isTracing = false;
  String? _lastOutput;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'SVG TRACING (VTRACER)',
          style: TextStyle(
            color: colors.textDisabled,
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 16),

        if (_isTracing)
          Center(
            child: Column(
              children: [
                CircularProgressIndicator(
                    strokeWidth: 2, color: colors.primary),
                const SizedBox(height: 12),
                Text(
                  'Tracing image...',
                  style:
                      TextStyle(color: colors.textSecondary, fontSize: 11),
                ),
              ],
            ),
          )
        else
          Column(
            children: [
              _buildTraceButton(colors),
              if (_lastOutput != null) ...[
                const SizedBox(height: 12),
                Text(
                  'Last output: ${_lastOutput!.split(r'\').last}',
                  style: TextStyle(color: colors.success, fontSize: 10),
                ),
              ],
            ],
          ),

        const SizedBox(height: 24),
        Text(
          'PATH OPTIMIZATION',
          style: TextStyle(
            color: colors.textDisabled,
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 12),
        _buildSliderSetting('Color Precision', 6, 1, 8, colors),
        _buildSliderSetting('Filter Speckle', 4, 1, 64, colors),
        _buildSliderSetting('Corner Threshold', 60, 0, 180, colors),
      ],
    );
  }

  Widget _buildTraceButton(AppColorScheme colors) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        icon: const Icon(Icons.architecture_rounded, size: 16),
        label: const Text('Trace Selected Layer',
            style: TextStyle(fontSize: 11)),
        onPressed: () => _startTrace(),
        style: FilledButton.styleFrom(
          backgroundColor: colors.primary,
          foregroundColor: colors.onPrimary,
        ),
      ),
    );
  }

  Widget _buildSliderSetting(
    String label,
    double value,
    double min,
    double max,
    AppColorScheme colors,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style:
                    TextStyle(color: colors.textSecondary, fontSize: 11)),
            Text(
              value.toInt().toString(),
              style: TextStyle(
                color: colors.primary,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          onChanged: (v) {},
          activeColor: colors.primary,
        ),
      ],
    );
  }

  Future<void> _startTrace() async {
    setState(() => _isTracing = true);
    await Future.delayed(const Duration(seconds: 2));
    setState(() {
      _isTracing = false;
      _lastOutput = 'traced_asset.svg';
    });
  }
}
