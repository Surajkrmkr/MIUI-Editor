import 'package:flutter_riverpod/flutter_riverpod.dart';

class SystemStatus {
  final int memoryUsageMb;
  final int activeTasks;
  final double exportProgress;
  final String? statusMessage;

  SystemStatus({
    this.memoryUsageMb = 420,
    this.activeTasks = 0,
    this.exportProgress = 0.0,
    this.statusMessage = 'Ready',
  });

  SystemStatus copyWith({
    int? memoryUsageMb,
    int? activeTasks,
    double? exportProgress,
    String? statusMessage,
  }) {
    return SystemStatus(
      memoryUsageMb: memoryUsageMb ?? this.memoryUsageMb,
      activeTasks: activeTasks ?? this.activeTasks,
      exportProgress: exportProgress ?? this.exportProgress,
      statusMessage: statusMessage ?? this.statusMessage,
    );
  }
}

class SystemStatusNotifier extends Notifier<SystemStatus> {
  @override
  SystemStatus build() => SystemStatus();

  void setStatus(String message) => state = state.copyWith(statusMessage: message);
  void addTask() => state = state.copyWith(activeTasks: state.activeTasks + 1);
  void removeTask() => state = state.copyWith(activeTasks: state.activeTasks > 0 ? state.activeTasks - 1 : 0);
  void setProgress(double p) => state = state.copyWith(exportProgress: p);
  void updateMemory(int mb) => state = state.copyWith(memoryUsageMb: mb);
}

final systemStatusProvider = NotifierProvider<SystemStatusNotifier, SystemStatus>(SystemStatusNotifier.new);
