import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:miui_icon_generator/core/theme/app_radius.dart';
import 'package:miui_icon_generator/core/theme/theme_extensions.dart';
import '../../../domain/entities/user_profile.dart';
import '../../../presentation/providers/font_provider.dart';
import '../../../presentation/providers/element_provider.dart';

class FontListPanel extends ConsumerStatefulWidget {
  const FontListPanel({super.key});

  @override
  ConsumerState<FontListPanel> createState() => _FontListPanelState();
}

class _FontListPanelState extends ConsumerState<FontListPanel> {
  String? _hoveredFontFamily;

  @override
  Widget build(BuildContext context) {
    final fontsAsync = ref.watch(fontListProvider);
    final elState = ref.watch(elementProvider);
    final selectedUser = ref.watch(fontUserSelectionProvider);
    final colors = context.appColors;
    final scheme = Theme.of(context).colorScheme;
    final activeFont = elState.active?.font;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
          // Header with preview
          _FontHeaderPreview(
            activeFont: activeFont,
            hoveredFont: _hoveredFontFamily,
            colors: colors,
            scheme: scheme,
          ),

          // User selection grid
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              children: kUserProfiles.entries.map((e) {
                final isSelected = selectedUser == e.key;
                return GestureDetector(
                  onTap: () => ref.read(fontUserSelectionProvider.notifier).select(e.key),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected ? colors.primary : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: CircleAvatar(
                          radius: 16,
                          backgroundImage: AssetImage(e.value.avatarAsset),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        e.value.displayName,
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected ? colors.primary : scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),

          // Font list
          fontsAsync.when(
            loading: () =>
                const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(
              child: Text(
                '$e',
                style: TextStyle(
                  fontSize: 12,
                  color: scheme.error,
                ),
              ),
            ),
            data: (fonts) => ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: fonts.length,
              itemBuilder: (_, i) {
                  final font = fonts[i];
                  final sel = activeFont == font.fontFamily;
                  final isHovered = _hoveredFontFamily == font.fontFamily;
                  return MouseRegion(
                    onEnter: (_) => setState(() => _hoveredFontFamily = font.fontFamily),
                    onExit: (_) => setState(() => _hoveredFontFamily = null),
                    cursor: SystemMouseCursors.click,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 4),
                      decoration: BoxDecoration(
                        color: sel
                            ? colors.primary.withAlpha(30)
                            : isHovered
                                ? colors.primary.withAlpha(15)
                                : Colors.transparent,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        border: Border.all(
                          color: sel
                              ? colors.primary.withAlpha(80)
                              : isHovered
                                  ? colors.primary.withAlpha(40)
                                  : colors.border,
                          width: 1.0,
                        ),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        clipBehavior: Clip.antiAlias,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        child: ListTile(
                          dense: true,
                          contentPadding:
                              const EdgeInsets.symmetric(horizontal: 12),
                          leading: sel
                              ? Icon(Icons.check_rounded,
                                  size: 16, color: colors.primary)
                              : null,
                          title: Text(
                            font.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: font.name,
                              fontSize: 20,
                              color: sel ? colors.primary : scheme.onSurface,
                              fontWeight: sel ? FontWeight.w700 : FontWeight.normal,
                            ),
                          ),
                          subtitle: Text(
                            font.name,
                            style: TextStyle(
                              fontSize: 10,
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                          onTap: () {
                            final type = ref.read(elementProvider).activeType;
                            ref
                                .read(elementProvider.notifier)
                                .setFont(type, font.fontFamily);
                          },
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      );
  }
}

class _FontHeaderPreview extends StatelessWidget {
  const _FontHeaderPreview({
    required this.activeFont,
    required this.hoveredFont,
    required this.colors,
    required this.scheme,
  });
  final String? activeFont;
  final String? hoveredFont;
  final AppColorScheme colors;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    final displayFont = hoveredFont ?? activeFont;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
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
            'Fonts',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: scheme.onSurface,
            ),
          ),
          const Spacer(),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: colors.surfaceOverlay,
              border: Border.all(
                color: hoveredFont != null ? colors.primary.withAlpha(120) : colors.border,
              ),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Text(
              '02 : 36',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: scheme.onSurface,
                fontFamily: displayFont,
              ),
            ),
          ),
          if (activeFont != null) ...[
            const SizedBox(width: 6),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: scheme.secondaryContainer,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Text(
                'Active',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: scheme.onSecondaryContainer,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
