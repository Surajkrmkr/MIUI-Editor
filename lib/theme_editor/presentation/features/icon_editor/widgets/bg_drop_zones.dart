import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:miui_icon_generator/core/theme/app_theme.dart';
import '../../../../presentation/common/widgets/drop_zone.dart';
import '../../../../presentation/providers/icon_editor_provider.dart';
import '../../../../presentation/providers/wallpaper_provider.dart';
import '../../../../presentation/providers/service_providers.dart';
import '../../../../core/constants/path_constants.dart';

class BgDropZones extends ConsumerWidget {
  const BgDropZones({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: 500,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: isDark ? Colors.white.withAlpha(18) : Colors.black.withAlpha(15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section label
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Container(
                  width: 3,
                  height: 12,
                  margin: const EdgeInsets.only(right: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.accent,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Text(
                  'VECTOR ASSETS',
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
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: _DropLabel(
                  label: 'Before Vector',
                  sublabel: '.png',
                  child: AppDropZone(
                    label: 'Before\nVector',
                    allowedExtensions: const ['.png'],
                    onDropped: (path) => _save(ref, path, 'beforeVector'),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _DropLabel(
                  label: 'After Vector',
                  sublabel: '.png',
                  child: AppDropZone(
                    label: 'After\nVector',
                    allowedExtensions: const ['.png'],
                    onDropped: (path) => _save(ref, path, 'afterVector'),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _save(WidgetRef ref, String srcPath, String name) async {
    final ws = ref.read(wallpaperProvider);
    if (ws.weekNum == null || ws.currentThemeName == null) return;
    final tp = PathConstants.themePath(ws.weekNum!, ws.currentThemeName!);
    final dest =
        PathConstants.p('${PathConstants.lockscreenAdvance(tp)}$name.png');
    await ref.read(fileServiceProvider).copyFile(srcPath, dest);
    if (name == 'beforeVector') {
      ref.read(iconEditorProvider.notifier).setBeforeVector(dest);
    } else {
      ref.read(iconEditorProvider.notifier).setAfterVector(dest);
    }
  }
}

class _DropLabel extends StatelessWidget {
  const _DropLabel({
    required this.label,
    required this.sublabel,
    required this.child,
  });
  final String label;
  final String sublabel;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        child,
        const SizedBox(height: 6),
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: scheme.onSurface,
                ),
              ),
              TextSpan(
                text: '  $sublabel',
                style: TextStyle(
                  fontSize: 10,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
