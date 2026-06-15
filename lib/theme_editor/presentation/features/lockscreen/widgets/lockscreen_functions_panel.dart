import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/theme/theme_extensions.dart';
import 'package:miui_icon_generator/theme_editor/presentation/providers/wallpaper_provider.dart';
import '../../../../core/constants/path_constants.dart';
import '../../../providers/element_provider.dart';
import '../../../providers/lockscreen_provider.dart';
import '../../../providers/service_providers.dart';
import '../../../providers/ai_provider.dart';
import '../../../common/widgets/drop_zone.dart';
import 'ai_generate_dialog.dart';
import '../preset_dialog.dart';
import 'manifest_editor_dialog.dart';

class LockscreenFunctionsPanel extends ConsumerWidget {
  const LockscreenFunctionsPanel({
    super.key,
    this.toolsOnly = false,
    this.hideTools = false,
  });

  final bool toolsOnly;
  final bool hideTools;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final lsState = ref.watch(lockscreenProvider);
    final aiState = ref.watch(aiProvider);
    final busy = lsState.isExporting || aiState.isLoading;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Background section ───────────────────────────────────────────
        if (!toolsOnly) _SectionCard(
          title: 'BACKGROUND',
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _DropTile(
                      icon: Icons.image_rounded,
                      label: 'Image',
                      sublabel: 'PNG / JPG',
                      child: AppDropZone(
                        label: 'Drop BG',
                        allowedExtensions: const ['.png', '.jpg'],
                        onDropped: (path) => _dropBg(ref, path),
                        size: const Size(75, 60),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _DropTile(
                      icon: Icons.videocam_rounded,
                      label: 'Video',
                      sublabel: 'MP4',
                      child: AppDropZone(
                        label: 'Drop MP4',
                        allowedExtensions: const ['.mp4'],
                        onDropped: (path) => _dropVideo(ref, path),
                        size: const Size(75, 60),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Consumer(builder: (_, ref, __) {
                final alpha = ref.watch(elementProvider).bgAlpha;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Darken',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: scheme.primaryContainer,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${(alpha * 100).toStringAsFixed(0)}%',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: scheme.onPrimaryContainer,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Slider(
                      value: alpha,
                      min: 0,
                      max: 1,
                      divisions: 20,
                      onChanged: (v) =>
                          ref.read(elementProvider.notifier).setBgAlpha(v),
                    ),
                  ],
                );
              }),
            ],
          ),
        ),

        if (!toolsOnly) const SizedBox(height: 10),

