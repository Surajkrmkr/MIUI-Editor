import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/vtracer_service.dart';
import 'package:miui_icon_generator/core/theme/app_theme.dart';

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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'SVG TRACING (VTRACER)',
          style: TextStyle(
            color: Colors.white38,
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 16),
        
        // Tracing Status
        if (_isTracing)
          const Center(
            child: Column(
              children: [
                CircularProgressIndicator(strokeWidth: 2, color: AppTheme.accent),
                SizedBox(height: 12),
                Text('Tracing image...', style: TextStyle(color: Colors.white54, fontSize: 11)),
              ],
            ),
          )
        else
          Column(
            children: [
              _buildTraceButton(),
              if (_lastOutput != null) ...[
                const SizedBox(height: 12),
                Text('Last output: ${_lastOutput!.split(r'\').last}', 
                    style: const TextStyle(color: Colors.green, fontSize: 10)),
              ],
            ],
          ),
          
        const SizedBox(height: 24),
        const Text(
          'PATH OPTIMIZATION',
          style: TextStyle(
            color: Colors.white38,
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 12),
        _buildSliderSetting('Color Precision', 6, 1, 8),
        _buildSliderSetting('Filter Speckle', 4, 1, 64),
        _buildSliderSetting('Corner Threshold', 60, 0, 180),
      ],
    );
  }

  Widget _buildTraceButton() {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        icon: const Icon(Icons.architecture_rounded, size: 16),
        label: const Text('Trace Selected Layer', style: TextStyle(fontSize: 11)),
        onPressed: () => _startTrace(),
        style: FilledButton.styleFrom(
          backgroundColor: AppTheme.accent,
          foregroundColor: Colors.black,
        ),
      ),
    );
  }

  Widget _buildSliderSetting(String label, double value, double min, double max) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
            Text(value.toInt().toString(), style: const TextStyle(color: AppTheme.accent, fontSize: 11, fontWeight: FontWeight.bold)),
          ],
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          onChanged: (v) {},
          activeColor: AppTheme.accent,
        ),
      ],
    );
  }

  Future<void> _startTrace() async {
    setState(() => _isTracing = true);
    // Simulation for Phase 3 UI work
    await Future.delayed(const Duration(seconds: 2));
    setState(() {
      _isTracing = false;
      _lastOutput = 'traced_asset.svg';
    });
  }
}
