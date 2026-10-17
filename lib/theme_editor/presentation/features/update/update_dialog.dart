import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../domain/entities/update_info.dart';
import '../../providers/update_provider.dart';

/// Shows the update prompt once after launch when a newer release exists.
class UpdateGate extends ConsumerStatefulWidget {
  const UpdateGate({super.key, required this.child});
  final Widget child;

  @override
  ConsumerState<UpdateGate> createState() => _UpdateGateState();
}

class _UpdateGateState extends ConsumerState<UpdateGate> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final notifier = ref.read(updateProvider.notifier);
      await notifier.checkOnLaunch();
      if (!mounted) return;
      if (ref.read(updateProvider).phase == UpdatePhase.available) {
        await showUpdateDialog(context);
      }
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

Future<void> showUpdateDialog(BuildContext context) => showDialog<void>(
  context: context,
  barrierDismissible: false,
  builder: (_) => const UpdateDialog(),
);

class UpdateDialog extends ConsumerWidget {
  const UpdateDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(updateProvider);
    final notifier = ref.read(updateProvider.notifier);
    final info = state.info;
    final busy =
        state.phase == UpdatePhase.downloading ||
        state.phase == UpdatePhase.installing;

    return AlertDialog(
      title: Text(
        info == null ? 'Update' : 'Version ${info.version} available',
      ),
      content: SizedBox(
        width: 420,
        child: switch (state.phase) {
          UpdatePhase.downloading => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Downloading update…'),
              const SizedBox(height: 12),
              LinearProgressIndicator(value: state.progress),
            ],
          ),
          UpdatePhase.installing => const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Installing — the app will restart.'),
              SizedBox(height: 12),
              LinearProgressIndicator(),
            ],
          ),
          UpdatePhase.error => Text(state.message ?? 'Update failed'),
          _ => _Notes(info: info, current: state.currentVersion),
        },
      ),
      actions: [
        if (!busy && state.phase == UpdatePhase.available)
          TextButton(
            onPressed: () async {
              await notifier.skipVersion();
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Skip this version'),
          ),
        if (!busy && state.phase == UpdatePhase.error && info != null)
          TextButton(
            onPressed: () => launchUrl(Uri.parse(info.pageUrl)),
            child: const Text('Open release page'),
          ),
        if (!busy)
          TextButton(
            onPressed: () {
              notifier.dismiss();
              Navigator.pop(context);
            },
            child: Text(state.phase == UpdatePhase.error ? 'Close' : 'Later'),
          ),
        if (state.phase == UpdatePhase.available)
          FilledButton(
            onPressed: notifier.install,
            child: const Text('Update'),
          ),
      ],
    );
  }
}

class _Notes extends StatelessWidget {
  const _Notes({required this.info, required this.current});
  final UpdateInfo? info;
  final String current;

  @override
  Widget build(BuildContext context) {
    final notes = info?.notes.trim() ?? '';
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 260),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('You have $current.'),
            if (notes.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(notes, style: Theme.of(context).textTheme.bodySmall),
            ],
          ],
        ),
      ),
    );
  }
}