        // ── AI + Presets section ─────────────────────────────────────────
        if (!hideTools) _SectionCard(
          title: 'TOOLS',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _ActionButton(
                icon: Icons.auto_awesome_rounded,
                label: 'AI Generate',
                onPressed: busy ? null : () => _showAiDialog(context, ref),
                isPrimary: true,
              ),
              const SizedBox(height: 8),
              _ActionButton(
                icon: Icons.code_rounded,
                label: 'Manifest Editor',
                onPressed: () => _showManifestEditor(context, ref),
              ),
              const SizedBox(height: 8),
              _ActionButton(
                icon: Icons.bookmark_rounded,
                label: 'Save Preset',
                onPressed: () async {
                  final failure = await ref
                      .read(lockscreenProvider.notifier)
                      .savePreset(
                          DateTime.now().millisecondsSinceEpoch.toString());
                  if (!context.mounted) return;
                  if (failure != null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Save failed: ${failure.message}'),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Preset saved')),
                    );
                  }
                },
              ),
              const SizedBox(height: 8),
              _ActionButton(
                icon: Icons.layers_rounded,
                label: 'Load Presets',
                onPressed: () => showDialog(
                  context: context,
                  builder: (_) => const PresetDialog(),
                ),
                isOutlined: true,
              ),
            ],
          ),
        ),

        if (!toolsOnly && !hideTools) const SizedBox(height: 10),

        // ── Export section ───────────────────────────────────────────────
        if (!toolsOnly) Consumer(builder: (_, ref, __) {
          final s = ref.watch(lockscreenProvider);
          return _SectionCard(
            title: 'EXPORT',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _DualVersionToggle(
                  value: s.dualMtzExport,
                  onChanged: (_) => ref
                      .read(lockscreenProvider.notifier)
                      .toggleDualMtzExport(),
                ),
                const SizedBox(height: 8),
                _ExportMainButton(state: s, onTap: () => _export(context, ref)),
                if (s.isExportingPngs) ...[
                  const SizedBox(height: 8),
                  _GradientProgress(value: s.pngsProgress),
                  const SizedBox(height: 4),
                  Text(
                    s.pngsLabel,
                    style: TextStyle(
                      fontSize: 10,
                      color: scheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
                const SizedBox(height: 8),
                _ActionButton(
                  icon: Icons.archive_rounded,
                  label: 'Re-pack MTZ',
                  isOutlined: true,
                  onPressed: s.isBusy ? null : () => _repackMtz(context, ref),
                ),
                // const SizedBox(height: 8),
                // _ActionButton(
                //   icon: Icons.auto_fix_high_rounded,
                //   label: s.isTracing
                //       ? 'Generating…'
                //       : 'Generate Copyright',
                //   isOutlined: true,
                //   onPressed: s.isBusy
                //       ? null
                //       : () async {
                //           await ref
                //               .read(lockscreenProvider.notifier)
                //               .generateLayeredSvg();
                //           if (context.mounted) {
                //             final err =
                //                 ref.read(lockscreenProvider).error;
                //             ScaffoldMessenger.of(context).showSnackBar(
                //               SnackBar(
                //                 backgroundColor: err != null
                //                     ? scheme.errorContainer
                //                     : scheme.primaryContainer,
                //                 content: Text(
                //                   err ??
                //                       'Copyright generated in "svg" folder',
                //                   style: TextStyle(
                //                     color: err != null
                //                         ? scheme.onErrorContainer
                //                         : scheme.onPrimaryContainer,
                //                   ),
                //                 ),
                //               ),
                //             );
                //           }
                //         },
                // ),
                if (s.isTracing) ...[
                  const SizedBox(height: 8),
                  const LinearProgressIndicator(minHeight: 2),
                ],
              ],
            ),
          );
        }),
      ],
    );
  }

  Future<void> _dropBg(WidgetRef ref, String path) async {
    final ws = ref.read(wallpaperProvider);
    if (ws.weekNum == null || ws.currentThemeName == null) return;
    final tp = PathConstants.themePath(ws.weekNum!, ws.currentThemeName!);
    final dest = '${PathConstants.lockscreenAdvance(tp)}bg.png';
    await ref.read(fileServiceProvider).copyFile(path, dest);
    ref
        .read(elementProvider.notifier)
        .setGuideLines(ref.read(elementProvider).activeType, false);
  }

  Future<void> _dropVideo(WidgetRef ref, String path) async {
    final ws = ref.read(wallpaperProvider);
    if (ws.weekNum == null || ws.currentThemeName == null) return;
    final tp = PathConstants.themePath(ws.weekNum!, ws.currentThemeName!);
    final dest = '${PathConstants.lockscreenAdvance(tp)}video.mp4';
    await ref.read(fileServiceProvider).copyFile(path, dest);
  }

  Future<void> _export(BuildContext context, WidgetRef ref) async {
    final failure = await ref.read(lockscreenProvider.notifier).export(context);
    if (!context.mounted) return;
    if (failure != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Export failed: ${failure.message}')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lockscreen exported')),
      );
    }
  }

  Future<void> _repackMtz(BuildContext context, WidgetRef ref) async {
    final isDual = ref.read(lockscreenProvider.select((s) => s.dualMtzExport));
    final (path, failure) =
        await ref.read(lockscreenProvider.notifier).exportMtz(context);
    if (!context.mounted) return;
    if (failure != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('MTZ failed: ${failure.message}')),
      );
    } else if (isDual) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Exported HyperOS 1.0 & 3.0 MTZ to: $path')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Re-packed: $path')),
      );
    }
  }

  Future<void> _showAiDialog(BuildContext context, WidgetRef ref) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const AiGenerateDialog(),
    );
  }

  void _showManifestEditor(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (_) => const ManifestEditorDialog(),
    );
  }
}

