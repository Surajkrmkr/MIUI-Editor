// ─────────────────────────────────────────────────────────────────────────────
// FILE: lib/presentation/features/lockscreen/widgets/mtz_export_button.dart
//
// BEFORE: had its own inline ZipFileEncoder logic, never touched the use case.
// AFTER:  delegates entirely to LockscreenNotifier.exportMtz() which calls
//         ExportMtzUseCase under the hood.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/lockscreen_provider.dart';

class MtzExportButton extends ConsumerWidget {
  const MtzExportButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch only the MTZ-relevant slice of state so the button doesn't
    // rebuild during icon/PNG export phases.
    final isExporting = ref.watch(
      lockscreenProvider.select((s) => s.isExporting),
    );
    final isExported = ref.watch(
      lockscreenProvider.select((s) => s.isExported),
    );

    return FilledButton.icon(
      icon: Icon(isExported ? Icons.check : Icons.archive, size: 14),
      label: const Text('MTZ'),
      onPressed: isExporting ? null : () => _export(context, ref),
    );
  }

  Future<void> _export(BuildContext context, WidgetRef ref) async {
    final (path, failure) =
        await ref.read(lockscreenProvider.notifier).exportMtz();

    if (!context.mounted) return;

    if (failure != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('MTZ export failed: ${failure.message}'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Exported: $path ✅')),
      );
    }
  }
}
