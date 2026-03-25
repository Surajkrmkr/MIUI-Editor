import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/deployment_config.dart';
import '../providers/deployment_provider.dart';

class DeploymentPage extends ConsumerStatefulWidget {
  const DeploymentPage({super.key});

  @override
  ConsumerState<DeploymentPage> createState() => _DeploymentPageState();
}

class _DeploymentPageState extends ConsumerState<DeploymentPage> {
  final _scriptsDirCtrl = TextEditingController();
  final _basePathCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  bool _showPassword = false;
  bool _initialized = false;

  @override
  void dispose() {
    _scriptsDirCtrl.dispose();
    _basePathCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _descriptionCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _syncFromState(DeploymentConfig config) {
    if (!_initialized) {
      _scriptsDirCtrl.text = config.scriptsDir;
      _basePathCtrl.text = config.basePath;
      _emailCtrl.text = config.email;
      _passwordCtrl.text = config.password;
      _descriptionCtrl.text = config.description;
      _initialized = true;
    }
  }

  DeploymentConfig _buildConfig(int maxTab) => DeploymentConfig(
        scriptsDir: _scriptsDirCtrl.text.trim(),
        basePath: _basePathCtrl.text.trim(),
        maxTab: maxTab,
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text,
        description: _descriptionCtrl.text.trim(),
      );

  void _save(int maxTab) =>
      ref.read(deploymentProvider.notifier).updateConfig(_buildConfig(maxTab));

  Future<void> _pickDir(TextEditingController ctrl, int maxTab) async {
    final path = await FilePicker.platform.getDirectoryPath();
    if (path != null) {
      ctrl.text = path;
      _save(maxTab);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(deploymentProvider);
    _syncFromState(state.config);

    if (state.outputLines.isNotEmpty) _scrollToBottom();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Themes Deployment'),
        leading: BackButton(
          onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Left: Config form ─────────────────────────────────────────────
            SizedBox(
              width: 380,
              child: _ConfigPanel(
                scriptsDirCtrl: _scriptsDirCtrl,
                basePathCtrl: _basePathCtrl,
                emailCtrl: _emailCtrl,
                passwordCtrl: _passwordCtrl,
                descriptionCtrl: _descriptionCtrl,
                maxTab: state.config.maxTab,
                showPassword: _showPassword,
                isRunning: state.isRunning,
                onTogglePassword: () =>
                    setState(() => _showPassword = !_showPassword),
                onPickDir: (ctrl) => _pickDir(ctrl, state.config.maxTab),
                onSave: () => _save(state.config.maxTab),
                onMaxTabChanged: (val) => _save(val),
                onRun: () {
                  _save(state.config.maxTab);
                  ref.read(deploymentProvider.notifier).run();
                },
                onStop: () => ref.read(deploymentProvider.notifier).stop(),
              ),
            ),
            const SizedBox(width: 20),
            // ── Right: Console output ─────────────────────────────────────────
            Expanded(
              child: _ConsolePanel(
                outputLines: state.outputLines,
                isRunning: state.isRunning,
                completed: state.completed,
                scrollCtrl: _scrollCtrl,
                onClear: () =>
                    ref.read(deploymentProvider.notifier).clearOutput(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// Config form panel
// =============================================================================

class _ConfigPanel extends StatelessWidget {
  const _ConfigPanel({
    required this.scriptsDirCtrl,
    required this.basePathCtrl,
    required this.emailCtrl,
    required this.passwordCtrl,
    required this.descriptionCtrl,
    required this.maxTab,
    required this.showPassword,
    required this.isRunning,
    required this.onTogglePassword,
    required this.onPickDir,
    required this.onSave,
    required this.onMaxTabChanged,
    required this.onRun,
    required this.onStop,
  });

  final TextEditingController scriptsDirCtrl;
  final TextEditingController basePathCtrl;
  final TextEditingController emailCtrl;
  final TextEditingController passwordCtrl;
  final TextEditingController descriptionCtrl;
  final int maxTab;
  final bool showPassword;
  final bool isRunning;
  final VoidCallback onTogglePassword;
  final Future<void> Function(TextEditingController) onPickDir;
  final VoidCallback onSave;
  final ValueChanged<int> onMaxTabChanged;
  final VoidCallback onRun;
  final VoidCallback onStop;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Configuration',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.accent,
                  ),
            ),
            const SizedBox(height: 20),

            // Scripts directory
            _PathField(
              label: 'Scripts Directory',
              hint: '/path/to/project/scripts',
              controller: scriptsDirCtrl,
              onChanged: (_) => onSave(),
              onPick: () => onPickDir(scriptsDirCtrl),
            ),
            const SizedBox(height: 14),

            // Base path (mtz folder)
            _PathField(
              label: 'Base Path (MTZ folder)',
              hint: '/path/to/week_XX/mtz',
              controller: basePathCtrl,
              onChanged: (_) => onSave(),
              onPick: () => onPickDir(basePathCtrl),
            ),
            const SizedBox(height: 14),

            // Max Tab stepper
            _LabeledField(
              label: 'Max Tabs per Batch',
              child: _StepperCounter(
                value: maxTab,
                min: 1,
                max: 20,
                onChanged: onMaxTabChanged,
              ),
            ),
            const SizedBox(height: 14),

            // Email
            _LabeledField(
              label: 'Email / Phone',
              child: TextField(
                controller: emailCtrl,
                decoration:
                    const InputDecoration(hintText: 'Login credential'),
                onChanged: (_) => onSave(),
              ),
            ),
            const SizedBox(height: 14),

            // Password
            _LabeledField(
              label: 'Password',
              child: TextField(
                controller: passwordCtrl,
                obscureText: !showPassword,
                decoration: InputDecoration(
                  hintText: 'Login password',
                  suffixIcon: IconButton(
                    icon: Icon(
                      showPassword ? Icons.visibility_off : Icons.visibility,
                      size: 18,
                    ),
                    onPressed: onTogglePassword,
                  ),
                ),
                onChanged: (_) => onSave(),
              ),
            ),
            const SizedBox(height: 14),

            // Description
            _LabeledField(
              label: 'Description',
              child: TextField(
                controller: descriptionCtrl,
                decoration:
                    const InputDecoration(hintText: 'Theme description'),
                onChanged: (_) => onSave(),
              ),
            ),
            const SizedBox(height: 24),

            // Run / Stop button
            SizedBox(
              height: 44,
              child: isRunning
                  ? FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor:
                            Theme.of(context).colorScheme.error,
                      ),
                      icon: const Icon(Icons.stop_rounded, size: 18),
                      label: const Text('Stop'),
                      onPressed: onStop,
                    )
                  : FilledButton.icon(
                      icon: const Icon(Icons.rocket_launch_rounded, size: 18),
                      label: const Text('Run Deployment'),
                      onPressed: onRun,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// Stepper counter widget
// =============================================================================

class _StepperCounter extends StatelessWidget {
  const _StepperCounter({
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final canDecrement = value > min;
    final canIncrement = value < max;

    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withAlpha(20)),
      ),
      child: Row(
        children: [
          // Decrement
          _StepButton(
            icon: Icons.remove_rounded,
            enabled: canDecrement,
            onTap: () => onChanged(value - 1),
            isLeft: true,
          ),
          // Value display
          Expanded(
            child: Text(
              '$value',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          // Increment
          _StepButton(
            icon: Icons.add_rounded,
            enabled: canIncrement,
            onTap: () => onChanged(value + 1),
            isLeft: false,
          ),
        ],
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({
    required this.icon,
    required this.enabled,
    required this.onTap,
    required this.isLeft,
  });

  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;
  final bool isLeft;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.horizontal(
        left: isLeft ? const Radius.circular(12) : Radius.zero,
        right: isLeft ? Radius.zero : const Radius.circular(12),
      ),
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: enabled
              ? AppTheme.accent.withAlpha(30)
              : Colors.transparent,
          borderRadius: BorderRadius.horizontal(
            left: isLeft ? const Radius.circular(11) : Radius.zero,
            right: isLeft ? Radius.zero : const Radius.circular(11),
          ),
        ),
        child: Icon(
          icon,
          size: 18,
          color: enabled ? AppTheme.accent : Colors.white24,
        ),
      ),
    );
  }
}

// =============================================================================
// Console output panel
// =============================================================================

class _ConsolePanel extends StatelessWidget {
  const _ConsolePanel({
    required this.outputLines,
    required this.isRunning,
    required this.completed,
    required this.scrollCtrl,
    required this.onClear,
  });

  final List<String> outputLines;
  final bool isRunning;
  final bool completed;
  final ScrollController scrollCtrl;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header row
        Row(
          children: [
            Text(
              'Console Output',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.accent,
                  ),
            ),
            const SizedBox(width: 12),
            if (isRunning)
              const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            if (completed && !isRunning)
              const Icon(Icons.check_circle_rounded,
                  size: 16, color: Colors.greenAccent),
            const Spacer(),
            TextButton.icon(
              icon: const Icon(Icons.delete_outline, size: 16),
              label: const Text('Clear'),
              onPressed: outputLines.isEmpty ? null : onClear,
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Terminal box
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF0D0D17),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withAlpha(20)),
            ),
            padding: const EdgeInsets.all(14),
            child: outputLines.isEmpty
                ? Center(
                    child: Text(
                      'No output yet. Run the deployment to see logs here.',
                      style: TextStyle(
                        color: Colors.white.withAlpha(40),
                        fontFamily: 'monospace',
                        fontSize: 13,
                      ),
                    ),
                  )
                : ListView.builder(
                    controller: scrollCtrl,
                    itemCount: outputLines.length,
                    itemBuilder: (_, i) =>
                        _ConsoleLine(line: outputLines[i]),
                  ),
          ),
        ),
      ],
    );
  }
}

