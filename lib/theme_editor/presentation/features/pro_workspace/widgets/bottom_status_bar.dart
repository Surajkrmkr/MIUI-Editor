import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/theme/theme_extensions.dart';
import '../../../providers/system_status_provider.dart';

class BottomStatusBar extends ConsumerWidget {
  const BottomStatusBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.appColors;
    final status = ref.watch(systemStatusProvider);

    return Container(
      height: 24,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(top: BorderSide(color: colors.border)),
      ),
      child: Row(
        children: [
          Icon(
            status.activeTasks > 0
                ? Icons.sync_rounded
                : Icons.check_circle_outline_rounded,
            size: 12,
            color: status.activeTasks > 0 ? colors.warning : colors.success,
          ),
          const SizedBox(width: 6),
          Text(
            status.statusMessage ?? 'Ready',
            style: TextStyle(color: colors.textDisabled, fontSize: 10),
          ),
          const SizedBox(width: 24),
          Text(
            'Tasks: ${status.activeTasks}',
            style: TextStyle(color: colors.textDisabled, fontSize: 10),
          ),

          if (status.exportProgress > 0 && status.exportProgress < 1) ...[
            const SizedBox(width: 16),
            SizedBox(
              width: 60,
              height: 2,
              child: LinearProgressIndicator(
                value: status.exportProgress,
                backgroundColor: colors.border,
                color: colors.primary,
              ),
            ),
          ],

          const Spacer(),
          const _CursorCoordinates(),
          const SizedBox(width: 24),
          Text(
            'Zoom: 100%',
            style: TextStyle(color: colors.textDisabled, fontSize: 10),
          ),
          const SizedBox(width: 24),
          Text(
            'RAM: ${status.memoryUsageMb}MB',
            style: TextStyle(color: colors.textDisabled, fontSize: 10),
          ),
          const SizedBox(width: 12),
          Icon(Icons.notifications_none_rounded,
              size: 14, color: colors.textDisabled),
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
    final colors = context.appColors;
    return MouseRegion(
      onHover: (e) => setState(() => _pos = e.localPosition),
      child: Text(
        'X: ${_pos.dx.toInt()}  Y: ${_pos.dy.toInt()}',
        style: TextStyle(
          color: colors.textDisabled,
          fontSize: 9,
          fontFamily: 'monospace',
        ),
      ),
    );
  }
}
