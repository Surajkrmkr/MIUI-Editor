import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/theme/theme_extensions.dart';
import '../../../providers/workspace_provider.dart';
import '../../../providers/wallpaper_provider.dart';
import '../../../providers/element_provider.dart';
import '../../../providers/icon_editor_provider.dart';
import '../../../providers/export_provider.dart';
import '../../../providers/lockscreen_provider.dart';
import '../../../providers/adb_provider.dart';
import '../../../providers/spec_provider.dart';
import '../../lockscreen/widgets/apply_to_device_dialog.dart';
import 'floating_layers_panel.dart';

class TopCommandBar extends ConsumerWidget {
  const TopCommandBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.appColors;
    final n = ref.read(workspaceProvider.notifier);

    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(bottom: BorderSide(color: colors.border)),
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(
              Icons.arrow_back_rounded,
              color: colors.textSecondary,
              size: 18,
            ),
            tooltip: 'Back to Project Selection',
            visualDensity: VisualDensity.compact,
            mouseCursor: SystemMouseCursors.click,
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          const SizedBox(width: 4),
          IconButton(
            icon: Icon(
              Icons.menu_rounded,
              color: colors.textSecondary,
              size: 18,
            ),
            tooltip: 'Toggle Sidebar',
            visualDensity: VisualDensity.compact,
            mouseCursor: SystemMouseCursors.click,
            onPressed: () => n.toggleSidebar(),
          ),
          const SizedBox(width: 8),

          // Project breadcrumb
          Consumer(
            builder: (context, ref, _) {
              final wallState = ref.watch(wallpaperProvider);
              final name = wallState.currentThemeName ?? 'Default Theme';
              return Text(
                name,
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              );
            },
          ),
          const Spacer(),

          // Undo / Redo
          Consumer(
            builder: (_, ref, __) {
              final page = ref.watch(workspaceProvider).page;
              if (page != WorkspacePage.lockscreen &&
                  page != WorkspacePage.lockscreenPresets) {
                return const SizedBox.shrink();
              }
              final elState = ref.watch(elementProvider);
              final n = ref.read(elementProvider.notifier);
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const LayersButton(),
                  IconButton.filled(
                    icon: const Icon(Icons.play_arrow_rounded, size: 18),
                    tooltip: 'Replay animations',
                    style: IconButton.styleFrom(
                      backgroundColor: colors.primary,
                      foregroundColor: colors.onPrimary,
                    ),
                    visualDensity: VisualDensity.compact,
                    onPressed:
                        elState.elements.any(
                          (element) =>
                              element.isVisible &&
                              element.activeAnimations.isNotEmpty,
                        )
                        ? () =>
                              ref.read(animationReplayProvider.notifier).state++
                        : null,
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.undo_rounded,
                      color: elState.canUndo
                          ? colors.textSecondary
                          : colors.textDisabled,
                      size: 18,
                    ),
                    tooltip: 'Undo',
                    visualDensity: VisualDensity.compact,
                    mouseCursor: elState.canUndo
                        ? SystemMouseCursors.click
                        : SystemMouseCursors.basic,
                    onPressed: elState.canUndo ? n.undo : null,
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.redo_rounded,
                      color: elState.canRedo
                          ? colors.textSecondary
                          : colors.textDisabled,
                      size: 18,
                    ),
                    tooltip: 'Redo',
                    visualDensity: VisualDensity.compact,
                    mouseCursor: elState.canRedo
                        ? SystemMouseCursors.click
                        : SystemMouseCursors.basic,
                    onPressed: elState.canRedo ? n.redo : null,
                  ),
                  const SizedBox(width: 4),
                  Consumer(
                    builder: (_, ref, __) {
                      final isLocked = ref.watch(canvasLockProvider);
                      return IconButton(
                        icon: Icon(
                          isLocked
                              ? Icons.lock_rounded
                              : Icons.lock_open_rounded,
                          color: isLocked
                              ? colors.primary
                              : colors.textSecondary,
                          size: 18,
                        ),
                        tooltip: isLocked
                            ? 'Canvas Locked (Drag & Zoom disabled) · Click to unlock'
                            : 'Lock Canvas (Prevent drag & zoom)',
                        visualDensity: VisualDensity.compact,
                        mouseCursor: SystemMouseCursors.click,
                        onPressed: () =>
                            ref.read(canvasLockProvider.notifier).toggle(),
                      );
                    },
                  ),
                  const SizedBox(width: 4),
                ],
              );
            },
          ),

          IconButton(
            icon: const Icon(Icons.description_outlined, size: 20),
            tooltip: 'Save theme spec…',
            onPressed: () => _saveSpec(context, ref),
          ),

          // Palette strip
          Consumer(
            builder: (_, ref, __) {
              final paletteColors = ref.watch(wallpaperProvider).colorPalette;
              final page = ref.watch(workspaceProvider).page;
              if (paletteColors.isEmpty) return const SizedBox.shrink();
              return _PaletteStrip(colors: paletteColors, page: page, ref: ref);
            },
          ),
          const SizedBox(width: 4),

          // Export action — lockscreen tab only
          Consumer(
            builder: (_, ref, __) {
              final page = ref.watch(workspaceProvider).page;
              if (page != WorkspacePage.lockscreen &&
                  page != WorkspacePage.lockscreenPresets) {
                return const SizedBox.shrink();
              }
              final ls = ref.watch(lockscreenProvider);
              final icons = ref.watch(exportProvider);
              final adb = ref.watch(applyToDeviceProvider);
              final busy = ls.isBusy || icons.isRunning;
              final adbLocked =
                  adb.isRunning || adb.isBusy || adb.isDownloading;
              final runningStep = applySteps
                  .where((step) => adb.statusOf(step) == StepStatus.running)
                  .firstOrNull;

              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _BarButton(
                    label: icons.isRunning
                        ? icons.statusLabel
                        : ls.isExportingPngs
                        ? ls.pngsLabel
                        : ls.isExporting
                        ? 'Exporting…'
                        : ls.isExported
                        ? 'Re-Export'
                        : 'Export',
                    icon: ls.isExported
                        ? Icons.check_circle_rounded
                        : Icons.file_upload_outlined,
                    loading: busy,
                    progress: ls.isExportingPngs ? ls.pngsProgress : null,
                    filled: true,
                    onTap: (busy || adbLocked)
                        ? null
                        : () async {
                            final failure = await ref
                                .read(lockscreenProvider.notifier)
                                .exportWorkspace(context);
                            if (!context.mounted) return;
                            if (failure != null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Export failed: ${failure.message}',
                                  ),
                                ),
                              );
                            }
                          },
                  ),
                  const SizedBox(width: 8),
                  _BarButton(
                    label: adb.isRunning
                        ? '${runningStep?.label ?? 'Applying'}…'
                        : 'Apply',
                    icon: Icons.phone_android_rounded,
                    loading: adbLocked,
                    filled: true,
                    tooltip: 'Apply to Phone',
                    onSecondaryTap: adbLocked
                        ? null
                        : () => _showDeviceDialog(context),
                    onTap: (busy || adbLocked)
                        ? null
                        : () => _applyToDevice(context, ref),
                  ),
                  const SizedBox(width: 8),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _saveSpec(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    final spec = ref.read(themeSpecProvider);
    if (spec == null) {
      messenger.showSnackBar(const SnackBar(content: Text('No active theme')));
      return;
    }
    final picked = await FilePicker.platform.saveFile(
      dialogTitle: 'Save theme spec',
      fileName: '${spec.meta.title}.json',
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    if (picked == null) return;
    final path = picked.endsWith('.json') ? picked : '$picked.json';
    final failure = await ref.read(themeSpecSaveAsProvider)(path);
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          failure == null ? 'Saved $path' : 'Save failed: ${failure.message}',
        ),
      ),
    );
  }

  static void _showDeviceDialog(BuildContext context) => showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const ApplyToDeviceDialog(),
  );

  Future<void> _applyToDevice(BuildContext context, WidgetRef ref) async {
    await ref.read(applyToDeviceProvider.notifier).apply();
    if (!context.mounted) return;
    final s = ref.read(applyToDeviceProvider);
    final messenger = ScaffoldMessenger.of(context)..hideCurrentSnackBar();
    if (s.error != null) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            s.errorStep == null
                ? s.error!
                : '${s.errorStep!.label}: ${s.error}',
          ),
          duration: const Duration(seconds: 8),
          action: SnackBarAction(
            label: 'Configure',
            onPressed: () => _showDeviceDialog(context),
          ),
        ),
      );
    } else if (s.info != null) {
      messenger.showSnackBar(SnackBar(content: Text(s.info!)));
    }
  }
}

