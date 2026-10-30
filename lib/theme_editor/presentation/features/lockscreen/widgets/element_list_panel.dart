import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:miui_icon_generator/core/theme/app_radius.dart';
import '../../../../../core/theme/theme_extensions.dart';
import '../../../../domain/entities/element_widget.dart';
import '../../../../domain/entities/builtin_widget_styles.dart';
import '../../../providers/element_provider.dart';
import '../../../providers/user_profile_provider.dart';
import '../../../../domain/entities/user_profile.dart';

class ElementListPanel extends ConsumerWidget {
  const ElementListPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.appColors;
    final scheme = Theme.of(context).colorScheme;
    final state = ref.watch(elementProvider);
    final profile = ref.watch(userProfileProvider);
    final user = profile == UserProfileType.defaultUser ? null : profile.name;
    final notifier = ref.read(elementProvider.notifier);
    final addedCount = state.elements.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
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
                'Widgets',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurface,
                ),
              ),
              const Spacer(),
              if (addedCount > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: scheme.primaryContainer,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Text(
                    '$addedCount',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: scheme.onPrimaryContainer,
                    ),
                  ),
                ),
            ],
          ),
        ),

        // List
        Column(
          mainAxisSize: MainAxisSize.min,
          children: kElementGroups.entries.map((entry) {
            final groupAdded = state.elements
                .where((element) => entry.value.contains(element.type))
                .length;
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Theme(
                data: Theme.of(
                  context,
                ).copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  title: Row(
                    children: [
                      Expanded(
                        child: Text(
                          entry.key,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (groupAdded > 0)
                        Container(
                          width: 18,
                          height: 18,
                          decoration: BoxDecoration(
                            color: colors.primary,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              '$groupAdded',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: colors.onPrimary,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  shape: RoundedRectangleBorder(
                    side: BorderSide(color: colors.border),
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                  ),
                  collapsedShape: RoundedRectangleBorder(
                    side: BorderSide(color: colors.border),
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                  ),
                  collapsedBackgroundColor: colors.surfaceOverlay,
                  backgroundColor: colors.surfaceOverlay,
                  children: [
                    if (entry.key == 'Custom Widgets') ...[
                      _SetsTile(
                        title: 'Clock Sets',
                        all: clockSetsFor(user),
                        user: user,
                        owns: (e) => clockSetElementTypes.contains(e.type),
                        state: state,
                        notifier: notifier,
                      ),
                      _SetsTile(
                        title: 'Weather Sets',
                        all: _forUser(builtinWeatherSets, user),
                        user: user,
                        owns: isWeatherSetElement,
                        state: state,
                        notifier: notifier,
                      ),
                      _SetsTile(
                        title: 'Battery Sets',
                        all: _forUser(builtinBatterySets, user),
                        user: user,
                        owns: isBatterySetElement,
                        state: state,
                        notifier: notifier,
                      ),
                    ],
                    ...entry.value.map((type) {
                      final added = state.contains(type);
                      final styled =
                          type == ElementType.shortcutSet ||
                          type == ElementType.analogClock;
                      final style = styled ? _firstStyleFor(type, user) : null;
                      final noStyles = styled && !added && style == null;
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        child: Material(
                          color: added ? colors.primary : Colors.transparent,
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                          clipBehavior: Clip.antiAlias,
                          child: ListTile(
                            dense: true,
                            selected: added,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppRadius.sm),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                            ),
                            leading: Icon(
                              type.isShape
                                  ? Icons.add_rounded
                                  : added
                                  ? Icons.check_circle_rounded
                                  : Icons.radio_button_unchecked_rounded,
                              size: 16,
                              color: added
                                  ? colors.onPrimary
                                  : scheme.onSurfaceVariant,
                            ),
                            title: Tooltip(
                              message: noStyles ? 'No styles for $user' : '',
                              child: Text(
                                type == ElementType.shortcutSet
                                    ? 'Shortcut Sets'
                                    : type.label,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: added
                                      ? FontWeight.w700
                                      : FontWeight.normal,
                                  color: noStyles
                                      ? scheme.onSurface.withAlpha(110)
                                      : added
                                      ? colors.onPrimary
                                      : scheme.onSurface,
                                ),
                              ),
                            ),
                            onTap: () {
                              if (noStyles) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'No ${type == ElementType.shortcutSet ? 'shortcut' : 'analog clock'} styles for $user.',
                                    ),
                                  ),
                                );
                              } else if (!added && style != null) {
                                notifier.add(style);
                              } else if (!added || type.isShape) {
                                notifier.add(
                                  LockElement(
                                    type: type,
                                    sweepAngle: type == ElementType.arcShape
                                        ? 360
                                        : 270,
                                    width: type == ElementType.calendarGrid
                                        ? 560
                                        : type == ElementType.slideToUnlock ||
                                              type == ElementType.dragToUnlock
                                        ? 640
                                        : 200,
                                    height: type == ElementType.calendarGrid
                                        ? 640
                                        : type == ElementType.slideToUnlock ||
                                              type == ElementType.dragToUnlock
                                        ? 128
                                        : 200,
                                    fontSize: type == ElementType.calendarGrid
                                        ? 8
                                        : 20,
                                    unlockBackgroundOpacity:
                                        type == ElementType.dragToUnlock
                                        ? 0
                                        : 48 / 255,
                                    colorSecondary:
                                        type == ElementType.notification
                                        ? colors.primary.withAlpha(60)
                                        : type == ElementType.calendarGrid
                                        ? colors.primary
                                        : Colors.white,
                                  ),
                                );
                              } else {
                                notifier.remove(type);
                              }
                            },
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _SetsTile extends StatelessWidget {
  const _SetsTile({
    required this.title,
    required this.all,
    required this.user,
    required this.owns,
    required this.state,
    required this.notifier,
  });
  final String title;
  final List<ClockSetPreset> all;
  final String? user;
  final bool Function(LockElement element) owns;
  final ElementState state;
  final ElementNotifier notifier;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final scheme = Theme.of(context).colorScheme;
    final added = state.elements.any(owns);
    final empty = all.isEmpty && !added;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Material(
        color: added ? colors.primary : Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        clipBehavior: Clip.antiAlias,
        child: ListTile(
          dense: true,
          selected: added,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12),
          leading: Icon(
            added
                ? Icons.check_circle_rounded
                : Icons.radio_button_unchecked_rounded,
            size: 16,
            color: added ? colors.onPrimary : scheme.onSurfaceVariant,
          ),
          title: Tooltip(
            message: empty ? 'No $title for $user' : '',
            child: Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: added ? FontWeight.w700 : FontWeight.normal,
                color: empty
                    ? scheme.onSurface.withAlpha(110)
                    : added
                    ? colors.onPrimary
                    : scheme.onSurface,
              ),
            ),
          ),
          onTap: () {
            if (added) {
              notifier.removeElements(owns);
            } else if (empty) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text('No $title for $user.')));
            } else {
              notifier.applyElementSet(all.first.elements, owns);
            }
          },
        ),
      ),
    );
  }
}

List<ClockSetPreset> _forUser(List<ClockSetPreset> sets, String? user) => [
  for (final set in sets)
    if (user == null || set.user == null || set.user == user) set,
];

/// The first style of [type] in the sets [user] may use; null if none.
LockElement? _firstStyleFor(ElementType type, String? user) {
  for (final set in builtinStyleSets) {
    if (set.user != null && user != null && set.user != user) continue;
    for (final style in set.styles) {
      if (style.type == type) return style.applyTo(LockElement(type: type));
    }
  }
  return null;
}
