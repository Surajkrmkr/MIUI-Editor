import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:miui_icon_generator/core/theme/app_radius.dart';
import '../../../../../core/theme/theme_extensions.dart';
import '../../../providers/directory_provider.dart';
import '../../home/home_screen.dart';

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

  @override
  Widget build(BuildContext context) {
    final dirState = ref.watch(directoryProvider);
    final colors = context.appColors;
    final cs = Theme.of(context).colorScheme;

    return SizedBox(
      width: 560,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Section heading ─────────────────────────────────────────────
            Row(
              children: [
                Icon(Icons.folder_open_rounded,
                    color: colors.primary, size: 20),
                const SizedBox(width: 8),
                Text('Select Folder',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 16),

            // ── Folder chips ────────────────────────────────────────────────
            Container(
              constraints: const BoxConstraints(maxHeight: 180),
              decoration: BoxDecoration(
                color: cs.surface,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(color: cs.outline.withAlpha(40)),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(12),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children:
                      (dirState.preLockFolders.toList()..sort()).map((folder) {
                    final selected = folder == dirState.selectedFolder;
                    return ChoiceChip(
                      label: Text(folder),
                      selected: selected,
                      onSelected: (_) {
                        ref
                            .read(directoryProvider.notifier)
                            .selectFolder(folder);
                        ref
                            .read(directoryProvider.notifier)
                            .loadPreviewWalls(folder);
                      },
                    );
                  }).toList(),
                ),
              ),
            ),

            // ── Status ──────────────────────────────────────────────────────
            if (dirState.status.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: colors.primary.withAlpha(15),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  border: Border.all(color: colors.primary.withAlpha(40)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline_rounded,
                        size: 16, color: colors.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        dirState.status,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: colors.primary,
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 28),

            // ── Week number ─────────────────────────────────────────────────
            Row(
              children: [
                Icon(Icons.calendar_today_rounded,
                    color: colors.primary, size: 20),
                const SizedBox(width: 8),
                Text('Week Number',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _weekCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onSubmitted: (_) => _submit(),
                    textInputAction: TextInputAction.go,
                    decoration: const InputDecoration(
                      hintText: 'Enter week number…',
                      prefixIcon: Icon(Icons.tag_rounded, size: 18),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  height: 44,
                  child: FilledButton.icon(
                    icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                    label: const Text('Continue'),
                    onPressed: _submit,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
