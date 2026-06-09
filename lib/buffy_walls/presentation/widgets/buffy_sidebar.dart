import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:miui_icon_generator/core/theme/theme_extensions.dart';
import '../../application/providers/buffy_cms_provider.dart';
import '../../application/providers/buffy_settings_provider.dart';
import 'buffy_settings_dialog.dart';

class BuffySidebar extends ConsumerWidget {
  const BuffySidebar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(buffySettingsProvider);
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

          if (settings.jsonFilePath.isEmpty)
            ListTile(
              leading: Icon(Icons.add_circle_outline_rounded,
                  size: 18, color: colors.textDisabled),
              title: Text(
                'Configure JSON Path',
                style: TextStyle(color: colors.textDisabled, fontSize: 13),
              ),
              onTap: () {
                Navigator.pop(context);
                showDialog(context: context, builder: (_) => const BuffySettingsDialog());
              },
              dense: true,
            )
          else
            ListTile(
              leading: Icon(
                Icons.insert_drive_file_rounded,
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
                settings.jsonFilePath,
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

          // ── Active file indicator ────────────────────────────────────────
          if (settings.jsonFilePath.isNotEmpty)
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
                          settings.jsonFilePath.split('\\').last.split('/').last,
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
