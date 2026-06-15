import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:miui_icon_generator/core/theme/app_radius.dart';
import '../../../../../core/theme/theme_extensions.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../domain/entities/element_widget.dart';
import '../../../providers/directory_provider.dart';
import '../../../providers/lockscreen_provider.dart';
import '../../../../../widgets/iphone_frame.dart';
import 'preset_thumbnail.dart';
import 'preset_preview_dialog.dart';

// ── Frame geometry (must match IPhoneFrame constants) ────────────────────────
const _frameW = AppConstants.screenWidth + 26; // 302.92
const _frameH = AppConstants.screenHeight + 16; // 616
const _displayW = 140.0;
const _displayH = _frameH * _displayW / _frameW; // ≈ 284.7
const _frameScale = _displayW / _frameW;

// IPhoneFrame internals (mirrored here for hover-glow math)
const _iphoneBtnGap = 5.0;
const _iphoneBodyRadius = 48.0;
// Scaled versions for the card thumbnail size
const _glowInset = _iphoneBtnGap * _frameScale; // ≈ 2.31 px
const _glowRadius = _iphoneBodyRadius * _frameScale; // ≈ 22.2 px

/// Loads a preset's JSON, renders a phone-canvas thumbnail, and applies it on tap.
class PresetCard extends ConsumerWidget {
  const PresetCard({
    super.key,
    required this.path,
    required this.index,
    this.onApplied,
  });

  final String path;
  final int index;

  /// Called after the preset is loaded. When non-null the card does NOT call
  /// [Navigator.pop] — the caller decides what happens next (inline use).
  final VoidCallback? onApplied;

