import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:miui_icon_generator/core/theme/app_radius.dart';
import '../../../providers/directory_provider.dart';
import '../../../providers/service_providers.dart';
import '../../../providers/wallpaper_provider.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/path_constants.dart';
import '../../../../data/datasources/remote/ai_remote_datasource.dart';
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
  late TextEditingController _geminiKeyCtrl;
  late TextEditingController _groqKeyCtrl;
  late TextEditingController _ollamaHostCtrl;
  late TextEditingController _ollamaModelCtrl;
  List<String>? _geminiModels;
  bool _loadingModels = false;

  @override
  void initState() {
    super.initState();
    final s = ref.read(wallpaperProvider);
    final prefs = ref.read(sharedPrefsProvider);
    final settings =
        ThemeSettings.decode(prefs.getString('themeSettings') ?? '{}');

    _countCtrl     = TextEditingController(text: s.themeCount.toString());
    _basePathCtrl  = TextEditingController(
        text: settings.basePath ?? PathConstants.customBasePath);
    _designerCtrl  = TextEditingController(text: s.designerName);
    _authorTagCtrl = TextEditingController(text: s.authorTag);
    _uiVersionCtrl = TextEditingController(text: s.uiVersion);
    _geminiKeyCtrl = TextEditingController(
        text: prefs.getString(AppConstants.prefsGeminiKey) ?? '');
    _groqKeyCtrl = TextEditingController(
        text: prefs.getString(AppConstants.prefsGroqKey) ?? '');
    _ollamaHostCtrl = TextEditingController(
        text: prefs.getString(AppConstants.prefsOllamaHost) ??
            AppConstants.ollamaDefaultHost);
    _ollamaModelCtrl = TextEditingController(
        text: prefs.getString(AppConstants.prefsOllamaModel) ??
            AppConstants.ollamaDefaultModel);
  }

  @override
  void dispose() {
    _countCtrl.dispose();
    _basePathCtrl.dispose();
    _designerCtrl.dispose();
    _authorTagCtrl.dispose();
    _uiVersionCtrl.dispose();
    _geminiKeyCtrl.dispose();
    _groqKeyCtrl.dispose();
    _ollamaHostCtrl.dispose();
    _ollamaModelCtrl.dispose();
    super.dispose();
  }

  void _saveProvider(AiProvider p) {
    ref.read(sharedPrefsProvider).setString(AppConstants.prefsAiProvider, p.name);
    ref.read(aiProviderProvider.notifier).state = p;
  }

  void _saveGeminiKey() {
    final key = _geminiKeyCtrl.text.trim();
    ref.read(sharedPrefsProvider).setString(AppConstants.prefsGeminiKey, key);
    ref.read(geminiApiKeyProvider.notifier).state = key;
  }

  void _saveGroqKey() {
    final key = _groqKeyCtrl.text.trim();
    ref.read(sharedPrefsProvider).setString(AppConstants.prefsGroqKey, key);
    ref.read(groqApiKeyProvider.notifier).state = key;
  }

  void _saveOllamaHost() {
    final v = _ollamaHostCtrl.text.trim();
    ref.read(sharedPrefsProvider).setString(AppConstants.prefsOllamaHost, v);
    ref.read(ollamaHostProvider.notifier).state = v;
  }

  void _saveOllamaModel() {
    final v = _ollamaModelCtrl.text.trim();
    ref.read(sharedPrefsProvider).setString(AppConstants.prefsOllamaModel, v);
    ref.read(ollamaModelProvider.notifier).state = v;
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
    final currentProvider = ref.watch(aiProviderProvider);

    return Dialog(
      child: SizedBox(
        width: 520,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ───────────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(24, 20, 16, 20),
              decoration: BoxDecoration(
                color: cs.primary.withAlpha(20),
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(AppRadius.xl)),
                border:
                    Border(bottom: BorderSide(color: cs.outline.withAlpha(40))),
              ),
              child: Row(
                children: [
                  Icon(Icons.tune_rounded, color: cs.primary),
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
            Flexible(
              child: SingleChildScrollView(
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

                    // ── AI section ────────────────────────────────────────────
                    _sectionLabel(context, 'AI'),
                    const SizedBox(height: 12),

                    // Provider picker
                    Row(
                      children: AiProvider.values.map((p) {
                        final selected = currentProvider == p;
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: _ProviderChip(
                              label: switch (p) {
                                AiProvider.groq   => 'Groq',
                                AiProvider.gemini => 'Gemini',
                                AiProvider.ollama => 'Ollama',
                              },
                              subtitle: switch (p) {
                                AiProvider.groq   => 'Free cloud',
                                AiProvider.gemini => 'Google AI',
                                AiProvider.ollama => 'Local / offline',
                              },
                              icon: switch (p) {
                                AiProvider.groq   => Icons.bolt_rounded,
                                AiProvider.gemini => Icons.auto_awesome_rounded,
                                AiProvider.ollama => Icons.computer_rounded,
                              },
                              selected: selected,
                              onTap: () => _saveProvider(p),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),

                    // Provider-specific fields
                    if (currentProvider == AiProvider.groq) ...[
                      const _AiNote(
                        icon: Icons.info_outline_rounded,
                        text:
                            'Free at console.groq.com — no credit card needed.\n'
                            'Model: ${AppConstants.groqModel}',
                      ),
                      const SizedBox(height: 12),
                      _ObscuredField(
                        controller: _groqKeyCtrl,
                        label: 'Groq API Key',
                        hint: 'gsk_…',
                        onChanged: (_) => _saveGroqKey(),
                      ),
                    ],

                    if (currentProvider == AiProvider.gemini) ...[
                      const _AiNote(
                        icon: Icons.warning_amber_rounded,
                        text:
                            'Requires a project with free quota > 0.\n'
                            'Go to aistudio.google.com → "Get API key" → "Create in new project".',
                        isWarning: true,
                      ),
                      const SizedBox(height: 12),
                      _ObscuredField(
                        controller: _geminiKeyCtrl,
                        label: 'Gemini API Key',
                        hint: 'AIza…',
                        onChanged: (_) {
                          _saveGeminiKey();
                          setState(() => _geminiModels = null);
                        },
                      ),
                      const SizedBox(height: 8),
                      StatefulBuilder(
                        builder: (context, setSt) => Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton.icon(
                                icon: _loadingModels
                                    ? const SizedBox(
                                        width: 14,
                                        height: 14,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2),
                                      )
                                    : const Icon(Icons.list_rounded, size: 16),
                                label: const Text('List available models'),
                                style: TextButton.styleFrom(
                                    visualDensity: VisualDensity.compact),
                                onPressed: _loadingModels
                                    ? null
                                    : () async {
                                        setSt(() => _loadingModels = true);
                                        try {
                                          final ds = AiRemoteDataSource(
                                            provider: AiProvider.gemini,
                                            geminiKey:
                                                _geminiKeyCtrl.text.trim(),
                                          );
                                          final models =
                                              await ds.listGeminiModels();
                                          setSt(() {
                                            _geminiModels = models;
                                            _loadingModels = false;
                                          });
                                        } catch (e) {
                                          setSt(
                                              () => _loadingModels = false);
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(SnackBar(
                                                    content: Text('$e')));
                                          }
                                        }
                                      },
                              ),
                            ),
                            if (_geminiModels != null) ...[
                              const SizedBox(height: 6),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: cs.surfaceContainerHighest,
                                  borderRadius:
                                      BorderRadius.circular(AppRadius.sm),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Models (${_geminiModels!.length}):',
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelSmall
                                          ?.copyWith(
                                              fontWeight: FontWeight.w600),
                                    ),
                                    const SizedBox(height: 4),
                                    ..._geminiModels!.map((m) => Padding(
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 1),
                                          child: Text(m,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodySmall),
                                        )),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],

                    if (currentProvider == AiProvider.ollama) ...[
                      const _AiNote(
                        icon: Icons.info_outline_rounded,
                        text:
                            'Install Ollama from ollama.com, then run:\n'
                            '  ollama pull llama3.2\n'
                            'Runs 100% locally — no internet, no API key.',
                      ),
                      const SizedBox(height: 12),
                      _field(
                        controller: _ollamaHostCtrl,
                        label: 'Ollama Host',
                        hint: AppConstants.ollamaDefaultHost,
                        icon: Icons.dns_rounded,
                        onChanged: (_) => _saveOllamaHost(),
                      ),
                      const SizedBox(height: 12),
                      _field(
                        controller: _ollamaModelCtrl,
                        label: 'Model',
                        hint: AppConstants.ollamaDefaultModel,
                        icon: Icons.psychology_rounded,
                        onChanged: (_) => _saveOllamaModel(),
                      ),
                      const SizedBox(height: 8),
                      _OllamaModelList(
                        getHost: () => _ollamaHostCtrl.text.trim(),
                      ),
                    ],
                    const SizedBox(height: 24),
                  ],
                ),
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
              color: Theme.of(context).colorScheme.primary,
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

// ── Reusable AI sub-widgets ───────────────────────────────────────────────────

class _ProviderChip extends StatelessWidget {
  const _ProviderChip({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? cs.primary.withAlpha(20) : cs.surfaceContainerHighest,
          border: Border.all(
            color: selected ? cs.primary : cs.outline.withAlpha(60),
            width: selected ? 1.5 : 1,
          ),
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 16,
                    color: selected ? cs.primary : cs.onSurfaceVariant),
                const SizedBox(width: 6),
                Text(label,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: selected ? cs.primary : null,
                          fontWeight: selected ? FontWeight.w600 : null,
                        )),
              ],
            ),
            const SizedBox(height: 2),
            Text(subtitle,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: cs.onSurfaceVariant,
                    )),
          ],
        ),
      ),
    );
  }
}

