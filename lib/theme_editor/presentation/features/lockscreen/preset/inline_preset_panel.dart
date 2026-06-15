import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/theme_extensions.dart';
import '../../../providers/directory_provider.dart';
import '../../../providers/lockscreen_provider.dart';
import 'preset_card.dart';

/// Inline preset browser — lives inside the Presets tab of the side panel.
/// Shows the preset grid directly without opening a dialog.
class InlinePresetPanel extends ConsumerStatefulWidget {
  const InlinePresetPanel({super.key});

  @override
  ConsumerState<InlinePresetPanel> createState() => _InlinePresetPanelState();
}

class _InlinePresetPanelState extends ConsumerState<InlinePresetPanel> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => ref.read(directoryProvider.notifier).loadPresetPaths(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dirState = ref.watch(directoryProvider);
    final appColors = context.appColors;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Toolbar ────────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 3,
                height: 16,
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: appColors.primary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Text(
                'Presets',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: cs.onSurface,
                ),
              ),
              const Spacer(),
              _SaveButton(),
              const SizedBox(width: 4),
              IconButton(
                icon: Icon(Icons.refresh_rounded,
                    size: 14, color: cs.onSurfaceVariant),
                tooltip: 'Refresh',
                style: IconButton.styleFrom(
                  minimumSize: const Size(28, 28),
                ),
                onPressed: () =>
                    ref.read(directoryProvider.notifier).loadPresetPaths(),
              ),
            ],
          ),
        ),

        // ── Grid ────────────────────────────────────────────────────────────
        Expanded(
          child: dirState.isLoadingPresets
              ? const Center(child: CircularProgressIndicator())
              : dirState.presetPaths.isEmpty
                  ? _EmptyState()
                  : GridView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                      gridDelegate:
                          const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 165,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        mainAxisExtent: 330,
                      ),
                      itemCount: dirState.presetPaths.length,
                      itemBuilder: (_, i) => PresetCard(
                        path: dirState.presetPaths[i],
                        index: i,
                        // Inline — don't pop any route on apply.
                        onApplied: () => ScaffoldMessenger.of(context)
                            .showSnackBar(const SnackBar(
                          content: Text('Preset applied'),
                          duration: Duration(seconds: 1),
                        )),
                      ),
                    ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _SaveButton extends ConsumerStatefulWidget {
  @override
  ConsumerState<_SaveButton> createState() => _SaveButtonState();
}

class _SaveButtonState extends ConsumerState<_SaveButton> {
  bool _saving = false;

  Future<void> _save() async {
    final name = await showDialog<String>(
      context: context,
      builder: (_) => _SaveDialog(),
    );
    if (name == null || name.isEmpty || !mounted) return;

    setState(() => _saving = true);
    final failure =
        await ref.read(lockscreenProvider.notifier).savePreset(name);
    if (!mounted) return;
    setState(() => _saving = false);

    if (failure != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Save failed: ${failure.message}')),
      );
    } else {
      ref.read(directoryProvider.notifier).loadPresetPaths();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preset saved')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return FilledButton.icon(
      onPressed: _saving ? null : _save,
      style: FilledButton.styleFrom(
        minimumSize: const Size(0, 28),
        padding: const EdgeInsets.symmetric(horizontal: 10),
        textStyle: const TextStyle(fontSize: 11),
      ),
      icon: _saving
          ? SizedBox(
              width: 11,
              height: 11,
              child: CircularProgressIndicator(
                strokeWidth: 1.5,
                color: cs.onPrimary,
              ),
            )
          : const Icon(Icons.bookmark_add_rounded, size: 13),
      label: const Text('Save'),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _SaveDialog extends StatefulWidget {
  @override
  State<_SaveDialog> createState() => _SaveDialogState();
}

class _SaveDialogState extends State<_SaveDialog> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(
      text: 'Preset ${DateTime.now().millisecondsSinceEpoch ~/ 1000}',
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Save Preset'),
      content: TextField(
        controller: _ctrl,
        autofocus: true,
        decoration: const InputDecoration(labelText: 'Preset name'),
        onSubmitted: (_) => Navigator.pop(context, _ctrl.text.trim()),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _ctrl.text.trim()),
          child: const Text('Save'),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.inbox_rounded, size: 40, color: cs.onSurfaceVariant),
          const SizedBox(height: 10),
          Text(
            'No presets yet',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            'Save your current design using the\nSave button above.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: cs.onSurfaceVariant.withAlpha(160),
                ),
          ),
        ],
      ),
    );
  }
}