class _ConsoleLine extends StatelessWidget {
  const _ConsoleLine({required this.line});
  final String line;

  @override
  Widget build(BuildContext context) {
    final Color color;
    if (line.startsWith('[ERR]') || line.startsWith('[FATAL]') ||
        line.startsWith('[ERROR]')) {
      color = const Color(0xFFFF6B6B);
    } else if (line.startsWith('[OK]') || line.startsWith('[DONE]')) {
      color = const Color(0xFF69D2A0);
    } else if (line.startsWith('---')) {
      color = const Color(0xFFFFD93D);
    } else if (line.startsWith('[WARN]')) {
      color = const Color(0xFFFFB347);
    } else {
      color = const Color(0xFFCDD6F4);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1.5),
      child: Text(
        line,
        style: TextStyle(
          color: color,
          fontFamily: 'monospace',
          fontSize: 12.5,
          height: 1.5,
        ),
      ),
    );
  }
}

// =============================================================================
// Shared form helpers
// =============================================================================

class _LabeledField extends StatelessWidget {
  const _LabeledField({required this.label, required this.child});
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: Colors.white60,
              ),
        ),
        const SizedBox(height: 6),
        child,
      ],
    );
  }
}

class _PathField extends StatelessWidget {
  const _PathField({
    required this.label,
    required this.hint,
    required this.controller,
    required this.onChanged,
    required this.onPick,
  });

  final String label;
  final String hint;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    return _LabeledField(
      label: label,
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              decoration: InputDecoration(hintText: hint),
              onChanged: onChanged,
            ),
          ),
          const SizedBox(width: 8),
          IconButton.outlined(
            tooltip: 'Pick folder',
            icon: const Icon(Icons.folder_open_rounded, size: 18),
            onPressed: onPick,
          ),
        ],
      ),
    );
  }
}