// ── Section Card ──────────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.surfaceOverlay,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                Container(
                  width: 3,
                  height: 12,
                  margin: const EdgeInsets.only(right: 6),
                  decoration: BoxDecoration(
                    color: colors.primary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: scheme.onSurfaceVariant,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ),
          child,
        ],
      ),
    );
  }
}

// ── Action Button ─────────────────────────────────────────────────────────────

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.isPrimary = false,
    this.isOutlined = false,
  });
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final bool isPrimary;
  final bool isOutlined;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final labelWidget = FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.visible,
        softWrap: false,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
    if (isPrimary) {
      return FilledButton.icon(
        icon: Icon(icon, size: 14),
        label: labelWidget,
        onPressed: onPressed,
      );
    }
    if (isOutlined) {
      return OutlinedButton.icon(
        icon: Icon(icon, size: 14),
        label: labelWidget,
        onPressed: onPressed,
      );
    }
    return FilledButton.tonalIcon(
      icon: Icon(icon, size: 14),
      label: labelWidget,
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: scheme.secondaryContainer,
        foregroundColor: scheme.onSecondaryContainer,
      ),
    );
  }
}

// ── Export Main Button ────────────────────────────────────────────────────────

class _ExportMainButton extends StatelessWidget {
  const _ExportMainButton({required this.state, required this.onTap});
  final LockscreenState state;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final label = state.isExportingPngs
        ? state.pngsLabel
        : state.isExporting
            ? 'Exporting…'
            : state.isExported
                ? 'Re-Export'
                : 'Export + MTZ';

    return FilledButton.icon(
      icon: Icon(
        state.isExported ? Icons.check_circle_rounded : Icons.lock_rounded,
        size: 14,
      ),
      label: Text(
        label,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
      ),
      style: FilledButton.styleFrom(
        backgroundColor:
            state.isExported ? scheme.primaryContainer : scheme.primary,
        foregroundColor:
            state.isExported ? scheme.onPrimaryContainer : scheme.onPrimary,
      ),
      onPressed: state.isBusy ? null : onTap,
    );
  }
}

// ── Gradient Progress Bar ─────────────────────────────────────────────────────

class _GradientProgress extends StatelessWidget {
  const _GradientProgress({required this.value});
  final double value;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: Stack(
        children: [
          Container(height: 5, color: colors.border),
          FractionallySizedBox(
            widthFactor: value,
            child: Container(
              height: 5,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [colors.primary, colors.primaryPressed],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Dual Version Toggle ───────────────────────────────────────────────────────

class _DualVersionToggle extends StatelessWidget {
  const _DualVersionToggle({required this.value, required this.onChanged});
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Both Versions',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: scheme.onSurface,
                  ),
                ),
                Text(
                  'HyperOS 1.0 & 3.0',
                  style: TextStyle(
                    fontSize: 9,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: scheme.primary,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ],
      ),
    );
  }
}

// ── Drop Tile ─────────────────────────────────────────────────────────────────

class _DropTile extends StatelessWidget {
  const _DropTile({
    required this.icon,
    required this.label,
    required this.sublabel,
    required this.child,
  });
  final IconData icon;
  final String label;
  final String sublabel;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        child,
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: scheme.onSurface,
          ),
        ),
        Text(sublabel,
            style: TextStyle(fontSize: 9, color: scheme.onSurfaceVariant)),
      ],
    );
  }
}
