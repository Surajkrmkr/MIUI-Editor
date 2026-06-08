import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/settings_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          SwitchListTile(
            title: const Text('Dark Mode'),
            value: settings.darkMode,
            onChanged: (value) => notifier.updateSettings(darkMode: value),
          ),
          const Divider(),
          const Text('VTracer Parameters', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          ListTile(
            title: const Text('Mode'),
            subtitle: const Text('spline or polygon'),
            trailing: DropdownButton<String>(
              value: settings.mode,
              items: const [
                DropdownMenuItem(value: 'spline', child: Text('spline')),
                DropdownMenuItem(value: 'polygon', child: Text('polygon')),
                DropdownMenuItem(value: 'none', child: Text('none')),
              ],
              onChanged: (value) => notifier.updateSettings(mode: value),
            ),
          ),
          ListTile(
            title: const Text('Color Precision'),
            subtitle: Text(settings.colorPrecision.toString()),
            trailing: SizedBox(
              width: 150,
              child: Slider(
                value: settings.colorPrecision.toDouble(),
                min: 1,
                max: 8,
                divisions: 7,
                label: settings.colorPrecision.toString(),
                onChanged: (value) => notifier.updateSettings(colorPrecision: value.toInt()),
              ),
            ),
          ),
          ListTile(
            title: const Text('Filter Speckle'),
            subtitle: Text(settings.filterSpeckle.toString()),
            trailing: SizedBox(
              width: 150,
              child: Slider(
                value: settings.filterSpeckle.toDouble(),
                min: 1,
                max: 16,
                divisions: 15,
                label: settings.filterSpeckle.toString(),
                onChanged: (value) => notifier.updateSettings(filterSpeckle: value.toInt()),
              ),
            ),
          ),
        ],
      ),
    );
  }
}