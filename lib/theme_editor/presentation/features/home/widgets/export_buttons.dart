import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/export_provider.dart';
import '../../../providers/lockscreen_provider.dart';
import '../../../providers/tag_provider.dart';
import '../../lockscreen/lockscreen_screen.dart';

class ExportButtons extends ConsumerWidget {
  const ExportButtons({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exportState = ref.watch(exportProvider);
    final lsState     = ref.watch(lockscreenProvider);
    final tags        = ref.watch(tagProvider).appliedTags;

    return Column(
      children: [
        // Tag warning
        if (tags.length < 6)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              'Please select 6 tags',
              style: TextStyle(
                  color: Theme.of(context).colorScheme.error, fontSize: 12),
            ),
          ),

        // ── Combined icon + module export ─────────────────────────────────
        _ExportButton(
          label:    'Icon + Module Export',
          icon:     exportState.isExported ? Icons.check : Icons.android,
          loading:  exportState.isRunning,
          progress: exportState.progress,
          statusLabel: exportState.statusLabel,
          onPressed: () => ref.read(exportProvider.notifier).exportAll(context),
        ),

        const SizedBox(height: 12),

        // ── Lockscreen ────────────────────────────────────────────────────
        _ExportButton(
          label:   'Lockscreen',
          icon:    Icons.lock,
          loading: lsState.isCopyingDefaults,
          onPressed: () => _goLockscreen(context, ref),
        ),
      ],
    );
  }

  Future<void> _goLockscreen(BuildContext context, WidgetRef ref) async {
    await ref.read(lockscreenProvider.notifier).copyDefaultPngs();
    if (context.mounted) {
      Navigator.push(context,
          MaterialPageRoute(builder: (_) => const LockscreenScreen()));
    }
  }
}

// ── Reusable animated button ──────────────────────────────────────────────────

class _ExportButton extends StatelessWidget {
  const _ExportButton({
    required this.label,
    required this.icon,
    required this.loading,
    required this.onPressed,
    this.progress,
    this.statusLabel,
  });

  final String label;
  final IconData icon;
  final bool loading;
  final VoidCallback onPressed;
  final double? progress;
  final String? statusLabel;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      child: Column(
        children: [
          ElevatedButton.icon(
            icon: loading
                ? const SizedBox(
                    width: 18, height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : Icon(icon),
            label: Text(label),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 18),
              minimumSize: const Size.fromHeight(52),
            ),
            onPressed: loading ? null : onPressed,
          ),
          // Progress bar (visible during icon export phase)
          if (loading && progress != null) ...[
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 4,
              ),
            ),
          ],
          // Status label
          if (statusLabel != null && statusLabel!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                statusLabel!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                    ),
              ),
            ),
        ],
      ),
    );
  }
}
