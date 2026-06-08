import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/material.dart';
import 'package:miui_icon_generator/core/theme/app_radius.dart';
import 'package:miui_icon_generator/core/theme/theme_extensions.dart';

class AppDropZone extends StatefulWidget {
  const AppDropZone({
    super.key,
    required this.label,
    required this.onDropped,
    this.allowedExtensions,
    this.size = const Size(100, 100),
  });

  final String label;
  final void Function(String path) onDropped;
  final List<String>? allowedExtensions;
  final Size size;

  @override
  State<AppDropZone> createState() => _AppDropZoneState();
}

class _AppDropZoneState extends State<AppDropZone> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) => DropTarget(
        onDragEntered: (_) => setState(() => _hovering = true),
        onDragExited: (_) => setState(() => _hovering = false),
        onDragDone: (d) {
          setState(() => _hovering = false);
          if (d.files.isEmpty) return;
          final path = d.files.first.path;
          final allowed = widget.allowedExtensions;
          if (allowed == null || allowed.any((e) => path.endsWith(e))) {
            widget.onDropped(path);
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          height: widget.size.height,
          width: widget.size.width,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            color: _hovering
                ? context.appColors.primary.withAlpha(20)
                : context.appColors.surface,
            border: Border.all(
              color: _hovering
                  ? context.appColors.primary.withAlpha(120)
                  : context.appColors.border,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            widget.label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _hovering
                  ? context.appColors.primary
                  : context.appColors.textSecondary,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ),
      );
}
