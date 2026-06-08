import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:miui_icon_generator/core/theme/app_theme.dart';
import '../../../providers/export_provider.dart';

class IconExportCard extends ConsumerWidget {
  const IconExportCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exportState = ref.watch(exportProvider);
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    const cardBg = AppTheme.proCard;
    const borderColor = Colors.black;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ExportButton(
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

          // Progress bar
          if (exportState.isRunning) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Stack(
                children: [
                  Container(
                      height: 4,
                      color: isDark
                          ? AppTheme.proSidebar
                          : const Color(0xFFF0F0F5)),
                  FractionallySizedBox(
                    widthFactor: exportState.progress,
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
}

class _ExportButton extends StatelessWidget {
  const _ExportButton({
    required this.label,
    required this.sublabel,
    required this.icon,
    required this.loading,
    required this.onPressed,
    this.isSuccess = false,
  });

  final String label;
  final String sublabel;
  final IconData icon;
  final bool loading;
  final VoidCallback onPressed;
  final bool isSuccess;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final bgColor = isSuccess ? scheme.primaryContainer : scheme.primary;
    final fgColor = isSuccess ? scheme.onPrimaryContainer : scheme.onPrimary;
    final iconBg = Colors.white.withAlpha(30);

    return Material(
      color: bgColor,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: loading ? null : onPressed,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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
              const SizedBox(width: 12),
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