  Future<List<LockElement>> _load() async {
    final file = File('$path${Platform.pathSeparator}preset.json');
    if (!await file.exists()) return [];
    final raw = await file.readAsString();
    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .map((e) => LockElement.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final name = path.split(Platform.pathSeparator).last;
    final previewFile = File('$path${Platform.pathSeparator}preview.png');

    return FutureBuilder<List<LockElement>>(
      future: _load(),
      builder: (context, snapshot) {
        Widget phoneContent;

        if (previewFile.existsSync()) {
          phoneContent = Image.file(
            previewFile,
            fit: BoxFit.cover,
            width: AppConstants.screenWidth,
            height: AppConstants.screenHeight,
          );
        } else {
          phoneContent = switch (snapshot.connectionState) {
            ConnectionState.done when snapshot.hasData => PresetThumbnail(
                elements: snapshot.data!,
                thumbnailWidth: AppConstants.screenWidth,
              ),
            ConnectionState.done => _ErrorPlaceholder(),
            _ => _LoadingPlaceholder(),
          };
        }

        final elements = snapshot.data ?? [];

        return _PresetCardFrame(
          name: name,
          index: index,
          onTap: () async {
            await ref
                .read(lockscreenProvider.notifier)
                .loadPreset('$path${Platform.pathSeparator}preset.json');
            if (!context.mounted) return;
            if (onApplied != null) {
              onApplied!();
            } else {
              Navigator.pop(context);
            }
          },
          onPreview: elements.isEmpty
              ? null
              : () => showDialog<void>(
                    context: context,
                    builder: (_) => PresetPreviewDialog(
                      elements: elements,
                      presetName: name,
                      onApply: (mappedElements) async {
                        await ref
                            .read(lockscreenProvider.notifier)
                            .applyElements(mappedElements);
                        if (context.mounted && onApplied == null) {
                          Navigator.pop(context);
                        }
                        onApplied?.call();
                      },
                    ),
                  ),
          onDelete: () async {
            final confirmed = await showDialog<bool>(
              context: context,
              builder: (dlgCtx) => AlertDialog(
                title: const Text('Delete Preset'),
                content: Text('Delete "$name"? This cannot be undone.'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(dlgCtx, false),
                    child: const Text('Cancel'),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.pop(dlgCtx, true),
                    style: FilledButton.styleFrom(
                      backgroundColor: Theme.of(dlgCtx).colorScheme.error,
                    ),
                    child: const Text('Delete'),
                  ),
                ],
              ),
            );
            if (confirmed != true) return;
            try {
              await Directory(path).delete(recursive: true);
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Delete failed: $e')),
                );
              }
              return;
            }
            ref.read(directoryProvider.notifier).loadPresetPaths();
          },
          onRename: () async {
            final newName = await showDialog<String>(
              context: context,
              builder: (_) => _RenameDialog(initialName: name),
            );
            if (newName != null && newName.isNotEmpty && newName != name) {
              final parent = Directory(path).parent.path;
              await Directory(path)
                  .rename('$parent${Platform.pathSeparator}$newName');
              if (context.mounted) {
                ref.read(directoryProvider.notifier).loadPresetPaths();
              }
            }
          },
          phone: SizedBox(
            width: _displayW,
            height: _displayH,
            child: OverflowBox(
              alignment: Alignment.topLeft,
              maxWidth: _frameW,
              maxHeight: _frameH,
              child: Transform.scale(
                scale: _frameScale,
                alignment: Alignment.topLeft,
                child: IPhoneFrame(child: phoneContent),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _PresetCardFrame extends StatefulWidget {
  const _PresetCardFrame({
    required this.name,
    required this.index,
    required this.onTap,
    required this.onDelete,
    required this.onRename,
    required this.phone,
    this.onPreview,
  });

  final String name;
  final int index;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback onRename;
  final VoidCallback? onPreview;
  final Widget phone;

  @override
  State<_PresetCardFrame> createState() => _PresetCardFrameState();
}

class _PresetCardFrameState extends State<_PresetCardFrame>
    with SingleTickerProviderStateMixin {
  bool _hovering = false;
  late final AnimationController _ctrl;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _onEnter(_) {
    setState(() => _hovering = true);
    _ctrl.forward();
  }

  void _onExit(_) {
    setState(() => _hovering = false);
    _ctrl.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: _onEnter,
      onExit: _onExit,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _hovering ? 1.04 : 1.0,
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          child: Column(
            children: [
              // ── Phone with overlays ──────────────────────────────────────
              Expanded(
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.topLeft,
                  children: [
                    widget.phone,

                    // Hover glow — matches IPhoneFrame body shape exactly:
                    // inset by _glowInset on each side, radius = _glowRadius.
                    FadeTransition(
                      opacity: _fade,
                      child: IgnorePointer(
                        child: SizedBox(
                          width: _displayW,
                          height: _displayH,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: _glowInset),
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                borderRadius:
                                    BorderRadius.circular(_glowRadius),
                                border: Border.all(
                                  color: cs.primary.withAlpha(200),
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: cs.primary.withAlpha(55),
                                    blurRadius: 16,
                                    spreadRadius: 3,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    // "Tap to apply" fade-in bar at the bottom of the phone body
                    FadeTransition(
                      opacity: _fade,
                      child: IgnorePointer(
                        child: SizedBox(
                          width: _displayW,
                          height: _displayH,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: _glowInset),
                            child: Align(
                              alignment: Alignment.bottomCenter,
                              child: Container(
                                height: 40,
                                decoration: BoxDecoration(
                                  borderRadius: const BorderRadius.vertical(
                                    bottom: Radius.circular(_glowRadius),
                                  ),
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.transparent,
                                      cs.primary.withAlpha(200),
                                    ],
                                  ),
                                ),
                                alignment: Alignment.bottomCenter,
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Text(
                                  'Tap to apply',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 8,
                                    letterSpacing: 0.4,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 6),

              // Preset name
              Text(
                widget.name,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontSize: 9,
                  color: cs.onSurfaceVariant.withAlpha(180),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 4),

              // Action buttons — fade in on hover
              FadeTransition(
                opacity: _fade,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.onPreview != null) ...[
                      _ActionButton(
                        icon: Icons.visibility_rounded,
                        color: cs.secondary,
                        tooltip: 'Preview',
                        onTap: widget.onPreview!,
                      ),
                      const SizedBox(width: 4),
                    ],
                    _ActionButton(
                      icon: Icons.drive_file_rename_outline_rounded,
                      color: cs.primary,
                      tooltip: 'Rename',
                      onTap: widget.onRename,
                    ),
                    const SizedBox(width: 4),
                    _ActionButton(
                      icon: Icons.delete_outline_rounded,
                      color: cs.error,
                      tooltip: 'Delete',
                      onTap: widget.onDelete,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.color,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon, size: 14),
      tooltip: tooltip,
      style: IconButton.styleFrom(
        foregroundColor: color,
        backgroundColor: color.withAlpha(20),
        minimumSize: const Size(28, 28),
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.radiusXs),
      ),
      onPressed: onTap,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _LoadingPlaceholder extends StatelessWidget {
  static const _w = 120.0;
  static const _h = _w * AppConstants.screenHeight / AppConstants.screenWidth;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      width: _w,
      height: _h,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [colors.bg, colors.surfaceElevated],
        ),
      ),
      child: const Center(
        child: SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }
}

class _ErrorPlaceholder extends StatelessWidget {
  static const _w = 120.0;
  static const _h = _w * AppConstants.screenHeight / AppConstants.screenWidth;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      width: _w,
      height: _h,
      color: colors.error.withAlpha(30),
      child: Center(
          child: Icon(Icons.error_outline, size: 22, color: colors.error)),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _RenameDialog extends StatefulWidget {
  const _RenameDialog({required this.initialName});
  final String initialName;

  @override
  State<_RenameDialog> createState() => _RenameDialogState();
}

class _RenameDialogState extends State<_RenameDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialName);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() => Navigator.pop(context, _controller.text.trim());

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Rename Preset'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        decoration: const InputDecoration(labelText: 'New name'),
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _submit,
          child: const Text('Rename'),
        ),
      ],
    );
  }
}
