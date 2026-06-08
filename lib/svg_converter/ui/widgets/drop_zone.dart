import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/app_state_provider.dart';

class FolderDropZone extends ConsumerStatefulWidget {
  final Widget child;
  const FolderDropZone({super.key, required this.child});

  @override
  ConsumerState<FolderDropZone> createState() => _FolderDropZoneState();
}

class _FolderDropZoneState extends ConsumerState<FolderDropZone> {
  bool _isDragging = false;

  @override
  Widget build(BuildContext context) {
    return DropTarget(
      onDragEntered: (details) => setState(() => _isDragging = true),
      onDragExited: (details) => setState(() => _isDragging = false),
      onDragDone: (details) {
        setState(() => _isDragging = false);
        if (details.files.isNotEmpty) {
          // Take the first dropped folder
          final path = details.files.first.path;
          ref.read(appStateProvider.notifier).selectFolder(path);
        }
      },
      child: Container(
        decoration: BoxDecoration(
          border: _isDragging 
            ? Border.all(color: Theme.of(context).colorScheme.primary, width: 2)
            : null,
          color: _isDragging ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3) : null,
        ),
        child: widget.child,
      ),
    );
  }
}