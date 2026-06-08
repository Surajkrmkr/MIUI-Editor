import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:miui_icon_generator/core/theme/app_radius.dart';
import 'package:miui_icon_generator/core/theme/theme_extensions.dart';
import '../../../providers/export_provider.dart';
import '../../../providers/lockscreen_provider.dart';
import '../../../providers/workspace_provider.dart';


class ExportButtons extends ConsumerWidget {
  const ExportButtons({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exportState = ref.watch(exportProvider);
    final lsState = ref.watch(lockscreenProvider);
    final colors = context.appColors;
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surfaceOverlay,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header row
          Row(
            children: [
              Container(
                width: 3,
                height: 16,
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: colors.primary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Text(
                'EXPORT',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurfaceVariant,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          Row(
            children: [
              Expanded(
                child: _ExportButton(
                  label: 'Icon + Module',
                  sublabel: 'Icons/Modules',
                  icon: exportState.isExported
                      ? Icons.check_circle_rounded
                      : Icons.format_paint_outlined,
                  loading: exportState.isRunning,
                  isSuccess: exportState.isExported,
                  onPressed: () =>
                      ref.read(exportProvider.notifier).exportAll(context),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ExportButton(
                  label: 'Lockscreen',
                  sublabel: 'Editor',
                  icon: Icons.wallpaper_rounded,
                  loading: lsState.isCopyingDefaults,
                  outlined: true,
                  onPressed: () => _goLockscreen(context, ref),
                ),
              ),
            ],
          ),

          // Progress bar (Global for the section)
          if (exportState.isRunning) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Stack(
                children: [
                  Container(height: 4, color: colors.border),
                  FractionallySizedBox(
                    widthFactor: exportState.progress,
                    child: Container(
                      height: 4,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [colors.primary, colors.primaryPressed],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (exportState.statusLabel.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  exportState.statusLabel,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: scheme.primary,
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }

  Future<void> _goLockscreen(BuildContext context, WidgetRef ref) async {
    await ref.read(lockscreenProvider.notifier).copyDefaultPngs();
    ref.read(workspaceProvider.notifier).setPage(WorkspacePage.lockscreen);
  }
}

// ── Export Button ─────────────────────────────────────────────────────────────

class _ExportButton extends StatelessWidget {
  const _ExportButton({
    required this.label,
    required this.sublabel,
    required this.icon,
    required this.loading,
    required this.onPressed,
    this.isSuccess = false,
    this.outlined = false,
  });

  final String label;
  final String sublabel;
  final IconData icon;
  final bool loading;
  final VoidCallback onPressed;
  final bool isSuccess;
  final bool outlined;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final bgColor = outlined
        ? Colors.transparent
        : isSuccess
            ? scheme.primaryContainer
            : scheme.primary;
    final fgColor = outlined
        ? scheme.primary
        : isSuccess
            ? scheme.onPrimaryContainer
            : scheme.onPrimary;
    final iconBg =
        outlined ? scheme.primaryContainer : Colors.white.withAlpha(30);

    return Material(
      color: bgColor,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        onTap: loading ? null : onPressed,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: outlined
              ? BoxDecoration(
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  border: Border.all(
                    color: scheme.primary.withAlpha(130),
                    width: 1.5,
                  ),
                )
              : null,
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Center(
                  child: loading
                      ? SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: fgColor,
                          ),
                        )
                      : Icon(icon, size: 16, color: fgColor),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: fgColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      sublabel,
                      style: TextStyle(
                        fontSize: 9,
                        color: fgColor.withAlpha(180),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