// ── Bar Button ────────────────────────────────────────────────────────────────

class _BarButton extends StatelessWidget {
  const _BarButton({
    required this.label,
    required this.icon,
    required this.loading,
    required this.filled,
    required this.onTap,
    this.progress,
    this.tooltip,
    this.onSecondaryTap,
  });
  final String label;
  final IconData icon;
  final bool loading;
  final bool filled;
  final VoidCallback? onTap;
  final VoidCallback? onSecondaryTap;
  final double? progress;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bg = filled ? scheme.primary : scheme.surfaceContainerHighest;
    final fg = filled ? scheme.onPrimary : scheme.onSurfaceVariant;
    final isInteractive = onTap != null || loading;

    Widget button = MouseRegion(
      cursor: onTap == null
          ? SystemMouseCursors.basic
          : SystemMouseCursors.click,
      child: Opacity(
        opacity: isInteractive ? 1.0 : 0.55,
        child: Material(
          color: bg,
          borderRadius: BorderRadius.circular(8),
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: onTap,
            onSecondaryTap: onSecondaryTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (loading)
                    SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(
                        strokeWidth: 1.5,
                        color: fg,
                      ),
                    )
                  else
                    Icon(icon, size: 14, color: fg),
                  const SizedBox(width: 5),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: fg,
                    ),
                  ),
                  if (progress != null) ...[
                    const SizedBox(width: 6),
                    SizedBox(
                      width: 36,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 3,
                          color: fg,
                          backgroundColor: fg.withAlpha(40),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );

    if (tooltip != null) {
      button = Tooltip(message: tooltip!, child: button);
    }
    return button;
  }
}

// ── Palette Strip ─────────────────────────────────────────────────────────────

class _PaletteStrip extends StatelessWidget {
  const _PaletteStrip({
    required this.colors,
    required this.page,
    required this.ref,
  });
  final List<Color> colors;
  final WorkspacePage page;
  final WidgetRef ref;

  bool get _isIconSection =>
      page == WorkspacePage.svgEditor || page == WorkspacePage.icons;

  void _onTap(Color c) {
    if (_isIconSection) {
      ref.read(iconEditorProvider.notifier)
        ..setBgColor(c)
        ..setBgColor2(c)
        ..setAccentColor(c);
    } else {
      final elState = ref.read(elementProvider);
      ref.read(elementProvider.notifier)
        ..setColor(elState.activeType, c)
        ..setColorSecondary(elState.activeType, c);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(width: 6),
        ...colors.map(
          (c) => MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () => _onTap(c),
              child: Container(
                margin: const EdgeInsets.only(right: 5),
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: c,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withAlpha(80),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: c.withAlpha(100),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
