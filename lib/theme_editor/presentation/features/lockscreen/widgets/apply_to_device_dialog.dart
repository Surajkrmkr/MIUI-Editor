import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../core/services/adb/adb_locator.dart';
import '../../../../core/services/adb/adb_service.dart';
import '../../../providers/adb_provider.dart';

/// Pushes the exported .mtz to a phone over adb and opens the Themes app.
class ApplyToDeviceDialog extends ConsumerStatefulWidget {
  const ApplyToDeviceDialog({super.key});

  @override
  ConsumerState<ApplyToDeviceDialog> createState() =>
      _ApplyToDeviceDialogState();
}

class _ApplyToDeviceDialogState extends ConsumerState<ApplyToDeviceDialog> {
  final _adbPathCtrl = TextEditingController();
  final _ipCtrl = TextEditingController();
  final _portCtrl = TextEditingController(text: '${AdbService.defaultTcpPort}');
  final _pairPortCtrl = TextEditingController();
  final _pairCodeCtrl = TextEditingController();
  String? _testMessage;

  ApplyToDeviceNotifier get _notifier =>
      ref.read(applyToDeviceProvider.notifier);

  @override
  void initState() {
    super.initState();
    _adbPathCtrl.text = _notifier.userAdbPath;
    final (ip, port) = AdbService.parseTarget(_notifier.lastWirelessTarget);
    if (ip != null) {
      _ipCtrl.text = ip;
      _portCtrl.text = '$port';
    }
    Future.microtask(_notifier.init);
  }

  @override
  void dispose() {
    _adbPathCtrl.dispose();
    _ipCtrl.dispose();
    _portCtrl.dispose();
    _pairPortCtrl.dispose();
    _pairCodeCtrl.dispose();
    super.dispose();
  }

  int _port(TextEditingController c, int fallback) =>
      int.tryParse(c.text.trim()) ?? fallback;

  Future<void> _browse() async {
    final result = await FilePicker.platform.pickFiles(
      dialogTitle: 'Select ${AdbLocator.exeName}',
      type: FileType.any,
    );
    final path = result?.files.single.path;
    if (path == null) return;
    _adbPathCtrl.text = path;
    await _notifier.saveUserAdbPath(path);
  }

  Future<void> _test() async {
    await _notifier.saveUserAdbPath(_adbPathCtrl.text);
    final msg = await _notifier.testAdbPath(_adbPathCtrl.text);
    if (!mounted) return;
    setState(() => _testMessage = msg);
    if (msg.startsWith('OK')) await _notifier.refreshDevices();
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(applyToDeviceProvider);
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final locked = s.isRunning || s.isBusy || s.isDownloading;

    return AlertDialog(
      title: const Text('Apply to Device'),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                s.mtzPath == null
                    ? 'No exported .mtz found for the current theme.'
                    : 'File: ${s.mtzPath}',
                style: text.bodySmall?.copyWith(
                  color: s.mtzPath == null ? scheme.error : null,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              for (final step in applySteps)
                _StepRow(label: step.label, status: s.statusOf(step)),
              if (s.error != null) ...[
                const SizedBox(height: AppSpacing.sm),
                _MessageBox(
                  title: s.errorStep == null
                      ? s.error!
                      : '${s.errorStep!.label}: ${s.error}',
                  details: s.errorDetails,
                  isError: true,
                ),
              ],
              if (s.info != null) ...[
                const SizedBox(height: AppSpacing.sm),
                _MessageBox(title: s.info!, isError: false),
              ],
              const Divider(height: AppSpacing.xxl),
              _deviceSection(s, locked, text),
              const Divider(height: AppSpacing.xxl),
              _wirelessSection(s, locked, text),
              const Divider(height: AppSpacing.xxl),
              _adbSection(s, locked, text, scheme),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: s.isRunning ? null : () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
        FilledButton.icon(
          onPressed: locked || s.mtzPath == null ? null : _notifier.apply,
          icon: s.isRunning
              ? const SizedBox.square(
                  dimension: AppSpacing.lg,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.phone_android_rounded),
          label: const Text('Apply to Device'),
        ),
      ],
    );
  }

