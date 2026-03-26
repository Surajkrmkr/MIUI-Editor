import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/material.dart';

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
            borderRadius: BorderRadius.circular(20),
            color: _hovering
                ? Theme.of(context).colorScheme.onPrimaryContainer
                : Theme.of(context).colorScheme.primaryContainer,
          ),
          alignment: Alignment.center,
          child: Text(widget.label,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w600)),
        ),
      );
}
