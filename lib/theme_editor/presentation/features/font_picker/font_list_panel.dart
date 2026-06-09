import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:miui_icon_generator/core/theme/app_radius.dart';
import 'package:miui_icon_generator/core/theme/theme_extensions.dart';
import '../../../core/utils/font_utils.dart';
import '../../../data/models/unified_font.dart';
import '../../../domain/entities/user_profile.dart';
import '../../../presentation/providers/font_provider.dart';
import '../../../presentation/providers/element_provider.dart';

const double _kHeaderHeight = 72.0;

class FontListPanel extends ConsumerStatefulWidget {
  const FontListPanel({super.key, this.footer});

  final Widget? footer;

  @override
  ConsumerState<FontListPanel> createState() => _FontListPanelState();
}

class _FontListPanelState extends ConsumerState<FontListPanel> {
  String? _hoveredStorageKey;
  String? _loadingKey;
  final Set<String> _loadedGoogleFonts = {};

  Future<void> _applyFont(UnifiedFont font) async {
    final key = font.storageKey;

    if (font.source == FontSource.google && !_loadedGoogleFonts.contains(key)) {
      if (!mounted) return;
      setState(() => _loadingKey = key);
      try {
        await GoogleFonts.pendingFonts([GoogleFonts.getFont(font.name)]);
        if (!mounted) return;
        _loadedGoogleFonts.add(key);
      } finally {
        if (mounted) setState(() => _loadingKey = null);
      }
    }

    if (!mounted) return;
    final type = ref.read(elementProvider).activeType;
    ref.read(elementProvider.notifier).setFont(type, key);
  }

  @override
  Widget build(BuildContext context) {
    final fontsAsync = ref.watch(unifiedFontListProvider);
    final elState = ref.watch(elementProvider);
    final selectedUser = ref.watch(fontUserSelectionProvider);
    final source = ref.watch(fontSourceProvider);
    final colors = context.appColors;
    final scheme = Theme.of(context).colorScheme;
    final activeFont = elState.active?.font;

    return CustomScrollView(
      slivers: [
        SliverPersistentHeader(
          pinned: true,
          delegate: _FontHeaderDelegate(
            activeFont: activeFont,
            hoveredKey: _hoveredStorageKey,
            source: source,
            onSourceChanged: (s) =>
                ref.read(fontSourceProvider.notifier).select(s),
            colors: colors,
            scheme: scheme,
          ),
        ),

        // User profile grid — only for API fonts
        if (source == FontSource.api)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                children: kUserProfiles.entries.map((e) {
                  final isSelected = selectedUser == e.key;
                  return GestureDetector(
                    onTap: () => ref
                        .read(fontUserSelectionProvider.notifier)
                        .select(e.key),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected
                                  ? colors.primary
                                  : Colors.transparent,
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
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: isSelected
                                ? colors.primary
                                : scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

        // Font list
        fontsAsync.when(
          loading: () => const SliverToBoxAdapter(
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => SliverToBoxAdapter(
            child: Center(
              child: Text(
                '$e',
                style: TextStyle(fontSize: 12, color: scheme.error),
              ),
            ),
          ),
          data: (fonts) => SliverList(
            delegate: SliverChildBuilderDelegate(
              (_, i) {
                final font = fonts[i];
                final key = font.storageKey;
                final sel = activeFont == key;
                final isHovered = _hoveredStorageKey == key;
                final isLoading = _loadingKey == key;

                return MouseRegion(
                  onEnter: (_) =>
                      setState(() => _hoveredStorageKey = key),
                  onExit: (_) =>
                      setState(() => _hoveredStorageKey = null),
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
                        trailing: isLoading
                            ? SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 1.5,
                                  color: colors.primary,
                                ),
                              )
                            : null,
                        title: Text(
                          font.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: font.previewStyle(
                            fontSize: 20,
                            color: sel ? colors.primary : scheme.onSurface,
                            fontWeight:
                                sel ? FontWeight.w700 : FontWeight.normal,
                          ),
                        ),
                        subtitle: Text(
                          font.name,
                          style: TextStyle(
                            fontSize: 10,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                        onTap: () => _applyFont(font),
                      ),
                    ),
                  ),
                );
              },
              childCount: fonts.length,
            ),
          ),
        ),

        if (widget.footer != null)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 16),
              child: widget.footer!,
            ),
          ),

        const SliverToBoxAdapter(child: SizedBox(height: 16)),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Sticky header delegate
// ---------------------------------------------------------------------------

class _FontHeaderDelegate extends SliverPersistentHeaderDelegate {
  const _FontHeaderDelegate({
    required this.activeFont,
    required this.hoveredKey,
    required this.source,
    required this.onSourceChanged,
    required this.colors,
    required this.scheme,
  });

  final String? activeFont;
  final String? hoveredKey;
  final FontSource source;
  final ValueChanged<FontSource> onSourceChanged;
  final AppColorScheme colors;
  final ColorScheme scheme;

  @override
  double get minExtent => _kHeaderHeight;
  @override
  double get maxExtent => _kHeaderHeight;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return ColoredBox(
      color: colors.surface,
      child: Column(
        mainAxisSize: MainAxisSize.max,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _FontHeaderPreview(
            activeFont: activeFont,
            hoveredKey: hoveredKey,
            colors: colors,
            scheme: scheme,
          ),
          _FontSourceToggle(
            source: source,
            onChanged: onSourceChanged,
            colors: colors,
            scheme: scheme,
          ),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(_FontHeaderDelegate old) =>
      old.activeFont != activeFont ||
      old.hoveredKey != hoveredKey ||
      old.source != source;
}

// ---------------------------------------------------------------------------

class _FontHeaderPreview extends StatelessWidget {
  const _FontHeaderPreview({
    required this.activeFont,
    required this.hoveredKey,
    required this.colors,
    required this.scheme,
  });

  final String? activeFont;
  final String? hoveredKey;
  final AppColorScheme colors;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    final displayKey = hoveredKey ?? activeFont;

    final previewStyle = displayKey != null
        ? fontTextStyle(
            font: displayKey,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: scheme.onSurface,
          )
        : TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: scheme.onSurface,
          );

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
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
                color: hoveredKey != null
                    ? colors.primary.withAlpha(120)
                    : colors.border,
              ),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Text('02 : 36', style: previewStyle),
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

class _FontSourceToggle extends StatelessWidget {
  const _FontSourceToggle({
    required this.source,
    required this.onChanged,
    required this.colors,
    required this.scheme,
  });

  final FontSource source;
  final ValueChanged<FontSource> onChanged;
  final AppColorScheme colors;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: FontSource.values.map((s) {
        final selected = source == s;
        final label = s == FontSource.api ? 'Custom' : 'Google Fonts';
        return Padding(
          padding: const EdgeInsets.only(right: 6),
          child: GestureDetector(
            onTap: () => onChanged(s),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: selected ? colors.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(AppRadius.sm),
                border: Border.all(
                  color: selected ? colors.primary : colors.border,
                ),
              ),
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  color: selected ? Colors.white : scheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
