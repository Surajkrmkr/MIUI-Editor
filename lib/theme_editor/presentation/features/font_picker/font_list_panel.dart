import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:miui_icon_generator/core/theme/app_radius.dart';
import 'package:miui_icon_generator/core/theme/theme_extensions.dart';
import '../../../core/utils/font_utils.dart';
import '../../../core/utils/remote_fonts.dart';
import '../../../data/models/unified_font.dart';
import '../../../domain/entities/element_widget.dart';
import '../../../domain/entities/user_profile.dart';
import '../../../presentation/providers/font_provider.dart';
import '../../../presentation/providers/element_provider.dart';

const double _kHeaderHeight = 76.0;

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
  static const _fontRestrictionMessage =
      'Native text uses the system font. Custom fonts are available for image-based clocks.';

  bool _blockUnsupportedFont() {
    if (ref.read(elementProvider).activeType.supportsCustomFont) return false;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(_fontRestrictionMessage),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );
    return true;
  }

  Future<void> _applyFont(UnifiedFont font) async {
    if (_blockUnsupportedFont()) return;
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

    if (font.source.isRemoteCatalog) {
      if (!mounted) return;
      setState(() => _loadingKey = key);
      try {
        await RemoteFonts.ensureKey(key);
      } finally {
        if (mounted) setState(() => _loadingKey = null);
      }
    }

    if (!mounted || _blockUnsupportedFont()) return;
    ref.read(elementProvider.notifier).applyFont(key);
    await ref.read(fontUsageProvider.notifier).rememberFont(font);
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
    final isClockType = clockFontTypes.contains(elState.activeType);

    return CustomScrollView(
      slivers: [
        SliverPersistentHeader(
          pinned: true,
          delegate: _FontHeaderDelegate(
            activeFont: activeFont,
            hoveredKey: _hoveredStorageKey,
            source: source,
            onSourceChanged: (s) {
              if (ref.read(fontSourceProvider) == s) return;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                ref.read(fontSourceProvider.notifier).select(s);
              });
            },
            colors: colors,
            scheme: scheme,
            showLinkToggle: isClockType,
            linkHourMinFont: elState.linkHourMinFont,
            onToggleLink: () =>
                ref.read(elementProvider.notifier).toggleLinkHourMinFont(),
          ),
        ),

        // User profile horizontal list — only for API fonts
        if (source == FontSource.api)
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: colors.surfaceOverlay,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: colors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.palette_outlined,
                        size: 13,
                        color: colors.primary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'DESIGNER COLLECTIONS',
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.6,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      children: kUserProfiles.entries.map((e) {
                        final isSelected = selectedUser == e.key;
                        return Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(AppRadius.md),
                            onTap: isSelected
                                ? null
                                : () {
                                    WidgetsBinding.instance
                                        .addPostFrameCallback((_) {
                                      ref
                                          .read(
                                            fontUserSelectionProvider.notifier,
                                          )
                                          .select(e.key);
                                    });
                                  },
                            child: Padding(
                              padding: const EdgeInsets.all(2),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 180),
                                    padding: const EdgeInsets.all(2),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: isSelected
                                            ? colors.primary
                                            : colors.border.withAlpha(120),
                                        width: isSelected ? 2 : 1.5,
                                      ),
                                      boxShadow: isSelected
                                          ? [
                                              BoxShadow(
                                                color: colors.primary.withAlpha(
                                                  60,
                                                ),
                                                blurRadius: 6,
                                                spreadRadius: 1,
                                              ),
                                            ]
                                          : null,
                                    ),
                                    child: CircleAvatar(
                                      radius: 17,
                                      backgroundColor: colors.surface,
                                      backgroundImage: AssetImage(
                                        e.value.avatarAsset,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    e.value.displayName,
                                    style: TextStyle(
                                      fontSize: 10,
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
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
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
          data: (fonts) => fonts.isEmpty && source == FontSource.frequent
              ? SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 24,
                      horizontal: 12,
                    ),
                    child: Text(
                      'No frequently used fonts yet.',
                      style: TextStyle(color: scheme.onSurfaceVariant),
                    ),
                  ),
                )
              : SliverGrid(
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 180,
                    mainAxisExtent: 64,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 6,
                  ),
                  delegate: SliverChildBuilderDelegate((_, i) {
                    final font = fonts[i];
                    final key = font.storageKey;
                    final sel = activeFont == key;
                    final isHovered = _hoveredStorageKey == key;
                    final isLoading = _loadingKey == key;

                    return MouseRegion(
                      onEnter: (_) => setState(() => _hoveredStorageKey = key),
                      onExit: (_) => setState(() => _hoveredStorageKey = null),
                      cursor: SystemMouseCursors.click,
                      child: Container(
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
                          child: InkWell(
                            key: ValueKey('font-$key'),
                            onTap: () => _applyFont(font),
                            child: Semantics(
                              button: true,
                              selected: sel,
                              child: Stack(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 6,
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        SizedBox(
                                          height: 26,
                                          width: double.infinity,
                                          child: Padding(
                                            padding: const EdgeInsets.only(
                                              right: 18,
                                            ),
                                            child: FittedBox(
                                              fit: BoxFit.scaleDown,
                                              alignment: Alignment.centerLeft,
                                              child: Text(
                                                '02:36',
                                                style: font.previewStyle(
                                                  fontSize: 20,
                                                  color: sel
                                                      ? colors.primary
                                                      : scheme.onSurface,
                                                  fontWeight: sel
                                                      ? FontWeight.w700
                                                      : FontWeight.normal,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          font.name,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: scheme.onSurfaceVariant,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (sel || isLoading)
                                    Positioned(
                                      top: 6,
                                      right: 6,
                                      child: isLoading
                                          ? SizedBox(
                                              width: 14,
                                              height: 14,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 1.5,
                                                color: colors.primary,
                                              ),
                                            )
                                          : Icon(
                                              Icons.check_rounded,
                                              size: 14,
                                              color: colors.primary,
                                            ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }, childCount: fonts.length),
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
    required this.showLinkToggle,
    required this.linkHourMinFont,
    required this.onToggleLink,
  });

  final String? activeFont;
  final String? hoveredKey;
  final FontSource source;
  final ValueChanged<FontSource> onSourceChanged;
  final AppColorScheme colors;
  final ColorScheme scheme;
  final bool showLinkToggle;
  final bool linkHourMinFont;
  final VoidCallback onToggleLink;

  static const double _linkRowHeight = 44.0;

  @override
  double get minExtent =>
      _kHeaderHeight + (showLinkToggle ? _linkRowHeight : 0);
  @override
  double get maxExtent => minExtent;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return ColoredBox(
      color: colors.surface,
      child: SizedBox(
        height: minExtent,
        child: Column(
          mainAxisSize: MainAxisSize.max,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: SizedBox(
                height: 28,
                child: _FontHeaderPreview(
                  activeFont: activeFont,
                  hoveredKey: hoveredKey,
                  colors: colors,
                  scheme: scheme,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: SizedBox(
                height: 32,
                child: _FontSourceToggle(
                  source: source,
                  onChanged: onSourceChanged,
                  colors: colors,
                  scheme: scheme,
                ),
              ),
            ),
            if (showLinkToggle)
              Padding(
                padding: const EdgeInsets.only(top: 4, bottom: 6),
                child: Container(
                  height: 34,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: colors.surfaceOverlay,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(
                      color: linkHourMinFont
                          ? colors.primary.withAlpha(60)
                          : colors.border,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.link_rounded,
                              size: 14,
                              color: linkHourMinFont
                                  ? colors.primary
                                  : scheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                'Link Hour, Min & Sec',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: linkHourMinFont
                                      ? scheme.onSurface
                                      : scheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Transform.scale(
                        scale: 0.75,
                        child: Switch.adaptive(
                          value: linkHourMinFont,
                          onChanged: (_) => onToggleLink(),
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(_FontHeaderDelegate old) =>
      old.activeFont != activeFont ||
      old.hoveredKey != hoveredKey ||
      old.source != source ||
      old.showLinkToggle != showLinkToggle ||
      old.linkHourMinFont != linkHourMinFont;
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

    return Row(
      children: [
        Container(
          width: 3,
          height: 14,
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
            letterSpacing: 0.2,
          ),
        ),
        const Spacer(),
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: hoveredKey != null
                ? colors.primary.withAlpha(20)
                : colors.surfaceOverlay,
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
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              color: colors.primary.withAlpha(25),
              borderRadius: BorderRadius.circular(AppRadius.full),
              border: Border.all(color: colors.primary.withAlpha(70)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 5,
                  height: 5,
                  margin: const EdgeInsets.only(right: 4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: colors.primary,
                  ),
                ),
                Text(
                  'Active',
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w600,
                    color: colors.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
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
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(children: FontSource.values.map(_chip).toList()),
    );
  }

  Widget _chip(FontSource s) {
    final selected = source == s;
    final icon = switch (s) {
      FontSource.frequent => Icons.history_rounded,
      FontSource.api => Icons.brush_outlined,
      FontSource.google => Icons.font_download_outlined,
      FontSource.fontsource => Icons.cloud_queue_rounded,
      FontSource.fontshare => Icons.share_rounded,
    };

    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.full),
          onTap: selected ? null : () => onChanged(s),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: selected ? colors.primary : colors.surfaceOverlay,
              borderRadius: BorderRadius.circular(AppRadius.full),
              border: Border.all(
                color: selected ? colors.primary : colors.border,
                width: 1,
              ),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: colors.primary.withAlpha(50),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 13,
                  color: selected ? Colors.white : scheme.onSurfaceVariant,
                ),
                const SizedBox(width: 5),
                Text(
                  s.label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                    color: selected ? Colors.white : scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
