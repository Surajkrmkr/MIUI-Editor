import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:miui_icon_generator/core/theme/app_theme.dart';
import '../../../providers/export_provider.dart';
import '../../../providers/lockscreen_provider.dart';
import '../../../providers/tag_provider.dart';
import '../../lockscreen/lockscreen_screen.dart';

class ExportButtons extends ConsumerWidget {
  const ExportButtons({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exportState = ref.watch(exportProvider);
    final lsState = ref.watch(lockscreenProvider);
    final tags = ref.watch(tagProvider).appliedTags;
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppTheme.cardDark : Colors.white;
    final borderColor = isDark ? Colors.white.withAlpha(18) : Colors.black.withAlpha(15);

    return Container(
      width: 240,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
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
                  color: AppTheme.accent,
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
              if (tags.length < 6) ...[
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: scheme.errorContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'Need 6 tags',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: scheme.onErrorContainer,
                    ),
                  ),
                ),
              ],
            ],
          ),

          const SizedBox(height: 14),

          _ExportButton(
            label: 'Icon + Module',
            sublabel: 'Export icons and modules',
            icon: exportState.isExported
                ? Icons.check_circle_rounded
                : Icons.android_rounded,
            loading: exportState.isRunning,
            progress: exportState.progress,
            statusLabel: exportState.statusLabel,
            isSuccess: exportState.isExported,
            onPressed: () =>
                ref.read(exportProvider.notifier).exportAll(context),
          ),

          const SizedBox(height: 10),

          _ExportButton(
            label: 'Lockscreen',
            sublabel: 'Open lockscreen editor',
            icon: Icons.lock_rounded,
            loading: lsState.isCopyingDefaults,
            outlined: true,
            onPressed: () => _goLockscreen(context, ref),
          ),
        ],
      ),
    );
  }

  Future<void> _goLockscreen(BuildContext context, WidgetRef ref) async {
    await ref.read(lockscreenProvider.notifier).copyDefaultPngs();
    if (context.mounted) {
      Navigator.push(context,
          MaterialPageRoute(builder: (_) => const LockscreenScreen()));
    }
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
    this.progress,
    this.statusLabel,
    this.isSuccess = false,
    this.outlined = false,
  });

  final String label;
  final String sublabel;
  final IconData icon;
  final bool loading;
  final VoidCallback onPressed;
  final double? progress;
  final String? statusLabel;
  final bool isSuccess;
  final bool outlined;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
    final iconBg = outlined
        ? scheme.primaryContainer
        : Colors.white.withAlpha(30);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Material(
          color: bgColor,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: loading ? null : onPressed,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
              decoration: outlined
                  ? BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: scheme.primary.withAlpha(130),
                        width: 1.5,
                      ),
                    )
                  : null,
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: iconBg,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: loading
                          ? SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: fgColor,
                              ),
                            )
                          : Icon(icon, size: 18, color: fgColor),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          label,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: fgColor,
                          ),
                        ),
                        Text(
                          sublabel,
                          style: TextStyle(
                            fontSize: 10,
                            color: fgColor.withAlpha(180),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 16,
                    color: fgColor.withAlpha(160),
                  ),
                ],
              ),
            ),
          ),
        ),
        // Progress bar
        if (loading && progress != null) ...[
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Stack(
              children: [
                Container(height: 4, color: isDark ? AppTheme.surfaceDark : const Color(0xFFF0F0F5)),
                FractionallySizedBox(
                  widthFactor: progress,
                  child: Container(
                    height: 4,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppTheme.accent, AppTheme.accentDark],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        // Status label
        if (statusLabel != null && statusLabel!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              statusLabel!,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: scheme.primary,
              ),
            ),
          ),
      ],
    );
  }
}