class _AiNote extends StatelessWidget {
  const _AiNote(
      {required this.icon, required this.text, this.isWarning = false});
  final IconData icon;
  final String text;
  final bool isWarning;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = isWarning ? cs.error : cs.primary;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withAlpha(15),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: color.withAlpha(50)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: color)),
          ),
        ],
      ),
    );
  }
}

class _OllamaModelList extends StatefulWidget {
  const _OllamaModelList({required this.getHost});
  final String Function() getHost;

  @override
  State<_OllamaModelList> createState() => _OllamaModelListState();
}

class _OllamaModelListState extends State<_OllamaModelList> {
  List<String>? _models;
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            icon: _loading
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.list_rounded, size: 16),
            label: const Text('List installed models'),
            style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
            onPressed: _loading
                ? null
                : () async {
                    setState(() => _loading = true);
                    try {
                      final ds = AiRemoteDataSource(
                        provider: AiProvider.ollama,
                        ollamaHost: widget.getHost(),
                      );
                      final models = await ds.listOllamaModels();
                      setState(() {
                        _models = models;
                        _loading = false;
                      });
                    } catch (e) {
                      setState(() => _loading = false);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              e.toString().contains('Connection refused') ||
                                      e.toString().contains('SocketException')
                                  ? 'Ollama is not running. Start it with: ollama serve'
                                  : 'Error: $e',
                            ),
                          ),
                        );
                      }
                    }
                  },
          ),
        ),
        if (_models != null) ...[
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: _models!.isEmpty
                ? Text(
                    'No models installed.\nRun: ollama pull llama3.2',
                    style: Theme.of(context).textTheme.bodySmall,
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Installed models — paste one into the Model field above:',
                        style: Theme.of(context)
                            .textTheme
                            .labelSmall
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 4),
                      ..._models!.map((m) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 1),
                            child: Text(m,
                                style: Theme.of(context).textTheme.bodySmall),
                          )),
                    ],
                  ),
          ),
        ],
      ],
    );
  }
}

class _ObscuredField extends StatefulWidget {
  const _ObscuredField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.onChanged,
  });
  final TextEditingController controller;
  final String label;
  final String hint;
  final void Function(String) onChanged;

  @override
  State<_ObscuredField> createState() => _ObscuredFieldState();
}

class _ObscuredFieldState extends State<_ObscuredField> {
  bool _obscured = true;

  @override
  Widget build(BuildContext context) => TextField(
        controller: widget.controller,
        obscureText: _obscured,
        onChanged: widget.onChanged,
        decoration: InputDecoration(
          labelText: widget.label,
          hintText: widget.hint,
          prefixIcon: const Icon(Icons.key_rounded, size: 18),
          suffixIcon: IconButton(
            icon: Icon(
              _obscured ? Icons.visibility_rounded : Icons.visibility_off_rounded,
              size: 18,
            ),
            onPressed: () => setState(() => _obscured = !_obscured),
          ),
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
            color: cs.primary,
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
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Icon(icon, size: 18, color: color),
          ),
        ),
      );
}
