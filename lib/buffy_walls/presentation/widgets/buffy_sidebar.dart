import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:miui_icon_generator/core/theme/theme_extensions.dart';
import '../../domain/buffy_storage_layout.dart';
import 'buffy_settings_dialog.dart';

class BuffySidebar extends ConsumerWidget {
  const BuffySidebar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                  child: Icon(Icons.dashboard_customize_rounded, size: 24, color: colors.primary),
                ),
                const SizedBox(height: 12),
                Text(
                  'BuffyWalls CMS',
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

          // ── Source File ─────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'SOURCE FILE',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: colors.textSecondary,
                  letterSpacing: 1.1,
                ),
              ),
            ),
          ),

          ListTile(
            leading: Icon(
              Icons.cloud_done_rounded,
              size: 18,
              color: colors.primary,
            ),
            title: Text(
              'buffy.json',
              style: TextStyle(
                color: colors.primary,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
            subtitle: Text(
              'Firebase: $kBuffyBucket',
              style: TextStyle(fontSize: 10, color: colors.textDisabled),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            selected: true,
            dense: true,
            onTap: () {
              Navigator.pop(context);
            },
          ),

          const Spacer(),

          // ── Footer ──────────────────────────────────────────────────────────
          Divider(color: colors.borderSubtle),
          ListTile(
            leading: Icon(Icons.settings_rounded, color: colors.textSecondary, size: 18),
            title: Text('Settings',
                style: TextStyle(color: colors.textPrimary, fontSize: 13)),
            onTap: () {
              Navigator.pop(context);
              showDialog(context: context, builder: (_) => const BuffySettingsDialog());
            },
            dense: true,
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
