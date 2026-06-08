import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import '../../models/conversion_task.dart';
import '../../providers/app_state_provider.dart';

class TaskList extends ConsumerWidget {
  const TaskList({super.key});

  Widget _buildIcon(TaskStatus status, BuildContext context) {
    switch (status) {
      case TaskStatus.pending:
        return Icon(Icons.circle_outlined, color: Colors.grey.withOpacity(0.5), size: 20);
      case TaskStatus.processing:
        return SizedBox(
          width: 18, height: 18,
          child: CircularProgressIndicator(strokeWidth: 2, color: Theme.of(context).colorScheme.primary),
        );
      case TaskStatus.success:
        return const Icon(Icons.check_circle_rounded, color: Colors.greenAccent, size: 22);
      case TaskStatus.failed:
        return const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 22);
    }
  }

  Widget? _buildSubtitle(ConversionTask task, BuildContext context) {
    if (task.status == TaskStatus.failed) {
      return Text(
        task.errorMessage ?? 'Conversion failed',
        style: const TextStyle(color: Colors.redAccent, fontSize: 12),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    } else if (task.status == TaskStatus.success) {
      final after = task.fileSizeAfter != null ? (task.fileSizeAfter! / 1024).toStringAsFixed(1) : '?';
      final time = task.duration != null ? '${task.duration!.inMilliseconds}ms' : '?';
      return Text(
        '${after}KB • $time',
        style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5), fontSize: 12),
      );
    }
    return Text(
      p.dirname(task.inputPath),
      style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3), fontSize: 11),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget? _buildTrailing(ConversionTask task, BuildContext context) {
    if (task.status == TaskStatus.success) {
      if (task.fileSizeBefore != null && task.fileSizeAfter != null && task.fileSizeBefore! > 0) {
        final ratio = (task.fileSizeAfter! / task.fileSizeBefore!) * 100;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            '${ratio.toStringAsFixed(0)}%',
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
              fontSize: 10,
            ),
          ),
        );
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appStateProvider);
    final tasks = state.tasks;

    if (tasks.isEmpty) {
      return const Center(child: Text('Empty folder', style: TextStyle(color: Colors.grey)));
    }

    return ListView.separated(
      itemCount: tasks.length,
      padding: const EdgeInsets.symmetric(vertical: 8),
      separatorBuilder: (context, index) => Divider(
        height: 1,
        indent: 56,
        color: Theme.of(context).dividerColor.withOpacity(0.05),
      ),
      itemBuilder: (context, index) {
        final task = tasks[index];
        return ListTile(
          dense: true,
          leading: _buildIcon(task.status, context),
          title: Text(
            p.basename(task.inputPath),
            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
          ),
          subtitle: _buildSubtitle(task, context),
          trailing: _buildTrailing(task, context),
        );
      },
    );
  }
}