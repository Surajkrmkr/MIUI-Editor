import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../core/services/adb/adb_locator.dart';
import '../../../../core/services/adb/adb_models.dart';
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
    final destination = ref.watch(adbThemeDestinationProvider);

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
      actionsPadding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: scheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.send_to_mobile_rounded,
              color: scheme.primary,
              size: 22,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Apply to Device',
                  style: text.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  'Push and preview theme directly on device',
                  style: text.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              // MTZ Theme File Card
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: scheme.outlineVariant.withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      s.mtzPath == null
                          ? Icons.warning_amber_rounded
                          : Icons.folder_zip_rounded,
                      size: 20,
                      color: s.mtzPath == null ? scheme.error : scheme.primary,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            s.mtzPath == null
                                ? 'No exported .mtz file found'
                                : s.mtzPath!.split(RegExp(r'[/\\]')).last,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                              color: s.mtzPath == null
                                  ? scheme.error
                                  : scheme.onSurface,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (s.mtzPath != null)
                            Text(
                              s.mtzPath!,
                              style: TextStyle(
                                fontSize: 11,
                                color: scheme.onSurfaceVariant,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              DropdownButtonFormField<AdbThemeDestination>(
                initialValue: destination,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Theme push path',
                  prefixIcon: Icon(Icons.phone_android_rounded),
                ),
                items: [
                  for (final option in AdbThemeDestination.values)
                    DropdownMenuItem(value: option, child: Text(option.label)),
                ],
                onChanged: locked
                    ? null
                    : (value) async {
                        if (value == null) return;
                        try {
                          await ref
                              .read(adbThemeDestinationProvider.notifier)
                              .select(value);
                        } catch (error) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(
                              context,
                            ).showSnackBar(SnackBar(content: Text('$error')));
                          }
                        }
                      },
              ),
              const SizedBox(height: AppSpacing.sm),
              SelectableText(destination.path, style: text.bodySmall),
              const SizedBox(height: AppSpacing.md),

              // Progress Stepper Card
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: scheme.outlineVariant.withValues(alpha: 0.35),
                  ),
                ),
                child: Column(
                  children: [
                    for (int i = 0; i < applySteps.length; i++) ...[
                      if (i > 0) const SizedBox(height: 4),
                      _StepRow(
                        label: applySteps[i].label,
                        status: s.statusOf(applySteps[i]),
                      ),
                    ],
                  ],
                ),
              ),

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

              const SizedBox(height: AppSpacing.lg),
              _deviceSection(s, locked, text, scheme),

              const SizedBox(height: AppSpacing.lg),
              _wirelessSection(s, locked, text, scheme),

              const SizedBox(height: AppSpacing.lg),
              _adbSection(s, locked, text, scheme),
              const SizedBox(height: AppSpacing.sm),
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
                  dimension: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.send_to_mobile_rounded, size: 18),
          label: const Text('Apply to Device'),
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      ],
    );
  }

  Widget _deviceSection(
    ApplyToDeviceState s,
    bool locked,
    TextTheme text,
    ColorScheme scheme,
  ) {
    final selected = s.selectedDevice;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(Icons.devices_rounded, size: 18, color: scheme.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Device',
                style: text.titleSmall?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
            if (s.isBusy)
              const Padding(
                padding: EdgeInsets.only(right: 8),
                child: SizedBox.square(
                  dimension: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            IconButton(
              tooltip: 'Refresh devices',
              visualDensity: VisualDensity.compact,
              iconSize: 20,
              onPressed: locked ? null : _notifier.refreshDevices,
              icon: const Icon(Icons.refresh_rounded),
            ),
            IconButton(
              tooltip: 'Restart ADB Server',
              visualDensity: VisualDensity.compact,
              iconSize: 20,
              onPressed: locked || s.adbMissing
                  ? null
                  : _notifier.restartServer,
              icon: const Icon(Icons.power_settings_new_rounded),
            ),
          ],
        ),
        const SizedBox(height: 6),
        if (s.devices.isEmpty)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: scheme.outlineVariant.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.phonelink_erase_rounded,
                  size: 20,
                  color: scheme.outline,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'No devices detected. Connect phone via USB or Wi-Fi.',
                    style: text.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          )
        else
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: scheme.outlineVariant.withValues(alpha: 0.4),
              ),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true,
                value: selected?.serial,
                hint: Row(
                  children: [
                    Icon(
                      Icons.phone_android_outlined,
                      size: 18,
                      color: scheme.outline,
                    ),
                    const SizedBox(width: 8),
                    const Text('Select a device'),
                  ],
                ),
                icon: Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: scheme.onSurfaceVariant,
                ),
                items: [
                  for (final d in s.devices)
                    DropdownMenuItem(
                      value: d.serial,
                      enabled: d.isReady,
                      child: Row(
                        children: [
                          Icon(
                            d.isWireless
                                ? Icons.wifi_rounded
                                : Icons.usb_rounded,
                            size: 18,
                            color: d.isReady ? scheme.primary : scheme.outline,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              d.displayName,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: d.serial == selected?.serial
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                          if (!d.isReady)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: scheme.error.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                d.rawState,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: scheme.error,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                ],
                onChanged: locked ? null : _notifier.selectDevice,
              ),
            ),
          ),
        if (selected != null && selected.isReady && !selected.isWireless)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: FilledButton.tonalIcon(
                onPressed: locked ? null : _notifier.switchToWireless,
                style: FilledButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                icon: const Icon(Icons.wifi_rounded, size: 16),
                label: const Text('Switch to wireless mode'),
              ),
            ),
          ),
      ],
    );
  }

  Widget _wirelessSection(
    ApplyToDeviceState s,
    bool locked,
    TextTheme text,
    ColorScheme scheme,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(Icons.wifi_rounded, size: 18, color: scheme.primary),
            const SizedBox(width: 8),
            Text(
              'Wireless Connection',
              style: text.titleSmall?.copyWith(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              flex: 3,
              child: TextField(
                controller: _ipCtrl,
                style: const TextStyle(fontSize: 13),
                decoration: InputDecoration(
                  labelText: 'Phone IP',
                  hintText: '192.168.1.20',
                  prefixIcon: const Icon(Icons.router_outlined, size: 18),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 10,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              flex: 2,
              child: TextField(
                controller: _portCtrl,
                keyboardType: TextInputType.number,
                style: const TextStyle(fontSize: 13),
                decoration: InputDecoration(
                  labelText: 'Port',
                  prefixIcon: const Icon(Icons.numbers_rounded, size: 18),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 10,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            FilledButton.tonalIcon(
              onPressed: locked || s.adbMissing
                  ? null
                  : () => _notifier.connectWireless(
                      _ipCtrl.text,
                      _port(_portCtrl, AdbService.defaultTcpPort),
                    ),
              icon: const Icon(Icons.link_rounded, size: 16),
              label: const Text('Connect'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
        Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            tilePadding: EdgeInsets.zero,
            shape: const Border(),
            collapsedShape: const Border(),
            title: Row(
              children: [
                Icon(
                  Icons.qr_code_scanner_rounded,
                  size: 16,
                  color: scheme.onSurfaceVariant,
                ),
                const SizedBox(width: 6),
                Text(
                  'Pair (Android 11+ wireless debugging)',
                  style: text.bodySmall?.copyWith(fontWeight: FontWeight.w500),
                ),
              ],
            ),
            childrenPadding: const EdgeInsets.only(
              top: 4,
              bottom: AppSpacing.xs,
            ),
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _pairPortCtrl,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(fontSize: 13),
                      decoration: InputDecoration(
                        labelText: 'Pairing port',
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: TextField(
                      controller: _pairCodeCtrl,
                      style: const TextStyle(fontSize: 13),
                      decoration: InputDecoration(
                        labelText: 'Pairing code (6 digits)',
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  FilledButton.tonal(
                    onPressed: locked || s.adbMissing
                        ? null
                        : () => _notifier.pair(
                            _ipCtrl.text,
                            _port(_pairPortCtrl, 0),
                            _pairCodeCtrl.text,
                          ),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Pair'),
                  ),
                ],
              ),
            ],
          ),
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
    final adbActive = !s.adbMissing && s.adbPath != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(Icons.terminal_rounded, size: 18, color: scheme.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'ADB Settings',
                style: text.titleSmall?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: (adbActive ? Colors.green : scheme.error).withValues(
                  alpha: 0.1,
                ),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: (adbActive ? Colors.green : scheme.error).withValues(
                    alpha: 0.3,
                  ),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    adbActive
                        ? Icons.check_circle_rounded
                        : Icons.cancel_outlined,
                    size: 13,
                    color: adbActive ? Colors.green : scheme.error,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    adbActive ? 'ADB Active' : 'ADB Missing',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: adbActive ? Colors.green : scheme.error,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        if (s.adbPath != null) ...[
          const SizedBox(height: 4),
          Text(
            'Using: ${s.adbPath}',
            style: text.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
              fontSize: 11,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
        const SizedBox(height: 8),
        TextField(
          controller: _adbPathCtrl,
          style: const TextStyle(fontSize: 12),
          decoration: InputDecoration(
            labelText: 'ADB path (file or platform-tools folder)',
            hintText: AdbLocator.exeName,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            suffixIcon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: 'Browse ADB file',
                  iconSize: 18,
                  icon: const Icon(Icons.folder_open_rounded),
                  onPressed: locked ? null : _browse,
                ),
                IconButton(
                  tooltip: 'Test ADB connection',
                  iconSize: 18,
                  icon: const Icon(Icons.play_arrow_rounded),
                  onPressed: locked ? null : _test,
                ),
              ],
            ),
          ),
          onSubmitted: (v) async {
            await _notifier.saveUserAdbPath(v);
            await _notifier.refreshDevices();
          },
        ),
        if (s.adbMissing || s.isDownloading) ...[
          const SizedBox(height: AppSpacing.sm),
          FilledButton.tonalIcon(
            onPressed: locked ? null : _notifier.downloadAdb,
            icon: const Icon(Icons.download_rounded, size: 16),
            label: const Text('Download Android Platform Tools'),
            style: FilledButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
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
    final isDone = status == StepStatus.done;
    final isRunning = status == StepStatus.running;
    final isFailed = status == StepStatus.failed;

    final Widget icon = switch (status) {
      StepStatus.pending => Icon(
        Icons.radio_button_unchecked_rounded,
        size: 18,
        color: scheme.outlineVariant,
      ),
      StepStatus.running => SizedBox(
        width: 16,
        height: 16,
        child: CircularProgressIndicator(strokeWidth: 2, color: scheme.primary),
      ),
      StepStatus.done => const Icon(
        Icons.check_circle_rounded,
        size: 18,
        color: Colors.green,
      ),
      StepStatus.failed => Icon(
        Icons.cancel_rounded,
        size: 18,
        color: scheme.error,
      ),
    };

    final statusText = switch (status) {
      StepStatus.pending => 'Pending',
      StepStatus.running => 'In progress…',
      StepStatus.done => 'Completed',
      StepStatus.failed => 'Failed',
    };

    final statusColor = switch (status) {
      StepStatus.pending => scheme.onSurfaceVariant.withValues(alpha: 0.6),
      StepStatus.running => scheme.primary,
      StepStatus.done => Colors.green,
      StepStatus.failed => scheme.error,
    };

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          icon,
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isRunning || isDone
                    ? FontWeight.w600
                    : FontWeight.normal,
                color: isRunning || isDone
                    ? scheme.onSurface
                    : scheme.onSurfaceVariant,
              ),
            ),
          ),
          Text(
            statusText,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isRunning || isDone
                  ? FontWeight.w600
                  : FontWeight.normal,
              color: statusColor,
            ),
          ),
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
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: (isError ? scheme.error : scheme.primary).withValues(
            alpha: 0.2,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isError
                    ? Icons.error_outline_rounded
                    : Icons.info_outline_rounded,
                size: 18,
                color: fg,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SelectableText(
                  title,
                  style: text.bodyMedium?.copyWith(
                    color: fg,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          if (details.isNotEmpty)
            Theme(
              data: Theme.of(
                context,
              ).copyWith(dividerColor: scheme.surface.withValues(alpha: 0)),
              child: ExpansionTile(
                tilePadding: EdgeInsets.zero,
                shape: const Border(),
                collapsedShape: const Border(),
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
