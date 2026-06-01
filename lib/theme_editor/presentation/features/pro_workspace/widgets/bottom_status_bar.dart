import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/system_status_provider.dart';

class BottomStatusBar extends ConsumerWidget {
  const BottomStatusBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(systemStatusProvider);

    return Container(
      height: 24,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: const BoxDecoration(
        color: Color(0xFF1E1E1E),
        border: Border(top: BorderSide(color: Colors.black, width: 1)),
      ),
      child: Row(
        children: [
          Icon(
            status.activeTasks > 0 ? Icons.sync_rounded : Icons.check_circle_outline_rounded,
            size: 12, 
            color: status.activeTasks > 0 ? Colors.blue : Colors.green
          ),
          const SizedBox(width: 6),
          Text(
            status.statusMessage ?? 'Ready',
            style: const TextStyle(color: Colors.white38, fontSize: 10),
          ),
          const SizedBox(width: 24),
          Text(
            'Tasks: ${status.activeTasks}',
            style: const TextStyle(color: Colors.white38, fontSize: 10),
          ),
          
          if (status.exportProgress > 0 && status.exportProgress < 1) ...[
            const SizedBox(width: 16),
            SizedBox(
              width: 60,
              height: 2,
              child: LinearProgressIndicator(
                value: status.exportProgress,
                backgroundColor: Colors.white10,
                color: Colors.blue,
              ),
            ),
          ],
          
          const Spacer(),
          const _CursorCoordinates(),
          const SizedBox(width: 24),
          const Text(
            'Zoom: 100%',
            style: TextStyle(color: Colors.white38, fontSize: 10),
          ),
          const SizedBox(width: 24),
          Text(
            'RAM: ${status.memoryUsageMb}MB',
            style: const TextStyle(color: Colors.white38, fontSize: 10),
          ),
          const SizedBox(width: 12),
          const Icon(Icons.notifications_none_rounded, size: 14, color: Colors.white38),
        ],
      ),
    );
  }
}

class _CursorCoordinates extends StatefulWidget {
  const _CursorCoordinates();

  @override
  State<_CursorCoordinates> createState() => _CursorCoordinatesState();
}

class _CursorCoordinatesState extends State<_CursorCoordinates> {
  Offset _pos = Offset.zero;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onHover: (e) => setState(() => _pos = e.localPosition),
      child: Text(
        'X: ${_pos.dx.toInt()}  Y: ${_pos.dy.toInt()}',
        style: const TextStyle(color: Colors.white10, fontSize: 9, fontFamily: 'monospace'),
      ),
    );
  }
}
