import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:miui_icon_generator/core/theme/theme_extensions.dart';
import 'package:miui_icon_generator/widgets/app_icon_button.dart';

import '../../application/providers/catalog_provider.dart';
import '../../domain/models/catalog.dart';
import '../../infrastructure/services/storage_client.dart';

/// Every save backs up the previous catalog; this lists those backups and
/// makes one live again.
class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kind = ref.watch(selectedKindProvider);
    final history = ref.watch(catalogHistoryProvider(kind));
    final colors = context.appColors;
    final format = DateFormat('d MMM yyyy, HH:mm:ss');

    return Scaffold(
      appBar: AppBar(
        leading: AppBackButton(onPressed: () => context.go('/')),
        title: Text('History · ${kind.jsonFile}'),
        actions: [
          SegmentedButton<CatalogKind>(
            showSelectedIcon: false,
            segments: [
              for (final k in CatalogKind.values) ButtonSegment(value: k, label: Text(k.label)),
            ],
            selected: {kind},
            onSelectionChanged: (s) => ref.read(selectedKindProvider.notifier).select(s.first),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: history.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: SelectableText('$err', style: TextStyle(color: colors.error))),
        data: (backups) {
          if (backups.isEmpty) {
            return Center(
              child: Text('No backups yet. One is made before every save.',
                  style: TextStyle(color: colors.textSecondary)),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(24),
            itemCount: backups.length,
            separatorBuilder: (_, __) => Divider(color: colors.borderSubtle, height: 1),
            itemBuilder: (context, index) {
              final backup = backups[index];
              final when = backup.updated?.toLocal();
              return ListTile(
                leading: Icon(Icons.history_rounded, color: colors.textSecondary),
                title: Text(when == null ? backup.path.split('/').last : format.format(when),
                    style: TextStyle(color: colors.textPrimary)),
                subtitle: Text(
                  '${(backup.size / 1024).toStringAsFixed(0)} KB · version replaced at this time',
                  style: TextStyle(color: colors.textSecondary, fontSize: 12),
                ),
                trailing: OutlinedButton(
                  onPressed: () => _confirmRestore(context, ref, kind, backup, when, format),
                  child: const Text('Restore'),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _confirmRestore(
    BuildContext context,
    WidgetRef ref,
    CatalogKind kind,
    StorageObject backup,
    DateTime? when,
    DateFormat format,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restore this version?'),
        content: Text(
          '${kind.jsonFile} will be replaced with the version from '
          '${when == null ? backup.path : format.format(when)}. '
          'The current version is backed up first, so this can be undone. '
          'The app shows it within ~5 minutes.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Restore')),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(catalogProvider(kind).notifier).restore(backup);
      messenger.showSnackBar(SnackBar(content: Text('Restored ${kind.jsonFile}')));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Restore failed: $e')));
    }
  }
}
