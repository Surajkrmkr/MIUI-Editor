import 'dart:io';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:miui_icon_generator/core/theme/theme_extensions.dart';
import 'package:miui_icon_generator/widgets/app_icon_button.dart';
import 'package:miui_icon_generator/widgets/glass_card.dart';
import 'package:path/path.dart' as p;
import 'package:url_launcher/url_launcher.dart';
import '../../application/providers/upscaler_provider.dart';
import '../../domain/models/upscale_options.dart';
import '../widgets/comparison_slider.dart';
import '../widgets/log_panel.dart';
import '../widgets/upscaler_settings_dialog.dart';

class AiUpscalerScreen extends ConsumerStatefulWidget {
  const AiUpscalerScreen({super.key});

  @override
  ConsumerState<AiUpscalerScreen> createState() => _AiUpscalerScreenState();
}

class _AiUpscalerScreenState extends ConsumerState<AiUpscalerScreen> {
  bool _isDragging = false;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(upscalerProvider);
    final notifier = ref.read(upscalerProvider.notifier);
    final colors = context.appColors;
    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: colors.bg,
      body: Stack(
        children: [
          _buildBackgroundGlow(context),
          Column(
            children: [
              _buildTopBar(context),
              Expanded(
                child: DropTarget(
                  onDragDone: (details) {
                    if (details.files.isNotEmpty) {
                      notifier.setInputPath(details.files.first.path);
                    }
                  },
                  onDragEntered: (_) => setState(() => _isDragging = true),
                  onDragExited: (_) => setState(() => _isDragging = false),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: !state.isBinaryInstalled
                        ? _buildBinaryMissingState(context)
                        : state.inputPath == null && state.queue.isEmpty
                            ? _buildEmptyState(context)
                            : _buildWorkspace(context, state, notifier),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBackgroundGlow(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Stack(
      children: [
        Positioned(
          top: -150,
          right: -100,
          child: Container(
            width: 500,
            height: 500,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: primary.withValues(alpha: isDark ? 0.08 : 0.06),
            ),
          ),
        ),
        Positioned(
          bottom: -100,
          left: -100,
          child: Container(
            width: 400,
            height: 400,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: primary.withValues(alpha: isDark ? 0.04 : 0.04),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTopBar(BuildContext context) {
    final colors = context.appColors;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12),
      child: Row(
        children: [
          AppBackButton.close(
            onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
          ),
          const SizedBox(width: 16),
          Text(
            'AI UPSCALER',
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
          const Spacer(),
          GlassCard(
            padding: const EdgeInsets.all(8),
            borderRadius: 12,
            child: InkWell(
              onTap: () => showDialog(context: context, builder: (_) => const UpscalerSettingsDialog()),
              child: Icon(Icons.tune_rounded,
                  color: colors.primary, size: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBinaryMissingState(BuildContext context) {
    final colors = context.appColors;
    return Center(
      child: GlassCard(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.warning_amber_rounded, size: 64, color: Colors.orangeAccent),
            const SizedBox(height: 24),
            Text(
              'Real-ESRGAN Not Found',
              style: TextStyle(color: colors.textPrimary, fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              'Please ensure realesrgan-ncnn-vulkan.exe or upscayl-bin.exe is in the bin folder or configure your Upscayl path manually.',
              textAlign: TextAlign.center,
              style: TextStyle(color: colors.textSecondary, fontSize: 14),
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ElevatedButton(
                  onPressed: () => ref.read(upscalerProvider.notifier).checkInstallation(),
                  child: const Text('Retry Search'),
                ),
                const SizedBox(width: 16),
                OutlinedButton(
                  onPressed: () => showDialog(context: context, builder: (_) => const UpscalerSettingsDialog()),
                  child: const Text('Configure Manually'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final colors = context.appColors;
    final primary = Theme.of(context).colorScheme.primary;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.auto_fix_high_rounded,
              size: 80,
              color: primary.withValues(alpha: 0.15)),
          const SizedBox(height: 32),
          Text(
            'Neural Enhancement Studio',
            style: TextStyle(
                color: colors.textPrimary,
                fontSize: 26,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5),
          ),
          const SizedBox(height: 12),
          Text(
            'Drag images or folders to begin the upscale pipeline',
            style: TextStyle(color: colors.textDisabled, fontSize: 14),
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton.icon(
                onPressed: () async {
                  final result = await FilePicker.platform.pickFiles(type: FileType.image);
                  if (result != null && result.files.single.path != null) {
                    ref.read(upscalerProvider.notifier).setInputPath(result.files.single.path!);
                  }
                },
                icon: const Icon(Icons.add_photo_alternate_rounded),
                label: const Text('Select Image'),
              ),
              const SizedBox(width: 16),
              OutlinedButton.icon(
                onPressed: () async {
                  final path = await FilePicker.platform.getDirectoryPath();
                  if (path != null) {
                    ref.read(upscalerProvider.notifier).startBatchUpscale(path);
                  }
                },
                icon: const Icon(Icons.folder_special_rounded),
                label: const Text('Batch Folder'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWorkspace(BuildContext context, UpscalerState state, UpscalerNotifier notifier) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          width: 320,
          child: Column(
            children: [
              _buildSettingsPanel(context, state, notifier),
              const SizedBox(height: 16),
              Expanded(
                flex: 1,
                child: _buildActionPanel(context, state, notifier),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
        const SizedBox(width: 24),
        Expanded(
          child: _buildPreviewArea(context, state),
        ),
      ],
    );
  }

  Widget _buildSettingsPanel(BuildContext context, UpscalerState state, UpscalerNotifier notifier) {
    final colors = context.appColors;
    return Expanded(
      flex: 2,
      child: GlassCard(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Studio Config',
                style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5),
              ),
              const SizedBox(height: 24),
              _buildSectionTitle('UPSCALING PRESET'),
              const SizedBox(height: 12),
              ...UpscalePreset.values.map((p) => _PresetTile(
                preset: p,
                selected: state.preset == p,
                onTap: () => notifier.setPreset(p),
              )),
              const SizedBox(height: 24),
              _buildSectionTitle('SCALE FACTOR'),
              const SizedBox(height: 12),
              Row(
                children: UpscaleScale.values.map((s) => Expanded(
                  child: _ChoiceChip(
                    label: s.label,
                    selected: state.scale == s,
                    onTap: () => notifier.setScale(s),
                  ),
                )).toList(),
              ),
              const SizedBox(height: 24),
              _buildSectionTitle('OUTPUT FORMAT'),
              const SizedBox(height: 12),
              Row(
                children: OutputFormat.values.map((f) => Expanded(
                  child: _ChoiceChip(
                    label: f.label,
                    selected: state.format == f,
                    onTap: () => notifier.setFormat(f),
                  ),
                )).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionPanel(BuildContext context, UpscalerState state, UpscalerNotifier notifier) {
    final colors = context.appColors;
    final primary = Theme.of(context).colorScheme.primary;
    final isDone = !state.isProcessing && (state.outputPath != null || (state.queue.isNotEmpty && state.completedTasks == state.totalTasks));

    return GlassCard(
      padding: const EdgeInsets.all(20),
      hasGlow: state.isProcessing,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            state.queue.isNotEmpty ? 'Batch Workflow' : 'Single Workflow',
            style: TextStyle(
                color: colors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            state.queue.isNotEmpty 
                ? 'Queue: ${state.completedTasks}/${state.totalTasks} complete'
                : state.inputPath != null ? 'Ready to process file' : 'Idle',
            style: TextStyle(color: colors.textDisabled, fontSize: 12),
          ),
          const Spacer(),
          if (state.isProcessing)
             LinearProgressIndicator(
               value: state.progress,
               backgroundColor: colors.bgSubtle,
               borderRadius: BorderRadius.circular(10),
               minHeight: 6,
             )
          else if (isDone)
            _buildPipelineButton(
              context: context,
              label: 'PROCESS ANOTHER',
              icon: Icons.replay_rounded,
              color: primary,
              onPressed: () => notifier.clear(),
            )
          else
            _buildPipelineButton(
              context: context,
              label: 'INITIALIZE PIPELINE',
              icon: Icons.play_circle_filled_rounded,
              color: primary,
              onPressed: state.inputPath == null && state.queue.isEmpty ? null : () => notifier.startUpscale(),
            ),
          const SizedBox(height: 12),
          _buildPipelineButton(
            context: context,
            label: 'OPEN STUDIO OUTPUT',
            icon: Icons.folder_copy_rounded,
            color: colors.surfaceOverlay,
            onPressed: state.outputPath == null ? null : () {
               if (Platform.isWindows) {
                Process.run('explorer.exe', ['/select,', state.outputPath!]);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewArea(BuildContext context, UpscalerState state) {
    final colors = context.appColors;
    final notifier = ref.read(upscalerProvider.notifier);

    return GlassCard(
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (state.outputPath != null && !state.isProcessing)
            ComparisonSlider(
              beforeImagePath: state.inputPath!,
              afterImagePath: state.outputPath!,
            )
          else if (state.inputPath != null)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.file(
                    File(state.inputPath!),
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            )
          else
            Center(
                child: Icon(Icons.image_search_rounded,
                    size: 64,
                    color: colors.textDisabled.withValues(alpha: 0.2))),

          // Global clear button (top-right of preview)
          if (state.inputPath != null && !state.isProcessing)
            Positioned(
              top: 16,
              right: 16,
              child: AppIconButton(
                icon: Icons.close_rounded,
                tooltip: 'Clear Workspace',
                onPressed: () => notifier.clear(),
              ),
            ),

          if (state.isProcessing || state.logs.isNotEmpty)
            Positioned(
              left: 20,
              right: 20,
              bottom: 20,
              child: SizedBox(
                height: 150,
                child: LogPanel(logs: state.logs),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.2,
        color: Colors.grey,
      ),
    );
  }

  Widget _buildPipelineButton({
    required BuildContext context,
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback? onPressed,
  }) {
    final colors = context.appColors;
    final isPrimary = color == Theme.of(context).colorScheme.primary;

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: isPrimary ? colors.onPrimary : colors.textSecondary,
          padding: const EdgeInsets.symmetric(vertical: 16),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        onPressed: onPressed,
        icon: Icon(icon, size: 20),
        label: Text(label,
            style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 11,
                letterSpacing: 1.2)),
      ),
    );
  }
}

class _PresetTile extends StatelessWidget {
  final UpscalePreset preset;
  final bool selected;
  final VoidCallback onTap;

  const _PresetTile({required this.preset, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final primary = Theme.of(context).colorScheme.primary;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: selected ? primary.withValues(alpha: 0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? primary.withValues(alpha: 0.3) : colors.borderSubtle,
            ),
          ),
          child: Row(
            children: [
              Icon(preset.icon, size: 18, color: selected ? primary : colors.textSecondary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      preset.label,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: selected ? colors.textPrimary : colors.textSecondary,
                      ),
                    ),
                    Text(
                      preset.description,
                      style: TextStyle(
                        fontSize: 9,
                        color: colors.textDisabled,
                      ),
                    ),
                  ],
                ),
              ),
              if (selected)
                Icon(Icons.check_circle_rounded, size: 14, color: primary),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChoiceChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ChoiceChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final primary = Theme.of(context).colorScheme.primary;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? primary : colors.bgSubtle.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: selected ? primary : colors.borderSubtle),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 11,
              color: selected ? Colors.white : colors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
