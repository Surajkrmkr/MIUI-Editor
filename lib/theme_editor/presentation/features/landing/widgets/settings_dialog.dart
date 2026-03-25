import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/directory_provider.dart';
import '../../../providers/service_providers.dart';
import '../../../providers/wallpaper_provider.dart';
import '../../../../../../core/theme/app_theme.dart';
import '../../../../core/constants/path_constants.dart';
import '../../../../data/models/theme_settings_model.dart';

class SettingsDialog extends ConsumerStatefulWidget {
  const SettingsDialog({super.key});
  @override
  ConsumerState<SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends ConsumerState<SettingsDialog> {
  late TextEditingController _countCtrl;
  late TextEditingController _basePathCtrl;
  late TextEditingController _designerCtrl;
  late TextEditingController _authorTagCtrl;
  late TextEditingController _uiVersionCtrl;

  @override
  void initState() {
    super.initState();
    final s = ref.read(wallpaperProvider);
    // Read saved basePath directly from prefs (PathConstants.customBasePath
    // may have been set, but we also need the raw saved value for the field).
    final prefs = ref.read(sharedPrefsProvider);
    final settings = ThemeSettings.decode(prefs.getString('themeSettings') ?? '{}');

    _countCtrl     = TextEditingController(text: s.themeCount.toString());
    _basePathCtrl  = TextEditingController(text: settings.basePath ?? PathConstants.customBasePath);
    _designerCtrl  = TextEditingController(text: s.designerName);
    _authorTagCtrl = TextEditingController(text: s.authorTag);
    _uiVersionCtrl = TextEditingController(text: s.uiVersion);
  }

  @override
  void dispose() {
    _countCtrl.dispose();
    _basePathCtrl.dispose();
    _designerCtrl.dispose();
    _authorTagCtrl.dispose();
    _uiVersionCtrl.dispose();
    super.dispose();
  }

  void _save() {
    final count = int.tryParse(_countCtrl.text);
    ref.read(wallpaperProvider.notifier).updateSettings(
          themeCount: count != null && count > 0 ? count : null,
          basePath: _basePathCtrl.text.trim(),
          designerName: _designerCtrl.text.trim(),
          authorTag: _authorTagCtrl.text.trim(),
          uiVersion: _uiVersionCtrl.text.trim(),
        );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Dialog(
      child: SizedBox(
        width: 500,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ───────────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(24, 20, 16, 20),
              decoration: BoxDecoration(
                color: AppTheme.accent.withAlpha(20),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
                border: Border(
                    bottom: BorderSide(color: cs.outline.withAlpha(40))),
              ),
              child: Row(
                children: [
                  const Icon(Icons.tune_rounded, color: AppTheme.accent),
                  const SizedBox(width: 12),
                  Text('Settings',
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontWeight: FontWeight.w600)),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            ),

            // ── Body ─────────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionLabel(context, 'Workspace'),
                  const SizedBox(height: 12),
                  _field(
                    controller: _basePathCtrl,
                    label: 'Base Path',
                    hint: '/path/to/Xiaomi Contract/',
                    icon: Icons.folder_outlined,
                    onChanged: (_) => _save(),
                  ),
                  const SizedBox(height: 24),
                  _sectionLabel(context, 'Theme Metadata'),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _field(
                          controller: _designerCtrl,
                          label: 'Designer Name',
                          hint: 'e.g. John Doe',
                          icon: Icons.person_outline_rounded,
                          onChanged: (_) => _save(),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _field(
                          controller: _authorTagCtrl,
                          label: 'Author Tag',
                          hint: 'e.g. @johndoe',
                          icon: Icons.alternate_email_rounded,
                          onChanged: (_) => _save(),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _field(
                    controller: _uiVersionCtrl,
                    label: 'UI Version',
                    hint: 'e.g. 13.0 / HyperOS',
                    icon: Icons.phone_android_rounded,
                    onChanged: (_) => _save(),
                  ),
                  const SizedBox(height: 24),
                  _sectionLabel(context, 'Workflow'),
                  const SizedBox(height: 12),
                  _ThemeCountRow(ctrl: _countCtrl, onChanged: _save),
                  const SizedBox(height: 24),
                ],
              ),
            ),

            // ── Footer ───────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  FilledButton.icon(
                    icon: const Icon(Icons.check_rounded, size: 18),
                    label: const Text('Apply & Reload'),
                    onPressed: () {
                      _save();
                      ref.read(directoryProvider.notifier)
                        ..loadPreLockFolders()
                        ..loadPreviewWalls('1');
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(BuildContext context, String text) => Text(
        text,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: AppTheme.accent,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.8,
            ),
      );

  Widget _field({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required void Function(String) onChanged,
  }) =>
      TextField(
        controller: controller,
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(icon, size: 18),
        ),
      );
}

// ── Theme count stepper ───────────────────────────────────────────────────────

class _ThemeCountRow extends StatefulWidget {
  const _ThemeCountRow({required this.ctrl, required this.onChanged});
  final TextEditingController ctrl;
  final VoidCallback onChanged;

  @override
  State<_ThemeCountRow> createState() => _ThemeCountRowState();
}

class _ThemeCountRowState extends State<_ThemeCountRow> {
  void _adjust(int delta) {
    final v = int.tryParse(widget.ctrl.text) ?? 25;
    final next = v + delta;
    if (next < 1) return;
    widget.ctrl.text = next.toString();
    widget.onChanged();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: widget.ctrl,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: (_) => widget.onChanged(),
            decoration: const InputDecoration(
              labelText: 'Themes per Week',
              prefixIcon: Icon(Icons.grid_view_rounded, size: 18),
            ),
          ),
        ),
        const SizedBox(width: 8),
        _StepButton(
            icon: Icons.remove_rounded,
            color: cs.error,
            onTap: () => _adjust(-1)),
        const SizedBox(width: 6),
        _StepButton(
            icon: Icons.add_rounded,
            color: AppTheme.accent,
            onTap: () => _adjust(1)),
      ],
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton(
      {required this.icon, required this.color, required this.onTap});
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Icon(icon, size: 18, color: color),
          ),
        ),
      );
}