  Widget _deviceSection(ApplyToDeviceState s, bool locked, TextTheme text) {
    final selected = s.selectedDevice;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(child: Text('Device', style: text.titleSmall)),
            if (s.isBusy)
              const SizedBox.square(
                dimension: AppSpacing.lg,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            IconButton(
              tooltip: 'Refresh devices',
              onPressed: locked ? null : _notifier.refreshDevices,
              icon: const Icon(Icons.refresh_rounded),
            ),
            IconButton(
              tooltip: 'Restart ADB server (adb kill-server)',
              onPressed: locked || s.adbMissing
                  ? null
                  : _notifier.restartServer,
              icon: const Icon(Icons.restart_alt_rounded),
            ),
          ],
        ),
        if (s.devices.isEmpty)
          Text('No devices listed.', style: text.bodySmall)
        else
          DropdownButton<String>(
            isExpanded: true,
            value: selected?.serial,
            hint: const Text('Select a device'),
            items: [
              for (final d in s.devices)
                DropdownMenuItem(
                  value: d.serial,
                  enabled: d.isReady,
                  child: Text(d.displayName, overflow: TextOverflow.ellipsis),
                ),
            ],
            onChanged: locked ? null : _notifier.selectDevice,
          ),
        if (selected != null && selected.isReady && !selected.isWireless)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: locked ? null : _notifier.switchToWireless,
              icon: const Icon(Icons.wifi_rounded),
              label: const Text('Switch to wireless'),
            ),
          ),
      ],
    );
  }

  Widget _wirelessSection(ApplyToDeviceState s, bool locked, TextTheme text) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Wireless', style: text.titleSmall),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              flex: 3,
              child: TextField(
                controller: _ipCtrl,
                decoration: const InputDecoration(
                  labelText: 'Phone IP',
                  hintText: '192.168.1.20',
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: TextField(
                controller: _portCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Port',
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            OutlinedButton(
              onPressed: locked || s.adbMissing
                  ? null
                  : () => _notifier.connectWireless(
                      _ipCtrl.text,
                      _port(_portCtrl, AdbService.defaultTcpPort),
                    ),
              child: const Text('Connect'),
            ),
          ],
        ),
        ExpansionTile(
          tilePadding: EdgeInsets.zero,
          title: Text(
            'Pair (Android 11+ wireless debugging)',
            style: text.bodyMedium,
          ),
          childrenPadding: const EdgeInsets.only(bottom: AppSpacing.sm),
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _pairPortCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Pairing port',
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: TextField(
                    controller: _pairCodeCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Pairing code',
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                OutlinedButton(
                  onPressed: locked || s.adbMissing
                      ? null
                      : () => _notifier.pair(
                          _ipCtrl.text,
                          _port(_pairPortCtrl, 0),
                          _pairCodeCtrl.text,
                        ),
                  child: const Text('Pair'),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _adbSection(
    ApplyToDeviceState s,
    bool locked,
    TextTheme text,
    ColorScheme scheme,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('ADB settings', style: text.titleSmall),
        const SizedBox(height: AppSpacing.xs),
        Text(
          s.adbPath == null ? 'ADB: not found' : 'Using: ${s.adbPath}',
          style: text.bodySmall,
        ),
        const SizedBox(height: AppSpacing.sm),
        TextField(
          controller: _adbPathCtrl,
          decoration: InputDecoration(
            labelText: 'ADB path (file or platform-tools folder)',
            hintText: AdbLocator.exeName,
            isDense: true,
          ),
          onSubmitted: (v) async {
            await _notifier.saveUserAdbPath(v);
            await _notifier.refreshDevices();
          },
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            OutlinedButton.icon(
              onPressed: locked ? null : _browse,
              icon: const Icon(Icons.folder_open_rounded),
              label: const Text('Browse'),
            ),
            OutlinedButton.icon(
              onPressed: locked ? null : _test,
              icon: const Icon(Icons.check_circle_outline_rounded),
              label: const Text('Test'),
            ),
            if (s.adbMissing || s.isDownloading)
              FilledButton.tonalIcon(
                onPressed: locked ? null : _notifier.downloadAdb,
                icon: const Icon(Icons.download_rounded),
                label: const Text('Download ADB'),
              ),
          ],
        ),
        if (s.isDownloading) ...[
          const SizedBox(height: AppSpacing.sm),
          LinearProgressIndicator(value: s.downloadProgress),
          const SizedBox(height: AppSpacing.xs),
          Text(
            s.downloadProgress == null
                ? 'Downloading platform-tools…'
                : 'Downloading platform-tools… '
                      '${(s.downloadProgress! * 100).toStringAsFixed(0)}%',
            style: text.bodySmall,
          ),
        ],
        if (_testMessage != null) ...[
          const SizedBox(height: AppSpacing.sm),
          SelectableText(
            _testMessage!,
            style: text.bodySmall?.copyWith(
              color: _testMessage!.startsWith('OK') ? null : scheme.error,
            ),
          ),
        ],
      ],
    );
  }
}

class _StepRow extends StatelessWidget {
  const _StepRow({required this.label, required this.status});

  final String label;
  final StepStatus status;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final Widget icon = switch (status) {
      StepStatus.pending => Icon(
        Icons.circle_outlined,
        size: AppSpacing.lg,
        color: scheme.outline,
      ),
      StepStatus.running => const SizedBox.square(
        dimension: AppSpacing.lg,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
      StepStatus.done => Icon(
        Icons.check_circle_rounded,
        size: AppSpacing.lg,
        color: scheme.primary,
      ),
      StepStatus.failed => Icon(
        Icons.error_rounded,
        size: AppSpacing.lg,
        color: scheme.error,
      ),
    };
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          icon,
          const SizedBox(width: AppSpacing.sm),
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class _MessageBox extends StatelessWidget {
  const _MessageBox({
    required this.title,
    required this.isError,
    this.details = '',
  });

  final String title;
  final bool isError;
  final String details;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final fg = isError ? scheme.onErrorContainer : scheme.onSecondaryContainer;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isError ? scheme.errorContainer : scheme.secondaryContainer,
        borderRadius: AppRadius.radiusSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SelectableText(title, style: text.bodyMedium?.copyWith(color: fg)),
          if (details.isNotEmpty)
            Theme(
              data: Theme.of(
                context,
              ).copyWith(dividerColor: scheme.surface.withValues(alpha: 0)),
              child: ExpansionTile(
                tilePadding: EdgeInsets.zero,
                title: Text(
                  'Details',
                  style: text.bodySmall?.copyWith(color: fg),
                ),
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: SelectableText(
                      details,
                      style: text.bodySmall?.copyWith(
                        color: fg,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
