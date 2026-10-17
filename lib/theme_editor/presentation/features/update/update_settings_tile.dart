import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/update_provider.dart';
import 'update_dialog.dart';

class UpdateSettingsTile extends ConsumerWidget {
  const UpdateSettingsTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (UpdateNotifier.platform == null) return const SizedBox.shrink();
    final state = ref.watch(updateProvider);
    final version = ref.watch(appVersionProvider).valueOrNull ?? '';
    final notifier = ref.read(updateProvider.notifier);
    final checking = state.phase == UpdatePhase.checking;

    final status = switch (state.phase) {
      UpdatePhase.checking => 'Checking…',
      UpdatePhase.upToDate => 'You are up to date.',
      UpdatePhase.available => 'Version ${state.info?.version} is available.',
      UpdatePhase.error => state.message ?? 'Update check failed.',
      _ => 'Version $version',
    };

    return Row(
      children: [
        Expanded(
          child: Text(status, style: Theme.of(context).textTheme.bodyMedium),
        ),
        const SizedBox(width: 12),
        if (state.phase == UpdatePhase.available)
          FilledButton(
            onPressed: () => showUpdateDialog(context),
            child: const Text('Update'),
          )
        else
          OutlinedButton(
            onPressed: checking ? null : notifier.check,
            child: const Text('Check for updates'),
          ),
      ],
    );
  }
}
