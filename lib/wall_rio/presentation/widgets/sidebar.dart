import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:miui_icon_generator/core/theme/theme_extensions.dart';

import '../../application/providers/catalog_provider.dart';
import '../../domain/models/catalog.dart';
import '../screens/settings_screen.dart';

class Sidebar extends ConsumerWidget {
  const Sidebar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kind = ref.watch(selectedKindProvider);
    final settings = ref.watch(storageSettingsProvider).valueOrNull;
    final location = GoRouterState.of(context).uri.path;
    final colors = context.appColors;
    final scheme = Theme.of(context).colorScheme;

    Widget item({
      required IconData icon,
      required String label,
      required bool selected,
      required VoidCallback onTap,
    }) {
      return ListTile(
        leading: Icon(icon, size: 18, color: selected ? colors.primary : colors.textSecondary),
        title: Text(
          label,
          style: TextStyle(
            color: selected ? colors.primary : colors.textPrimary,
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
            fontSize: 13,
          ),
        ),
        selected: selected,
        dense: true,
        onTap: () {
          Navigator.pop(context);
          onTap();
        },
      );
    }

    return Drawer(
      child: Column(
        children: [
          // ── Header ──────────────────────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 48, 20, 20),
            decoration: BoxDecoration(
              color: scheme.primary.withAlpha(18),
              border: Border(bottom: BorderSide(color: colors.borderSubtle)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: colors.primary.withAlpha(25),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.wallpaper_rounded, size: 24, color: colors.primary),
                ),
                const SizedBox(height: 12),
                Text(
                  'WallRio CMS',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: colors.textPrimary),
                ),
                if (settings != null)
                  Text(
                    settings.bucket,
                    style: TextStyle(fontSize: 10, color: colors.textDisabled),
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // ── Catalogs ─────────────────────────────────────────────────────
          for (final k in CatalogKind.values)
            item(
              icon: switch (k) {
                CatalogKind.mobile => Icons.smartphone_rounded,
                CatalogKind.desktop => Icons.desktop_windows_rounded,
                CatalogKind.live => Icons.play_circle_outline_rounded,
                CatalogKind.collections => Icons.collections_bookmark_outlined,
              },
              label: '${k.label} · ${k.jsonFile}',
              selected: location == '/' && kind == k,
              onTap: () {
                ref.read(selectedKindProvider.notifier).select(k);
                context.go('/');
              },
            ),
          item(
            icon: Icons.history_rounded,
            label: 'History & Restore',
            selected: location == '/history',
            onTap: () => context.go('/history'),
          ),

          const Spacer(),

          // ── Footer ──────────────────────────────────────────────────────────
          Divider(color: colors.borderSubtle),
          ListTile(
            leading: Icon(Icons.settings_rounded, color: colors.textSecondary, size: 18),
            title: Text('Settings', style: TextStyle(color: colors.textPrimary, fontSize: 13)),
            onTap: () {
              Navigator.pop(context);
              showWallRioSettings(context);
            },
            dense: true,
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
