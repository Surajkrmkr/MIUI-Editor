import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/directory_provider.dart';
import '../../../providers/wallpaper_provider.dart';

class SettingsDialog extends ConsumerStatefulWidget {
  const SettingsDialog({super.key});
  @override
  ConsumerState<SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends ConsumerState<SettingsDialog> {
  late TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    final count = ref.read(wallpaperProvider).themeCount;
    _ctrl = TextEditingController(text: count.toString());
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  void _save() {
    final v = int.tryParse(_ctrl.text);
    if (v != null && v > 0) {
      ref.read(wallpaperProvider.notifier).updateThemeCount(v);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Settings'),
      content: SizedBox(
        width: 300,
        child: TextField(
          controller: _ctrl,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          onChanged: (_) => _save(),
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            labelText: 'Theme Count per Week',
            suffixIcon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () {
                    final v = int.tryParse(_ctrl.text) ?? 25;
                    _ctrl.text = (v + 1).toString();
                    _save();
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.remove),
                  onPressed: () {
                    final v = int.tryParse(_ctrl.text) ?? 25;
                    if (v > 1) { _ctrl.text = (v - 1).toString(); _save(); }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            ref.read(directoryProvider.notifier)
              ..loadPreLockFolders()
              ..loadPreviewWalls('1');
            Navigator.pop(context);
          },
          child: const Text('OK'),
        ),
      ],
    );
  }
}
