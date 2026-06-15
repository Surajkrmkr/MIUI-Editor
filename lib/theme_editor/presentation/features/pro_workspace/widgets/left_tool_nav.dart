import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/theme/theme_extensions.dart';
import '../../../providers/workspace_provider.dart';
import '../../landing/widgets/settings_dialog.dart';

// ── Layout constants ──────────────────────────────────────────────────────────
const _kTopPadding = 12.0;
const _kItemSlot = 40.0; // padding(2) + container(36) + padding(2)
const _kBarH = 20.0;
const _kBarW = 2.5;

double _barTop(int index) =>
    _kTopPadding + index * _kItemSlot + (_kItemSlot - _kBarH) / 2;

// ─────────────────────────────────────────────────────────────────────────────

class LeftToolNav extends ConsumerWidget {
  const LeftToolNav({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.appColors;
    final page = ref.watch(workspaceProvider).page;
    final n = ref.read(workspaceProvider.notifier);

    // Index of the active main nav item (-1 = none / settings).
    final activeIndex = switch (page) {
      WorkspacePage.svgEditor || WorkspacePage.icons => 0,
      WorkspacePage.lockscreen => 1,
      WorkspacePage.lockscreenPresets => 2,
      _ => -1,
    };

    return Container(
      width: 48,
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(right: BorderSide(color: colors.border)),
      ),
      child: Stack(
        children: [
          // ── Nav items ───────────────────────────────────────────────────
          Positioned.fill(
            child: Column(
              children: [
                const SizedBox(height: _kTopPadding),
                _NavIcon(
                  icon: Icons.grid_view_outlined,
                  activeIcon: Icons.grid_view,
                  label: 'Icon Editor',
                  isActive: activeIndex == 0,
                  onTap: () => n.setPage(WorkspacePage.svgEditor),
                ),
                _NavIcon(
                  icon: Icons.lock_outline_rounded,
                  activeIcon: Icons.lock_rounded,
                  label: 'Lockscreen',
                  isActive: activeIndex == 1,
                  onTap: () => n.setPage(WorkspacePage.lockscreen),
                ),
                _NavIcon(
                  icon: Icons.style_outlined,
                  activeIcon: Icons.style_rounded,
                  label: 'Presets',
                  isActive: activeIndex == 2,
                  onTap: () => n.setPage(
                    page == WorkspacePage.lockscreenPresets
                        ? WorkspacePage.lockscreen
                        : WorkspacePage.lockscreenPresets,
                  ),
                ),
                const Spacer(),
                _NavIcon(
                  icon: Icons.settings_outlined,
                  label: 'Settings',
                  isActive: false,
                  onTap: () => showDialog(
                    context: context,
                    builder: (_) => const SettingsDialog(),
                  ),
                ),
                const SizedBox(height: _kTopPadding),
              ],
            ),
          ),

          // ── Shared sliding accent bar ────────────────────────────────────
          AnimatedPositioned(
            duration: const Duration(milliseconds: 320),
            curve: Curves.easeOutCubic,
            left: 0,
            top: activeIndex >= 0 ? _barTop(activeIndex) : -_kBarH,
            child: _SliderBar(
              visible: activeIndex >= 0,
              color: colors.primary,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Slider bar ────────────────────────────────────────────────────────────────

class _SliderBar extends StatelessWidget {
  const _SliderBar({required this.visible, required this.color});
  final bool visible;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      width: _kBarW,
      height: visible ? _kBarH : 0,
      decoration: BoxDecoration(
        color: color,
        borderRadius: const BorderRadius.horizontal(right: Radius.circular(2)),
      ),
    );
  }
}

// ── Nav icon ──────────────────────────────────────────────────────────────────

class _NavIcon extends StatefulWidget {
  const _NavIcon({
    required this.icon,
    this.activeIcon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  final IconData icon;
  final IconData? activeIcon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  State<_NavIcon> createState() => _NavIconState();
}

class _NavIconState extends State<_NavIcon>
    with SingleTickerProviderStateMixin {
  bool _hovering = false;
  late final AnimationController _pressCtrl;
  late final Animation<double> _pressScale;

  @override
  void initState() {
    super.initState();
    _pressCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 90),
      reverseDuration: const Duration(milliseconds: 160),
    );
    _pressScale = Tween<double>(begin: 1.0, end: 0.82).animate(
      CurvedAnimation(parent: _pressCtrl, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _pressCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return SizedBox(
      width: 48,
      height: _kItemSlot,
      child: Tooltip(
        message: widget.label,
        preferBelow: false,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (_) => setState(() => _hovering = true),
          onExit: (_) {
            setState(() => _hovering = false);
            _pressCtrl.reverse();
          },
          child: GestureDetector(
            onTapDown: (_) => _pressCtrl.forward(),
            onTapUp: (_) {
              _pressCtrl.reverse();
              widget.onTap();
            },
            onTapCancel: () => _pressCtrl.reverse(),
            child: Center(
              child: ScaleTransition(
                scale: _pressScale,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Background pill
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeOut,
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: widget.isActive
                            ? colors.primary.withAlpha(28)
                            : _hovering
                                ? colors.primary.withAlpha(12)
                                : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: widget.isActive
                              ? colors.primary.withAlpha(55)
                              : Colors.transparent,
                          width: 1,
                        ),
                      ),
                    ),

                    // Icon (outlined ↔ filled with scale+fade)
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 220),
                      switchInCurve: Curves.easeOut,
                      switchOutCurve: Curves.easeIn,
                      transitionBuilder: (child, anim) => ScaleTransition(
                        scale: Tween<double>(begin: 0.7, end: 1.0).animate(anim),
                        child: FadeTransition(opacity: anim, child: child),
                      ),
                      child: Icon(
                        widget.isActive
                            ? (widget.activeIcon ?? widget.icon)
                            : widget.icon,
                        key: ValueKey(widget.isActive),
                        color: widget.isActive
                            ? colors.primary
                            : _hovering
                                ? colors.textSecondary
                                : colors.textDisabled,
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
