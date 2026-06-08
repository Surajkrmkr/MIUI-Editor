import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:miui_icon_generator/core/theme/theme_extensions.dart';
import '../../application/providers/cms_provider.dart';
import '../../application/providers/settings_provider.dart';
import '../screens/settings_screen.dart';

class Sidebar extends ConsumerWidget {
  const Sidebar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentPath = ref.watch(currentFilePathProvider);
    final savedPathsState = ref.watch(savedPathsProvider);
    final colors = context.appColors;
    final scheme = Theme.of(context).colorScheme;

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
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // ── Projects section ─────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'PROJECTS',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: colors.textSecondary,
                  letterSpacing: 1.1,
                ),
              ),
            ),
          ),

          savedPathsState.when(
            data: (paths) => Column(
              children: List.generate(3, (index) {
                final p = index < paths.length ? paths[index] : null;

                if (p == null) {
                  return ListTile(
                    leading: Icon(Icons.add_circle_outline_rounded,
                        size: 18, color: colors.textDisabled),
                    title: Text(
                      'Slot ${index + 1} — Empty',
                      style: TextStyle(color: colors.textDisabled, fontSize: 13),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      showWallRioSettings(context);
                    },
                    dense: true,
                  );
                }

                final isActive = currentPath == p.path;
                return ListTile(
                  leading: Icon(
                    isActive
                        ? Icons.insert_drive_file_rounded
                        : Icons.insert_drive_file_outlined,
                    size: 18,
                    color: isActive ? colors.primary : colors.textSecondary,
                  ),
                  title: Text(
                    p.label,
                    style: TextStyle(
                      color: isActive ? colors.primary : colors.textPrimary,
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                      fontSize: 13,
                    ),
                  ),
                  subtitle: Text(
                    p.path.split('/').last,
                    style: TextStyle(fontSize: 10, color: colors.textDisabled),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  selected: isActive,
                  dense: true,
                  onTap: () {
                    ref.read(currentFilePathProvider.notifier).set(p.path);
                    ref.read(cmsProvider.notifier).loadFile(p.path);
                    Navigator.pop(context);
                  },
                );
              }),
            ),
            loading: () => const Padding(
              padding: EdgeInsets.all(16),
              child: LinearProgressIndicator(),
            ),
            error: (_, __) =>
                const ListTile(title: Text('Error loading projects')),
          ),

          const Spacer(),

          // ── Active file indicator ────────────────────────────────────────
          if (currentPath != null)
            Container(
              margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: colors.primary.withAlpha(15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: colors.primary.withAlpha(40)),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle_rounded, size: 14, color: colors.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Active File',
                          style: TextStyle(
                              fontSize: 9,
                              color: colors.primary,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.8),
                        ),
                        Text(
                          currentPath.split('/').last,
                          style: TextStyle(
                              fontSize: 11,
                              color: colors.textPrimary,
                              fontWeight: FontWeight.w500),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          // ── Footer ──────────────────────────────────────────────────────────
          Divider(color: colors.borderSubtle),
          ListTile(
            leading: Icon(Icons.settings_rounded, color: colors.textSecondary, size: 18),
            title: Text('Settings',
                style: TextStyle(color: colors.textPrimary, fontSize: 13)),
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
