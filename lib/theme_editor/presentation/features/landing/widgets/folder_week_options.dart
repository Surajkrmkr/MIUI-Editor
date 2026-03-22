import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/directory_provider.dart';
import '../../home/home_screen.dart';
import 'pick_walls_screen.dart';

class FolderWeekOptions extends ConsumerStatefulWidget {
  const FolderWeekOptions({super.key});

  @override
  ConsumerState<FolderWeekOptions> createState() => _FolderWeekOptionsState();
}

class _FolderWeekOptionsState extends ConsumerState<FolderWeekOptions> {
  final _weekCtrl = TextEditingController();

  @override
  void dispose() {
    _weekCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (_weekCtrl.text.isEmpty) return;
    final dirState = ref.read(directoryProvider);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => HomeScreen(
          folderNum: dirState.selectedFolder,
          weekNum: _weekCtrl.text,
        ),
      ),
    );
  }

  void _pickWalls() {
    final dirState = ref.read(directoryProvider);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PickWallsScreen(
          folderNum: dirState.selectedFolder,
          weekNum: _weekCtrl.text,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dirState = ref.watch(directoryProvider);

    return SizedBox(
      width: 600,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Select Folder', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 20),
            SizedBox(
              height: 200,
              child: SingleChildScrollView(
                child: Wrap(
                  alignment: WrapAlignment.center,
                  children: dirState.preLockFolders.map((folder) {
                    return SizedBox(
                      width: 150,
                      child: RadioListTile<String>(
                        title: Text(folder),
                        value: folder,
                        groupValue: dirState.selectedFolder,
                        onChanged: (val) {
                          if (val == null) return;
                          ref.read(directoryProvider.notifier).selectFolder(val);
                          ref.read(directoryProvider.notifier).loadPreviewWalls(val);
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              dirState.status,
              style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: 300,
              child: TextField(
                controller: _weekCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onSubmitted: (_) => _submit(),
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Week Number',
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FilledButton.icon(
                  icon: const Icon(Icons.wallpaper),
                  label: const Text('Get Walls'),
                  onPressed: _pickWalls,
                ),
                const SizedBox(width: 16),
                FilledButton.icon(
                  icon: const Icon(Icons.chevron_right_rounded),
                  label: const Text('Continue'),
                  onPressed: _submit,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
