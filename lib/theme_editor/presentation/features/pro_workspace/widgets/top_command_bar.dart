import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/theme/theme_extensions.dart';
import '../../../providers/workspace_provider.dart';
import '../../../providers/wallpaper_provider.dart';
import '../../../providers/element_provider.dart';
import '../../../providers/icon_editor_provider.dart';
import '../../../providers/export_provider.dart';

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
            icon: Icon(Icons.arrow_back_rounded,
                color: colors.textSecondary, size: 18),
            tooltip: 'Back to Project Selection',
            visualDensity: VisualDensity.compact,
            mouseCursor: SystemMouseCursors.click,
            onPressed: () => Navigator.of(context).pop(),
          ),
          const SizedBox(width: 4),
          IconButton(
            icon:
                Icon(Icons.menu_rounded, color: colors.textSecondary, size: 18),
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
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              );
            },
          ),
          const Spacer(),

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

          // Export button — lockscreen tab only
          Consumer(
            builder: (_, ref, __) {
              final page = ref.watch(workspaceProvider).page;
              if (page != WorkspacePage.lockscreen)
                return const SizedBox.shrink();
              final exportState = ref.watch(exportProvider);
              final colors = context.appColors;
              final scheme = Theme.of(context).colorScheme;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: exportState.isExported
                      ? scheme.primaryContainer
                      : exportState.isRunning
                          ? colors.primary.withAlpha(180)
                          : colors.primary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    mouseCursor: exportState.isRunning
                        ? SystemMouseCursors.wait
                        : SystemMouseCursors.click,
                    onTap: exportState.isRunning
                        ? null
                        : () => ref
                            .read(exportProvider.notifier)
                            .exportAll(context),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (exportState.isRunning)
                            SizedBox(
                              width: 12,
                              height: 12,
                              child: CircularProgressIndicator(
                                strokeWidth: 1.5,
                                color: scheme.onPrimary,
                              ),
                            )
                          else
                            Icon(
                              exportState.isExported
                                  ? Icons.check_circle_rounded
                                  : Icons.file_upload_outlined,
                              size: 14,
                              color: exportState.isExported
                                  ? scheme.onPrimaryContainer
                                  : scheme.onPrimary,
                            ),
                          const SizedBox(width: 6),
                          Text(
                            exportState.isRunning
                                ? exportState.statusLabel
                                : exportState.isExported
                                    ? 'Exported'
                                    : 'Export',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: exportState.isExported
                                  ? scheme.onPrimaryContainer
                                  : scheme.onPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ── Palette Strip ─────────────────────────────────────────────────────────────

class _PaletteStrip extends StatelessWidget {
  const _PaletteStrip(
      {required this.colors, required this.page, required this.ref});
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
        ...colors.map((c) => MouseRegion(
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
                        color: Colors.white.withAlpha(80), width: 1.5),
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
            )),
      ],
    );
  }
}
